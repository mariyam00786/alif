import { ScoringService } from '../scoring/scoring-service';
import type { Activity, ActivityRating, ActivityScoringRule } from '../../types/database';
import type { ActivityLogDraft, ActivityLogUpsert } from '../../types/domain';
interface BuildActivityLogInput {
    draft: ActivityLogDraft;
    activity: Pick<Activity, 'id' | 'name' | 'has_quantity'>;
    rating?: Pick<ActivityRating, 'id' | 'activity_id' | 'marks' | 'rating_name'> | null;
    scoringRules?: Array<Pick<ActivityScoringRule, 'id' | 'activity_id' | 'rule_type' | 'min_quantity' | 'max_quantity' | 'marks' | 'display_order'>>;
}
export declare class ActivityLoggingService {
    private readonly scoringService;
    constructor(scoringService?: ScoringService);
    buildLogEntry(input: BuildActivityLogInput): ActivityLogUpsert;
}
export {};
//# sourceMappingURL=activity-logging-service.d.ts.map