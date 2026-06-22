import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final bool _isMalayalam = false;

  @override
  Widget build(BuildContext context) {
    final pageCopy =
        _sectionCopy[widget.selectedSection] ??
        const _SectionCopy('Overview', 'അവലോകനം');

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _viewportForWidth(constraints.maxWidth);

        final textScale = constraints.maxWidth < 600
            ? 0.90
            : constraints.maxWidth <= 1024
            ? 0.96
            : 1.0;

        final media = MediaQuery.of(context);
        final scaffold = _buildScaffoldForViewport(context, viewport, pageCopy);

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
    _SectionCopy pageCopy,
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: widget.child,
          ),
        ),
        bottomNavigationBar: _MobileNav(
          primarySections: primarySections,
          selectedSection: widget.selectedSection,
          isMalayalam: _isMalayalam,
          onSectionSelected: widget.onSectionSelected,
          onMoreTapped: () => _showMoreSheet(context),
        ),
      );
    }

    if (viewport == _ShellViewport.tablet) {
      final showExpandedSidebar = _tabletSidebarHovered;
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _tabletSidebarHovered = true),
              onExit: (_) => setState(() => _tabletSidebarHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: showExpandedSidebar ? 260 : 88,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: showExpandedSidebar ? 260 : 88,
                    maxWidth: showExpandedSidebar ? 260 : 88,
                    child: SizedBox(
                      width: showExpandedSidebar ? 260 : 88,
                      child: _SidebarContent(
                        sections: widget.sections,
                        selectedSection: widget.selectedSection,
                        isMalayalam: _isMalayalam,
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
                      isMalayalam: _isMalayalam,
                      height: 78,
                      horizontalPadding: 16,
                      onSignOut: widget.onSignOut,
                      notifications: widget.notifications,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 16, 0),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: _SidebarContent(
              sections: widget.sections,
              selectedSection: widget.selectedSection,
              isMalayalam: _isMalayalam,
              onSectionSelected: widget.onSectionSelected,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    isMalayalam: _isMalayalam,
                    onSignOut: widget.onSignOut,
                    notifications: widget.notifications,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 24, 0),
                      child: widget.child,
                    ),
                  ),
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
      toolbarHeight: 72,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const AlifLogo(height: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alif Online Moral School',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AdminNotificationBell(
          isMalayalam: _isMalayalam,
          size: 40,
          notifications: widget.notifications,
        ),
        const SizedBox(width: 8),
        AdminProfileButton(
          isMalayalam: _isMalayalam,
          onSignOut: widget.onSignOut,
          size: 40,
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    const secondarySections = <AdminSection>[
      AdminSection.batches,
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
        isMalayalam: _isMalayalam,
        onSectionSelected: (s) {
          Navigator.of(ctx).pop();
          widget.onSectionSelected(s);
        },
      ),
    );
  }
}

