import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../provider/app_state_provider.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../shared/theme/theme.dart';

/// Shared premium UI kit for the student/parent portal.
/// Minimal: soft white cards, hairline borders, micro labels and bold numbers.

const Color kHeading = AppColors.heading;
const Color kBody = AppColors.body;
const Color kMuted = AppColors.muted;
const Color kBorder = AppColors.border;
const Color kSurface = AppColors.background;
const Color kGreen = AppColors.primary;
const Color kGreenSoft = AppColors.primaryMuted;

/// A green gradient header with rounded bottom corners.
class PortalHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? bottom;

  const PortalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF14B8A6)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x300F766E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 14), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular profile button that shows who is currently signed in.
///
/// Tapping it opens a small sheet with the user's name, email and role so
/// you always know who is logged in while marking or viewing progress.
class PortalProfileAvatar extends StatelessWidget {
  final double size;
  final String? fallbackName;

  /// Whether the avatar sits on a dark/green surface (header) or a light one.
  final bool onDark;

  const PortalProfileAvatar({
    super.key,
    this.size = 44,
    this.fallbackName,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final user = MobileGoogleAuthService.currentUser;
    final name = (user?.name?.isNotEmpty == true)
        ? user!.name!
        : ((fallbackName?.isNotEmpty == true) ? fallbackName! : 'User');
    final avatarUrl = user?.avatarUrl;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    final ringColor = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : kGreen.withValues(alpha: 0.25);
    final bgColor = onDark ? Colors.white.withValues(alpha: 0.18) : kGreenSoft;
    final fgColor = onDark ? Colors.white : kGreen;

    return GestureDetector(
      onTap: () => _showProfile(context, name, user?.email, avatarUrl, initial),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
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
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.42,
                ),
              ),
      ),
    );
  }

  void _showProfile(
    BuildContext context,
    String name,
    String? email,
    String? avatarUrl,
    String initial,
  ) {
    final state = context.appState;
    final isMalayalam = state.isMalayalam;
    final roleLabel = _roleLabel(state.activeRole, isMalayalam);

    // Anchor the profile card just below the avatar (same in-place behaviour as
    // the notification bell) so all details + logout are visible at once.
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context);
    final width = math.min(280.0, media.size.width - 24);

    final bottomLeft = button.localToGlobal(
      button.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final topRight = button.localToGlobal(
      button.size.topRight(Offset.zero),
      ancestor: overlay,
    );

    final left = (topRight.dx - width).clamp(
      8.0,
      overlay.size.width - width - 8,
    );
    final position = RelativeRect.fromLTRB(
      left,
      bottomLeft.dy + 8,
      overlay.size.width - left - width,
      0,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kGreenSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kGreen.withValues(alpha: 0.2),
                        width: 2,
                      ),
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
                              color: kGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isMalayalam ? 'ലോഗിൻ ചെയ്തിരിക്കുന്നത്' : 'Signed in as',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: kMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kHeading,
                    ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: kMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kGreenSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: kGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: kGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.appState.logout();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD45555),
                        side: const BorderSide(color: Color(0xFFE7B9B9)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        isMalayalam ? 'ലോഗ് ഔട്ട്' : 'Log out',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String? role, bool ml) {
    switch (role) {
      case 'student':
        return ml ? 'വിദ്യാർത്ഥി' : 'Student';
      case 'parent':
        return ml ? 'രക്ഷിതാവ്' : 'Parent';
      case 'teacher':
        return ml ? 'അധ്യാപകൻ' : 'Teacher';
      case 'admin':
        return ml ? 'അഡ്മിൻ' : 'Admin';
      default:
        return ml ? 'ഉപയോക്താവ്' : 'User';
    }
  }
}

