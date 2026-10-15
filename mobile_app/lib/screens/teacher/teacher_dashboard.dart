import 'package:flutter/material.dart';

import '../../components/portal_ui.dart';
import '../../provider/app_state_provider.dart';
import '../../services/google_auth_service.dart';
import '../../services/teacher_api_service.dart';
import 'teacher_analytics_screen.dart';
import 'teacher_data.dart';
import 'teacher_home_screen.dart';
import 'teacher_student_detail_screen.dart';
import 'teacher_students_screen.dart';

/// Bottom-navigation shell shown to an authenticated teacher (FRD §4.3).
///
/// Tabs: Home (dashboard) · Students · Analytics · Profile.
/// Notifications live in the header bell; the floating action button composes
/// a batch reminder / motivational message (FRD §4.3.4).
class TeacherDashboard extends StatefulWidget {
  final AppLocale locale;
  final ValueChanged<AppLocale> onLocaleChanged;
  final VoidCallback onLogout;

  const TeacherDashboard({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onLogout,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  TeacherStudent? _openStudent;
  String? _focusBatchId;
  bool _loadingLive = false;

  @override
  void initState() {
    super.initState();
    _refreshLive();
  }

  /// Pulls live batches/students from the backend (no-op in demo mode).
  Future<void> _refreshLive() async {
    setState(() => _loadingLive = true);
    final ok = await TeacherApiService.refresh();
    if (!mounted) return;
    setState(() => _loadingLive = false);
    if (ok) {
      // Surface the signed-in teacher's name on the dashboard.
      final user = MobileGoogleAuthService.currentUser;
      if (user?.name != null && user!.name!.isNotEmpty) {
        TeacherData.teacherName = user.name!;
        TeacherData.teacherNameMl = user.name!;
      }
    }
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, labelEn: 'Home', labelMl: 'ഹോം'),
    _NavItem(
      icon: Icons.groups_rounded,
      labelEn: 'Students',
      labelMl: 'വിദ്യാർഥികൾ',
    ),
    _NavItem(
      icon: Icons.insights_rounded,
      labelEn: 'Analytics',
      labelMl: 'വിശകലനം',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      labelEn: 'Profile',
      labelMl: 'പ്രൊഫൈൽ',
    ),
  ];

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      _openStudent = null;
      if (index != 1) _focusBatchId = null;
    });
  }

  void _openStudentDetail(TeacherStudent student) {
    setState(() => _openStudent = student);
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final user = MobileGoogleAuthService.currentUser;
    final teacherName =
        user?.name ??
        (isMalayalam ? TeacherData.teacherNameMl : TeacherData.teacherName);

    // A student detail overlays whichever tab is active.
    final Widget body = _openStudent != null
        ? TeacherStudentDetailScreen(
            isMalayalam: isMalayalam,
            student: _openStudent!,
            onBack: () => setState(() => _openStudent = null),
          )
        : _buildTab(isMalayalam, teacherName);

    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<String>(
                '$_selectedIndex-${_openStudent?.id ?? ''}-${_focusBatchId ?? ''}',
              ),
              child: body,
            ),
          ),
          if (_loadingLive)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: kGreen,
              ),
            ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0 && _openStudent == null)
          ? FloatingActionButton.extended(
              onPressed: () => _composeMessage(isMalayalam),
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign_rounded),
              label: Text(isMalayalam ? 'അറിയിപ്പ്' : 'Notify'),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(isMalayalam),
    );
  }

  Widget _buildTab(bool isMalayalam, String teacherName) {
    switch (_selectedIndex) {
      case 1:
        return TeacherStudentsScreen(
          isMalayalam: isMalayalam,
          batches: TeacherData.batches,
          students: TeacherData.students,
          initialBatchId: _focusBatchId,
          onOpenStudent: _openStudentDetail,
        );
      case 2:
        return TeacherAnalyticsScreen(
          isMalayalam: isMalayalam,
          batches: TeacherData.batches,
          students: TeacherData.students,
        );
      case 3:
        return _buildProfile(isMalayalam, teacherName);
      case 0:
      default:
        return TeacherHomeScreen(
          isMalayalam: isMalayalam,
          teacherName: teacherName,
          batches: TeacherData.batches,
          needsAttention: TeacherData.needsAttention,
          onOpenBatch: (batch) {
            setState(() {
              _focusBatchId = batch.id;
              _selectedIndex = 1;
            });
          },
          onOpenStudent: _openStudentDetail,
          onOpenStudents: () => _select(1),
        );
    }
  }

  Future<void> _composeMessage(bool isMalayalam) async {
    if (TeacherData.batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMalayalam ? 'ബാച്ചുകളൊന്നുമില്ല' : 'No batches available',
          ),
        ),
      );
      return;
    }
    String? batchId = TeacherData.batches.first.id;
    // type: batch_reminder | motivational | acknowledgement (FRD §4.3.4).
    String type = 'batch_reminder';
    final controller = TextEditingController();

    final sent = await showModalBottomSheet<({String batchId, String type, String message})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final types = <({String key, String en, String ml, IconData icon, Color color})>[
              (key: 'batch_reminder', en: 'Reminder', ml: 'റിമൈൻഡർ', icon: Icons.campaign_rounded, color: kGreen),
              (key: 'motivational', en: 'Motivational', ml: 'പ്രചോദനം', icon: Icons.auto_awesome_rounded, color: const Color(0xFF8B5CF6)),
              (key: 'acknowledgement', en: 'Acknowledge', ml: 'അംഗീകാരം', icon: Icons.workspace_premium_rounded, color: const Color(0xFFF59E0B)),
            ];
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isMalayalam ? 'ബാച്ചിന് അറിയിപ്പ്' : 'Notify a batch',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kHeading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMalayalam
                        ? 'റിമൈൻഡർ, പ്രചോദനം അല്ലെങ്കിൽ നേട്ട അംഗീകാരം അയയ്ക്കുക.'
                        : 'Send a reminder, motivational note or acknowledge an achievement.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Batch selector
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TeacherData.batches.map((b) {
                      final selected = b.id == batchId;
                      return GestureDetector(
                        onTap: () => setSheet(() => batchId = b.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? kGreen : Colors.white,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: selected ? kGreen : kBorder,
                            ),
                          ),
                          child: Text(
                            isMalayalam ? b.nameMl : b.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : kBody,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Type selector
                  Row(
                    children: types.map((t) {
                      final selected = type == t.key;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setSheet(() => type = t.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? t.color.withValues(alpha: 0.12) : Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(
                                  color: selected ? t.color : kBorder,
                                  width: selected ? 1.6 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(t.icon, color: t.color, size: 20),
                                  const SizedBox(height: 5),
                                  Text(
                                    isMalayalam ? t.ml : t.en,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? t.color : kBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: isMalayalam
                          ? 'നിങ്ങളുടെ സന്ദേശം...'
                          : 'Your message...',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kGreen, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final msg = controller.text.trim();
                        if (msg.isEmpty || batchId == null) return;
                        Navigator.pop(
                          ctx,
                          (batchId: batchId!, type: type, message: msg),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                        isMalayalam ? 'അയയ്ക്കുക' : 'Send',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (sent == null || !mounted) return;

    // Persist via the API when live; else keep a local-only snackbar.
    final result = await TeacherApiService.notifyBatch(
      sent.batchId,
      title: '',
      body: sent.message,
      type: sent.type,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? (isMalayalam
                    ? '${result.recipients} വിദ്യാർഥികൾക്ക് അറിയിപ്പ് അയച്ചു'
                    : 'Sent to ${result.recipients} student${result.recipients == 1 ? '' : 's'}')
              : (isMalayalam
                    ? 'അയയ്ക്കാനായില്ല — ലൈവ് അല്ലെങ്കിൽ ലോക്കൽ ആയി സൂക്ഷിച്ചു'
                    : 'Could not send — saved locally (demo mode)'),
        ),
        backgroundColor: result != null ? kGreen : const Color(0xFFDC2626),
      ),
    );
  }

  Widget _buildProfile(bool isMalayalam, String teacherName) {
    final user = MobileGoogleAuthService.currentUser;
    final email = user?.email;
    final avatarUrl = user?.avatarUrl;
    final initial = (teacherName.isNotEmpty ? teacherName.trim()[0] : '?')
        .toUpperCase();

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
                            teacherName,
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
                            isMalayalam
                                ? 'അധ്യാപകൻ · ${TeacherData.batches.length} ബാച്ചുകൾ'
                                : 'Teacher · ${TeacherData.batches.length} batches',
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
                icon: Icons.logout_rounded,
                label: isMalayalam ? 'ലോഗ് ഔട്ട്' : 'Log out',
                danger: true,
                onTap: widget.onLogout,
              ),
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

  Widget _buildBottomNav(bool isMalayalam) {
    return AppBottomNavBar(
      isMalayalam: isMalayalam,
      currentIndex: _openStudent == null ? _selectedIndex : -1,
      onTap: _select,
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
