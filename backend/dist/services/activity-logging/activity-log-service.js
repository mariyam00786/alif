"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ActivityLogService = void 0;
const supabase_1 = require("../../config/supabase");
const http_error_1 = require("../../errors/http-error");
const audit_log_service_1 = require("../audit/audit-log-service");
const activity_logging_service_1 = require("./activity-logging-service");
class ActivityLogService {
    constructor() {
        this.activityLoggingService = new activity_logging_service_1.ActivityLoggingService();
        this.auditLogService = new audit_log_service_1.AuditLogService();
    }
    async list(filters) {
        let query = (0, supabase_1.getSupabaseClient)().from('activity_logs').select('*').order('log_date', { ascending: false });
        if (filters.studentId) {
            query = query.eq('student_id', filters.studentId);
        }
        if (filters.from) {
            query = query.gte('log_date', filters.from);
        }
        if (filters.to) {
            query = query.lte('log_date', filters.to);
        }
        const { data, error } = await query;
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to fetch activity logs.', error);
        }
        return (data ?? []);
    }
    async upsert(draft, actor) {
        const activity = await this.loadActivity(draft.activityId);
        const rating = draft.ratingId ? await this.loadRating(draft.ratingId) : null;
        const scoringRules = await this.loadScoringRules(draft.activityId);
        const payload = this.activityLoggingService.buildLogEntry({
            draft,
            activity,
            rating,
            scoringRules,
        });
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_logs')
            .upsert(payload, {
            onConflict: 'student_id,activity_id,log_date',
        })
            .select('*')
            .single();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to save activity log.', error);
        }
        await this.auditLogService.log({
            actor,
            action: 'upsert-activity-log',
            entityType: 'activity_log',
            entityId: String(data.id ?? ''),
            metadata: payload,
        });
        return data;
    }
    async loadActivity(activityId) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activities')
            .select('id, name, has_quantity')
            .eq('id', activityId)
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to load activity.', error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, 'Activity not found.');
        }
        return data;
    }
    async loadRating(ratingId) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_ratings')
            .select('id, activity_id, marks, rating_name')
            .eq('id', ratingId)
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to load activity rating.', error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, 'Activity rating not found.');
        }
        return data;
    }
    async loadScoringRules(activityId) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_scoring_rules')
            .select('id, activity_id, rule_type, min_quantity, max_quantity, marks, display_order')
            .eq('activity_id', activityId)
            .order('display_order', { ascending: true });
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to load activity scoring rules.', error);
        }
        return (data ?? []);
    }
}
exports.ActivityLogService = ActivityLogService;
//# sourceMappingURL=activity-log-service.js.map