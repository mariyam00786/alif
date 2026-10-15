import type { AuthenticatedUser } from '../../types/domain';
interface NotificationInput {
    title: string;
    body?: string;
    target_type: 'all' | 'batch' | 'class' | 'student';
    target_id?: string;
    scheduled_at?: string | null;
    sent_at?: string | null;
    deviceToken?: string;
    topic?: string;
}
export declare class NotificationService {
    private readonly auditLogService;
    list(): Promise<Record<string, unknown>[]>;
    create(input: NotificationInput, actor: AuthenticatedUser): Promise<Record<string, unknown>>;
    update(id: string, payload: Record<string, unknown>, actor?: AuthenticatedUser): Promise<Record<string, unknown>>;
    private sendRealtimeMessage;
    remove(id: string, actor?: AuthenticatedUser): Promise<void>;
}
export {};
//# sourceMappingURL=notification-service.d.ts.map