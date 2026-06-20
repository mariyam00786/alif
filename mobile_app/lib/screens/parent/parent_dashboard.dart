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

  const ParentDashboard({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
    required this.onLogout,
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
                                color: Color(0xFF1B6B3A),
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
                    color: Color(0xFF1B6B3A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => widget.onLocaleChanged(
                  isMalayalam ? AppLocale.en : AppLocale.ml,
                ),
              ),
              const SizedBox(height: 10),
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
    final color = danger ? const Color(0xFFD45555) : const Color(0xFF1B6B3A);
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

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final selected = _selectedIndex == index;
            final showBadge = index == 1 && totalPending > 0;
            return Expanded(
              child: GestureDetector(
                onTap: () => _select(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1B6B3A).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: selected ? 40 : 36,
                            height: selected ? 40 : 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF1B6B3A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  '$totalPending',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMalayalam ? item.labelMl : item.labelEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF1B6B3A)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
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
