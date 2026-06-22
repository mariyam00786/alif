import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/app_models.dart';
import '../services/supabase_bootstrap.dart';

/// A lightweight notification item shown inside the admin bell dropdown.
class AdminNotification {
  final String title;
  final String titleMl;
  final String body;
  final String bodyMl;
  final String timeAgo;
  final String timeAgoMl;
  final IconData icon;
  final Color color;
  final bool unread;

  const AdminNotification({
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

/// Sample admin inbox notifications (mock data until backend is wired).
const List<AdminNotification> kAdminNotifications = [
  AdminNotification(
    title: 'New student awaiting approval',
    titleMl: 'പുതിയ വിദ്യാർത്ഥി അംഗീകാരത്തിനായി',
    body: '3 student registrations are pending your review.',
    bodyMl: '3 വിദ്യാർത്ഥി രജിസ്ട്രേഷനുകൾ അവലോകനത്തിനായി കാത്തിരിക്കുന്നു.',
    timeAgo: '15 minutes ago',
    timeAgoMl: '15 മിനിറ്റ് മുമ്പ്',
    icon: Icons.person_add_alt_1_rounded,
    color: Color(0xFF0F766E),
    unread: true,
  ),
  AdminNotification(
    title: 'Teacher verification request',
    titleMl: 'അധ്യാപക പരിശോധന അഭ്യർത്ഥന',
    body: 'A new teacher submitted documents for verification.',
    bodyMl: 'ഒരു പുതിയ അധ്യാപകൻ പരിശോധനയ്ക്കായി രേഖകൾ സമർപ്പിച്ചു.',
    timeAgo: '1 hour ago',
    timeAgoMl: '1 മണിക്കൂർ മുമ്പ്',
    icon: Icons.verified_user_rounded,
    color: Color(0xFFF59E0B),
    unread: true,
  ),
  AdminNotification(
    title: 'Notification campaign approved',
    titleMl: 'അറിയിപ്പ് കാമ്പെയ്ൻ അംഗീകരിച്ചു',
    body: 'The weekly progress campaign is ready to send.',
    bodyMl: 'പ്രതിവാര പുരോഗതി കാമ്പെയ്ൻ അയയ്ക്കാൻ തയ്യാറാണ്.',
    timeAgo: '3 hours ago',
    timeAgoMl: '3 മണിക്കൂർ മുമ്പ്',
    icon: Icons.campaign_rounded,
    color: Color(0xFF3B82F6),
    unread: false,
  ),
  AdminNotification(
    title: 'Monthly reports generated',
    titleMl: 'മാസ റിപ്പോർട്ടുകൾ തയ്യാറായി',
    body: 'All batch reports for this month are now available.',
    bodyMl: 'ഈ മാസത്തെ എല്ലാ ബാച്ച് റിപ്പോർട്ടുകളും ലഭ്യമാണ്.',
    timeAgo: 'Yesterday',
    timeAgoMl: 'ഇന്നലെ',
    icon: Icons.assessment_rounded,
    color: Color(0xFF8B5CF6),
    unread: false,
  ),
];

/// Best-effort current admin email from the Supabase session.
String? _currentAdminEmail() {
  if (!SupabaseBootstrap.isConfigured) return null;
  try {
    return Supabase.instance.client.auth.currentUser?.email;
  } catch (_) {
    return null;
  }
}

/// Maps backend notification campaigns (already loaded by the admin provider)
/// into the [AdminNotification] UI model used by the bell. Campaigns awaiting
/// approval are surfaced as unread.
List<AdminNotification> adminNotificationsFromCampaigns(
  List<NotificationCampaign> campaigns,
) {
  return campaigns.map((c) {
    IconData icon;
    Color color;
    switch (c.status) {
      case CampaignStatus.sent:
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case CampaignStatus.scheduled:
        icon = Icons.schedule_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case CampaignStatus.draft:
        icon = Icons.edit_note_rounded;
        color = const Color(0xFF8B5CF6);
        break;
    }
    final statusEn = c.status == CampaignStatus.sent
        ? 'Sent'
        : c.status == CampaignStatus.scheduled
        ? 'Scheduled'
        : 'Draft';
    final statusMl = c.status == CampaignStatus.sent
        ? 'അയച്ചു'
        : c.status == CampaignStatus.scheduled
        ? 'ഷെഡ്യൂൾ ചെയ്തു'
        : 'ഡ്രാഫ്റ്റ്';
    final body = c.audience;
    final time = c.scheduledFor.isNotEmpty ? c.scheduledFor : statusEn;
    final timeMl = c.scheduledFor.isNotEmpty ? c.scheduledFor : statusMl;
    return AdminNotification(
      title: c.title,
      titleMl: c.title,
      body: body,
      bodyMl: body,
      timeAgo: time,
      timeAgoMl: timeMl,
      icon: icon,
      color: color,
      unread: c.status == CampaignStatus.draft,
    );
  }).toList();
}

/// A circular bell button with an unread badge that opens an anchored dropdown
/// listing recent admin notifications inline — no separate page.
class AdminNotificationBell extends StatelessWidget {
  final bool isMalayalam;
  final double size;
  final List<AdminNotification> notifications;

  const AdminNotificationBell({
    super.key,
    required this.isMalayalam,
    this.size = 44,
    this.notifications = kAdminNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final unread = notifications.where((n) => n.unread).length;

    return Tooltip(
      message: isMalayalam ? 'അറിയിപ്പുകൾ' : 'Notifications',
      child: GestureDetector(
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
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.notifications_rounded,
                  color: primary,
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
                      border: Border.all(color: Colors.white, width: 2),
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
      ),
    );
  }

  void _open(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context);
    final width = math.min(380.0, media.size.width - 24);

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
          child: _AdminNotificationPanel(
            isMalayalam: isMalayalam,
            width: width,
            notifications: notifications,
          ),
        ),
      ],
    );
  }
}

