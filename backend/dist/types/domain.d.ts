import type { Activity, ActivityRating, ActivityScoringRule } from './database';
export type UserRole = 'student' | 'parent' | 'teacher' | 'admin';
export interface AuthenticatedUser {
    profileId: string;
    authUserId: string;
    role: UserRole;
    phone?: string;
    id?: string;
    profile_id?: string;
    name?: string;
    iat?: number;
    exp?: number;
}
export interface QuantityBand {
    minQuantity: number;
    maxQuantity?: number;
    marks: number;
}
export interface ScoringContext {
    activity: Pick<Activity, 'id' | 'has_quantity' | 'name'>;
    rating?: Pick<ActivityRating, 'id' | 'activity_id' | 'marks' | 'rating_name'> | null;
    scoringRules?: Array<Pick<ActivityScoringRule, 'id' | 'activity_id' | 'rule_type' | 'min_quantity' | 'max_quantity' | 'marks' | 'display_order'>>;
    quantity?: number;
}
export interface CalculatedScore {
    marks: number;
    ratingId: string | null;
    quantity: number | null;
    source: 'rating' | 'quantity';
}
export interface ActivityLogDraft {
    studentId: string;
    activityId: string;
    logDate: string;
    quantity?: number;
    ratingId?: string;
    parentApproved?: boolean;
    notes?: string;
}
export interface ActivityLogUpsert {
    student_id: string;
    activity_id: string;
    rating_id: string | null;
    log_date: string;
    quantity: number | null;
    marks_earned: number;
    parent_approved: boolean;
    notes: string | null;
}
//# sourceMappingURL=domain.d.ts.map