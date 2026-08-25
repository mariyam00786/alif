import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/error-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { getSupabaseClient } from '../config/supabase';
import { TeacherService } from '../services/teachers/teacher-service';

const router = Router();
const teacherService = new TeacherService();

const DEFAULT_TEACHER_PASSWORD = 'Demo@12345';

/** Normalise an incoming status value to the DB-allowed set. */
function normaliseStatus(value: unknown): 'active' | 'inactive' {
  return value === 'inactive' ? 'inactive' : 'active';
}

/** Basic email-format check for the optional teacher login email. */
function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

/** Coerce an incoming value into a clean list of non-empty strings. */
function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .map((item) => String(item ?? '').trim())
    .filter((item) => item !== '');
}

/** Resolve a list of batch names to their ids (skips names that don't match). */
async function resolveBatchIds(
  supabase: ReturnType<typeof getSupabaseClient>,
  batchNames: string[],
): Promise<string[]> {
  if (batchNames.length === 0) {
    return [];
  }
  const { data } = await supabase
    .from('batches')
    .select('id, name')
    .in('name', batchNames);
  return ((data ?? []) as Array<{ id: string }>).map((row) => row.id);
}

/** Replace the teacher_batches rows for a teacher with the given batch ids. */
async function syncTeacherBatches(
  supabase: ReturnType<typeof getSupabaseClient>,
  teacherId: string,
  batchIds: string[],
): Promise<void> {
  await supabase.from('teacher_batches').delete().eq('teacher_id', teacherId);
  if (batchIds.length > 0) {
    await supabase
      .from('teacher_batches')
      .insert(batchIds.map((batchId) => ({ teacher_id: teacherId, batch_id: batchId })));
  }
}

router.get('/', authenticateRequest, requireRoles('admin'), asyncHandler(async (_req: Request, res: Response) => {
  res.json({ success: true, data: await teacherService.list('created_at') });
}));

router.get('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req: Request, res: Response) => {
  res.json({ success: true, data: await teacherService.getById(req.params.id) });
}));

/**
 * POST /api/teachers
 * Create a teacher: auth user + profile (role=teacher) + teacher row + batch
 * assignments. The teacher signs in with the provided email (or a synthetic
 * one) and the shared demo password.
 */
