"use strict";
/**
 * Daily Records Routes
 *
 * API endpoints for managing student daily activity records
 *
 * Endpoints:
 * - POST   /api/daily-records - Create new daily record
 * - GET    /api/daily-records/:recordId - Get specific record
 * - PUT    /api/daily-records/:recordId - Update record
 * - GET    /api/students/:studentId/daily-records - List records for student
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const error_handler_1 = require("../middleware/error-handler");
const activity_logging_service_1 = require("../services/activity-logging-service");
const router = (0, express_1.Router)();
/**
 * POST /api/daily-records
 *
 * Create a new daily record for a student
 *
 * Request body:
 * ```json
 * {
 *   "student_id": "student-123",
 *   "log_date": "2026-06-18",
 *   "items": {
 *     "activity-prayer": {
 *       "activity_id": "activity-prayer",
 *       "rating_id": "rating-excellent",
 *       "marks_earned": 10,
 *       "notes": "Prayed with focus"
 *     },
 *     "activity-quran": {
 *       "activity_id": "activity-quran",
 *       "rating_id": "rating-satisfactory",
 *       "quantity": 10,
 *       "marks_earned": 7,
 *       "notes": "Read 10 pages"
 *     }
 *   }
 * }
 * ```
 *
 * Response: 201 Created
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "id": "daily-...",
 *     "student_id": "student-123",
 *     "log_date": "2026-06-18",
 *     "items": { ... },
 *     "total_marks": 17,
 *     "activities_completed": 2,
 *     "completion_percentage": 40,
 *     "is_submitted": false
 *   }
 * }
 * ```
 *
 * Error: 400 Bad Request (validation error)
 * Error: 409 Conflict (record already exists for date)
 */
router.post('/daily-records', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { student_id, log_date, items } = req.body;
    // Validate input
    if (!student_id || !log_date || !items) {
        return (0, error_handler_1.validationError)(res, 'Missing required fields: student_id, log_date, items');
    }
    // Check user ownership (student can only create for themselves, others need admin)
    if (req.user?.role === 'student' && req.user?.id !== student_id) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
            message: 'Students can only create records for themselves',
        });
    }
    // Create the record
    const record = (0, activity_logging_service_1.createDailyRecord)(student_id, log_date, items, Object.keys(items).length);
    // In production: save to database
    // const { data, error } = await supabase
    //   .from('activity_logs')
    //   .insert(dailyRecordToActivityLogs(record));
    // if (error) throw error;
    res.status(201).json({
        success: true,
        data: record,
    });
}));
/**
 * GET /api/daily-records/:recordId
 *
 * Retrieve a specific daily record
 *
 * Response: 200 OK
 */
router.get('/daily-records/:recordId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { recordId } = req.params;
    // In production: fetch from database
    // const { data, error } = await supabase
    //   .from('activity_logs')
    //   .select('*')
    //   .eq('id', recordId)
    //   .single();
    // For now, return mock
    const record = {
        id: recordId,
        student_id: 'student-123',
        log_date: '2026-06-18',
        items: {},
        total_marks: 0,
        activities_completed: 0,
        total_activities: 0,
        completion_percentage: 0,
        is_submitted: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: record,
    });
}));
/**
 * PUT /api/daily-records/:recordId
 *
 * Update an existing daily record
 * Only allowed before record is submitted
 *
 * Request body: Any fields to update (items, notes, etc.)
 *
 * Response: 200 OK
 * Error: 400 Bad Request (validation error)
 * Error: 409 Conflict (record already submitted)
 */
router.put('/daily-records/:recordId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { recordId } = req.params;
    const { items, submitted, parent_approved } = req.body;
    // In production: fetch existing record
    // const { data: record } = await supabase
    //   .from('activity_logs')
    //   .select('*')
    //   .eq('id', recordId)
    //   .single();
    // Mock record
    let record = {
        id: recordId,
        student_id: 'student-123',
        log_date: '2026-06-18',
        items: {},
        total_marks: 0,
        activities_completed: 0,
        total_activities: 0,
        completion_percentage: 0,
        is_submitted: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    // Check ownership
    if (req.user?.role === 'student' && req.user?.id !== record.student_id) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
            message: 'Cannot update other students\' records',
        });
    }
    // Update the record
    record = (0, activity_logging_service_1.updateDailyRecord)(record, {
        items,
        is_submitted: submitted,
        parent_approved,
    });
    // In production: save to database
    res.status(200).json({
        success: true,
        data: record,
    });
}));
/**
 * GET /api/students/:studentId/daily-records
 *
 * List all daily records for a student
 * Optional query params:
 * - startDate: YYYY-MM-DD (default: 30 days ago)
 * - endDate: YYYY-MM-DD (default: today)
 * - limit: number (default: 30)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     { id: "...", student_id: "...", log_date: "...", ... },
 *     ...
 *   ],
 *   "pagination": {
 *     "total": 45,
 *     "limit": 30,
 *     "offset": 0
 *   }
 * }
 * ```
 */
router.get('/students/:studentId/daily-records', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { startDate, endDate, limit = 30, offset = 0 } = req.query;
    // Check access (student own records, parent child's records, teacher batch, admin all)
    if (req.user?.role === 'student' &&
        req.user?.id !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // In production:
    // let query = supabase
    //   .from('activity_logs')
    //   .select('*', { count: 'exact' })
    //   .eq('student_id', studentId);
    //
    // if (startDate) query = query.gte('log_date', startDate as string);
    // if (endDate) query = query.lte('log_date', endDate as string);
    //
    // const { data, count, error } = await query
    //   .order('log_date', { ascending: false })
    //   .range(Number(offset), Number(offset) + Number(limit) - 1);
    const mockRecords = [];
    res.status(200).json({
        success: true,
        data: mockRecords,
        pagination: {
            total: mockRecords.length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/daily-records/:recordId/submit
 *
 * Submit a daily record (lock it)
 * Once submitted, cannot be edited by student
 *
 * Response: 200 OK
 */
router.post('/daily-records/:recordId/submit', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { recordId } = req.params;
    // Mock record
    let record = {
        id: recordId,
        student_id: 'student-123',
        log_date: '2026-06-18',
        items: {},
        total_marks: 0,
        activities_completed: 0,
        total_activities: 0,
        completion_percentage: 0,
        is_submitted: false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    // Submit
    record = (0, activity_logging_service_1.submitDailyRecord)(record);
    res.status(200).json({
        success: true,
        data: record,
    });
}));
/**
 * POST /api/daily-records/:recordId/approve
 *
 * Parent approval of submitted record
 * Only parent role can approve
 *
 * Response: 200 OK
 */
router.post('/daily-records/:recordId/approve', auth_1.requireAuth, (0, auth_1.requireRole)('parent'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { recordId } = req.params;
    // Mock record
    let record = {
        id: recordId,
        student_id: 'student-123',
        log_date: '2026-06-18',
        items: {},
        total_marks: 0,
        activities_completed: 0,
        total_activities: 0,
        completion_percentage: 0,
        is_submitted: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    // Approve
    record = (0, activity_logging_service_1.approveDailyRecord)(record);
    res.status(200).json({
        success: true,
        data: record,
    });
}));
exports.default = router;
//# sourceMappingURL=daily-records.js.map