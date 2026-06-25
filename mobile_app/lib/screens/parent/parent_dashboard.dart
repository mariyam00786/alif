import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../components/portal_ui.dart';
import '../../services/google_auth_service.dart';
import '../../services/parent_api_service.dart';
import 'child_detail_screen.dart';
import 'parent_approvals_screen.dart';
import 'parent_data.dart';
import 'parent_home_screen.dart';

/// Bottom-navigation shell shown to an authenticated parent.
///
/// Tabs: Home (children overview) · Approvals · Profile.
/// Notifications live in the header bell. Selecting a child from Home opens
/// the per-child detail in place.
class ParentDashboard extends StatefulWidget {
  final AppLocale locale;
  final ValueChanged<AppLocale> onLocaleChanged;
  final VoidCallback onLogout;

  /// When provided, the profile tab offers a "switch to student" action so a
  /// dual student/parent account can return to its own student board without
  /// signing out. Defaults to null for parent-only accounts.
  final VoidCallback? onSwitchToStudent;

  const ParentDashboard({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onLogout,
    this.onSwitchToStudent,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  ParentChild? _openChild;

  List<ParentChild> _children = const [];
  List<PortalNotification> _notifications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final results = await Future.wait([
        ParentApiService.fetchChildren(),
        ParentApiService.fetchNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _children = results[0] as List<ParentChild>;
        _notifications = results[1] as List<PortalNotification>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, labelEn: 'Home', labelMl: 'ഹോം'),
    _NavItem(
      icon: Icons.fact_check_rounded,
      labelEn: 'Approvals',
      labelMl: 'അംഗീകാരം',
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
      if (index != 0) _openChild = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.isMalayalam;
    final user = MobileGoogleAuthService.currentUser;
    final parentName = user?.name ?? (isMalayalam ? 'രക്ഷിതാവ്' : 'Parent');

    final homeTab = _openChild != null
        ? ChildDetailScreen(
            child: _openChild!,
            isMalayalam: isMalayalam,
            onBack: () => setState(() => _openChild = null),
          )
        : ParentHomeScreen(
            isMalayalam: isMalayalam,
            parentName: parentName,
            children: _children,
            notifications: _notifications,
            loading: _loading,
            error: _error,
            onRefresh: _load,
            onOpenChild: (child) => setState(() => _openChild = child),
            onOpenApprovals: () => _select(1),
          );

    final pages = [
      homeTab,
      ParentApprovalsScreen(isMalayalam: isMalayalam, onChanged: _load),
      _buildProfile(isMalayalam, parentName),
    ];

    return Scaffold(
      backgroundColor: kSurface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<String>('$_selectedIndex-${_openChild?.id ?? ''}'),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isMalayalam),
    );
  }

  Widget _buildProfile(bool isMalayalam, String parentName) {
    final user = MobileGoogleAuthService.currentUser;
    final email = user?.email;
    final avatarUrl = user?.avatarUrl;
    final initial = (parentName.isNotEmpty ? parentName.trim()[0] : '?')
        .toUpperCase();
    final childCount = _children.length;

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
                            parentName,
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
                                ? 'രക്ഷിതാവ് · $childCount കുട്ടികൾ'
                                : 'Parent · $childCount children',
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
                icon: Icons.translate_rounded,
                label: isMalayalam ? 'ഭാഷ' : 'Language',
                trailing: Text(
                  isMalayalam ? 'മലയാളം' : 'English',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => widget.onLocaleChanged(
                  isMalayalam ? AppLocale.en : AppLocale.ml,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.onSwitchToStudent != null) ...[
                _profileTile(
                  icon: Icons.school_rounded,
                  label: isMalayalam
                      ? 'വിദ്യാർഥി പോർട്ടൽ തുറക്കുക'
                      : 'Open student portal',
                  onTap: widget.onSwitchToStudent,
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
    final totalPending = _children.fold<int>(
      0,
      (sum, c) => sum + c.pendingApprovals,
    );

    return AppBottomNavBar(
      isMalayalam: isMalayalam,
      currentIndex: _selectedIndex,
      onTap: _select,
      items: [
        for (var i = 0; i < _navItems.length; i++)
          AppNavItem(
            icon: _navItems[i].icon,
            labelEn: _navItems[i].labelEn,
            labelMl: _navItems[i].labelMl,
            badgeCount: i == 1 ? totalPending : 0,
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
