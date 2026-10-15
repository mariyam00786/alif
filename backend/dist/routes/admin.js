"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const auth_1 = require("../middleware/auth");
const authorization_1 = require("../middleware/authorization");
const validation_1 = require("../utils/validation");
const admin_dashboard_service_1 = require("../services/admin/admin-dashboard-service");
const msghex_service_1 = require("../services/msghex/msghex-service");
const supabase_1 = require("../config/supabase");
const http_error_1 = require("../errors/http-error");
const router = (0, express_1.Router)();
const adminDashboardService = new admin_dashboard_service_1.AdminDashboardService();
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** Maps the admin panel record status to the batches table CHECK enum. */
function toBatchStatus(value) {
    return value === 'active' ? 'active' : 'inactive';
}
function toCapacity(value) {
    if (value === null || value === undefined || value === '')
        return null;
    const n = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(n) ? n : null;
}
/** Clears and (optionally) re-creates the single teacher assignment for a batch. */
async function syncBatchTeacher(batchId, teacherId) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    await supabase.from('teacher_batches').delete().eq('batch_id', batchId);
    if (teacherId && UUID_RE.test(teacherId)) {
        await supabase.from('teacher_batches').insert({ batch_id: batchId, teacher_id: teacherId });
    }
}
/** Ensures a class with the given name is linked to the batch (non-destructive). */
async function ensureBatchClass(batchId, className) {
    const name = (className ?? '').trim();
    if (!name)
        return;
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: existing } = await supabase
        .from('classes')
        .select('id')
        .eq('batch_id', batchId)
        .eq('name', name)
        .maybeSingle();
    if (!existing) {
        await supabase.from('classes').insert({ name, batch_id: batchId });
    }
}
router.get('/overview', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await adminDashboardService.getSnapshot() });
}));
router.get('/whatsapp-status', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await (0, msghex_service_1.getSenderStatus)() });
}));
router.patch('/batches/:id/teacher', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    await adminDashboardService.assignTeacherToBatch(req.params.id, (0, validation_1.getRequiredString)(body.teacherId, 'teacherId'), req.user);
    res.json({ success: true });
}));
router.patch('/rating-rules/:id/primary', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    await adminDashboardService.setPrimaryRule(req.params.id, (0, validation_1.getEnumValue)(body.ruleKind, 'ruleKind', ['rating', 'scoring'], true), req.user);
    res.json({ success: true });
}));
// ===== Batch / Class CRUD =====
router.post('/batches', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('batches')
        .insert({
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        capacity: toCapacity(body.capacity),
        timing: (0, validation_1.getOptionalString)(body.schedule, 'schedule') ?? null,
        status: toBatchStatus(body.status),
    })
        .select('*')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to create batch: ${error.message}`);
    const batchId = data.id;
    await syncBatchTeacher(batchId, (0, validation_1.getOptionalString)(body.teacher_id, 'teacher_id'));
    await ensureBatchClass(batchId, (0, validation_1.getOptionalString)(body.class_name, 'class_name'));
    res.status(201).json({ success: true, data });
}));
router.put('/batches/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('batches')
        .update({
        name: (0, validation_1.getRequiredString)(body.name, 'name'),
        name_ml: (0, validation_1.getOptionalString)(body.name_ml, 'name_ml') ?? null,
        capacity: toCapacity(body.capacity),
        timing: (0, validation_1.getOptionalString)(body.schedule, 'schedule') ?? null,
        status: toBatchStatus(body.status),
    })
        .eq('id', req.params.id)
        .select('*')
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Unable to update batch: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'Batch not found.');
    await syncBatchTeacher(req.params.id, (0, validation_1.getOptionalString)(body.teacher_id, 'teacher_id'));
    await ensureBatchClass(req.params.id, (0, validation_1.getOptionalString)(body.class_name, 'class_name'));
    res.json({ success: true, data });
}));
router.delete('/batches/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase.from('batches').delete().eq('id', req.params.id);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete batch: ${error.message}`);
    res.json({ success: true });
}));
// ===== Rating band CRUD (on activity_ratings / activity_scoring_rules) =====
// Rating bands are defined per-activity in the database. New bands must be
// created from an activity (Activities screen); here we support editing and
// deleting existing bands, located by id across both rating tables.
router.post('/rating-rules', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, _res) => {
    throw new http_error_1.HttpError(400, 'Rating bands are defined per activity. Add or edit them from the activity they belong to.');
}));
router.put('/rating-rules/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const id = req.params.id;
    const marks = toCapacity(body.max_score) ?? toCapacity(body.min_score) ?? 0;
    const { data: rating } = await supabase.from('activity_ratings').select('id').eq('id', id).maybeSingle();
    if (rating) {
        const { data, error } = await supabase
            .from('activity_ratings')
            .update({
            rating_name: (0, validation_1.getRequiredString)(body.label, 'label'),
            rating_name_ml: (0, validation_1.getOptionalString)(body.label_ml, 'label_ml') ?? null,
            marks,
            color: (0, validation_1.getOptionalString)(body.color, 'color') ?? null,
        })
            .eq('id', id)
            .select('*')
            .maybeSingle();
        if (error)
            throw new http_error_1.HttpError(500, `Unable to update rating: ${error.message}`);
        res.json({ success: true, data });
        return;
    }
    const { data: scoring } = await supabase.from('activity_scoring_rules').select('id').eq('id', id).maybeSingle();
    if (scoring) {
        const { data, error } = await supabase
            .from('activity_scoring_rules')
            .update({ marks })
            .eq('id', id)
            .select('*')
            .maybeSingle();
        if (error)
            throw new http_error_1.HttpError(500, `Unable to update scoring rule: ${error.message}`);
        res.json({ success: true, data });
        return;
    }
    throw new http_error_1.HttpError(404, 'Rating rule not found.');
}));
router.delete('/rating-rules/:id', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const id = req.params.id;
    const { data: rating } = await supabase.from('activity_ratings').select('id').eq('id', id).maybeSingle();
    const table = rating ? 'activity_ratings' : 'activity_scoring_rules';
    const { error } = await supabase.from(table).delete().eq('id', id);
    if (error)
        throw new http_error_1.HttpError(500, `Unable to delete rating rule: ${error.message}`);
    res.json({ success: true });
}));
exports.default = router;
//# sourceMappingURL=admin.js.map