"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportService = void 0;
const supabase_1 = require("../../config/supabase");
const http_error_1 = require("../../errors/http-error");
class ReportService {
    async getDailySummary(logDate) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_logs')
            .select('student_id, log_date, marks_earned, students(batch_id)')
            .eq('log_date', logDate);
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to fetch daily summary.', error);
        }
        const summary = new Map();
        for (const row of data ?? []) {
            const item = row;
            const existing = summary.get(item.student_id) ?? {
                student_id: item.student_id,
                log_date: item.log_date,
                total_marks: 0,
                activities_completed: 0,
                batch_id: item.students?.batch_id ?? null,
            };
            existing.total_marks += item.marks_earned;
            existing.activities_completed += 1;
            summary.set(item.student_id, existing);
        }
        return Array.from(summary.values());
    }
    async getStudentProgress(studentId, from, to) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('activity_logs')
            .select('*')
            .eq('student_id', studentId)
            .gte('log_date', from)
            .lte('log_date', to)
            .order('log_date', { ascending: true });
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to fetch student progress.', error);
        }
        return (data ?? []);
    }
}
exports.ReportService = ReportService;
//# sourceMappingURL=report-service.js.map