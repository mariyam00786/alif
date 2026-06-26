"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendWhatsAppMessage = sendWhatsAppMessage;
exports.getSenderStatus = getSenderStatus;
const config_1 = __importDefault(require("../../config/config"));
/**
 * MsgHex expects the recipient phone number with the country code but
 * without a leading '+' or any separators (e.g. "919895123456").
 */
function toMsgHexPhone(phone) {
    return phone.replace(/\D/g, '');
}
/**
 * Sends a plain WhatsApp text message via MsgHex.
 *
 * @param phone - Phone number in +CCCXXXXXXXXX format
 * @param message - The text body to deliver
 */
async function sendWhatsAppMessage(phone, message) {
    const { apiUrl, secret, account } = config_1.default.msghex;
    if (!secret || !account) {
        return {
            success: false,
            message: 'MsgHex is not configured. Set MSGHEX_API_SECRET and MSGHEX_SESSION_ID.',
        };
    }
    try {
        const response = await fetch(`${apiUrl}/api/send/whatsapp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                secret,
                account,
                recipient: toMsgHexPhone(phone),
                type: 'text',
                message,
            }),
        });
        const payload = (await response.json().catch(() => ({})));
        if (!response.ok || (payload.status && payload.status >= 400)) {
            return {
                success: false,
                message: payload.message || 'Failed to send message via WhatsApp.',
            };
        }
        return {
            success: true,
            message: payload.message || 'Message sent successfully.',
            messageId: payload.data?.messageId,
        };
    }
    catch (error) {
        return {
            success: false,
            message: `MsgHex send failed: ${error.message}`,
        };
    }
}
/**
 * Checks whether the configured WhatsApp sender device is online.
 *
 * Calls MsgHex `GET /api/devices/list` and locates the device whose
 * `sessionId` matches our configured `account`. Use this to alert admins when
 * the sender has been logged out / unlinked, which would stop OTP delivery.
 */
async function getSenderStatus() {
    const { apiUrl, secret, account } = config_1.default.msghex;
    if (!secret || !account) {
        return {
            configured: false,
            connected: false,
            message: 'WhatsApp sender is not configured. Set MSGHEX_API_SECRET and MSGHEX_SESSION_ID.',
        };
    }
    try {
        const response = await fetch(`${apiUrl}/api/devices/list`, {
            method: 'GET',
            headers: { 'x-api-secret': secret },
        });
        const payload = (await response
            .json()
            .catch(() => ({})));
        if (!response.ok || (payload.status && payload.status >= 400)) {
            return {
                configured: true,
                connected: false,
                message: payload.message || 'Unable to fetch WhatsApp device status from MsgHex.',
            };
        }
        const devices = payload.data?.devices ?? [];
        const device = devices.find((d) => d.sessionId === account);
        if (!device) {
            return {
                configured: true,
                connected: false,
                subscriptionStatus: payload.data?.subscriptionStatus,
                message: 'The configured WhatsApp sender device was not found on MsgHex. It may have been deleted.',
            };
        }
        const connected = device.status === 'connected';
        return {
            configured: true,
            connected,
            status: device.status,
            phone: device.phone,
            name: device.name,
            subscriptionStatus: payload.data?.subscriptionStatus,
            message: connected
                ? 'WhatsApp sender is connected and ready to deliver OTPs.'
                : 'WhatsApp sender is disconnected. OTP delivery will fail until the device is reconnected (re-scan the QR in MsgHex).',
        };
    }
    catch (error) {
        return {
            configured: true,
            connected: false,
            message: `WhatsApp status check failed: ${error.message}`,
        };
    }
}
//# sourceMappingURL=msghex-service.js.map