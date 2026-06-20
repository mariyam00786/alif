import { getMessaging } from 'firebase-admin/messaging';
import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';
import type { AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';

interface NotificationInput {
  title: string;
  body?: string;
  target_type: 'all' | 'batch' | 'class' | 'student';
  target_id?: string;
  deviceToken?: string;
  topic?: string;
}

export class NotificationService {
  private readonly auditLogService = new AuditLogService();

  async list(): Promise<Record<string, unknown>[]> {
    const { data, error } = await getSupabaseClient()
      .from('notifications')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      throw new HttpError(500, 'Unable to fetch notifications.', error);
    }

    return (data ?? []) as Record<string, unknown>[];
  }

  async create(input: NotificationInput, actor: AuthenticatedUser): Promise<Record<string, unknown>> {
    const { deviceToken, topic, ...databasePayload } = input;
    const { data, error } = await getSupabaseClient()
      .from('notifications')
      .insert({
        ...databasePayload,
        target_id: databasePayload.target_id ?? null,
        created_by: actor.profileId,
      })
      .select('*')
      .single();

    if (error) {
      throw new HttpError(500, 'Unable to create notification.', error);
    }

    if (deviceToken || topic) {
      await this.sendRealtimeMessage({
        title: input.title,
        body: input.body,
        deviceToken,
        topic,
      });
    }

    await this.auditLogService.log({
      actor,
      action: 'create-notification',
      entityType: 'notification',
      entityId: String((data as Record<string, unknown>).id ?? ''),
      metadata: databasePayload as Record<string, unknown>,
    });

    return data as Record<string, unknown>;
  }

  async update(id: string, payload: Record<string, unknown>, actor?: AuthenticatedUser): Promise<Record<string, unknown>> {
    const updatePayload = {
      ...payload,
      target_id: payload.target_id ?? null,
      scheduled_at: payload.scheduled_at ?? null,
      sent_at: payload.sent_at ?? null,
    };

    const { data, error } = await getSupabaseClient()
      .from('notifications')
      .update(updatePayload)
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to update notification.', error);
    }

    if (!data) {
      throw new HttpError(404, 'Notification not found.');
    }

    await this.auditLogService.log({
      actor,
      action: 'update-notification',
      entityType: 'notification',
      entityId: id,
      metadata: payload,
    });

    return data as Record<string, unknown>;
  }

  private async sendRealtimeMessage(input: { title: string; body?: string; deviceToken?: string; topic?: string }): Promise<void> {
    const messaging = getMessaging();

    const message = {
      notification: {
        title: input.title,
        body: input.body,
      },
      token: input.deviceToken,
      topic: input.topic,
    };

    try {
      if (input.deviceToken) {
        await messaging.send({
          notification: message.notification,
          token: input.deviceToken,
        });
      }

      if (input.topic) {
        await messaging.send({
          notification: message.notification,
          topic: input.topic,
        });
      }
    } catch (error) {
      throw new HttpError(502, 'Notification was saved but Firebase delivery failed.', error);
    }
  }
}