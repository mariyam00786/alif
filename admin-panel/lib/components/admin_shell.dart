import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/admin_spacing.dart';
import '../model/app_models.dart';
import 'admin_top_actions.dart';
import 'alif_logo.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.selectedSection,
    required this.sections,
    required this.onSectionSelected,
    required this.onSignOut,
    required this.child,
    this.notifications = kAdminNotifications,
  });

  final AdminSection selectedSection;
  final List<AdminSection> sections;
  final ValueChanged<AdminSection> onSectionSelected;
  final Future<void> Function() onSignOut;
  final Widget child;
  final List<AdminNotification> notifications;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _tabletSidebarHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // During web startup and window resizing the shell can momentarily be
        // laid out at a near-zero width. Building the full (mobile) scaffold at
        // that point forces the fixed-size app-bar actions to overflow and logs
        // a RenderFlex error, so wait until a realistic width is available.
        if (constraints.maxWidth < 300) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }

        final viewport = _viewportForWidth(constraints.maxWidth);

        final textScale = constraints.maxWidth < 600
            ? 0.90
            : constraints.maxWidth <= 1024
            ? 0.96
            : 1.0;

        final media = MediaQuery.of(context);
        final scaffold = _buildScaffoldForViewport(context, viewport);

        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: scaffold,
        );
      },
    );
  }

  Widget _buildScaffoldForViewport(
    BuildContext context,
    _ShellViewport viewport,
  ) {
    if (viewport == _ShellViewport.mobile) {
      const primarySections = <AdminSection>[
        AdminSection.dashboard,
        AdminSection.students,
        AdminSection.teachers,
        AdminSection.activities,
      ];

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildMobileAppBar(context),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.xs + 6,
              AdminSpacing.xs + 6,
              AdminSpacing.xs + 6,
              0,
            ),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: _MobileNav(
          primarySections: primarySections,
          selectedSection: widget.selectedSection,
          onSectionSelected: widget.onSectionSelected,
          onMoreTapped: () => _showMoreSheet(context),
        ),
      );
    }

    if (viewport == _ShellViewport.tablet) {
      final showExpandedSidebar = _tabletSidebarHovered;
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _tabletSidebarHovered = true),
              onExit: (_) => setState(() => _tabletSidebarHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: showExpandedSidebar ? 248 : 84,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: showExpandedSidebar ? 248 : 84,
                    maxWidth: showExpandedSidebar ? 248 : 84,
                    child: SizedBox(
                      width: showExpandedSidebar ? 248 : 84,
                      child: _SidebarContent(
                        sections: widget.sections,
                        selectedSection: widget.selectedSection,
                        onSectionSelected: widget.onSectionSelected,
                        collapsed: !showExpandedSidebar,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      height: 72,
                      horizontalPadding: 20,
                      onSignOut: widget.onSignOut,
                      notifications: widget.notifications,
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 268,
            child: _SidebarContent(
              sections: widget.sections,
              selectedSection: widget.selectedSection,
              onSectionSelected: widget.onSectionSelected,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    onSignOut: widget.onSignOut,
                    notifications: widget.notifications,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ShellViewport _viewportForWidth(double width) {
    if (width < 600) {
      return _ShellViewport.mobile;
    }
    if (width <= 1024) {
      return _ShellViewport.tablet;
    }
    return _ShellViewport.desktop;
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 68,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: AdminSpacing.lg,
      title: Row(
        children: [
          const AlifLogo(height: 30),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Text(
              'Alif Online Moral School',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        AdminNotificationBell(size: 40, notifications: widget.notifications),
        const SizedBox(width: AdminSpacing.sm),
        AdminProfileButton(onSignOut: widget.onSignOut, size: 40),
        const SizedBox(width: AdminSpacing.md),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    const secondarySections = <AdminSection>[
      AdminSection.batches,
      AdminSection.rating,
      AdminSection.badges,
      AdminSection.notifications,
      AdminSection.reports,
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MoreSheet(
        sections: secondarySections,
        selectedSection: widget.selectedSection,
        onSectionSelected: (s) {
          HapticFeedback.selectionClick();
          Navigator.of(ctx).pop();
          widget.onSectionSelected(s);
        },
      ),
    );
  }
}

enum _ShellViewport { mobile, tablet, desktop }

// ── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onSignOut,
    required this.notifications,
    this.height = 80,
    this.horizontalPadding = 28,
  });

  final Future<void> Function() onSignOut;
  final List<AdminNotification> notifications;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alif Online Moral School',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin Console',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          AdminNotificationBell(notifications: notifications),
          const SizedBox(width: AdminSpacing.xs + 6),
          AdminProfileButton(onSignOut: onSignOut),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.sections,
    required this.selectedSection,
    required this.onSectionSelected,
    this.collapsed = false,
  });

  final List<AdminSection> sections;
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSectionSelected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            collapsed ? AdminSpacing.md : AdminSpacing.md + 6,
            AdminSpacing.xxl,
            collapsed ? AdminSpacing.md : AdminSpacing.md + 6,
            AdminSpacing.md + 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              if (collapsed)
                const Center(child: AlifLogo(height: 36))
              else
                Row(
                  children: [
                    const AlifLogo(height: 38),
                    const SizedBox(width: AdminSpacing.xs + 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alif',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Online Moral School',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AdminSpacing.xxl + 2),
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AdminSpacing.xs,
                    bottom: AdminSpacing.xs + 6,
                  ),
                  child: Text(
                    'MENU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AdminSpacing.xs),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return _SidebarTile(
                      section: section,
                      selected: section == selectedSection,
                      collapsed: collapsed,
                      onTap: () => onSectionSelected(section),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.section,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final AdminSection section;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final label = _sectionLabels[section] ?? 'Item';
    final icon = _sectionIcons[section] ?? Icons.circle;

    final activeColor = primary;
    const inactiveColor = Color(0xFF64748B);

    final tile = InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AdminSpacing.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : AdminSpacing.md,
          vertical: AdminSpacing.xs + 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AdminSpacing.md),
        ),
        child: collapsed
            ? Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? activeColor : inactiveColor,
                ),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(width: AdminSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? activeColor : const Color(0xFF475569),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (collapsed) {
      return Tooltip(message: label, child: tile);
    }
    return tile;
  }
}

