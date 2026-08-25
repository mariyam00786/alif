import 'package:flutter/material.dart';

/// A prominent warning banner shown to admins when the WhatsApp sender device
/// (used to deliver login OTPs) is disconnected. While it is down, no user can
/// receive an OTP, so the admin needs to reconnect it in the MsgHex dashboard.
class WhatsAppAlertBanner extends StatelessWidget {
  const WhatsAppAlertBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFB91C1C);
    const dangerBg = Color(0xFFFEF2F2);
    const dangerBorder = Color(0xFFFECACA);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WhatsApp OTP delivery is offline',
                  style: TextStyle(
                    color: danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'The WhatsApp sender is disconnected. Reconnect it (re-scan the QR in MsgHex) to resume OTP logins.',
                  style: const TextStyle(color: danger, fontSize: 13),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: danger),
              label: const Text(
                'Re-check',
                style: TextStyle(color: danger, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