/// White rounded card with soft border + layered shadow for depth.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.borderColor,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Pill segmented control. Use on a light background (light=true)
/// or over the green header (light=false).
class PortalSegmented extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool onHeader;

  const PortalSegmented({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.onHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = onHeader
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFF3F5F3);
    final border = onHeader ? Colors.transparent : const Color(0xFFE8EBE8);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? (onHeader ? Colors.white : kGreen)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: (onHeader ? Colors.black : kGreen)
                                .withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  items[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? (onHeader ? kGreen : Colors.white)
                        : (onHeader
                              ? Colors.white.withValues(alpha: 0.85)
                              : kMuted),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Small section label (gray, semibold).
class SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionLabel(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: kGreen),
          const SizedBox(width: 8),
        ],
        Text(text, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

/// Icon + big number + micro label stat tile.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tint = kGreen,
  });

  @override
  Widget build(BuildContext context) {
    // Scale down padding, icon and fonts on very narrow tiles (e.g. 3-up
    // rows on small phones) so nothing overflows.
    final bool compact = MediaQuery.of(context).size.width < 380;
    final double pad = compact ? 12 : 14;
    final double iconBox = compact ? 38 : 44;

    return SoftCard(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: compact ? 20 : 23, color: tint),
          ),
          SizedBox(height: compact ? 8 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 24 : 28,
                fontWeight: FontWeight.w800,
                height: 1,
                color: kHeading,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13.5,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty / loading placeholder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final bool loading;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kGreenSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation(kGreen),
                      ),
                    )
                  : Icon(icon, size: 44, color: kGreen),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kHeading,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A lightweight notification item shown inside the bell dropdown.
class PortalNotification {
  final String title;
  final String titleMl;
  final String body;
  final String bodyMl;
  final String timeAgo;
  final String timeAgoMl;
  final IconData icon;
  final Color color;
  final bool unread;

  const PortalNotification({
    required this.title,
    required this.titleMl,
    required this.body,
    required this.bodyMl,
    required this.timeAgo,
    required this.timeAgoMl,
    required this.icon,
    required this.color,
    this.unread = false,
  });
}

/// A circular notification bell with an unread badge that opens an anchored
/// dropdown listing recent notifications inline — no separate page.
///
/// Designed to sit next to [PortalProfileAvatar] in a [PortalHeader] trailing
/// slot. Set [onDark] = true on the green header, false on light surfaces.
class PortalNotificationBell extends StatelessWidget {
  final List<PortalNotification> notifications;
  final bool isMalayalam;
  final bool onDark;
  final double size;

  const PortalNotificationBell({
    super.key,
    required this.notifications,
    required this.isMalayalam,
    this.onDark = true,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => n.unread).length;
    final ringColor = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : kGreen.withValues(alpha: 0.25);
    final bgColor = onDark ? Colors.white.withValues(alpha: 0.18) : kGreenSoft;
    final fgColor = onDark ? Colors.white : kGreen;

    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_rounded,
                color: fgColor,
                size: size * 0.5,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: onDark ? kGreen : Colors.white,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context);
    final width = math.min(360.0, media.size.width - 24);

    final bottomLeft = button.localToGlobal(
      button.size.bottomLeft(Offset.zero),
      ancestor: overlay,
    );
    final topRight = button.localToGlobal(
      button.size.topRight(Offset.zero),
      ancestor: overlay,
    );

    final left = (topRight.dx - width).clamp(
      8.0,
      overlay.size.width - width - 8,
    );
    final position = RelativeRect.fromLTRB(
      left,
      bottomLeft.dy + 8,
      overlay.size.width - left - width,
      0,
    );

    showMenu<void>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _NotificationPanel(
            notifications: notifications,
            isMalayalam: isMalayalam,
            width: width,
          ),
        ),
      ],
    );
  }
}

/// Maps backend notification rows (id/title/body/target_type/created_at) into
/// the rich [PortalNotification] UI model used by the bell. The backend has no
/// Malayalam text, icon, colour or read-state, so sensible defaults are used:
/// icon/colour by target type, ML falls back to the English text, and items
/// created within the last 2 days are treated as unread.
List<PortalNotification> portalNotificationsFromApi(
  List<Map<String, dynamic>> rows,
) {
  final now = DateTime.now();
  return rows.map((row) {
    final title = (row['title'] ?? '').toString();
    final body = (row['body'] ?? '').toString();
    final targetType = (row['target_type'] ?? 'all').toString();
    final createdRaw = (row['created_at'] ?? row['sent_at'] ?? '').toString();
    final created = DateTime.tryParse(createdRaw)?.toLocal();

    IconData icon;
    Color color;
    switch (targetType) {
      case 'student':
        icon = Icons.person_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'batch':
        icon = Icons.groups_rounded;
        color = kGreen;
        break;
      case 'class':
        icon = Icons.school_rounded;
        color = const Color(0xFF3B82F6);
        break;
      default:
        icon = Icons.campaign_rounded;
        color = const Color(0xFF8B5CF6);
    }

    final timeEn = created != null ? _relativeTime(now, created, false) : '';
    final timeMl = created != null ? _relativeTime(now, created, true) : '';
    final unread = created != null && now.difference(created).inDays < 2;

    return PortalNotification(
      title: title.isEmpty ? 'Notification' : title,
      titleMl: title.isEmpty ? 'അറിയിപ്പ്' : title,
      body: body,
      bodyMl: body,
      timeAgo: timeEn,
      timeAgoMl: timeMl,
      icon: icon,
      color: color,
      unread: unread,
    );
  }).toList();
}

