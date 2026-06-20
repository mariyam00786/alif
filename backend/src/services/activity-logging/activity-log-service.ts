import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';
import type { Activity, ActivityRating, ActivityScoringRule } from '../../types/database';
import type { ActivityLogDraft, AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';
import { ActivityLoggingService } from './activity-logging-service';

export class ActivityLogService {
  private readonly activityLoggingService = new ActivityLoggingService();
  private readonly auditLogService = new AuditLogService();

  async list(filters: { studentId?: string; from?: string; to?: string }): Promise<Record<string, unknown>[]> {
    let query = getSupabaseClient().from('activity_logs').select('*').order('log_date', { ascending: false });

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
      throw new HttpError(500, 'Unable to fetch activity logs.', error);
    }

    return (data ?? []) as Record<string, unknown>[];
  }

  async upsert(draft: ActivityLogDraft, actor: AuthenticatedUser): Promise<Record<string, unknown>> {
    const activity = await this.loadActivity(draft.activityId);
    const rating = draft.ratingId ? await this.loadRating(draft.ratingId) : null;
    const scoringRules = await this.loadScoringRules(draft.activityId);
    const payload = this.activityLoggingService.buildLogEntry({
      draft,
      activity,
      rating,
      scoringRules,
    });

    const { data, error } = await getSupabaseClient()
      .from('activity_logs')
      .upsert(payload, {
        onConflict: 'student_id,activity_id,log_date',
      })
      .select('*')
      .single();

    if (error) {
      throw new HttpError(500, 'Unable to save activity log.', error);
    }

    await this.auditLogService.log({
      actor,
      action: 'upsert-activity-log',
      entityType: 'activity_log',
      entityId: String((data as Record<string, unknown>).id ?? ''),
      metadata: payload as unknown as Record<string, unknown>,
    });

    return data as Record<string, unknown>;
  }

  private async loadActivity(activityId: string): Promise<Pick<Activity, 'id' | 'name' | 'has_quantity'>> {
    const { data, error } = await getSupabaseClient()
      .from('activities')
      .select('id, name, has_quantity')
      .eq('id', activityId)
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to load activity.', error);
    }

    if (!data) {
      throw new HttpError(404, 'Activity not found.');
    }

    return data as Pick<Activity, 'id' | 'name' | 'has_quantity'>;
  }

  private async loadRating(ratingId: string): Promise<Pick<ActivityRating, 'id' | 'activity_id' | 'marks' | 'rating_name'>> {
    const { data, error } = await getSupabaseClient()
      .from('activity_ratings')
      .select('id, activity_id, marks, rating_name')
      .eq('id', ratingId)
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to load activity rating.', error);
    }

    if (!data) {
      throw new HttpError(404, 'Activity rating not found.');
    }

    return data as Pick<ActivityRating, 'id' | 'activity_id' | 'marks' | 'rating_name'>;
  }

  private async loadScoringRules(activityId: string): Promise<Array<Pick<ActivityScoringRule, 'id' | 'activity_id' | 'rule_type' | 'min_quantity' | 'max_quantity' | 'marks' | 'display_order'>>> {
    const { data, error } = await getSupabaseClient()
      .from('activity_scoring_rules')
      .select('id, activity_id, rule_type, min_quantity, max_quantity, marks, display_order')
      .eq('activity_id', activityId)
      .order('display_order', { ascending: true });

    if (error) {
      throw new HttpError(500, 'Unable to load activity scoring rules.', error);
    }

    return (data ?? []) as Array<Pick<ActivityScoringRule, 'id' | 'activity_id' | 'rule_type' | 'min_quantity' | 'max_quantity' | 'marks' | 'display_order'>>;
  }
}