import { BaseResourceService } from '../shared/base-resource-service';
export declare class BadgeService extends BaseResourceService {
    constructor();
    /**
     * Updates a badge. Overrides the base implementation because the `badges`
     * table has no `updated_at` column (the base service injects one).
     */
    updateBadge(id: string, payload: Record<string, unknown>): Promise<Record<string, unknown>>;
    remove(id: string): Promise<void>;
}
export declare class LeaderboardService {
    getWeeklyLeaderboard(startDate: string, endDate: string): Promise<Record<string, unknown>[]>;
    private getProfileName;
    private getBatchName;
}
//# sourceMappingURL=achievement-service.d.ts.map