enum _ShellViewport { mobile, tablet, desktop }

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onSignOut,
    required this.notifications,
    this.isMalayalam = false,
    this.height = 90,
    this.horizontalPadding = 24,
  });

  final Future<void> Function() onSignOut;
  final List<AdminNotification> notifications;
  final bool isMalayalam;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: isMalayalam
                ? Text(
                    'അലിഫ് ഓൺലൈൻ മോറൽ സ്കൂൾ',
                    style: GoogleFonts.notoSansMalayalam(
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Text(
                    'Alif Online Moral School',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryColor.withValues(alpha: 0.22)),
            ),
            child: Text(
              'Admin Console',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AdminNotificationBell(
            isMalayalam: isMalayalam,
            notifications: notifications,
          ),
          const SizedBox(width: 10),
          AdminProfileButton(isMalayalam: isMalayalam, onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.sections,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.isMalayalam,
    this.collapsed = false,
  });

  final List<AdminSection> sections;
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSectionSelected;
  final bool isMalayalam;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1220), Color(0xFF0F172A)],
        ),
        border: Border(right: BorderSide(color: Colors.white24, width: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            collapsed ? 10 : 18,
            20,
            collapsed ? 10 : 18,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(collapsed ? 8 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Align(
                  alignment: collapsed
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: AlifLogo(height: collapsed ? 52 : 88),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(height: 14),
                isMalayalam
                    ? Text(
                        'അലിഫ് ഓൺലൈൻ മോറൽ സ്കൂൾ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansMalayalam(
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Text(
                        'Alif Online Moral School',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final selected = section == selectedSection;
                    final copy =
                        _sectionCopy[section] ??
                        const _SectionCopy('Item', 'ഇനം');
                    final icon = _sectionIcons[section] ?? Icons.circle;

                    final navTile = InkWell(
                      onTap: () => onSectionSelected(section),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        constraints: const BoxConstraints(
                          minHeight: 56,
                          minWidth: 56,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 0 : 16,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.92,
                                    ),
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.72,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: selected
                              ? null
                              : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.65,
                                  )
                                : Colors.white.withValues(alpha: 0.14),
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: collapsed
                            ? Align(
                                alignment: Alignment.center,
                                child: Icon(
                                  icon,
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                  size: 24,
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      icon,
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: isMalayalam
                                        ? Text(
                                            copy.malayalam,
                                            style:
                                                GoogleFonts.notoSansMalayalam(
                                                  textStyle: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: selected
                                                            ? Colors.white
                                                            : Colors.white70,
                                                      ),
                                                ),
                                          )
                                        : Text(
                                            copy.english,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: selected
                                                      ? Colors.white
                                                      : Colors.white70,
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                      ),
                    );

                    if (collapsed) {
                      return Tooltip(message: copy.english, child: navTile);
                    }
                    return navTile;
                  },
                ),
              ),
              if (!collapsed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isMalayalam
                          ? Text(
                              'ഇന്നത്തെ ഫോക്കസ്',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansMalayalam(
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            )
                          : Text(
                              'Today Focus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      const SizedBox(height: 8),
                      isMalayalam
                          ? Text(
                              'അനുമതികളും റിപ്പോർട്ടുകളും പുതുക്കുക',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansMalayalam(
                                textStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          : Text(
                              'Review approvals, publish updates, and finalize daily reports.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile Bottom Navigation ────────────────────────────────────────────────
class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.primarySections,
    required this.selectedSection,
    required this.isMalayalam,
    required this.onSectionSelected,
    required this.onMoreTapped,
  });

  final List<AdminSection> primarySections;
  final AdminSection selectedSection;
  final bool isMalayalam;
  final ValueChanged<AdminSection> onSectionSelected;
  final VoidCallback onMoreTapped;

  @override
  Widget build(BuildContext context) {
    final isMoreActive = !primarySections.contains(selectedSection);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFEEF0F2), width: 1)),
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                ...primarySections.map((section) {
                  final copy =
                      _sectionCopy[section] ?? const _SectionCopy('', '');
                  final icon = _sectionIcons[section] ?? Icons.circle;

                  return SizedBox(
                    width: 84,
                    child: _NavItem(
                      icon: icon,
                      label: isMalayalam ? copy.malayalam : copy.english,
                      selected: section == selectedSection,
                      isMalayalam: isMalayalam,
                      onTap: () => onSectionSelected(section),
                    ),
                  );
                }),
                SizedBox(
                  width: 84,
                  child: _NavItem(
                    icon: Icons.more_horiz,
                    label: isMalayalam ? 'കൂടുതൽ' : 'More',
                    selected: isMoreActive,
                    isMalayalam: isMalayalam,
                    onTap: onMoreTapped,
                  ),
                ),
              ],
            ),
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
    required this.isMalayalam,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isMalayalam;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    const inactiveColor = Color(0xFF9CA3AF);
    final icon = widget.icon;
    final selected = widget.selected;
    final isMalayalam = widget.isMalayalam;
    final label = widget.label;
    final color = selected ? activeColor : inactiveColor;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(icon, size: 25, color: color),
              ),
              const SizedBox(height: 5),
              isMalayalam
                  ? Text(
                      label,
                      style: GoogleFonts.notoSansMalayalam(
                        textStyle: TextStyle(
                          fontSize: 11,
                          height: 1.0,
                          letterSpacing: 0,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.0,
                        letterSpacing: 0,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
            ],
          ),
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
    required this.isMalayalam,
    required this.onSectionSelected,
  });

  final List<AdminSection> sections;
  final AdminSection selectedSection;
  final bool isMalayalam;
  final ValueChanged<AdminSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          const SizedBox(height: 20),
          isMalayalam
              ? Text(
                  'കൂടുതൽ',
                  style: GoogleFonts.notoSansMalayalam(
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Text(
                  'More',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: sections.map((section) {
              final copy = _sectionCopy[section] ?? const _SectionCopy('', '');
              final icon = _sectionIcons[section] ?? Icons.circle;
              final label = isMalayalam ? copy.malayalam : copy.english;
              final selected = section == selectedSection;

              return InkWell(
                onTap: () => onSectionSelected(section),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: isMalayalam
                            ? Text(
                                label,
                                style: GoogleFonts.notoSansMalayalam(
                                  textStyle: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
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

// ── Section Copy ────────────────────────────────────────────────────────────
class _SectionCopy {
  const _SectionCopy(this.english, this.malayalam);

  final String english;
  final String malayalam;
}

const Map<AdminSection, _SectionCopy> _sectionCopy = {
  AdminSection.dashboard: _SectionCopy('Overview', 'അവലോകനം'),
  AdminSection.students: _SectionCopy('Students', 'വിദ്യാർത്ഥികൾ'),
  AdminSection.teachers: _SectionCopy('Teachers', 'അധ്യാപകർ'),
  AdminSection.batches: _SectionCopy(
    'Batches & Classes',
    'ബാച്ചുകളും ക്ലാസുകളും',
  ),
  AdminSection.activities: _SectionCopy('Activities', 'പ്രവർത്തനങ്ങൾ'),
  AdminSection.rating: _SectionCopy(
    'Rating & Scoring',
    'റേറ്റിംഗ് & സ്കോറിംഗ്',
  ),
  AdminSection.badges: _SectionCopy('Badges', 'ബാഡ്ജുകൾ'),
  AdminSection.notifications: _SectionCopy('Notifications', 'അറിയിപ്പുകൾ'),
  AdminSection.reports: _SectionCopy('Reports', 'റിപ്പോർട്ടുകൾ'),
};

const Map<AdminSection, IconData> _sectionIcons = {
  AdminSection.dashboard: Icons.dashboard,
  AdminSection.students: Icons.groups,
  AdminSection.teachers: Icons.school,
  AdminSection.batches: Icons.class_,
  AdminSection.activities: Icons.fact_check,
  AdminSection.rating: Icons.star_rate,
  AdminSection.badges: Icons.workspace_premium,
  AdminSection.notifications: Icons.notifications_active,
  AdminSection.reports: Icons.stacked_line_chart,
};
