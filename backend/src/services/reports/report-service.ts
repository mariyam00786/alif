import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';

export class ReportService {
  async getDailySummary(logDate: string): Promise<Record<string, unknown>[]> {
    const { data, error } = await getSupabaseClient()
      .from('activity_logs')
      .select('student_id, log_date, marks_earned, students(batch_id)')
      .eq('log_date', logDate);

    if (error) {
      throw new HttpError(500, 'Unable to fetch daily summary.', error);
    }

    const summary = new Map<string, { student_id: string; log_date: string; total_marks: number; activities_completed: number; batch_id: string | null }>();

    for (const row of data ?? []) {
      const item = row as {
        student_id: string;
        log_date: string;
        marks_earned: number;
        students?: { batch_id?: string | null } | null;
      };
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

  async getStudentProgress(studentId: string, from: string, to: string): Promise<Record<string, unknown>[]> {
    const { data, error } = await getSupabaseClient()
      .from('activity_logs')
      .select('*')
      .eq('student_id', studentId)
      .gte('log_date', from)
      .lte('log_date', to)
      .order('log_date', { ascending: true });

    if (error) {
      throw new HttpError(500, 'Unable to fetch student progress.', error);
    }

    return (data ?? []) as Record<string, unknown>[];
  }
}