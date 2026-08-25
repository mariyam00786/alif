import { BaseResourceService } from '../shared/base-resource-service';
export declare class BadgeService extends BaseResourceService {
    constructor();
}
export declare class LeaderboardService {
    getWeeklyLeaderboard(startDate: string, endDate: string): Promise<Record<string, unknown>[]>;
    private getProfileName;
    private getBatchName;
}
//# sourceMappingURL=achievement-service.d.ts.map