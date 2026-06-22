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

import config from '../../config/config';

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

interface MsgHexResponse {
  status?: number;
  message?: string;
  data?: {
    messageId?: string;
  };
}

interface MsgHexDevice {
  sessionId: string;
  name?: string;
  phone?: string;
  status?: string;
}

interface MsgHexDeviceListResponse {
  status?: number;
  message?: string;
  data?: {
    devices?: MsgHexDevice[];
    subscriptionStatus?: string;
  };
}

/**
 * MsgHex expects the recipient phone number with the country code but
 * without a leading '+' or any separators (e.g. "919895123456").
 */
function toMsgHexPhone(phone: string): string {
  return phone.replace(/\D/g, '');
}

/**
 * Sends a plain WhatsApp text message via MsgHex.
 *
 * @param phone - Phone number in +CCCXXXXXXXXX format
 * @param message - The text body to deliver
 */
export async function sendWhatsAppMessage(
  phone: string,
  message: string
): Promise<MsgHexSendResult> {
  const { apiUrl, secret, account } = config.msghex;

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

    const payload = (await response.json().catch(() => ({}))) as MsgHexResponse;

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
  } catch (error) {
    return {
      success: false,
      message: `MsgHex send failed: ${(error as Error).message}`,
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
export async function getSenderStatus(): Promise<MsgHexSenderStatus> {
  const { apiUrl, secret, account } = config.msghex;

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
      .catch(() => ({}))) as MsgHexDeviceListResponse;

    if (!response.ok || (payload.status && payload.status >= 400)) {
      return {
        configured: true,
        connected: false,
        message:
          payload.message || 'Unable to fetch WhatsApp device status from MsgHex.',
      };
    }

    const devices = payload.data?.devices ?? [];
    const device = devices.find((d) => d.sessionId === account);

    if (!device) {
      return {
        configured: true,
        connected: false,
        subscriptionStatus: payload.data?.subscriptionStatus,
        message:
          'The configured WhatsApp sender device was not found on MsgHex. It may have been deleted.',
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
  } catch (error) {
    return {
      configured: true,
      connected: false,
      message: `WhatsApp status check failed: ${(error as Error).message}`,
    };
  }
}

