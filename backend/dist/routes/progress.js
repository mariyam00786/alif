"use strict";
/**
 * Student Progress Endpoints
 *
 * API routes for retrieving student progress metrics
 * (Daily, Weekly, Monthly summaries, Rankings, Leaderboard)
 *
 * Endpoints:
 * - GET /api/students/:studentId/progress/daily
 * - GET /api/students/:studentId/progress/weekly
 * - GET /api/students/:studentId/progress/monthly
 * - GET /api/batches/:batchId/leaderboard
 * - GET /api/batches/:batchId/leaderboard/weekly
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const error_handler_1 = require("../middleware/error-handler");
const progress_service_1 = require("../services/progress-service");
const router = (0, express_1.Router)();
/**
 * GET /api/students/:studentId/progress/daily
 *
 * Get daily progress metrics for a student
 *
 * Query params:
 * - date: YYYY-MM-DD (optional, default: today)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "date": "2026-06-18",
 *     "marks_earned": 45,
 *     "completion_percentage": 75,
 *     "activities_completed": 9,
 *     "total_activities": 12,
 *     "trend": "improving",
 *     "previous_day_marks": 42
 *   }
 * }
 * ```
 */
router.get('/students/:studentId/progress/daily', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { date = new Date().toISOString().split('T')[0] } = req.query;
    // Check access
    if (req.user?.role === 'student' && (req.user?.profileId ?? req.user?.id) !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // Mock records for this student
    const records = [];
    // Get daily marks
    const dailyProgress = (0, progress_service_1.getDailyMarks)(records, date);
    // Get trend
    const trend = (0, progress_service_1.calculateTrend)(records, date);
    res.status(200).json({
        success: true,
        data: {
            date,
            ...dailyProgress,
            trend,
        },
    });
}));
/**
 * GET /api/students/:studentId/progress/weekly
 *
 * Get weekly progress summary for a student
 *
 * Query params:
 * - startDate: YYYY-MM-DD (optional, default: Monday of current week)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "week_start": "2026-06-15",
 *     "week_end": "2026-06-21",
 *     "total_marks": 287,
 *     "daily_average": 41,
 *     "days_logged": 6,
 *     "completion_percentage": 68,
 *     "daily_breakdown": [
 *       {
 *         "date": "2026-06-15",
 *         "marks": 35,
 *         "completion_percentage": 60,
 *         "activities_completed": 7
 *       },
 *       ...
 *     ]
 *   }
 * }
 * ```
 */
router.get('/students/:studentId/progress/weekly', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { startDate } = req.query;
    // Check access
    if (req.user?.role === 'student' && (req.user?.profileId ?? req.user?.id) !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // Mock records
    const records = [];
    // Calculate Monday of current week
    const date = startDate
        ? new Date(startDate)
        : new Date();
    const monday = new Date(date);
    const day = monday.getDay();
    const diff = monday.getDate() - day + (day === 0 ? -6 : 1);
    monday.setDate(diff);
    const weeklyProgress = (0, progress_service_1.getWeeklyTotal)(records, monday.toISOString().split('T')[0]);
    res.status(200).json({
        success: true,
        data: weeklyProgress,
    });
}));
/**
 * GET /api/students/:studentId/progress/monthly
 *
 * Get monthly progress summary for a student
 *
 * Query params:
 * - month: YYYY-MM (optional, default: current month)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "month": "2026-06",
 *     "total_marks": 1245,
 *     "daily_average": 42,
 *     "days_logged": 28,
 *     "completion_percentage": 65,
 *     "weekly_breakdown": [
 *       {
 *         "week": "week-1",
 *         "start_date": "2026-06-01",
 *         "end_date": "2026-06-07",
 *         "total_marks": 287,
 *         "days_logged": 6
 *       },
 *       ...
 *     ]
 *   }
 * }
 * ```
 */
