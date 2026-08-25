"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditLogService = void 0;
const supabase_1 = require("../../config/supabase");
class AuditLogService {
    async log(input) {
        const { error } = await (0, supabase_1.getSupabaseClient)()
            .from('audit_logs')
            .insert({
            actor_profile_id: input.actor?.profileId ?? null,
            action: input.action,
            entity_type: input.entityType,
            entity_id: input.entityId ?? null,
            metadata: input.metadata ?? {},
        });
        if (error) {
            console.error('Failed to write audit log', error);
        }
    }
}
exports.AuditLogService = AuditLogService;
//# sourceMappingURL=audit-log-service.js.map