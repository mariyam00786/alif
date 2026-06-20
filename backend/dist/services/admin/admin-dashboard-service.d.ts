import type { AuthenticatedUser } from '../../types/domain';
type DatabaseRow = Record<string, unknown>;
export interface AdminDashboardSnapshot {
    students: DatabaseRow[];
    teachers: DatabaseRow[];
    batchClasses: DatabaseRow[];
    activities: DatabaseRow[];
    ratingRules: DatabaseRow[];
    reports: DatabaseRow[];
    notifications: DatabaseRow[];
    badges: DatabaseRow[];
}
export declare class AdminDashboardService {
    private readonly auditLogService;
    getSnapshot(): Promise<AdminDashboardSnapshot>;
    assignTeacherToBatch(batchId: string, teacherId: string, actor?: AuthenticatedUser): Promise<void>;
    setPrimaryRule(ruleId: string, ruleKind: 'rating' | 'scoring', actor?: AuthenticatedUser): Promise<void>;
    private calculateStreak;
    private stringifyCriteria;
    private describeAudience;
    private buildReports;
    private getDemoSnapshot;
}
export {};
//# sourceMappingURL=admin-dashboard-service.d.ts.map