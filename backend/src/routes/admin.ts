import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { requireAuth } from '../middleware/auth';
import { requireRoles } from '../middleware/authorization';
import { ensureObject, getEnumValue, getOptionalString, getRequiredString } from '../utils/validation';
import { AdminDashboardService } from '../services/admin/admin-dashboard-service';
import { getSenderStatus } from '../services/msghex/msghex-service';
import { getSupabaseClient } from '../config/supabase';
import { HttpError } from '../errors/http-error';

const router = Router();
const adminDashboardService = new AdminDashboardService();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Maps the admin panel record status to the batches table CHECK enum. */
function toBatchStatus(value: unknown): 'active' | 'inactive' {
  return value === 'active' ? 'active' : 'inactive';
}

function toCapacity(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null;
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : null;
}

/** Clears and (optionally) re-creates the single teacher assignment for a batch. */
async function syncBatchTeacher(batchId: string, teacherId: string | undefined): Promise<void> {
  const supabase = getSupabaseClient();
  await supabase.from('teacher_batches').delete().eq('batch_id', batchId);
  if (teacherId && UUID_RE.test(teacherId)) {
    await supabase.from('teacher_batches').insert({ batch_id: batchId, teacher_id: teacherId });
  }
}

/** Ensures a class with the given name is linked to the batch (non-destructive). */
async function ensureBatchClass(batchId: string, className: string | undefined): Promise<void> {
  const name = (className ?? '').trim();
  if (!name) return;
  const supabase = getSupabaseClient();
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

router.get('/overview', requireAuth, requireRoles('admin'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await adminDashboardService.getSnapshot() });
}));

router.get('/whatsapp-status', requireAuth, requireRoles('admin'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await getSenderStatus() });
}));

router.patch('/batches/:id/teacher', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  await adminDashboardService.assignTeacherToBatch(req.params.id, getRequiredString(body.teacherId, 'teacherId'), req.user);
  res.json({ success: true });
}));

router.patch('/rating-rules/:id/primary', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  await adminDashboardService.setPrimaryRule(
    req.params.id,
    getEnumValue(body.ruleKind, 'ruleKind', ['rating', 'scoring'] as const, true)!,
    req.user,
  );
  res.json({ success: true });
}));

// ===== Batch / Class CRUD =====

router.post('/batches', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('batches')
    .insert({
      name: getRequiredString(body.name, 'name'),
      name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
      capacity: toCapacity(body.capacity),
      timing: getOptionalString(body.schedule, 'schedule') ?? null,
      status: toBatchStatus(body.status),
    })
    .select('*')
    .single();
  if (error) throw new HttpError(500, `Unable to create batch: ${error.message}`);

  const batchId = (data as { id: string }).id;
  await syncBatchTeacher(batchId, getOptionalString(body.teacher_id, 'teacher_id'));
  await ensureBatchClass(batchId, getOptionalString(body.class_name, 'class_name'));
  res.status(201).json({ success: true, data });
}));

router.put('/batches/:id', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('batches')
    .update({
      name: getRequiredString(body.name, 'name'),
      name_ml: getOptionalString(body.name_ml, 'name_ml') ?? null,
      capacity: toCapacity(body.capacity),
      timing: getOptionalString(body.schedule, 'schedule') ?? null,
      status: toBatchStatus(body.status),
    })
    .eq('id', req.params.id)
    .select('*')
    .maybeSingle();
  if (error) throw new HttpError(500, `Unable to update batch: ${error.message}`);
  if (!data) throw new HttpError(404, 'Batch not found.');

  await syncBatchTeacher(req.params.id, getOptionalString(body.teacher_id, 'teacher_id'));
  await ensureBatchClass(req.params.id, getOptionalString(body.class_name, 'class_name'));
  res.json({ success: true, data });
}));

router.delete('/batches/:id', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const supabase = getSupabaseClient();
  const { error } = await supabase.from('batches').delete().eq('id', req.params.id);
  if (error) throw new HttpError(500, `Unable to delete batch: ${error.message}`);
  res.json({ success: true });
}));

// ===== Rating band CRUD (on activity_ratings / activity_scoring_rules) =====
// Rating bands are defined per-activity in the database. New bands must be
// created from an activity (Activities screen); here we support editing and
// deleting existing bands, located by id across both rating tables.

router.post('/rating-rules', requireAuth, requireRoles('admin'), asyncHandler(async (_req, _res) => {
  throw new HttpError(
    400,
    'Rating bands are defined per activity. Add or edit them from the activity they belong to.',
  );
}));

router.put('/rating-rules/:id', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const supabase = getSupabaseClient();
  const id = req.params.id;
  const marks = toCapacity(body.max_score) ?? toCapacity(body.min_score) ?? 0;

  const { data: rating } = await supabase.from('activity_ratings').select('id').eq('id', id).maybeSingle();
  if (rating) {
    const { data, error } = await supabase
      .from('activity_ratings')
      .update({
        rating_name: getRequiredString(body.label, 'label'),
        rating_name_ml: getOptionalString(body.label_ml, 'label_ml') ?? null,
        marks,
        color: getOptionalString(body.color, 'color') ?? null,
      })
      .eq('id', id)
      .select('*')
      .maybeSingle();
    if (error) throw new HttpError(500, `Unable to update rating: ${error.message}`);
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
    if (error) throw new HttpError(500, `Unable to update scoring rule: ${error.message}`);
    res.json({ success: true, data });
    return;
  }

  throw new HttpError(404, 'Rating rule not found.');
}));

router.delete('/rating-rules/:id', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const supabase = getSupabaseClient();
  const id = req.params.id;
  const { data: rating } = await supabase.from('activity_ratings').select('id').eq('id', id).maybeSingle();
  const table = rating ? 'activity_ratings' : 'activity_scoring_rules';
  const { error } = await supabase.from(table).delete().eq('id', id);
  if (error) throw new HttpError(500, `Unable to delete rating rule: ${error.message}`);
  res.json({ success: true });
}));

export default router;