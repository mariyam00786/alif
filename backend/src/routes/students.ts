/**
 * Student Management Endpoints
 *
 * API routes for CRUD operations on students, backed by Supabase.
 * Primarily for the admin panel, restricted to the admin role.
 *
 * A "student" spans two tables:
 *   - profiles (id = auth.users.id, full_name, full_name_ml, phone, role)
 *   - students (profile_id, parent_phone, father/mother, dob, gender,
 *               batch_id, class_id, address, status)
 *
 * Endpoints:
 * - GET    /api/students - List all students (with filters)
 * - POST   /api/students - Create new student
 * - GET    /api/students/:studentId - Get student details
 * - PUT    /api/students/:studentId - Update student
 * - DELETE /api/students/:studentId - Delete student
 * - GET    /api/students/batch/:batchId/students - Get students in batch
 * - POST   /api/students/:studentId/assign-batch - Assign student to batch
 */

import { randomUUID } from 'crypto';
import { Router, Request, Response } from 'express';
import { requireAuth, requireRole } from '../middleware/auth';
import { asyncHandler, validationError } from '../middleware/error-handler';
import { getSupabaseClient } from '../config/supabase';

const router = Router();

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Normalises the admin panel status (active/review/archived) to the DB enum. */
function normaliseStatus(value: unknown): 'active' | 'inactive' {
  return value === 'active' ? 'active' : 'inactive';
}

/** Normalises a date value to a plain `YYYY-MM-DD` string (DATE column). */
function normaliseDate(value: unknown): string | null {
  if (!value || typeof value !== 'string') return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString().slice(0, 10);
}

/** Resolves a batch/class reference that may be either a UUID or a name. */
async function resolveReferenceId(
  table: 'batches' | 'classes',
  value: unknown
): Promise<string | null> {
  if (!value || typeof value !== 'string' || value.trim().length === 0) {
    return null;
  }
  const trimmed = value.trim();
  if (UUID_RE.test(trimmed)) return trimmed;

  const supabase = getSupabaseClient();
  const { data } = await supabase
    .from(table)
    .select('id')
    .eq('name', trimmed)
    .maybeSingle();
  return (data as { id?: string } | null)?.id ?? null;
}

