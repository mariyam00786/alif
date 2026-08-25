import type { AuthenticatedUser } from '../../types/domain';
interface AuditLogInput {
    actor?: AuthenticatedUser;
    action: string;
    entityType: string;
    entityId?: string;
    metadata?: Record<string, unknown>;
}
export declare class AuditLogService {
    log(input: AuditLogInput): Promise<void>;
}
export {};
//# sourceMappingURL=audit-log-service.d.ts.map