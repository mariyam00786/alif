/**
 * Activity Logging Service
 *
 * Handles creation, updates, and retrieval of daily activity logs
 *
 * Core functionality:
 * 1. Create daily records with multiple activities
 * 2. Update existing records with new ratings
 * 3. Calculate and update total marks
 * 4. Validate activity uniqueness per day
 * 5. Handle parent approval workflow
 */
import { DailyRecord, DailyRecordItem, ActivityLog } from '../types/database';
/**
 * Creates a new daily record
 *
 * @param studentId - ID of the student
 * @param logDate - Date in YYYY-MM-DD format
 * @param items - Map of activity_id to DailyRecordItem
 * @param totalActivities - Total number of available activities
 * @returns Created DailyRecord object
 * @throws Error if validation fails
 *
 * @example
 * const record = createDailyRecord(
 *   'student-123',
 *   '2026-06-18',
 *   {
 *     'activity-prayer': {
 *       activity_id: 'activity-prayer',
 *       rating_id: 'rating-excellent',
 *       marks_earned: 10,
 *     },
 *     'activity-quran': {
 *       activity_id: 'activity-quran',
 *       rating_id: null,
 *       quantity: 0,
 *       marks_earned: 0,
 *     }
 *   },
 *   5 // Total activities
 * );
 */
export declare function createDailyRecord(studentId: string, logDate: string, items: Record<string, DailyRecordItem>, totalActivities: number): DailyRecord;
/**
 * Updates an existing daily record
 *
 * Can update:
 * - Individual activity items (ratings, quantities, notes)
 * - Submission status
 * - Parent approval
 *
 * Cannot update after submission (is_submitted = true)
 *
 * @param record - Current daily record
 * @param updates - Fields to update
 * @returns Updated DailyRecord
 * @throws Error if record is submitted or validation fails
 *
 * @example
 * const updated = updateDailyRecord(record, {
 *   items: {
 *     ...record.items,
 *     'activity-prayer': {
 *       ...record.items['activity-prayer'],
 *       rating_id: 'rating-satisfactory',
 *       marks_earned: 5,
 *     }
 *   }
 * });
 */
export declare function updateDailyRecord(record: DailyRecord, updates: {
    items?: Record<string, DailyRecordItem>;
    is_submitted?: boolean;
    parent_approved?: boolean;
    submitted_at?: string;
}): DailyRecord;
/**
 * Marks a daily record as submitted (locked)
 *
 * Once submitted, the record cannot be edited by the student
 * Parent can approve if needed
 *
 * @param record - Daily record to submit
 * @returns Updated record with is_submitted = true
 */
export declare function submitDailyRecord(record: DailyRecord): DailyRecord;
/**
 * Approves a submitted record (parent approval)
 *
 * Only valid for submitted records
 *
 * @param record - Daily record to approve
 * @returns Updated record with parent_approved = true
 * @throws Error if record is not submitted
 */
export declare function approveDailyRecord(record: DailyRecord): DailyRecord;
/**
 * Converts DailyRecord to ActivityLog entries (for database storage)
 *
 * When storing a daily record in the database, it's normalized to
 * multiple ActivityLog rows (one per activity)
 *
 * @param dailyRecord - Daily record to convert
 * @returns Array of ActivityLog entries
 */
export declare function dailyRecordToActivityLogs(dailyRecord: DailyRecord): ActivityLog[];
/**
 * Converts ActivityLog entries back to DailyRecord (for retrieval)
 *
 * When retrieving a daily record from database, logs are aggregated
 * back into a single DailyRecord object
 *
 * @param logs - Array of activity logs for one day
 * @param totalActivities - Total available activities
 * @returns Daily record object
 */
export declare function activityLogsToDailyRecord(logs: ActivityLog[], totalActivities: number): DailyRecord;
/**
 * Calculates a completion score (0-100) for a daily record
 *
 * Used for visual feedback and leaderboard ranking
 *
 * @param record - Daily record
 * @param maxMarks - Maximum possible marks (default 100)
 * @returns Score 0-100
 */
export declare function calculateCompletionScore(record: DailyRecord, maxMarks?: number): number;
/**
 * Validates that all required activities have been marked for a day
 *
 * @param record - Daily record
 * @param requiredActivityIds - List of activity IDs that must be completed
 * @returns Validation result with list of missing activities
 */
export declare function validateAllActivitiesMarked(record: DailyRecord, requiredActivityIds: string[]): {
    allMarked: boolean;
    missing: string[];
};
/**
 * Activity Logging Summary
 *
 * ============================================
 * Daily Record Structure
 * ============================================
 * - student_id: Who is logging
 * - log_date: Which day (YYYY-MM-DD)
 * - items: { activity_id: { rating, quantity, marks } }
 * - total_marks: Sum of all marks
 * - activities_completed: Count of marked activities
 * - completion_percentage: %
 *
 * ============================================
 * Workflow
 * ============================================
 * 1. Create record with activities
 * 2. Update as student marks activities
 * 3. Submit when done (locked)
 * 4. Parent approves (optional)
 * 5. Store as ActivityLog entries in DB
 *
 * ============================================
 * Validation Rules
 * ============================================
 * - No duplicate activities per day
 * - Rating IDs must exist
 * - Quantities must be non-negative
 * - Marks must be calculated correctly
 * - Cannot edit after submission
 */
//# sourceMappingURL=activity-logging-service.d.ts.map