/** Shapes a joined student + profile row for API responses. */
function shapeStudent(
  student: Record<string, any>,
  profile?: Record<string, any> | null
): Record<string, unknown> {
  return {
    id: student.id,
    name: profile?.full_name ?? 'Unnamed student',
    nameMl: profile?.full_name_ml ?? '',
    mobile: student.parent_phone ?? profile?.phone ?? '',
    fatherName: student.father_name ?? '',
    motherName: student.mother_name ?? '',
    dateOfBirth: student.date_of_birth ?? null,
    gender: student.gender ?? 'male',
    batchId: student.batch_id ?? null,
    classId: student.class_id ?? null,
    address: student.address ?? '',
    status: student.status ?? 'active',
    createdAt: student.created_at ?? null,
  };
}

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
router.get(
  '/',
  requireAuth,
  requireRole('admin', 'teacher'),
  asyncHandler(async (req: Request, res: Response) => {
    const { batchId, classId, status, limit = 100, offset = 0 } = req.query;
    const supabase = getSupabaseClient();

    let query = supabase.from('students').select('*', { count: 'exact' });

    if (batchId) query = query.eq('batch_id', batchId);
    if (classId) query = query.eq('class_id', classId);
    if (status) query = query.eq('status', status);

    const {
      data: students,
      count,
      error,
    } = await query
      .order('created_at', { ascending: false })
      .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (error) {
      return res.status(500).json({ success: false, error: error.message });
    }

    const profileIds = (students ?? []).map((s: any) => s.profile_id);
    const { data: profiles } = profileIds.length
      ? await supabase
          .from('profiles')
          .select('id, full_name, full_name_ml, phone')
          .in('id', profileIds)
      : { data: [] as any[] };
    const profileMap = new Map((profiles ?? []).map((p: any) => [p.id, p]));

    res.status(200).json({
      success: true,
      data: (students ?? []).map((s: any) =>
        shapeStudent(s, profileMap.get(s.profile_id))
      ),
      pagination: {
        total: count ?? (students ?? []).length,
        limit: Number(limit),
        offset: Number(offset),
      },
    });
  })
);

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
router.post(
  '/',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = req.body ?? {};
    const fullName: string = (body.full_name ?? body.name ?? '').trim();
    const rawPhone: string = (
      body.parent_phone ??
      body.phone ??
      body.mobile ??
      ''
    )
      .toString()
      .trim();

    if (!fullName || !rawPhone) {
      return validationError(res, 'full_name and parent_phone are required');
    }

    const supabase = getSupabaseClient();
    // The login number belongs to the guardian. Store it in the canonical
    // '+CC...' form so it matches the OTP sign-in lookup.
    const phone = rawPhone.startsWith('+') ? rawPhone : `+${rawPhone}`;
    const phoneWithoutPlus = phone.slice(1);

    const [batchId, classId] = await Promise.all([
      resolveReferenceId('batches', body.batch_id ?? body.batch),
      resolveReferenceId('classes', body.class_id ?? body.class),
    ]);

    const guardianName: string =
      (body.guardian_name ?? body.father_name ?? body.mother_name ?? '')
        .toString()
        .trim() || `${fullName}'s guardian`;

    // ----- 1. Resolve (or create) the guardian login profile for this phone.
    // One phone number is a single sign-in account. Each child is a separate
    // student linked to that guardian via parent_students, so one login can
    // hold several students.
    const { data: existingProfiles, error: lookupErr } = await supabase
      .from('profiles')
      .select('id, role')
      .in('phone', [phone, phoneWithoutPlus])
      .limit(1);

    if (lookupErr) {
      return res.status(500).json({ success: false, error: lookupErr.message });
    }

    let parentProfileId: string;
    // Set only when we create a brand-new guardian, so it can be rolled back.
    let createdParentAuthId: string | null = null;

    if (existingProfiles && existingProfiles.length > 0) {
      const existing = existingProfiles[0] as { id: string; role: string };
      parentProfileId = existing.id;

      // A pre-multi-child profile (role 'student') becomes the shared guardian
      // login. Promote it and keep its own student record visible by linking
      // it. Teacher/admin/parent profiles keep their role.
      if (existing.role === 'student') {
        await supabase
          .from('profiles')
          .update({ role: 'parent' })
          .eq('id', existing.id);
        const { data: ownStudents } = await supabase
          .from('students')
          .select('id')
          .eq('profile_id', existing.id)
          .limit(1);
        const ownStudentId = (ownStudents?.[0] as { id?: string } | undefined)
          ?.id;
        if (ownStudentId) {
          await supabase.from('parent_students').upsert(
            {
              parent_profile_id: existing.id,
              student_id: ownStudentId,
              relationship: 'parent',
            },
            { onConflict: 'parent_profile_id,student_id' }
          );
        }
      }
    } else {
      // Brand-new phone → provision a guardian login profile.
      const guardianEmail = `parent.${Date.now()}.${Math.floor(
        Math.random() * 1e6
      )}@parents.alif.local`;
      const { data: parentAuth, error: parentAuthErr } =
        await supabase.auth.admin.createUser({
          email: guardianEmail,
          password: randomUUID(),
          email_confirm: true,
          user_metadata: { full_name: guardianName, role: 'parent' },
        });
      if (parentAuthErr || !parentAuth?.user) {
        return res.status(500).json({
          success: false,
          error: parentAuthErr?.message ?? 'Failed to create guardian identity',
        });
      }
      createdParentAuthId = parentAuth.user.id;
      const { error: parentProfileErr } = await supabase
        .from('profiles')
        .insert({
          id: parentAuth.user.id,
          phone,
          full_name: guardianName,
          role: 'parent',
        });
      if (parentProfileErr) {
        await supabase.auth.admin
          .deleteUser(parentAuth.user.id)
          .catch(() => undefined);
        return res
          .status(500)
          .json({ success: false, error: parentProfileErr.message });
      }
      parentProfileId = parentAuth.user.id;
    }

    // ----- 2. Create the child's own profile (non-login). The login phone is
    // on the guardian, so the child profile gets a unique non-numeric
    // placeholder phone that can never be used to sign in.
    const childEmail = `student.${Date.now()}.${Math.floor(
      Math.random() * 1e6
    )}@students.alif.local`;
    const { data: childAuth, error: childAuthErr } =
      await supabase.auth.admin.createUser({
        email: childEmail,
        password: randomUUID(),
        email_confirm: true,
        user_metadata: { full_name: fullName, role: 'student' },
      });
    if (childAuthErr || !childAuth?.user) {
      if (createdParentAuthId) {
        await supabase.auth.admin
          .deleteUser(createdParentAuthId)
          .catch(() => undefined);
      }
      return res.status(500).json({
        success: false,
        error: childAuthErr?.message ?? 'Failed to create student identity',
      });
    }
    const childProfileId = childAuth.user.id;

    const { error: childProfileErr } = await supabase.from('profiles').insert({
      id: childProfileId,
      phone: `student:${childProfileId}`,
      full_name: fullName,
      full_name_ml: (body.full_name_ml ?? '').toString().trim() || null,
      role: 'student',
    });
    if (childProfileErr) {
      // Deleting the auth user cascades to the orphaned profile.
      await supabase.auth.admin
        .deleteUser(childProfileId)
        .catch(() => undefined);
      if (createdParentAuthId) {
        await supabase.auth.admin
          .deleteUser(createdParentAuthId)
          .catch(() => undefined);
      }
      return res
        .status(500)
        .json({ success: false, error: childProfileErr.message });
    }

    // ----- 3. Create the student record and link it to the guardian.
    const { data: student, error: studentErr } = await supabase
      .from('students')
      .insert({
        profile_id: childProfileId,
        parent_phone: phone,
        father_name: (body.father_name ?? '').toString().trim() || null,
        mother_name: (body.mother_name ?? '').toString().trim() || null,
        date_of_birth: normaliseDate(body.date_of_birth),
        gender: body.gender === 'female' ? 'female' : 'male',
        batch_id: batchId,
        class_id: classId,
        address: (body.address ?? '').toString().trim() || null,
        status: normaliseStatus(body.status),
      })
      .select('*')
      .single();

    if (studentErr || !student) {
      await supabase.auth.admin
        .deleteUser(childProfileId)
        .catch(() => undefined);
      if (createdParentAuthId) {
        await supabase.auth.admin
          .deleteUser(createdParentAuthId)
          .catch(() => undefined);
      }
      return res.status(500).json({
        success: false,
        error: studentErr?.message ?? 'Failed to create student',
      });
    }

    const { error: linkErr } = await supabase.from('parent_students').insert({
      parent_profile_id: parentProfileId,
      student_id: student.id,
      relationship: 'parent',
    });
    if (linkErr) {
      // Deleting the child auth user cascades to its profile + student row, so
      // the add can be retried cleanly.
      await supabase.auth.admin
        .deleteUser(childProfileId)
        .catch(() => undefined);
      if (createdParentAuthId) {
        await supabase.auth.admin
          .deleteUser(createdParentAuthId)
          .catch(() => undefined);
      }
      return res
        .status(500)
        .json({ success: false, error: linkErr.message });
    }

    res.status(201).json({
      success: true,
      data: shapeStudent(student, {
        full_name: fullName,
        full_name_ml: body.full_name_ml ?? '',
        phone,
      }),
    });
  })
);

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
/**
 * Resolve the `students` row owned by the authenticated user (by profile id).
 * Returns null when the signed-in user is not a student.
 */
