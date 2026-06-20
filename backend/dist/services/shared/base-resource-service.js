"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BaseResourceService = void 0;
const supabase_1 = require("../../config/supabase");
const http_error_1 = require("../../errors/http-error");
const audit_log_service_1 = require("../audit/audit-log-service");
class BaseResourceService {
    constructor(tableName, entityType, auditLogService = new audit_log_service_1.AuditLogService()) {
        this.tableName = tableName;
        this.entityType = entityType;
        this.auditLogService = auditLogService;
    }
    async list(orderColumn = 'created_at') {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from(this.tableName)
            .select('*')
            .order(orderColumn, { ascending: false });
        if (error) {
            throw new http_error_1.HttpError(500, `Unable to fetch ${this.entityType} records.`, error);
        }
        return (data ?? []);
    }
    async getById(id) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from(this.tableName)
            .select('*')
            .eq('id', id)
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, `Unable to fetch ${this.entityType}.`, error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, `${this.entityType} not found.`);
        }
        return data;
    }
    async create(payload, actor) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from(this.tableName)
            .insert(payload)
            .select('*')
            .single();
        if (error) {
            throw new http_error_1.HttpError(500, `Unable to create ${this.entityType}.`, error);
        }
        await this.auditLogService.log({
            actor,
            action: 'create',
            entityType: this.entityType,
            entityId: String(data.id ?? ''),
            metadata: payload,
        });
        return data;
    }
    async update(id, payload, actor) {
        const updatePayload = {
            ...payload,
            updated_at: new Date().toISOString(),
        };
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from(this.tableName)
            .update(updatePayload)
            .eq('id', id)
            .select('*')
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, `Unable to update ${this.entityType}.`, error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, `${this.entityType} not found.`);
        }
        await this.auditLogService.log({
            actor,
            action: 'update',
            entityType: this.entityType,
            entityId: id,
            metadata: payload,
        });
        return data;
    }
}
exports.BaseResourceService = BaseResourceService;
//# sourceMappingURL=base-resource-service.js.map