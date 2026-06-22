import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../components/portal_ui.dart';
import '../../services/google_auth_service.dart';
import '../../services/api_service.dart';
import '../daily_marking_screen.dart';
import '../leaderboard_screen.dart';
import '../progress_view_screen.dart';
import '../student_home_screen.dart';
import '../student_badges_screen.dart';

/// Bottom-navigation shell shown to an authenticated student / parent.
class MobileStudentDashboard extends StatefulWidget {
  final AppLocale locale;
  final ValueChanged<AppLocale> onLocaleChanged;
  final VoidCallback onLogout;
  final String studentId;
  final String studentName;

  /// When provided the board is shown in "parent viewing" mode: a slim back
  /// bar appears at the top and the profile tab offers a return-to-parent
  /// action instead of logging out. Defaults to null (the student's own board).
  final VoidCallback? onExit;

  /// When provided, the profile tab offers a "switch to parent" action for a
  /// dual student/parent account (single sign-in, no re-login). Defaults to
  /// null for accounts that are not linked to any children.
  final VoidCallback? onSwitchToParent;

  const MobileStudentDashboard({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onLogout,
    this.studentId = 'self',
    this.studentName = 'My Progress',
    this.onExit,
    this.onSwitchToParent,
  });

  @override
  State<MobileStudentDashboard> createState() => _MobileStudentDashboardState();
}

class _MobileStudentDashboardState extends State<MobileStudentDashboard> {
  int _selectedIndex = 0;

  // Local settings state (persisted to the backend once wired).
  bool _notifyDailyReminder = true;
  bool _notifyResults = true;
  bool _notifyBadges = true;
  bool _privacyInitialsOnly = false;
  bool _privacyHideRank = false;

  // Real home-dashboard summary fetched from the backend.
  Map<String, dynamic>? _homeSummary;

  @override
  void initState() {
    super.initState();
    // The home summary endpoint is student-self only; skip in parent-view mode.
    if (widget.onExit == null) {
      _loadHomeSummary();
    }
  }

