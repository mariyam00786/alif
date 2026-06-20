import type { AuthenticatedUser } from '../../types/domain';
interface NotificationInput {
    title: string;
    body?: string;
    target_type: 'all' | 'batch' | 'class' | 'student';
    target_id?: string;
    deviceToken?: string;
    topic?: string;
}
export declare class NotificationService {
    private readonly auditLogService;
    list(): Promise<Record<string, unknown>[]>;
    create(input: NotificationInput, actor: AuthenticatedUser): Promise<Record<string, unknown>>;
    update(id: string, payload: Record<string, unknown>, actor?: AuthenticatedUser): Promise<Record<string, unknown>>;
    private sendRealtimeMessage;
}
export {};
//# sourceMappingURL=notification-service.d.ts.map