"use strict";
/**
 * Master Data Endpoints
 *
 * API routes for managing master data
 * (Batches, Classes, Roles, etc.)
 *
 * Endpoints:
 * - GET    /api/batches - List all batches
 * - POST   /api/batches - Create batch
 * - GET    /api/batches/:batchId - Get batch details
 * - PUT    /api/batches/:batchId - Update batch
 * - DELETE /api/batches/:batchId - Delete batch
 * - GET    /api/classes - List all classes
 * - POST   /api/classes - Create class
 * - GET    /api/classes/:classId - Get class details
 * - PUT    /api/classes/:classId - Update class
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const error_handler_1 = require("../middleware/error-handler");
const router = (0, express_1.Router)();
/**
 * GET /api/batches
 *
 * List all batches
 *
 * Query params:
 * - status: Filter by status (active, archived)
 * - limit: number (default: 50)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "batch-123",
 *       "name": "2026 Class A",
 *       "academic_year": "2025-2026",
 *       "teacher_id": "teacher-123",
 *       "status": "active",
 *       "created_at": "2026-06-01T..."
 *     },
 *     ...
 *   ],
 *   "pagination": { ... }
 * }
 * ```
 */
router.get('/batches', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { status = 'active', limit = 50, offset = 0 } = req.query;
    // In production:
    // let query = supabase
    //   .from('batches')
    //   .select('*', { count: 'exact' });
    //
    // if (status) query = query.eq('status', status);
    //
    // const { data, count, error } = await query
    //   .order('name')
    //   .range(Number(offset), Number(offset) + Number(limit) - 1);
    const mockBatches = [];
    res.status(200).json({
        success: true,
        data: mockBatches,
        pagination: {
            total: mockBatches.length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/batches
 *
 * Create a new batch (admin only)
 *
 * Request body:
 * ```json
 * {
 *   "name": "2026 Class A",
 *   "academic_year": "2025-2026",
 *   "teacher_id": "teacher-123"
 * }
 * ```
 *
 * Response: 201 Created
 */
router.post('/batches', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { name, academic_year, teacher_id } = req.body;
    if (!name || !academic_year) {
        return (0, error_handler_1.validationError)(res, 'name and academic_year are required');
    }
    // In production:
    // const { data, error } = await supabase
    //   .from('batches')
    //   .insert([{ name, academic_year, teacher_id, status: 'active' }])
    //   .select()
    //   .single();
    const newBatch = {
        id: 'batch-' + Date.now(),
        name,
        academic_year,
        teacher_id,
        status: 'active',
        created_at: new Date().toISOString(),
    };
    res.status(201).json({
        success: true,
        data: newBatch,
    });
}));
/**
 * GET /api/batches/:batchId
 *
 * Get detailed information about a batch
 *
 * Response: 200 OK
 */
router.get('/batches/:batchId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    // In production:
    // const { data, error } = await supabase
    //   .from('batches')
    //   .select('*')
    //   .eq('id', batchId)
    //   .single();
    const mockBatch = {
        id: batchId,
        name: 'Batch Name',
        academic_year: '2025-2026',
        teacher_id: 'teacher-123',
        status: 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: mockBatch,
    });
}));
/**
 * PUT /api/batches/:batchId
 *
 * Update a batch (admin only)
 *
 * Request body: Any fields to update
 *
 * Response: 200 OK
 */
router.put('/batches/:batchId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    const { name, academic_year, teacher_id, status } = req.body;
    // In production:
    // const { data, error } = await supabase
    //   .from('batches')
    //   .update({ name, academic_year, teacher_id, status, updated_at: new Date() })
    //   .eq('id', batchId)
    //   .select()
    //   .single();
    const updatedBatch = {
        id: batchId,
        name,
        academic_year,
        teacher_id,
        status,
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: updatedBatch,
    });
}));
/**
 * DELETE /api/batches/:batchId
 *
 * Delete a batch (soft delete - mark as archived)
 *
 * Response: 204 No Content
 */
router.delete('/batches/:batchId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    // In production: soft delete
    // const { error } = await supabase
    //   .from('batches')
    //   .update({ status: 'archived', updated_at: new Date() })
    //   .eq('id', batchId);
    res.status(204).send();
}));
/**
 * GET /api/classes
 *
 * List all classes
 *
 * Query params:
 * - status: Filter by status
 * - limit: number (default: 100)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 */
router.get('/classes', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { status = 'active', limit = 100, offset = 0 } = req.query;
    // In production:
    // let query = supabase
    //   .from('classes')
    //   .select('*', { count: 'exact' });
    //
    // if (status) query = query.eq('status', status);
    //
    // const { data, count, error } = await query
    //   .order('name')
    //   .range(Number(offset), Number(offset) + Number(limit) - 1);
    const mockClasses = [];
    res.status(200).json({
        success: true,
        data: mockClasses,
        pagination: {
            total: mockClasses.length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/classes
 *
 * Create a new class (admin only)
 *
 * Request body:
 * ```json
 * {
 *   "name": "Class A",
 *   "grade_level": 1,
 *   "status": "active"
 * }
 * ```
 *
 * Response: 201 Created
 */
router.post('/classes', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { name, grade_level } = req.body;
    if (!name) {
        return (0, error_handler_1.validationError)(res, 'name is required');
    }
    // In production:
    // const { data, error } = await supabase
    //   .from('classes')
    //   .insert([{ name, grade_level, status: 'active' }])
    //   .select()
    //   .single();
    const newClass = {
        id: 'class-' + Date.now(),
        name,
        grade_level,
        status: 'active',
        created_at: new Date().toISOString(),
    };
    res.status(201).json({
        success: true,
        data: newClass,
    });
}));
/**
 * GET /api/classes/:classId
 *
 * Get detailed information about a class
 *
 * Response: 200 OK
 */
router.get('/classes/:classId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { classId } = req.params;
    // In production:
    // const { data, error } = await supabase
    //   .from('classes')
    //   .select('*')
    //   .eq('id', classId)
    //   .single();
    const mockClass = {
        id: classId,
        name: 'Class Name',
        grade_level: 1,
        status: 'active',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: mockClass,
    });
}));
/**
 * PUT /api/classes/:classId
 *
 * Update a class (admin only)
 *
 * Request body: Any fields to update
 *
 * Response: 200 OK
 */
router.put('/classes/:classId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { classId } = req.params;
    const { name, grade_level, status } = req.body;
    // In production:
    // const { data, error } = await supabase
    //   .from('classes')
    //   .update({ name, grade_level, status, updated_at: new Date() })
    //   .eq('id', classId)
    //   .select()
    //   .single();
    const updatedClass = {
        id: classId,
        name,
        grade_level,
        status,
        updated_at: new Date().toISOString(),
    };
    res.status(200).json({
        success: true,
        data: updatedClass,
    });
}));
exports.default = router;
//# sourceMappingURL=master-data.js.map