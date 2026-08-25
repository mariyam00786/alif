/**
 * Progress Service
 *
 * Retrieves and calculates student progress metrics
 *
 * Metrics:
 * - Daily marks earned
 * - Weekly totals and trends
 * - Monthly summaries
 * - Batch rankings
 * - Performance statistics
 */
import { DailyRecord } from '../types/database';
/**
 * Daily progress metrics
 */
export interface DailyProgress {
    date: string;
    marks_earned: number;
    completion_percentage: number;
    activities_completed: number;
    total_activities: number;
}
/**
 * Weekly progress metrics
 */
export interface WeeklyProgress {
    week_start_date: string;
    week_end_date: string;
    total_marks: number;
    daily_average: number;
    days_logged: number;
    completion_percentage: number;
    days: DailyProgress[];
}
/**
 * Monthly progress metrics
 */
export interface MonthlyProgress {
    month: string;
    total_marks: number;
    daily_average: number;
    days_logged: number;
    completion_percentage: number;
    weekly_breakdown: {
        week_number: number;
        marks: number;
        average: number;
    }[];
}
/**
 * Batch ranking entry
 */
export interface RankingEntry {
    rank: number;
    student_id: string;
    student_name: string;
    total_marks: number;
    completion_percentage: number;
    days_logged: number;
}
/**
 * Gets daily marks for a specific date
 *
 * @param dailyRecords - Array of daily records or logs
 * @param date - Date in YYYY-MM-DD format
 * @returns Daily progress metrics
 */
export declare function getDailyMarks(records: DailyRecord[], date: string): DailyProgress | null;
/**
 * Gets weekly total marks for a student
 *
 * Returns total marks for the week containing the given start date
 *
 * @param records - Daily records for the student
 * @param startDate - Any date within the week (YYYY-MM-DD)
 * @returns Weekly progress metrics
 *
 * @example
 * const weekly = getWeeklyTotal(records, '2026-06-18');
 * // Returns { total_marks: 75, daily_average: 10.7, ... }
 */
export declare function getWeeklyTotal(records: DailyRecord[], startDate: string): WeeklyProgress;
/**
 * Gets monthly total marks for a student
 *
 * @param records - Daily records for the student
 * @param month - Month in YYYY-MM format
 * @returns Monthly progress metrics
 *
 * @example
 * const monthly = getMonthlyTotal(records, '2026-06');
 * // Returns { total_marks: 300, daily_average: 9.7, ... }
 */
export declare function getMonthlyTotal(records: DailyRecord[], month: string): MonthlyProgress;
/**
 * Calculates student rank in batch for a specific date
 *
 * Ranks students by total marks for the day
 *
 * @param studentId - Student to rank
 * @param allStudentRecords - Map of student_id to their records
 * @param batchStudentIds - IDs of students in the batch
 * @param date - Date to calculate ranking for (YYYY-MM-DD)
 * @returns Rank (1 = top) or null if no data
 *
 * @example
 * const rank = getRank('student-123', allRecords, batchIds, '2026-06-18');
 * // Returns 3 (3rd place in batch)
 */
export declare function getRank(studentId: string, allStudentRecords: Record<string, DailyRecord[]>, batchStudentIds: string[], date: string): number | null;
/**
 * Gets top N students in batch for a specific date
 *
 * @param allStudentRecords - Map of student_id to records and names
 * @param batchStudentIds - IDs of students in batch
 * @param date - Date to rank for
 * @param limit - Number of top students to return (default 10)
 * @returns Array of ranking entries sorted by marks descending
 */
export declare function getTopStudents(allStudentRecords: Record<string, {
    records: DailyRecord[];
    name: string;
}>, batchStudentIds: string[], date: string, limit?: number): RankingEntry[];
/**
 * Calculates performance trend (is student improving?)
 *
 * Compares recent week to previous week
 *
 * @param records - Daily records
 * @param referenceDate - Date to measure from
 * @returns Trend: positive (improving), negative (declining), neutral (same)
 */
export declare function calculateTrend(records: DailyRecord[], referenceDate?: string): {
    trend: 'improving' | 'declining' | 'neutral';
    percentage: number;
    currentWeekAverage: number;
    previousWeekAverage: number;
};
/**
 * Progress Service Summary
 *
 * ============================================
 * Metrics Available
 * ============================================
 * - Daily: marks, completion %
 * - Weekly: total, average, trend
 * - Monthly: total, average, weekly breakdown
 * - Ranking: position in batch, leaderboard
 * - Trend: improving/declining
 *
 * ============================================
 * Use Cases
 * ============================================
 * - Student dashboard: show daily/weekly/monthly
 * - Parent app: track child's progress
 * - Leaderboard: compare within batch
 * - Notifications: send when trend changes
 * - Reports: weekly/monthly summaries
 *
 * ============================================
 * Performance Considerations
 * ============================================
 * - Cache monthly summaries (rarely change)
 * - Calculate weekly on demand
 * - Calculate daily on write (from logs)
 * - Index by date for fast lookups
 */
//# sourceMappingURL=progress-service.d.ts.map