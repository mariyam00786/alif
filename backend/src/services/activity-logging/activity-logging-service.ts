import { ScoringService } from '../scoring/scoring-service';
import type { Activity, ActivityRating, ActivityScoringRule } from '../../types/database';
import type { ActivityLogDraft, ActivityLogUpsert } from '../../types/domain';

interface BuildActivityLogInput {
  draft: ActivityLogDraft;
  activity: Pick<Activity, 'id' | 'name' | 'has_quantity'>;
  rating?: Pick<ActivityRating, 'id' | 'activity_id' | 'marks' | 'rating_name'> | null;
  scoringRules?: Array<Pick<ActivityScoringRule, 'id' | 'activity_id' | 'rule_type' | 'min_quantity' | 'max_quantity' | 'marks' | 'display_order'>>;
}

export class ActivityLoggingService {
  constructor(private readonly scoringService: ScoringService = new ScoringService()) {}

  buildLogEntry(input: BuildActivityLogInput): ActivityLogUpsert {
    if (input.draft.activityId !== input.activity.id) {
      throw new Error('Draft activity and loaded activity do not match.');
    }

    const calculatedScore = this.scoringService.calculateScore({
      activity: input.activity,
      rating: input.rating,
      scoringRules: input.scoringRules,
      quantity: input.draft.quantity,
    });

    return {
      student_id: input.draft.studentId,
      activity_id: input.draft.activityId,
      rating_id: calculatedScore.ratingId,
      log_date: input.draft.logDate,
      quantity: calculatedScore.quantity,
      marks_earned: calculatedScore.marks,
      parent_approved: input.draft.parentApproved ?? false,
      notes: input.draft.notes ?? null,
    };
  }
}