router.get('/students/:studentId/progress/monthly', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const now = new Date();
    const { month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}` } = req.query;
    // Check access
    if (req.user?.role === 'student' && (req.user?.profileId ?? req.user?.id) !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // Mock records
    const records = [];
    const monthlyProgress = (0, progress_service_1.getMonthlyTotal)(records, month);
    res.status(200).json({
        success: true,
        data: monthlyProgress,
    });
}));
/**
 * GET /api/batches/:batchId/leaderboard
 *
 * Get leaderboard/ranking for a batch
 *
 * Query params:
 * - date: YYYY-MM-DD (optional, default: today)
 * - limit: number (optional, default: 50)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "rank": 1,
 *       "student_id": "student-123",
 *       "student_name": "Ahmed",
 *       "total_marks": 287,
 *       "completion_percentage": 95,
 *       "days_logged": 28
 *     },
 *     ...
 *   ]
 * }
 * ```
 */
router.get('/batches/:batchId/leaderboard', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    const { date = new Date().toISOString().split('T')[0], limit = 50 } = req.query;
    // Mock: Get batch students and their records
    const batchStudentIds = [];
    const allStudentRecords = {};
    // Get top students
    const topStudents = (0, progress_service_1.getTopStudents)(allStudentRecords, batchStudentIds, date, Number(limit));
    res.status(200).json({
        success: true,
        data: topStudents,
    });
}));
/**
 * GET /api/batches/:batchId/leaderboard/weekly
 *
 * Get weekly leaderboard for a batch
 *
 * Query params:
 * - startDate: YYYY-MM-DD (optional, default: Monday of current week)
 * - limit: number (optional, default: 50)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "rank": 1,
 *       "student_id": "student-123",
 *       "student_name": "Ahmed",
 *       "week_marks": 287,
 *       "daily_average": 41,
 *       "days_logged": 7
 *     },
 *     ...
 *   ]
 * }
 * ```
 */
router.get('/batches/:batchId/leaderboard/weekly', (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    const { startDate, limit = 50 } = req.query;
    // Calculate Monday of current week
    const date = startDate ? new Date(startDate) : new Date();
    const monday = new Date(date);
    const day = monday.getDay();
    const diff = monday.getDate() - day + (day === 0 ? -6 : 1);
    monday.setDate(diff);
    // Mock: Get batch students and their records
    const batchStudentIds = [];
    const allStudentRecords = {};
    // Get top students for the week
    const topStudents = (0, progress_service_1.getTopStudents)(allStudentRecords, batchStudentIds, monday.toISOString().split('T')[0], Number(limit));
    res.status(200).json({
        success: true,
        data: {
            week_start: monday.toISOString().split('T')[0],
            leaderboard: topStudents,
        },
    });
}));
/**
 * GET /api/students/:studentId/progress/comparison
 *
 * Compare student's progress between time periods
 *
 * Query params:
 * - currentStartDate: YYYY-MM-DD
 * - currentEndDate: YYYY-MM-DD
 * - previousStartDate: YYYY-MM-DD
 * - previousEndDate: YYYY-MM-DD
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "current_period": { ... },
 *     "previous_period": { ... },
 *     "improvement": {
 *       "marks_change": 15,
 *       "percentage_change": 5,
 *       "trend": "improving"
 *     }
 *   }
 * }
 * ```
 */
router.get('/students/:studentId/progress/comparison', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { currentStartDate, currentEndDate, previousStartDate, previousEndDate, } = req.query;
    // Check access
    if (req.user?.role === 'student' && (req.user?.profileId ?? req.user?.id) !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // Mock records
    const records = [];
    res.status(200).json({
        success: true,
        data: {
            current_period: {
                start_date: currentStartDate,
                end_date: currentEndDate,
                total_marks: 287,
                days_logged: 7,
            },
            previous_period: {
                start_date: previousStartDate,
                end_date: previousEndDate,
                total_marks: 265,
                days_logged: 6,
            },
            improvement: {
                marks_change: 22,
                percentage_change: 8.3,
                trend: 'improving',
            },
        },
    });
}));
exports.default = router;
//# sourceMappingURL=progress.js.map