router.post('/', authenticateRequest, requireRoles('admin'), asyncHandler(async (req: Request, res: Response) => {
  const body = (req.body ?? {}) as Record<string, unknown>;

  const fullName = String(body.full_name ?? body.name ?? '').trim();
  const phone = String(body.phone ?? body.mobile ?? '').trim();
  const providedEmail = String(body.email ?? '').trim().toLowerCase();
  const subjects = toStringArray(body.subjects);
  const batchNames = toStringArray(body.batches);

  if (!fullName) {
    return res.status(400).json({ success: false, error: 'full_name is required' });
  }
  if (!phone) {
    return res.status(400).json({ success: false, error: 'phone is required' });
  }
  if (providedEmail !== '' && !isValidEmail(providedEmail)) {
    return res.status(400).json({ success: false, error: 'email is not a valid email address' });
  }

  const supabase = getSupabaseClient();

  const unique = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 7)}`;
  const loginEmail = providedEmail !== '' ? providedEmail : `teacher.${unique}@alif.local`;

  // 1. Create the auth user (profiles.id is a FK to auth.users).
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email: loginEmail,
    password: DEFAULT_TEACHER_PASSWORD,
    email_confirm: true,
    user_metadata: { full_name: fullName, role: 'teacher' },
  });

  if (authError || !authData?.user) {
    return res.status(502).json({
      success: false,
      error: authError?.message ?? 'Failed to create teacher account',
    });
  }

  const userId = authData.user.id;

  // profiles.phone is UNIQUE NOT NULL — fall back to a unique value if taken.
  let profilePhone = phone;
  const { data: phoneTaken } = await supabase
    .from('profiles')
    .select('id')
    .eq('phone', profilePhone)
    .maybeSingle();
  if (phoneTaken) {
    profilePhone = `${phone}-${unique}`;
  }

  // 2. Create the profile row.
  const { error: profileError } = await supabase.from('profiles').insert({
    id: userId,
    phone: profilePhone,
    full_name: fullName,
    full_name_ml: body.full_name_ml ?? null,
    role: 'teacher',
  });

  if (profileError) {
    await supabase.auth.admin.deleteUser(userId);
    return res.status(502).json({ success: false, error: profileError.message });
  }

  // 3. Create the teacher row.
  const { data: teacher, error: teacherError } = await supabase
    .from('teachers')
    .insert({
      profile_id: userId,
      email: providedEmail !== '' ? providedEmail : null,
      qualification: body.qualification ?? null,
      status: normaliseStatus(body.status),
      subjects,
    })
    .select()
    .single();

  if (teacherError) {
    await supabase.auth.admin.deleteUser(userId);
    return res.status(502).json({ success: false, error: teacherError.message });
  }

  // 4. Assign batches.
  const batchIds = await resolveBatchIds(supabase, batchNames);
  await syncTeacherBatches(supabase, (teacher as { id: string }).id, batchIds);

  res.status(201).json({
    success: true,
    data: teacher,
    login_email: loginEmail,
    login_password: DEFAULT_TEACHER_PASSWORD,
  });
}));

/** Shared update handler for PUT and PATCH. */
const updateHandler = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  const body = (req.body ?? {}) as Record<string, unknown>;

  const supabase = getSupabaseClient();

  const { data: existing, error: lookupError } = await supabase
    .from('teachers')
    .select('id, profile_id, email')
    .eq('id', id)
    .maybeSingle();

  if (lookupError) {
    return res.status(502).json({ success: false, error: lookupError.message });
  }
  if (!existing) {
    return res.status(404).json({ success: false, error: 'Teacher not found' });
  }

  const existingTeacher = existing as { id: string; profile_id: string; email?: string | null };

  // Keep the Supabase auth login email in sync when it changes.
  if (body.email !== undefined) {
    const newEmail = String(body.email).trim().toLowerCase();
    if (newEmail !== '' && !isValidEmail(newEmail)) {
      return res.status(400).json({ success: false, error: 'email is not a valid email address' });
    }
    if (newEmail !== '' && newEmail !== (existingTeacher.email ?? '').toLowerCase()) {
      const { error: authUpdateError } = await supabase.auth.admin.updateUserById(
        existingTeacher.profile_id,
        { email: newEmail, email_confirm: true },
      );
      if (authUpdateError) {
        return res.status(502).json({ success: false, error: authUpdateError.message });
      }
    }
  }

  // Update the linked profile (name + phone live on profiles).
  const fullName = body.full_name ?? body.name;
  const phone = body.phone ?? body.mobile;
  if (fullName !== undefined || body.full_name_ml !== undefined || phone !== undefined) {
    const profilePatch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (fullName !== undefined) profilePatch.full_name = String(fullName).trim();
    if (body.full_name_ml !== undefined) profilePatch.full_name_ml = body.full_name_ml;
    if (phone !== undefined) profilePatch.phone = String(phone).trim();

    const { error: profileError } = await supabase
      .from('profiles')
      .update(profilePatch)
      .eq('id', existingTeacher.profile_id);
    if (profileError) {
      return res.status(502).json({ success: false, error: profileError.message });
    }
  }

  // Update the teacher row.
  const teacherPatch: Record<string, unknown> = { updated_at: new Date().toISOString() };
  if (body.email !== undefined) teacherPatch.email = String(body.email).trim() || null;
  if (body.qualification !== undefined) teacherPatch.qualification = body.qualification;
  if (body.status !== undefined) teacherPatch.status = normaliseStatus(body.status);
  if (body.subjects !== undefined) teacherPatch.subjects = toStringArray(body.subjects);

  const { data: teacher, error: teacherError } = await supabase
    .from('teachers')
    .update(teacherPatch)
    .eq('id', id)
    .select()
    .single();

  if (teacherError) {
    return res.status(502).json({ success: false, error: teacherError.message });
  }

  // Re-sync batch assignments when provided.
  if (body.batches !== undefined) {
    const batchIds = await resolveBatchIds(supabase, toStringArray(body.batches));
    await syncTeacherBatches(supabase, id, batchIds);
  }

  res.json({ success: true, data: teacher });
});

router.put('/:id', authenticateRequest, requireRoles('admin'), updateHandler);
router.patch('/:id', authenticateRequest, requireRoles('admin'), updateHandler);

/**
 * DELETE /api/teachers/:id
 * Deleting the auth user cascades to the profile, teacher row and batch links.
 */
router.delete('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  const supabase = getSupabaseClient();

  const { data: existing } = await supabase
    .from('teachers')
    .select('id, profile_id')
    .eq('id', id)
    .maybeSingle();

  if (!existing) {
    return res.status(404).json({ success: false, error: 'Teacher not found' });
  }

  const { error: authError } = await supabase.auth.admin.deleteUser(
    (existing as { profile_id: string }).profile_id,
  );

  if (authError) {
    // Fallback: remove the teacher row directly.
    const { error: rowError } = await supabase.from('teachers').delete().eq('id', id);
    if (rowError) {
      return res.status(502).json({ success: false, error: rowError.message });
    }
  }

  res.status(204).send();
}));

export default router;