// ── Mobile Bottom Navigation ────────────────────────────────────────────────
class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.primarySections,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onMoreTapped,
  });

  final List<AdminSection> primarySections;
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSectionSelected;
  final VoidCallback onMoreTapped;

  @override
  Widget build(BuildContext context) {
    final isMoreActive = !primarySections.contains(selectedSection);

    final items = <Widget>[
      ...primarySections.map((section) {
        final icon = _sectionIcons[section] ?? Icons.circle;
        return Expanded(
          child: _NavItem(
            icon: icon,
            label: _sectionLabels[section] ?? '',
            selected: section == selectedSection,
            onTap: () => onSectionSelected(section),
          ),
        );
      }),
      Expanded(
        child: _NavItem(
          icon: Icons.more_horiz,
          label: 'More',
          selected: isMoreActive,
          onTap: onMoreTapped,
        ),
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFEEF0F2))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  final bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    const inactiveColor = Color(0xFF94A3B8);
    final icon = widget.icon;
    final selected = widget.selected;
    final label = widget.label;

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 25,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                letterSpacing: 0,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── More Bottom Sheet ────────────────────────────────────────────────────────
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({
    required this.sections,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final List<AdminSection> sections;
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.md,
        AdminSpacing.xl,
        AdminSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AdminSpacing.xl),
          Text(
            'More',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AdminSpacing.md,
            mainAxisSpacing: AdminSpacing.md,
            childAspectRatio: 2.8,
            children: sections.map((section) {
              final icon = _sectionIcons[section] ?? Icons.circle;
              final label = _sectionLabels[section] ?? '';
              final selected = section == selectedSection;

              return InkWell(
                onTap: () => onSectionSelected(section),
                borderRadius: BorderRadius.circular(AdminSpacing.md + 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.md + 2,
                    vertical: AdminSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AdminSpacing.md + 2),
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.10)
                        : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected
                            ? theme.colorScheme.primary
                            : const Color(0xFF475569),
                      ),
                      const SizedBox(width: AdminSpacing.sm),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? theme.colorScheme.primary
                                : const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Section Labels & Icons ──────────────────────────────────────────────────
const Map<AdminSection, String> _sectionLabels = {
  AdminSection.dashboard: 'Dashboard',
  AdminSection.students: 'Students',
  AdminSection.teachers: 'Teachers',
  AdminSection.batches: 'Batches & Classes',
  AdminSection.activities: 'Activities',
  AdminSection.rating: 'Rating & Scoring',
  AdminSection.badges: 'Badges',
  AdminSection.notifications: 'Notifications',
  AdminSection.reports: 'Reports',
};

const Map<AdminSection, IconData> _sectionIcons = {
  AdminSection.dashboard: Icons.home_rounded,
  AdminSection.students: Icons.trending_up_rounded,
  AdminSection.teachers: Icons.fact_check_outlined,
  AdminSection.batches: Icons.class_rounded,
  AdminSection.activities: Icons.auto_graph_rounded,
  AdminSection.rating: Icons.star_rate_rounded,
  AdminSection.badges: Icons.workspace_premium_rounded,
  AdminSection.notifications: Icons.notifications_rounded,
  AdminSection.reports: Icons.leaderboard_rounded,
};
