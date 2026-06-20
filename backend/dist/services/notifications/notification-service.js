"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationService = void 0;
const messaging_1 = require("firebase-admin/messaging");
const supabase_1 = require("../../config/supabase");
const http_error_1 = require("../../errors/http-error");
const audit_log_service_1 = require("../audit/audit-log-service");
class NotificationService {
    constructor() {
        this.auditLogService = new audit_log_service_1.AuditLogService();
    }
    async list() {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('notifications')
            .select('*')
            .order('created_at', { ascending: false });
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to fetch notifications.', error);
        }
        return (data ?? []);
    }
    async create(input, actor) {
        const { deviceToken, topic, ...databasePayload } = input;
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('notifications')
            .insert({
            ...databasePayload,
            target_id: databasePayload.target_id ?? null,
            created_by: actor.profileId,
        })
            .select('*')
            .single();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to create notification.', error);
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
            entityId: String(data.id ?? ''),
            metadata: databasePayload,
        });
        return data;
    }
    async update(id, payload, actor) {
        const updatePayload = {
            ...payload,
            target_id: payload.target_id ?? null,
            scheduled_at: payload.scheduled_at ?? null,
            sent_at: payload.sent_at ?? null,
        };
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('notifications')
            .update(updatePayload)
            .eq('id', id)
            .select('*')
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to update notification.', error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, 'Notification not found.');
        }
        await this.auditLogService.log({
            actor,
            action: 'update-notification',
            entityType: 'notification',
            entityId: id,
            metadata: payload,
        });
        return data;
    }
    async sendRealtimeMessage(input) {
        const messaging = (0, messaging_1.getMessaging)();
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
        }
        catch (error) {
            throw new http_error_1.HttpError(502, 'Notification was saved but Firebase delivery failed.', error);
        }
    }
}
exports.NotificationService = NotificationService;
//# sourceMappingURL=notification-service.js.map