async function resolveOwnStudent(
  profileId: string | undefined
): Promise<Record<string, any> | null> {
  if (!profileId) return null;
  const { data } = await getSupabaseClient()
    .from('students')
    .select('*')
    .eq('profile_id', profileId)
    .maybeSingle();
  return (data as Record<string, any>) ?? null;
}

/** Local `YYYY-MM-DD` date string, optionally offset by N days. */
function ymd(offsetDays = 0): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${d.getFullYear()}-${m}-${day}`;
}

/**
 * GET /api/students/me
 *
 * Return the authenticated student's own profile. Must be registered before
 * `/:studentId` so the literal "me" is not parsed as a student id.
 */
router.get(
  '/me',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, full_name, full_name_ml, phone')
      .eq('id', student.profile_id)
      .maybeSingle();
    res.status(200).json({ success: true, data: shapeStudent(student, profile) });
  })
);

/**
 * PUT /api/students/me
 *
 * Update the authenticated student's own profile (name + phone).
 */
router.put(
  '/me',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }
    const body = req.body ?? {};
    const updates: Record<string, any> = {};
    if (typeof body.full_name === 'string' && body.full_name.trim()) {
      updates.full_name = body.full_name.trim();
    }
    if (typeof body.phone === 'string') {
      updates.phone = body.phone.trim();
    }
    if (Object.keys(updates).length > 0) {
      await supabase
        .from('profiles')
        .update(updates)
        .eq('id', student.profile_id);
    }
    const { data: profile } = await supabase
      .from('profiles')
      .select('id, full_name, full_name_ml, phone')
      .eq('id', student.profile_id)
      .maybeSingle();
    res.status(200).json({ success: true, data: shapeStudent(student, profile) });
  })
);

/**
 * GET /api/students/me/notifications
 *
 * Announcements relevant to the authenticated student: school-wide ("all"),
 * the student's batch, or the student personally.
 */
router.get(
  '/me/notifications',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }

    const studentId = student.id as string;
    const batchId = (student.batch_id as string | null) ?? null;

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('id, title, body, target_type, target_id, sent_at, created_at')
      .order('created_at', { ascending: false })
      .limit(40);
    if (error) {
      return res.status(500).json({
        success: false,
        error: `Failed to load notifications: ${error.message}`,
      });
    }

    const relevant = (notifications ?? []).filter((n: any) => {
      if (n.target_type === 'all' || !n.target_type) return true;
      if (n.target_type === 'batch') return !!batchId && n.target_id === batchId;
      if (n.target_type === 'student') return n.target_id === studentId;
      if (n.target_type === 'class') return true;
      return false;
    });

    res.status(200).json({
      success: true,
      data: relevant.map((n: any) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        target_type: n.target_type,
        created_at: n.created_at,
        sent_at: n.sent_at,
      })),
    });
  })
);

/**
 * GET /api/students/me/home-summary
 *
 * Dashboard summary for the authenticated student: today's completion,
 * current streak, points earned this week, and rank within their batch.
 */
router.get(
  '/me/home-summary',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }

    const today = ymd();
    const weekStart = ymd(-6);

    const { data: activeActivities } = await supabase
      .from('activities')
      .select('id')
      .eq('status', 'active');
    const activityIds = (activeActivities ?? []).map((a: any) => a.id);
    const todayTotal = activityIds.length;

    // Max possible marks today = sum of the highest rating per active activity.
    const { data: ratings } = activityIds.length
      ? await supabase
          .from('activity_ratings')
          .select('activity_id, marks')
          .in('activity_id', activityIds)
      : { data: [] as any[] };
    const maxByActivity = new Map<string, number>();
    for (const r of ratings ?? []) {
      const cur = maxByActivity.get(r.activity_id) ?? 0;
      if ((r.marks ?? 0) > cur) maxByActivity.set(r.activity_id, r.marks ?? 0);
    }
    const todayMaxMarks = [...maxByActivity.values()].reduce(
      (s, m) => s + m,
      0
    );

    const { data: todayLogs } = await supabase
      .from('activity_logs')
      .select('marks_earned')
      .eq('student_id', student.id)
      .eq('log_date', today);
    const todayDone = (todayLogs ?? []).length;
    const todayMarks = (todayLogs ?? []).reduce(
      (sum: number, r: any) => sum + (r.marks_earned ?? 0),
      0
    );

    // Streak: consecutive days (ending today or yesterday) with >=1 log.
    const { data: recent } = await supabase
      .from('activity_logs')
      .select('log_date')
      .eq('student_id', student.id)
      .order('log_date', { ascending: false })
      .limit(400);
    const days = new Set((recent ?? []).map((r: any) => r.log_date));
    let streak = 0;
    let cursor: number | null = days.has(today)
      ? 0
      : days.has(ymd(-1))
        ? -1
        : null;
    if (cursor !== null) {
      while (days.has(ymd(cursor))) {
        streak += 1;
        cursor -= 1;
      }
    }

    // Per-day completion for the current week (Monday..Sunday) so the home
    // dashboard can render real streak chips instead of placeholder data.
    const now = new Date();
    const mondayOffset = -((now.getDay() + 6) % 7); // 0 = Monday
    const weekDays = Array.from({ length: 7 }, (_, i) => {
      const offset = mondayOffset + i;
      const date = ymd(offset);
      return {
        date,
        done: days.has(date),
        is_today: offset === 0,
        is_future: offset > 0,
      };
    });

    const { data: weekLogs } = await supabase
      .from('activity_logs')
      .select('marks_earned')
      .eq('student_id', student.id)
      .gte('log_date', weekStart);
    const weekPoints = (weekLogs ?? []).reduce(
      (sum: number, r: any) => sum + (r.marks_earned ?? 0),
      0
    );

    let batchRank = 0;
    let batchSize = 0;
    let batchName: string | null = null;
    if (student.batch_id) {
      const { data: batch } = await supabase
        .from('batches')
        .select('name')
        .eq('id', student.batch_id)
        .maybeSingle();
      batchName = (batch as any)?.name ?? null;

      const { data: peers } = await supabase
        .from('students')
        .select('id')
        .eq('batch_id', student.batch_id);
      const peerIds = (peers ?? []).map((p: any) => p.id);
      batchSize = peerIds.length;
      const { data: peerLogs } = peerIds.length
        ? await supabase
            .from('activity_logs')
            .select('student_id, marks_earned')
            .gte('log_date', weekStart)
            .in('student_id', peerIds)
        : { data: [] as any[] };
      const totals = new Map<string, number>();
      for (const id of peerIds) totals.set(id, 0);
      for (const r of peerLogs ?? []) {
        totals.set(
          r.student_id,
          (totals.get(r.student_id) ?? 0) + (r.marks_earned ?? 0)
        );
      }
      const ranked = [...totals.entries()].sort((a, b) => b[1] - a[1]);
      batchRank = ranked.findIndex(([id]) => id === student.id) + 1;
    }

    // Real badge progress + a small preview (earned first) so the home card
    // reflects actual achievements instead of placeholder medallions.
    const { data: allBadges } = await supabase
      .from('badges')
      .select('id, name, name_ml, icon, created_at')
      .eq('status', 'active')
      .order('created_at', { ascending: true });
    const { data: earnedBadges } = await supabase
      .from('student_badges')
      .select('badge_id')
      .eq('student_id', student.id);
    const earnedSet = new Set(
      (earnedBadges ?? []).map((e: any) => e.badge_id)
    );
    const badgesTotal = (allBadges ?? []).length;
    const badgesEarned = (allBadges ?? []).filter((b: any) =>
      earnedSet.has(b.id)
    ).length;
    const badgePreview = [...(allBadges ?? [])]
      .sort((a: any, b: any) => {
        const ae = earnedSet.has(a.id) ? 0 : 1;
        const be = earnedSet.has(b.id) ? 0 : 1;
        return ae - be;
      })
      .slice(0, 5)
      .map((b: any) => ({
        name: b.name,
        name_ml: b.name_ml,
        icon: b.icon,
        earned: earnedSet.has(b.id),
      }));

    res.status(200).json({
      success: true,
      data: {
        today_done: todayDone,
        today_total: todayTotal,
        today_marks: todayMarks,
        today_max_marks: todayMaxMarks,
        streak_days: streak,
        week_points: weekPoints,
        week_days: weekDays,
        batch_rank: batchRank,
        batch_size: batchSize,
        batch_name: batchName,
        badges_earned: badgesEarned,
        badges_total: badgesTotal,
        badges: badgePreview,
      },
    });
  })
);

/**
 * GET /api/students/me/progress
 *
 * Real daily / weekly / monthly progress for the authenticated student,
 * computed from activity_logs and the active activity scoring rules.
 */
router.get(
  '/me/progress',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }

    // Active activities + max possible marks per day.
    const { data: activeActivities } = await supabase
      .from('activities')
      .select('id')
      .eq('status', 'active');
    const activityIds = (activeActivities ?? []).map((a: any) => a.id);
    const totalActivities = activityIds.length;
    const { data: ratings } = activityIds.length
      ? await supabase
          .from('activity_ratings')
          .select('activity_id, marks')
          .in('activity_id', activityIds)
      : { data: [] as any[] };
    const maxByActivity = new Map<string, number>();
    for (const r of ratings ?? []) {
      const cur = maxByActivity.get(r.activity_id) ?? 0;
      if ((r.marks ?? 0) > cur) maxByActivity.set(r.activity_id, r.marks ?? 0);
    }
    const dayMaxMarks = [...maxByActivity.values()].reduce((s, m) => s + m, 0);

    // Aggregate the last 60 days of logs by date.
    const since = ymd(-60);
    const { data: logs } = await supabase
      .from('activity_logs')
      .select('log_date, marks_earned')
      .eq('student_id', student.id)
      .gte('log_date', since);
    const byDate = new Map<string, { marks: number; done: number }>();
    for (const l of logs ?? []) {
      const e = byDate.get(l.log_date) ?? { marks: 0, done: 0 };
      e.marks += l.marks_earned ?? 0;
      e.done += 1;
      byDate.set(l.log_date, e);
    }

    const dayData = (offset: number) => {
      const date = ymd(offset);
      const e = byDate.get(date) ?? { marks: 0, done: 0 };
      const pct =
        dayMaxMarks > 0 ? Math.round((e.marks / dayMaxMarks) * 100) : 0;
      return {
        date,
        marks: e.marks,
        done: e.done,
        total: totalActivities,
        pct,
      };
    };

    // Daily — last 7 days (today first) with a trend vs the previous day.
    const daily = [];
    for (let i = 0; i < 7; i++) {
      const cur = dayData(-i);
      const prev = dayData(-i - 1);
      let trend = 'flat';
      if (cur.marks > prev.marks) trend = 'up';
      else if (cur.marks < prev.marks) trend = 'down';
      daily.push({ ...cur, trend });
    }

    // Weekly — last 7 days.
    const week = Array.from({ length: 7 }, (_, i) => dayData(-i));
    const weekTotalMarks = week.reduce((s, d) => s + d.marks, 0);
    const weekActiveDays = week.filter((d) => d.done > 0).length;
    const weekDone = week.reduce((s, d) => s + d.done, 0);
    const weekMaxMarks = dayMaxMarks * 7;
    const weekly = {
      totalMarks: weekTotalMarks,
      avg: weekActiveDays > 0 ? Math.round(weekTotalMarks / weekActiveDays) : 0,
      pct: weekMaxMarks > 0 ? Math.round((weekTotalMarks / weekMaxMarks) * 100) : 0,
      best: week.reduce((m, d) => Math.max(m, d.marks), 0),
      done: weekDone,
      total: totalActivities * 7,
    };

    // Monthly — last 30 days, with improvement vs the previous 30 days.
    const month = Array.from({ length: 30 }, (_, i) => dayData(-i));
    const monthTotalMarks = month.reduce((s, d) => s + d.marks, 0);
    const monthActiveDays = month.filter((d) => d.done > 0).length;
    const monthMaxMarks = dayMaxMarks * 30;
    const prevMonth = Array.from({ length: 30 }, (_, i) => dayData(-i - 30));
    const prevMonthMarks = prevMonth.reduce((s, d) => s + d.marks, 0);
    const monthly = {
      totalMarks: monthTotalMarks,
      avg: monthActiveDays > 0 ? Math.round(monthTotalMarks / monthActiveDays) : 0,
      pct:
        monthMaxMarks > 0 ? Math.round((monthTotalMarks / monthMaxMarks) * 100) : 0,
      best: month.reduce((m, d) => Math.max(m, d.marks), 0),
      improve:
        prevMonthMarks > 0
          ? Math.round(((monthTotalMarks - prevMonthMarks) / prevMonthMarks) * 100)
          : 0,
      days: monthActiveDays,
    };

    res.status(200).json({
      success: true,
      data: { daily, weekly, monthly },
    });
  })
);

/**
 * GET /api/students/me/leaderboard
 *
 * Batch leaderboard for the authenticated student across four periods
 * (daily / weekly / monthly / all_time).
 */
router.get(
  '/me/leaderboard',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }
    const empty = { daily: [], weekly: [], monthly: [], all_time: [] };
    if (!student.batch_id) {
      return res.status(200).json({ success: true, data: empty });
    }

    const { data: peers } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('batch_id', student.batch_id);
    const peerList = peers ?? [];
    const peerIds = peerList.map((p: any) => p.id);
    const profileIds = peerList.map((p: any) => p.profile_id);

    const { data: profiles } = profileIds.length
      ? await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', profileIds)
      : { data: [] as any[] };
    const nameByProfile = new Map(
      (profiles ?? []).map((p: any) => [p.id, p.full_name])
    );
    const profileByStudent = new Map(
      peerList.map((p: any) => [p.id, p.profile_id])
    );

    const { data: allLogs } = peerIds.length
      ? await supabase
          .from('activity_logs')
          .select('student_id, marks_earned, log_date')
          .in('student_id', peerIds)
      : { data: [] as any[] };
    const logs = allLogs ?? [];

    const build = (fromDate: string | null) => {
      const agg = new Map<string, { marks: number; acts: number }>();
      for (const id of peerIds) agg.set(id, { marks: 0, acts: 0 });
      for (const r of logs) {
        if (fromDate && r.log_date < fromDate) continue;
        const a = agg.get(r.student_id);
        if (!a) continue;
        a.marks += r.marks_earned ?? 0;
        a.acts += 1;
      }
      const rows = [...agg.entries()]
        .map(([id, v]) => ({
          id,
          name:
            (nameByProfile.get(profileByStudent.get(id)) as string) ??
            'Student',
          marks: v.marks,
          activities: v.acts,
        }))
        .sort((x, y) => y.marks - x.marks);
      return rows.map((r, i) => ({
        rank: i + 1,
        name: r.name,
        marks: r.marks,
        activities: r.activities,
        avatar: (r.name || '?').trim().charAt(0).toUpperCase(),
        me: r.id === student.id,
        trend: r.marks > 0 ? 'up' : 'flat',
      }));
    };

    res.status(200).json({
      success: true,
      data: {
        daily: build(ymd(0)),
        weekly: build(ymd(-6)),
        monthly: build(ymd(-29)),
        all_time: build(null),
      },
    });
  })
);

/**
 * GET /api/students/me/badges
 *
 * All active badges with an `earned` flag for the authenticated student.
 */
router.get(
  '/me/badges',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const student = await resolveOwnStudent(req.user!.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, error: 'STUDENT_NOT_FOUND' });
    }
    const { data: badges } = await supabase
      .from('badges')
      .select('id, name, name_ml, description, icon, bonus_points, status')
      .eq('status', 'active')
      .order('created_at', { ascending: true });
    const { data: earned } = await supabase
      .from('student_badges')
      .select('badge_id, earned_at')
      .eq('student_id', student.id);
    const earnedMap = new Map(
      (earned ?? []).map((e: any) => [e.badge_id, e.earned_at])
    );
    const list = (badges ?? []).map((b: any) => ({
      id: b.id,
      name: b.name,
      name_ml: b.name_ml,
      description: b.description,
      icon: b.icon,
      bonus_points: b.bonus_points,
      earned: earnedMap.has(b.id),
      earned_at: earnedMap.get(b.id) ?? null,
    }));
    res.status(200).json({ success: true, data: { badges: list } });
  })
);

router.get(
  '/:studentId',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const { studentId } = req.params;
    const supabase = getSupabaseClient();

    const { data: student, error } = await supabase
      .from('students')
      .select('*')
      .eq('id', studentId)
      .maybeSingle();

    if (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
    if (!student) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }

    // A student may only view their own record; admins/teachers may view all.
    if (req.user?.role === 'student' && req.user?.id !== student.profile_id) {
      return res.status(403).json({ success: false, error: 'FORBIDDEN' });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('id, full_name, full_name_ml, phone')
      .eq('id', student.profile_id)
      .maybeSingle();

    res.status(200).json({
      success: true,
      data: shapeStudent(student, profile),
    });
  })
);

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
router.put(
  '/:studentId',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const { studentId } = req.params;
    const body = req.body ?? {};
    const supabase = getSupabaseClient();

    const { data: existing, error: lookupErr } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('id', studentId)
      .maybeSingle();

    if (lookupErr) {
      return res.status(500).json({ success: false, error: lookupErr.message });
    }
    if (!existing) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }

    const [batchId, classId] = await Promise.all([
      resolveReferenceId('batches', body.batch_id ?? body.batch),
      resolveReferenceId('classes', body.class_id ?? body.class),
    ]);

    const contactPhone = body.parent_phone ?? body.phone ?? body.mobile;
    const fullName: string | undefined =
      body.full_name ?? body.name ?? undefined;

    const profileUpdate: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    if (fullName !== undefined) profileUpdate.full_name = fullName.trim();
    if (body.full_name_ml !== undefined) {
      profileUpdate.full_name_ml = body.full_name_ml.toString().trim() || null;
    }
    // The login phone lives on the guardian profile, not the child profile, so
    // editing a student's contact number only updates the student row's
    // parent_phone (below) — never the child profile's placeholder phone.

    const { error: profileErr } = await supabase
      .from('profiles')
      .update(profileUpdate)
      .eq('id', existing.profile_id);

    if (profileErr) {
      const conflict = profileErr.code === '23505';
      return res.status(conflict ? 409 : 500).json({
        success: false,
        error: conflict
          ? 'A profile with this phone number already exists.'
          : profileErr.message,
      });
    }

    const studentUpdate: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    if (contactPhone) studentUpdate.parent_phone = contactPhone.toString().trim();
    if (body.father_name !== undefined) {
      studentUpdate.father_name = body.father_name.toString().trim() || null;
    }
    if (body.mother_name !== undefined) {
      studentUpdate.mother_name = body.mother_name.toString().trim() || null;
    }
    if (body.date_of_birth !== undefined) {
      studentUpdate.date_of_birth = normaliseDate(body.date_of_birth);
    }
    if (body.gender !== undefined) {
      studentUpdate.gender = body.gender === 'female' ? 'female' : 'male';
    }
    if (body.address !== undefined) {
      studentUpdate.address = body.address.toString().trim() || null;
    }
    if (body.status !== undefined) {
      studentUpdate.status = normaliseStatus(body.status);
    }
    if (batchId !== null) studentUpdate.batch_id = batchId;
    if (classId !== null) studentUpdate.class_id = classId;

    const { data: student, error: studentErr } = await supabase
      .from('students')
      .update(studentUpdate)
      .eq('id', studentId)
      .select('*')
      .single();

    if (studentErr || !student) {
      return res.status(500).json({
        success: false,
        error: studentErr?.message ?? 'Failed to update student',
      });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('id, full_name, full_name_ml, phone')
      .eq('id', existing.profile_id)
      .maybeSingle();

    res.status(200).json({
      success: true,
      data: shapeStudent(student, profile),
    });
  })
);

/**
 * DELETE /api/students/:studentId
 * 
 * Delete a student (soft delete - mark as inactive)
 * 
 * Response: 204 No Content
 * Error: 404 Not Found
 */
router.delete(
  '/:studentId',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const { studentId } = req.params;
    const supabase = getSupabaseClient();

    const { data: existing, error: lookupErr } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('id', studentId)
      .maybeSingle();

    if (lookupErr) {
      return res.status(500).json({ success: false, error: lookupErr.message });
    }
    if (!existing) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }

    // Removing the auth user cascades to its profile and student rows
    // (profiles.id -> auth.users ON DELETE CASCADE,
    //  students.profile_id -> profiles ON DELETE CASCADE).
    const { error: deleteErr } = await supabase.auth.admin.deleteUser(
      existing.profile_id
    );
    if (deleteErr) {
      // Fall back to deleting the student row directly.
      const { error: rowErr } = await supabase
        .from('students')
        .delete()
        .eq('id', studentId);
      if (rowErr) {
        return res.status(500).json({ success: false, error: rowErr.message });
      }
    }

    res.status(204).send();
  })
);

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
router.get(
  '/batch/:batchId/students',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
    const { batchId } = req.params;
    const { classId, status = 'active', limit = 100, offset = 0 } = req.query;
    const supabase = getSupabaseClient();

    let query = supabase
      .from('students')
      .select('*', { count: 'exact' })
      .eq('batch_id', batchId)
      .eq('status', status);
    if (classId) query = query.eq('class_id', classId);

    const {
      data: students,
      count,
      error,
    } = await query.range(Number(offset), Number(offset) + Number(limit) - 1);

    if (error) {
      return res.status(500).json({ success: false, error: error.message });
    }

    const profileIds = (students ?? []).map((s: any) => s.profile_id);
    const { data: profiles } = profileIds.length
      ? await supabase
          .from('profiles')
          .select('id, full_name, full_name_ml, phone')
          .in('id', profileIds)
      : { data: [] as any[] };
    const profileMap = new Map((profiles ?? []).map((p: any) => [p.id, p]));

    res.status(200).json({
      success: true,
      data: (students ?? []).map((s: any) =>
        shapeStudent(s, profileMap.get(s.profile_id))
      ),
      pagination: {
        total: count ?? (students ?? []).length,
        limit: Number(limit),
        offset: Number(offset),
      },
    });
  })
);

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
router.post(
  '/:studentId/assign-batch',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const { studentId } = req.params;
    const batchId = await resolveReferenceId(
      'batches',
      req.body?.batch_id ?? req.body?.batch
    );

    if (!batchId) {
      return validationError(res, 'A valid batch_id is required');
    }

    const supabase = getSupabaseClient();
    const { data: student, error } = await supabase
      .from('students')
      .update({ batch_id: batchId, updated_at: new Date().toISOString() })
      .eq('id', studentId)
      .select('*')
      .single();

    if (error || !student) {
      return res.status(500).json({
        success: false,
        error: error?.message ?? 'Failed to assign batch',
      });
    }

    res.status(200).json({ success: true, data: shapeStudent(student) });
  })
);

export default router;