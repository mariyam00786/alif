/**
 * MsgHex WhatsApp Messaging Service
 *
 * Integrates with the MsgHex messaging API to deliver one-time passwords over
 * WhatsApp. The OTP itself is generated and verified server-side (bound to the
 * requesting phone number); MsgHex is used purely as the WhatsApp transport so
 * we control the code length and format.
 *
 * Docs: https://msghex.com/dashboard/settings/developers
 *  - Send Single Message: POST {apiUrl}/api/send/whatsapp
 *    { secret, account, recipient, type: 'text', message }
 */
export interface MsgHexSendResult {
    success: boolean;
    message: string;
    messageId?: string;
}
/**
 * Live connection status of the WhatsApp "sender" device that MsgHex uses to
 * deliver OTPs. If this device is not `connected`, OTP delivery will fail.
 */
export interface MsgHexSenderStatus {
    /** True when MsgHex credentials are present in the environment. */
    configured: boolean;
    /** True when the configured device is linked and online. */
    connected: boolean;
    /** Raw status reported by MsgHex (e.g. 'connected', 'disconnected'). */
    status?: string;
    /** Sender phone number (digits only) as reported by MsgHex. */
    phone?: string;
    /** Friendly device name from the MsgHex dashboard. */
    name?: string;
    /** MsgHex plan/subscription status. */
    subscriptionStatus?: string;
    /** Human-readable summary suitable for surfacing to an admin. */
    message: string;
}
/**
 * Sends a plain WhatsApp text message via MsgHex.
 *
 * @param phone - Phone number in +CCCXXXXXXXXX format
 * @param message - The text body to deliver
 */
export declare function sendWhatsAppMessage(phone: string, message: string): Promise<MsgHexSendResult>;
/**
 * Checks whether the configured WhatsApp sender device is online.
 *
 * Calls MsgHex `GET /api/devices/list` and locates the device whose
 * `sessionId` matches our configured `account`. Use this to alert admins when
 * the sender has been logged out / unlinked, which would stop OTP delivery.
 */
export declare function getSenderStatus(): Promise<MsgHexSenderStatus>;
//# sourceMappingURL=msghex-service.d.ts.map