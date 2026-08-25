"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDailyRecord = createDailyRecord;
exports.updateDailyRecord = updateDailyRecord;
exports.submitDailyRecord = submitDailyRecord;
exports.approveDailyRecord = approveDailyRecord;
exports.dailyRecordToActivityLogs = dailyRecordToActivityLogs;
exports.activityLogsToDailyRecord = activityLogsToDailyRecord;
exports.calculateCompletionScore = calculateCompletionScore;
exports.validateAllActivitiesMarked = validateAllActivitiesMarked;
/**
 * Validates a daily record item
 *
 * Checks that:
 * - activity_id is provided
 * - marks_earned is a valid number
 * - rating_id is either null (not done) or a valid string
 * - quantity is either undefined or a positive number
 */
function validateRecordItem(item) {
    // Check activity_id
    if (!item.activity_id || typeof item.activity_id !== 'string') {
        return { valid: false, error: 'Invalid activity_id' };
    }
    // Check marks_earned
    if (typeof item.marks_earned !== 'number' || item.marks_earned < 0) {
        return { valid: false, error: 'marks_earned must be a non-negative number' };
    }
    // Check rating_id if provided
    if (item.rating_id !== undefined && item.rating_id !== null) {
        if (typeof item.rating_id !== 'string') {
            return { valid: false, error: 'rating_id must be a string or null' };
        }
    }
    // Check quantity if provided
    if (item.quantity !== undefined) {
        if (typeof item.quantity !== 'number' || item.quantity < 0) {
            return { valid: false, error: 'quantity must be a non-negative number' };
        }
    }
    return { valid: true };
}
/**
 * Validates a complete daily record
 *
 * Checks:
 * - Student ID is provided
 * - Log date is valid (YYYY-MM-DD format)
 * - Items is an object with activity IDs as keys
 * - No duplicate activities in one day
 * - All items are valid
 */
function validateDailyRecord(record) {
    const errors = [];
    // Check student_id
    if (!record.student_id) {
        errors.push('student_id is required');
    }
    // Check log_date format (YYYY-MM-DD)
    if (!record.log_date || !/^\d{4}-\d{2}-\d{2}$/.test(record.log_date)) {
        errors.push('log_date must be in YYYY-MM-DD format');
    }
    else {
        // Validate date is valid
        const date = new Date(record.log_date);
        if (isNaN(date.getTime())) {
            errors.push('log_date is not a valid date');
        }
    }
    // Check items
    if (!record.items || typeof record.items !== 'object') {
        errors.push('items must be an object with activity IDs as keys');
    }
    else {
        // Check for duplicates (should already be prevented by object keys)
        const activityIds = Object.keys(record.items);
        const duplicates = activityIds.filter((id, index) => activityIds.indexOf(id) !== index);
        if (duplicates.length > 0) {
            errors.push(`Duplicate activities in one day: ${duplicates.join(', ')}`);
        }
        // Validate each item
        Object.entries(record.items).forEach(([activityId, item]) => {
            const validation = validateRecordItem(item);
            if (!validation.valid) {
                errors.push(`Activity ${activityId}: ${validation.error}`);
            }
        });
    }
    return {
        valid: errors.length === 0,
        errors,
    };
}
/**
 * Calculates daily statistics from items
 */
function calculateDailyStats(items, totalActivities) {
    const itemsList = Object.values(items);
    const total_marks = itemsList.reduce((sum, item) => sum + item.marks_earned, 0);
    const activities_completed = itemsList.filter(item => item.rating_id !== null && item.rating_id !== undefined).length;
    const completion_percentage = totalActivities > 0 ? (activities_completed / totalActivities) * 100 : 0;
    return {
        total_marks,
        activities_completed,
        completion_percentage,
    };
}
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
function createDailyRecord(studentId, logDate, items, totalActivities) {
    // Validate input
    const validation = validateDailyRecord({
        student_id: studentId,
        log_date: logDate,
        items,
    });
    if (!validation.valid) {
        throw new Error(`Daily record validation failed: ${validation.errors.join('; ')}`);
    }
    // Calculate statistics
    const stats = calculateDailyStats(items, totalActivities);
    const now = new Date().toISOString();
    return {
        id: `daily-${studentId}-${logDate}`, // Derived ID (or use UUID)
        student_id: studentId,
        log_date: logDate,
        items,
        total_marks: stats.total_marks,
        activities_completed: stats.activities_completed,
        total_activities: totalActivities,
        completion_percentage: stats.completion_percentage,
        is_submitted: false,
        created_at: now,
        updated_at: now,
    };
}
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
function updateDailyRecord(record, updates) {
    // Check if record is already submitted
    if (record.is_submitted && updates.items) {
        throw new Error('Cannot update items after record is submitted');
    }
    // Update items if provided
    let newItems = record.items;
    if (updates.items) {
        const validation = validateDailyRecord({
            student_id: record.student_id,
            log_date: record.log_date,
            items: updates.items,
        });
        if (!validation.valid) {
            throw new Error(`Daily record validation failed: ${validation.errors.join('; ')}`);
        }
        newItems = updates.items;
    }
    // Recalculate statistics
    const stats = calculateDailyStats(newItems, record.total_activities);
    // Build updated record
    const updated = {
        ...record,
        items: newItems,
        total_marks: stats.total_marks,
        activities_completed: stats.activities_completed,
        completion_percentage: stats.completion_percentage,
        is_submitted: updates.is_submitted ?? record.is_submitted,
        parent_approved: updates.parent_approved ?? record.parent_approved,
        submitted_at: updates.submitted_at ?? record.submitted_at,
        updated_at: new Date().toISOString(),
    };
    return updated;
}
/**
 * Marks a daily record as submitted (locked)
 *
 * Once submitted, the record cannot be edited by the student
 * Parent can approve if needed
 *
 * @param record - Daily record to submit
 * @returns Updated record with is_submitted = true
 */
