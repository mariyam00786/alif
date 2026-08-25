import type { AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';
type ResourceRecord = Record<string, unknown>;
export declare class BaseResourceService {
    private readonly tableName;
    private readonly entityType;
    private readonly auditLogService;
    constructor(tableName: string, entityType: string, auditLogService?: AuditLogService);
    list(orderColumn?: string): Promise<ResourceRecord[]>;
    getById(id: string): Promise<ResourceRecord>;
    create(payload: ResourceRecord, actor?: AuthenticatedUser): Promise<ResourceRecord>;
    update(id: string, payload: ResourceRecord, actor?: AuthenticatedUser): Promise<ResourceRecord>;
}
export {};
//# sourceMappingURL=base-resource-service.d.ts.map