String _relativeTime(DateTime now, DateTime then, bool ml) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return ml ? 'ഇപ്പോൾ' : 'Just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return ml ? '$m മിനിറ്റ് മുമ്പ്' : '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return ml ? '$h മണിക്കൂർ മുമ്പ്' : '$h hour${h == 1 ? '' : 's'} ago';
  }
  if (diff.inDays == 1) return ml ? 'ഇന്നലെ' : 'Yesterday';
  final d = diff.inDays;
  return ml ? '$d ദിവസം മുമ്പ്' : '$d days ago';
}

/// A notification bell that loads notifications from the backend on demand and
/// gracefully falls back to [fallback] (sample data) when the request fails or
/// returns nothing — so the UI never shows an empty/broken state.
///
/// Rendering is identical to [PortalNotificationBell]; only the data source
/// differs. Set [source] to choose which backend endpoint to call.
class PortalNotificationBellAsync extends StatefulWidget {
  final List<PortalNotification> fallback;
  final bool isMalayalam;
  final bool onDark;
  final double size;
  final PortalNotificationSource source;

  const PortalNotificationBellAsync({
    super.key,
    required this.fallback,
    required this.isMalayalam,
    required this.source,
    this.onDark = true,
    this.size = 44,
  });

  @override
  State<PortalNotificationBellAsync> createState() =>
      _PortalNotificationBellAsyncState();
}

enum PortalNotificationSource { parent }

class _PortalNotificationBellAsyncState
    extends State<PortalNotificationBellAsync> {
  late List<PortalNotification> _items = widget.fallback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      switch (widget.source) {
        case PortalNotificationSource.parent:
          final res = await MobileApiService.getParentNotifications();
          if (!mounted) return;
          if (res.success && res.data != null && res.data!.isNotEmpty) {
            final mapped = portalNotificationsFromApi(res.data!);
            if (mapped.isNotEmpty) {
              setState(() => _items = mapped);
            }
          }
          break;
      }
    } catch (_) {
      // Keep the fallback sample data on any failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortalNotificationBell(
      notifications: _items,
      isMalayalam: widget.isMalayalam,
      onDark: widget.onDark,
      size: widget.size,
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  final List<PortalNotification> notifications;
  final bool isMalayalam;
  final double width;

  const _NotificationPanel({
    required this.notifications,
    required this.isMalayalam,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => n.unread).length;

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_rounded,
                    color: kGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMalayalam ? 'അറിയിപ്പുകൾ' : 'Notifications',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kHeading,
                    ),
                  ),
                  const Spacer(),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kGreenSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMalayalam ? '$unread പുതിയത്' : '$unread new',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: kGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: kBorder),
            Flexible(
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_off_rounded,
                            size: 40,
                            color: kMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isMalayalam
                                ? 'അറിയിപ്പുകൾ ഇല്ല'
                                : 'No notifications',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFF1F4F1)),
                      itemBuilder: (context, i) => _NotificationTile(
                        n: notifications[i],
                        isMalayalam: isMalayalam,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PortalNotification n;
  final bool isMalayalam;

  const _NotificationTile({required this.n, required this.isMalayalam});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: n.unread ? const Color(0xFFF6FAF6) : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(n.icon, size: 20, color: n.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isMalayalam ? n.titleMl : n.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kHeading,
                        ),
                      ),
                    ),
                    if (n.unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isMalayalam ? n.bodyMl : n.body,
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                    color: kBody,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMalayalam ? n.timeAgoMl : n.timeAgo,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
