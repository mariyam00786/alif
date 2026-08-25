"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LeaderboardService = exports.BadgeService = void 0;
const supabase_1 = require("../../config/supabase");
const http_error_1 = require("../../errors/http-error");
const base_resource_service_1 = require("../shared/base-resource-service");
class BadgeService extends base_resource_service_1.BaseResourceService {
    constructor() {
        super('badges', 'badge');
    }
}
exports.BadgeService = BadgeService;
class LeaderboardService {
    async getWeeklyLeaderboard(startDate, endDate) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_logs')
            .select('student_id, marks_earned, students(batch_id, profiles(full_name)), students:batches(name)')
            .gte('log_date', startDate)
            .lte('log_date', endDate);
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to compute leaderboard.', error);
        }
        const totals = new Map();
        for (const row of data ?? []) {
            const item = row;
            const existing = totals.get(item.student_id) ?? {
                studentId: item.student_id,
                fullName: this.getProfileName(item),
                batchName: this.getBatchName(item),
                totalMarks: 0,
            };
            existing.totalMarks += item.marks_earned;
            totals.set(item.student_id, existing);
        }
        return Array.from(totals.values())
            .sort((left, right) => right.totalMarks - left.totalMarks)
            .map((entry, index) => ({
            student_id: entry.studentId,
            full_name: entry.fullName,
            batch_name: entry.batchName,
            total_marks: entry.totalMarks,
            rank: index + 1,
        }));
    }
    getProfileName(item) {
        const profiles = item.students?.profiles;
        if (Array.isArray(profiles)) {
            return profiles[0]?.full_name ?? 'Unknown Student';
        }
        return profiles?.full_name ?? 'Unknown Student';
    }
    getBatchName(item) {
        return item.batches?.name ?? item.students?.name ?? 'Unassigned Batch';
    }
}
exports.LeaderboardService = LeaderboardService;
//# sourceMappingURL=achievement-service.js.map