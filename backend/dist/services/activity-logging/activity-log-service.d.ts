import type { ActivityLogDraft, AuthenticatedUser } from '../../types/domain';
export declare class ActivityLogService {
    private readonly activityLoggingService;
    private readonly auditLogService;
    list(filters: {
        studentId?: string;
        from?: string;
        to?: string;
    }): Promise<Record<string, unknown>[]>;
    upsert(draft: ActivityLogDraft, actor: AuthenticatedUser): Promise<Record<string, unknown>>;
    private loadActivity;
    private loadRating;
    private loadScoringRules;
}
//# sourceMappingURL=activity-log-service.d.ts.map