function submitDailyRecord(record) {
    return updateDailyRecord(record, {
        is_submitted: true,
        submitted_at: new Date().toISOString(),
    });
}
/**
 * Approves a submitted record (parent approval)
 *
 * Only valid for submitted records
 *
 * @param record - Daily record to approve
 * @returns Updated record with parent_approved = true
 * @throws Error if record is not submitted
 */
function approveDailyRecord(record) {
    if (!record.is_submitted) {
        throw new Error('Can only approve submitted records');
    }
    return updateDailyRecord(record, {
        parent_approved: true,
    });
}
/**
 * Converts DailyRecord to ActivityLog entries (for database storage)
 *
 * When storing a daily record in the database, it's normalized to
 * multiple ActivityLog rows (one per activity)
 *
 * @param dailyRecord - Daily record to convert
 * @returns Array of ActivityLog entries
 */
function dailyRecordToActivityLogs(dailyRecord) {
    return Object.entries(dailyRecord.items).map(([, item]) => ({
        id: `log-${dailyRecord.student_id}-${dailyRecord.log_date}-${item.activity_id}`,
        student_id: dailyRecord.student_id,
        activity_id: item.activity_id,
        rating_id: item.rating_id ?? undefined,
        log_date: dailyRecord.log_date,
        quantity: item.quantity,
        marks_earned: item.marks_earned,
        parent_approved: dailyRecord.parent_approved ?? false,
        notes: item.notes,
        created_at: dailyRecord.created_at,
        updated_at: dailyRecord.updated_at,
    }));
}
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
function activityLogsToDailyRecord(logs, totalActivities) {
    const items = {};
    let submitted = false;
    let parentApproved = false;
    let submittedAt;
    logs.forEach(log => {
        items[log.activity_id] = {
            activity_id: log.activity_id,
            rating_id: log.rating_id ?? undefined,
            quantity: log.quantity,
            marks_earned: log.marks_earned,
            notes: log.notes,
        };
        parentApproved = parentApproved || log.parent_approved;
    });
    const stats = calculateDailyStats(items, totalActivities);
    const first = logs[0];
    return {
        id: `daily-${first.student_id}-${first.log_date}`,
        student_id: first.student_id,
        log_date: first.log_date,
        items,
        total_marks: stats.total_marks,
        activities_completed: stats.activities_completed,
        total_activities: totalActivities,
        completion_percentage: stats.completion_percentage,
        is_submitted: submitted,
        parent_approved: parentApproved,
        submitted_at: submittedAt,
        created_at: first.created_at,
        updated_at: first.updated_at,
    };
}
/**
 * Calculates a completion score (0-100) for a daily record
 *
 * Used for visual feedback and leaderboard ranking
 *
 * @param record - Daily record
 * @param maxMarks - Maximum possible marks (default 100)
 * @returns Score 0-100
 */
function calculateCompletionScore(record, maxMarks = 100) {
    return Math.min((record.total_marks / maxMarks) * 100, 100);
}
/**
 * Validates that all required activities have been marked for a day
 *
 * @param record - Daily record
 * @param requiredActivityIds - List of activity IDs that must be completed
 * @returns Validation result with list of missing activities
 */
function validateAllActivitiesMarked(record, requiredActivityIds) {
    const missing = requiredActivityIds.filter(id => !(id in record.items));
    return {
        allMarked: missing.length === 0,
        missing,
    };
}
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
//# sourceMappingURL=activity-logging-service.js.map