class _AdminNotificationPanel extends StatelessWidget {
  final bool isMalayalam;
  final double width;
  final List<AdminNotification> notifications;

  const _AdminNotificationPanel({
    required this.isMalayalam,
    required this.width,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final unread = notifications.where((n) => n.unread).length;

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.notifications_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isMalayalam ? 'അറിയിപ്പുകൾ' : 'Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
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
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isMalayalam ? '$unread പുതിയത്' : '$unread new',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: notifications.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF1F4F1)),
                itemBuilder: (context, i) => _AdminNotificationTile(
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

class _AdminNotificationTile extends StatelessWidget {
  final AdminNotification n;
  final bool isMalayalam;

  const _AdminNotificationTile({required this.n, required this.isMalayalam});

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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (n.unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F766E),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isMalayalam ? n.bodyMl : n.body,
                  style: GoogleFonts.inter(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMalayalam ? n.timeAgoMl : n.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
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

/// A circular avatar button that opens a dropdown with the signed-in admin's
/// identity, role and a sign-out action — mirrors the student/parent profile.
class AdminProfileButton extends StatelessWidget {
  final bool isMalayalam;
  final Future<void> Function() onSignOut;
  final double size;

  const AdminProfileButton({
    super.key,
    required this.isMalayalam,
    required this.onSignOut,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final email = _currentAdminEmail();
    final name = (email != null && email.isNotEmpty)
        ? email.split('@').first
        : (isMalayalam ? 'അഡ്മിൻ' : 'Administrator');
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'A';

    return Tooltip(
      message: isMalayalam ? 'പ്രൊഫൈൽ' : 'Profile',
      child: GestureDetector(
        onTap: () => _open(context, name, email, initial),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: primary.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.inter(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, String name, String? email, String initial) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context);
    final width = math.min(300.0, media.size.width - 24);

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
          child: _AdminProfilePanel(
            isMalayalam: isMalayalam,
            name: name,
            email: email,
            initial: initial,
            width: width,
            onSignOut: () async {
              Navigator.of(context).pop();
              await onSignOut();
            },
          ),
        ),
      ],
    );
  }
}

class _AdminProfilePanel extends StatelessWidget {
  final bool isMalayalam;
  final String name;
  final String? email;
  final String initial;
  final double width;
  final Future<void> Function() onSignOut;

  const _AdminProfilePanel({
    required this.isMalayalam,
    required this.name,
    required this.email,
    required this.initial,
    required this.width,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.20),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isMalayalam ? 'ലോഗിൻ ചെയ്തിരിക്കുന്നത്' : 'Signed in as',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 15,
                        color: primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMalayalam ? 'അഡ്മിൻ' : 'Admin',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(isMalayalam ? 'സൈൻ ഔട്ട്' : 'Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
