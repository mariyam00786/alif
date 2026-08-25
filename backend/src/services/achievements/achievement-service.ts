import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';
import { BaseResourceService } from '../shared/base-resource-service';

export class BadgeService extends BaseResourceService {
  constructor() {
    super('badges', 'badge');
  }

  /**
   * Updates a badge. Overrides the base implementation because the `badges`
   * table has no `updated_at` column (the base service injects one).
   */
  async updateBadge(id: string, payload: Record<string, unknown>): Promise<Record<string, unknown>> {
    const { data, error } = await getSupabaseClient()
      .from('badges')
      .update(payload)
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to update badge.', error);
    }
    if (!data) {
      throw new HttpError(404, 'Badge not found.');
    }
    return data as Record<string, unknown>;
  }

  async remove(id: string): Promise<void> {
    const { error } = await getSupabaseClient().from('badges').delete().eq('id', id);
    if (error) {
      throw new HttpError(500, 'Unable to delete badge.', error);
    }
  }
}

export class LeaderboardService {
  async getWeeklyLeaderboard(startDate: string, endDate: string): Promise<Record<string, unknown>[]> {
    const { data, error } = await getSupabaseClient()
      .from('activity_logs')
      .select('student_id, marks_earned, students(batch_id, profiles(full_name)), students:batches(name)')
      .gte('log_date', startDate)
      .lte('log_date', endDate);

    if (error) {
      throw new HttpError(500, 'Unable to compute leaderboard.', error);
    }

    const totals = new Map<string, { studentId: string; fullName: string; batchName: string; totalMarks: number }>();

    for (const row of data ?? []) {
      const item = row as {
        student_id: string;
        marks_earned: number;
        students?: { profiles?: { full_name?: string } | Array<{ full_name?: string }>; name?: string } | null;
        batches?: { name?: string } | null;
      };

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

  private getProfileName(item: { students?: { profiles?: { full_name?: string } | Array<{ full_name?: string }> } | null }): string {
    const profiles = item.students?.profiles;

    if (Array.isArray(profiles)) {
      return profiles[0]?.full_name ?? 'Unknown Student';
    }

    return profiles?.full_name ?? 'Unknown Student';
  }

  private getBatchName(item: { batches?: { name?: string } | null; students?: { name?: string } | null }): string {
    return item.batches?.name ?? item.students?.name ?? 'Unassigned Batch';
  }
}