  Future<void> _loadHomeSummary() async {
    final res = await MobileApiService.getHomeSummary();
    if (!mounted || !res.success || res.data == null) return;
    setState(() => _homeSummary = res.data);
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, labelEn: 'Home', labelMl: 'ഹോം'),
    _NavItem(
      icon: Icons.trending_up_rounded,
      labelEn: 'Progress',
      labelMl: 'പുരോഗതി',
    ),
    _NavItem(
      icon: Icons.check_box_outlined,
      labelEn: 'Marking',
      labelMl: 'മാർക്കിംഗ്',
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      labelEn: 'Ranking',
      labelMl: 'റാങ്കിംഗ്',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      labelEn: 'Profile',
      labelMl: 'പ്രൊഫൈൽ',
    ),
  ];

  void _goToTab(int index) => setState(() => _selectedIndex = index);

  void _openBadges() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudentBadgesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final today = DateTime.now().toIso8601String().split('T').first;

    // When the student is viewing their own board (onExit == null) greet them
    // by their real signed-in name; in parent-viewing mode keep the child name.
    final greetingName = widget.onExit == null
        ? (MobileGoogleAuthService.currentUser?.name?.trim().isNotEmpty == true
              ? MobileGoogleAuthService.currentUser!.name!.trim()
              : widget.studentName)
        : widget.studentName;

    final pages = [
      StudentHomeScreen(
        studentName: greetingName,
        onMarkToday: () => _goToTab(2),
        onOpenProgress: () => _goToTab(1),
        onOpenRanking: () => _goToTab(3),
        onOpenBadges: _openBadges,
        todayDone: (_homeSummary?['today_done'] as num?)?.toInt() ?? 0,
        todayTotal: (_homeSummary?['today_total'] as num?)?.toInt() ?? 9,
        streakDays: (_homeSummary?['streak_days'] as num?)?.toInt() ?? 0,
        weekPoints: (_homeSummary?['week_points'] as num?)?.toInt() ?? 0,
        batchRank: (_homeSummary?['batch_rank'] as num?)?.toInt() ?? 0,
      ),
      ProgressViewScreen(
        studentId: widget.studentId,
        studentName: widget.studentName,
      ),
      DailyMarkingScreen(
        studentId: widget.studentId,
        date: today,
        onSubmitSuccess: _loadHomeSummary,
      ),
      LeaderboardScreen(
        batchId: widget.studentId,
        batchName: (_homeSummary?['batch_name'] as String?) ?? 'My Batch',
      ),
      _buildProfile(isMalayalam),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Column(
        children: [
          if (widget.onExit != null) _viewingBar(isMalayalam),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isMalayalam),
    );
  }

  /// Slim bar shown above the board when a parent is viewing a child's board.
  Widget _viewingBar(bool isMalayalam) {
    return Material(
      color: const Color(0xFF115E59),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 14, 2),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onExit,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: isMalayalam ? 'രക്ഷിതാവിലേക്ക്' : 'Back to parent',
              ),
              const Icon(
                Icons.visibility_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMalayalam
                      ? '${widget.studentName} ന്റെ ബോർഡ് കാണുന്നു'
                      : "Viewing ${widget.studentName}'s board",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(bool isMalayalam) {
    final user = MobileGoogleAuthService.currentUser;
    final name = user?.name ?? widget.studentName;
    final email = user?.email;
    final avatarUrl = user?.avatarUrl;
    final initial = (name.isNotEmpty ? name.trim()[0] : '?').toUpperCase();
    return Column(
      children: [
        PortalHeader(
          title: isMalayalam ? 'പ്രൊഫൈൽ' : 'Profile',
          subtitle: email,
          icon: Icons.person_rounded,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EC),
                        shape: BoxShape.circle,
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: avatarUrl != null
                          ? null
                          : Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1729),
                            ),
                          ),
                          if (email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            isMalayalam ? 'വിദ്യാർത്ഥി' : 'Student',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _profileTile(
                icon: Icons.edit_rounded,
                label: isMalayalam ? 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക' : 'Edit profile',
                onTap: () => _openEditProfile(isMalayalam, name),
              ),
              const SizedBox(height: 10),
              _batchInfoCard(isMalayalam),
              const SizedBox(height: 16),
              SectionLabel(
                isMalayalam ? 'ക്രമീകരണങ്ങൾ' : 'Settings',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 12),
              _profileTile(
                icon: Icons.military_tech_rounded,
                label: isMalayalam
                    ? 'ബാഡ്ജുകൾ & നേട്ടങ്ങൾ'
                    : 'Badges & achievements',
                onTap: _openBadges,
              ),
              const SizedBox(height: 10),
              _profileTile(
                icon: Icons.notifications_active_rounded,
                label: isMalayalam
                    ? 'അറിയിപ്പ് ക്രമീകരണം'
                    : 'Notification settings',
                onTap: () => _openNotificationSettings(isMalayalam),
              ),
              const SizedBox(height: 10),
              _profileTile(
                icon: Icons.shield_outlined,
                label: isMalayalam ? 'സ്വകാര്യത' : 'Privacy settings',
                onTap: () => _openPrivacySettings(isMalayalam),
              ),
              const SizedBox(height: 10),
              if (widget.onExit != null)
                _profileTile(
                  icon: Icons.arrow_back_rounded,
                  label: isMalayalam
                      ? 'രക്ഷിതാവ് ബോർഡിലേക്ക് മടങ്ങുക'
                      : 'Back to parent board',
                  onTap: widget.onExit,
                )
              else ...[
                if (widget.onSwitchToParent != null) ...[
                  _profileTile(
                    icon: Icons.family_restroom_rounded,
                    label: isMalayalam
                        ? 'രക്ഷിതാവ് കാഴ്ചയിലേക്ക് മാറുക'
                        : 'Switch to parent view',
                    onTap: widget.onSwitchToParent,
                  ),
                  const SizedBox(height: 10),
                ],
                _profileTile(
                  icon: Icons.logout_rounded,
                  label: isMalayalam ? 'ലോഗ് ഔട്ട്' : 'Log out',
                  danger: true,
                  onTap: widget.onLogout,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final color = danger ? const Color(0xFFD45555) : const Color(0xFF0F766E);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: danger
                        ? const Color(0xFFD45555)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
              ?trailing,
              if (trailing == null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _batchInfoCard(bool isMalayalam) {
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F766E)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F1729),
            ),
          ),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          row(
            Icons.groups_rounded,
            isMalayalam ? 'ബാച്ച്' : 'Batch',
            (_homeSummary?['batch_name'] as String?) ?? '—',
          ),
          const Divider(height: 1, color: Color(0xFFEFF1F3)),
          row(
            Icons.class_rounded,
            isMalayalam ? 'ക്ലാസ്' : 'Class',
            isMalayalam ? '7-ാം ക്ലാസ്' : 'Grade 7',
          ),
          const Divider(height: 1, color: Color(0xFFEFF1F3)),
          row(
            Icons.badge_rounded,
            isMalayalam ? 'റോൾ നമ്പർ' : 'Roll No.',
            '12',
          ),
        ],
      ),
    );
  }

  void _openEditProfile(bool isMalayalam, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMalayalam ? 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക' : 'Edit Profile',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1729),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: isMalayalam ? 'പേര്' : 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isMalayalam ? 'ഫോൺ' : 'Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final newName = nameCtrl.text.trim();
                  final newPhone = phoneCtrl.text.trim();
                  Navigator.of(ctx).pop();
                  final res = await MobileApiService.updateMyProfile(
                    fullName: newName.isEmpty ? null : newName,
                    phone: newPhone.isEmpty ? null : newPhone,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        res.success
                            ? (isMalayalam
                                  ? 'പ്രൊഫൈൽ സേവ് ചെയ്തു'
                                  : 'Profile saved')
                            : (isMalayalam
                                  ? 'സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല'
                                  : 'Could not save profile'),
                      ),
                      backgroundColor: res.success
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFB91C1C),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isMalayalam ? 'സേവ് ചെയ്യുക' : 'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationSettings(bool isMalayalam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMalayalam ? 'അറിയിപ്പ് ക്രമീകരണം' : 'Notification Settings',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F1729),
                ),
              ),
              const SizedBox(height: 8),
              _switchTile(
                isMalayalam ? 'ദിന ഓർമ്മപ്പെടുത്തൽ' : 'Daily reminder',
                _notifyDailyReminder,
                (v) {
                  setSheet(() {});
                  setState(() => _notifyDailyReminder = v);
                },
              ),
              _switchTile(
                isMalayalam ? 'ഫല അറിയിപ്പുകൾ' : 'Result alerts',
                _notifyResults,
                (v) {
                  setSheet(() {});
                  setState(() => _notifyResults = v);
                },
              ),
              _switchTile(
                isMalayalam ? 'പുതിയ ബാഡ്ജുകൾ' : 'New badges',
                _notifyBadges,
                (v) {
                  setSheet(() {});
                  setState(() => _notifyBadges = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrivacySettings(bool isMalayalam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMalayalam ? 'സ്വകാര്യത' : 'Privacy Settings',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F1729),
                ),
              ),
              const SizedBox(height: 8),
              _switchTile(
                isMalayalam
                    ? 'റാങ്കിംഗിൽ ഇനീഷ്യൽ മാത്രം കാണിക്കുക'
                    : 'Show initials only in ranking',
                _privacyInitialsOnly,
                (v) {
                  setSheet(() {});
                  setState(() => _privacyInitialsOnly = v);
                },
              ),
              _switchTile(
                isMalayalam
                    ? 'മറ്റുള്ളവരിൽ നിന്ന് റാങ്ക് മറയ്ക്കുക'
                    : 'Hide my rank from others',
                _privacyHideRank,
                (v) {
                  setSheet(() {});
                  setState(() => _privacyHideRank = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF0F766E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isMalayalam) {
    return AppBottomNavBar(
      isMalayalam: isMalayalam,
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: [
        for (final item in _navItems)
          AppNavItem(
            icon: item.icon,
            labelEn: item.labelEn,
            labelMl: item.labelMl,
          ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String labelEn;
  final String labelMl;

  const _NavItem({
    required this.icon,
    required this.labelEn,
    required this.labelMl,
  });
}
