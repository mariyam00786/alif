"use strict";
/**
 * Student Management Endpoints
 *
 * API routes for CRUD operations on students
 * Primarily for admin panel, restricted to admin role
 *
 * Endpoints:
 * - GET    /api/students - List all students (with filters)
 * - POST   /api/students - Create new student
 * - GET    /api/students/:studentId - Get student details
 * - PUT    /api/students/:studentId - Update student
 * - DELETE /api/students/:studentId - Delete student
 * - GET    /api/batches/:batchId/students - Get students in batch
 * - POST   /api/students/:studentId/assign-batch - Assign student to batch
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const error_handler_1 = require("../middleware/error-handler");
const router = (0, express_1.Router)();
/**
 * GET /api/students
 *
 * List all students with optional filtering
 *
 * Query params:
 * - batchId: Filter by batch
 * - classId: Filter by class
 * - status: Filter by status (active, inactive)
 * - searchTerm: Search by name or phone
 * - limit: number (default: 50)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "student-123",
 *       "name": "Ahmed",
 *       "email": "ahmed@example.com",
 *       "phone": "+966...",
 *       "batch_id": "batch-123",
 *       "class_id": "class-123",
 *       "status": "active",
 *       "created_at": "2026-06-01T..."
 *     },
 *     ...
 *   ],
 *   "pagination": {
 *     "total": 120,
 *     "limit": 50,
 *     "offset": 0
 *   }
 * }
 * ```
 */
router.get('/', auth_1.requireAuth, (0, auth_1.requireRole)('admin', 'teacher'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId, classId, status = 'active', searchTerm, limit = 50, offset = 0, } = req.query;
    // In production:
    // let query = supabase
    //   .from('students')
    //   .select('*', { count: 'exact' });
    //
    // if (batchId) query = query.eq('batch_id', batchId);
    // if (classId) query = query.eq('class_id', classId);
    // if (status) query = query.eq('status', status);
    // if (searchTerm) {
    //   query = query.or(`name.ilike.%${searchTerm}%,phone.ilike.%${searchTerm}%`);
    // }
    //
    // const { data, count, error } = await query
    //   .order('created_at', { ascending: false })
    //   .range(Number(offset), Number(offset) + Number(limit) - 1);
    const mockStudents = [];
    res.status(200).json({
        success: true,
        data: mockStudents,
        pagination: {
            total: mockStudents.length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/students
 *
 * Create a new student
 *
 * Request body:
 * ```json
 * {
 *   "name": "Ahmed Ali",
 *   "email": "ahmed@example.com",
 *   "phone": "+966501234567",
 *   "batch_id": "batch-123",
 *   "class_id": "class-123",
 *   "parent_id": "parent-123"
 * }
 * ```
 *
 * Response: 201 Created
 */
router.post('/', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { name, email, phone, batch_id, class_id, parent_id } = req.body;
    // Validate required fields
    if (!name || !phone) {
        return (0, error_handler_1.validationError)(res, 'name and phone are required');
    }
    // In production:
    // const { data, error } = await supabase
    //   .from('students')
    //   .insert([{
    //     name,
    //     email,
    //     phone,
    //     batch_id,
    //     class_id,
    //     parent_id,
    //     status: 'active'
    //   }])
    //   .select()
    //   .single();
    const newStudent = {
        id: 'student-' + Date.now(),
        name,
        email,
        phone,
        batch_id,
        class_id,
        parent_id,
        status: 'active',
        created_at: new Date().toISOString(),
    };
    res.status(201).json({
        success: true,
        data: newStudent,
    });
}));
/**
 * GET /api/students/:studentId
 *
 * Get detailed information about a student
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "id": "student-123",
 *     "name": "Ahmed",
 *     "email": "ahmed@example.com",
 *     "phone": "+966...",
 *     "batch_id": "batch-123",
 *     "class_id": "class-123",
 *     "parent_id": "parent-123",
 *     "status": "active",
 *     "created_at": "2026-06-01T...",
 *     "updated_at": "2026-06-18T..."
 *   }
 * }
 * ```
 *
 * Error: 404 Not Found
 */
router.get('/:studentId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    // Check access: student can view self, admin can view all
    if (req.user?.role === 'student' && req.user?.id !== studentId) {
        return res.status(403).json({
            success: false,
            error: 'FORBIDDEN',
        });
    }
    // In production:
    // const { data, error } = await supabase
    //   .from('students')
    //   .select('*')
    //   .eq('id', studentId)
    //   .single();
    const mockStudent = {
        id: studentId,
        name: 'Student Name',
        email: 'student@example.com',
        phone: '+966501234567',
        batch_id: 'batch-123',
        class_id: 'class-123',
        parent_id: 'parent-123',
        status: 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: mockStudent,
    });
}));
/**
 * PUT /api/students/:studentId
 *
 * Update student information
 *
 * Request body: Any fields to update
 *
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.put('/:studentId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { name, email, phone, batch_id, class_id, status } = req.body;
    // In production:
    // const { data, error } = await supabase
    //   .from('students')
    //   .update({
    //     name,
    //     email,
    //     phone,
    //     batch_id,
    //     class_id,
    //     status,
    //     updated_at: new Date().toISOString()
    //   })
    //   .eq('id', studentId)
    //   .select()
    //   .single();
    const updatedStudent = {
        id: studentId,
        name,
        email,
        phone,
        batch_id,
        class_id,
        status,
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: updatedStudent,
    });
}));
/**
 * DELETE /api/students/:studentId
 *
 * Delete a student (soft delete - mark as inactive)
 *
 * Response: 204 No Content
 * Error: 404 Not Found
 */
router.delete('/:studentId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    // In production: soft delete
    // const { error } = await supabase
    //   .from('students')
    //   .update({ status: 'inactive', updated_at: new Date() })
    //   .eq('id', studentId);
    res.status(204).send();
}));
/**
 * GET /api/batches/:batchId/students
 *
 * Get all students in a specific batch
 *
 * Query params:
 * - classId: Filter by class
 * - status: Filter by status
 * - limit: number (default: 100)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 */
router.get('/batch/:batchId/students', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    const { classId, status = 'active', limit = 100, offset = 0 } = req.query;
    // In production:
    // let query = supabase
    //   .from('students')
    //   .select('*', { count: 'exact' })
    //   .eq('batch_id', batchId)
    //   .eq('status', status);
    //
    // if (classId) query = query.eq('class_id', classId);
    //
    // const { data, count, error } = await query
    //   .order('name')
    //   .range(Number(offset), Number(offset) + Number(limit) - 1);
    const mockStudents = [];
    res.status(200).json({
        success: true,
        data: mockStudents,
        pagination: {
            total: mockStudents.length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/students/:studentId/assign-batch
 *
 * Assign student to a batch
 *
 * Request body:
 * ```json
 * {
 *   "batch_id": "batch-456"
 * }
 * ```
 *
 * Response: 200 OK
 */
router.post('/:studentId/assign-batch', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const { batch_id } = req.body;
    if (!batch_id) {
        return (0, error_handler_1.validationError)(res, 'batch_id is required');
    }
    // In production:
    // const { data, error } = await supabase
    //   .from('students')
    //   .update({ batch_id, updated_at: new Date() })
    //   .eq('id', studentId)
    //   .select()
    //   .single();
    const updatedStudent = {
        id: studentId,
        batch_id,
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: updatedStudent,
    });
}));
exports.default = router;
//# sourceMappingURL=students.js.map