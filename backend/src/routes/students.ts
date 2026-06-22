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

import { Router, Request, Response } from 'express';
import { requireAuth, requireRole } from '../middleware/auth';
import { asyncHandler, validationError } from '../middleware/error-handler';
import { getSupabaseClient } from '../config/supabase';

const router = Router();

const DEFAULT_STUDENT_PASSWORD = 'Demo@12345';

/** Normalise an incoming gender value to the DB-allowed set. */
function normaliseGender(value: unknown): 'male' | 'female' | null {
  return value === 'male' || value === 'female' ? value : null;
}

/** Basic email-format check for the optional student login email. */
function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

/** Normalise an incoming status value to the DB-allowed set. */
function normaliseStatus(value: unknown): 'active' | 'inactive' {
  return value === 'inactive' ? 'inactive' : 'active';
}

/** Convert an ISO date/datetime string to a plain YYYY-MM-DD date (or null). */
function toDateOnly(value: unknown): string | null {
  if (typeof value !== 'string' || value.trim() === '') {
    return null;
  }
  return value.slice(0, 10);
}

/** Resolve a batch name to its id, returning null when not found / not provided. */
async function resolveBatchId(
  supabase: ReturnType<typeof getSupabaseClient>,
  batchName: unknown,
): Promise<string | null> {
  if (typeof batchName !== 'string' || batchName.trim() === '') {
    return null;
  }
  const { data } = await supabase
    .from('batches')
    .select('id')
    .eq('name', batchName.trim())
    .maybeSingle();
  return (data as { id?: string } | null)?.id ?? null;
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
    const {
      batchId,
      classId,
      status = 'active',
      searchTerm,
      limit = 50,
      offset = 0,
    } = req.query;
    
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
    
    const mockStudents: any[] = [];
    
    res.status(200).json({
      success: true,
      data: mockStudents,
      pagination: {
        total: mockStudents.length,
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
    const body = (req.body ?? {}) as Record<string, unknown>;

    const fullName = String(body.full_name ?? body.name ?? '').trim();
    const parentPhone = String(body.parent_phone ?? body.phone ?? '').trim();
    const providedEmail = String(body.email ?? '').trim().toLowerCase();

    // Validate required fields
    if (!fullName) {
      return validationError(res, 'full_name is required');
    }
    if (!parentPhone) {
      return validationError(res, 'parent_phone is required');
    }
    if (providedEmail !== '' && !isValidEmail(providedEmail)) {
      return validationError(res, 'email is not a valid email address');
    }

    const supabase = getSupabaseClient();

    // A unique suffix used for the synthetic auth email and, when needed, to
    // keep the profile phone unique (profiles.phone is UNIQUE NOT NULL).
    const unique = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 7)}`;
    // Use the admin-provided email as the student's login email when supplied,
    // otherwise fall back to a synthetic address. This is the email the student
    // signs in with on the student portal.
    const loginEmail = providedEmail !== '' ? providedEmail : `student.${unique}@alif.local`;

    // 1. Create the auth user (profiles.id is a FK to auth.users).
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: loginEmail,
      password: DEFAULT_STUDENT_PASSWORD,
      email_confirm: true,
      user_metadata: { full_name: fullName, role: 'student' },
    });

    if (authError || !authData?.user) {
      return res.status(502).json({
        success: false,
        error: authError?.message ?? 'Failed to create student account',
      });
    }

    const userId = authData.user.id;

    // The student profile needs its own unique phone. Use the parent phone when
    // available, falling back to a unique synthetic value if it is already taken
    // (e.g. siblings sharing a guardian phone).
    let profilePhone = parentPhone;
    const { data: phoneTaken } = await supabase
      .from('profiles')
      .select('id')
      .eq('phone', profilePhone)
      .maybeSingle();
    if (phoneTaken) {
      profilePhone = `${parentPhone}-${unique}`;
    }

    // 2. Create the profile row.
    const { error: profileError } = await supabase.from('profiles').insert({
      id: userId,
      phone: profilePhone,
      full_name: fullName,
      full_name_ml: body.full_name_ml ?? null,
      role: 'student',
    });

    if (profileError) {
      await supabase.auth.admin.deleteUser(userId);
      return res.status(502).json({ success: false, error: profileError.message });
    }

    // 3. Create the student row.
    const batchId = await resolveBatchId(supabase, body.batch);
    const { data: student, error: studentError } = await supabase
      .from('students')
      .insert({
        profile_id: userId,
        parent_phone: parentPhone,
        email: providedEmail !== '' ? providedEmail : null,
        father_name: body.father_name ?? null,
        mother_name: body.mother_name ?? null,
        date_of_birth: toDateOnly(body.date_of_birth),
        gender: normaliseGender(body.gender),
        address: body.address ?? null,
        batch_id: batchId,
        status: normaliseStatus(body.status),
      })
      .select()
      .single();

    if (studentError) {
      // Cascade-cleanup: deleting the auth user removes the profile too.
      await supabase.auth.admin.deleteUser(userId);
      return res.status(502).json({ success: false, error: studentError.message });
    }

    res.status(201).json({
      success: true,
      data: student,
      login_email: loginEmail,
      login_password: DEFAULT_STUDENT_PASSWORD,
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
router.get(
  '/:studentId',
  requireAuth,
  asyncHandler(async (req: Request, res: Response) => {
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
  })
);

/**
 * GET /api/students/me/home-summary
 *
 * Real dashboard summary for the authenticated student, computed from
 * activity_logs: today's completion, points, streak and batch rank.
 */
router.get(
  '/me/home-summary',
  requireAuth,
  requireRole('student'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const userId = req.user!.profileId ?? req.user!.id!;

    const { data: studentRow } = await supabase
      .from('students')
      .select('id, batch_id')
      .eq('profile_id', userId)
      .maybeSingle();
    if (!studentRow) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }
    const student = studentRow as { id: string; batch_id: string | null };

    // Batch name for cross-portal-consistent display.
    let batchName: string | null = null;
    if (student.batch_id) {
      const { data: batchRow } = await supabase
        .from('batches')
        .select('name')
        .eq('id', student.batch_id)
        .maybeSingle();
      batchName = (batchRow as { name: string | null } | null)?.name ?? null;
    }

    const today = new Date().toISOString().split('T')[0];
    const weekAgo = new Date(Date.now() - 6 * 86400000)
      .toISOString()
      .split('T')[0];

    // Total active activities (the denominator for "today done").
    const { count: totalActivities } = await supabase
      .from('activities')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'active');

    // Today's logs.
    const { data: todayLogsRaw } = await supabase
      .from('activity_logs')
      .select('activity_id, marks_earned')
      .eq('student_id', student.id)
      .eq('log_date', today);
    const todayLogs = (todayLogsRaw ?? []) as Array<{
      activity_id: string;
      marks_earned: number | null;
    }>;
    const todayDone = new Set(todayLogs.map((l) => l.activity_id)).size;
    const todayPoints = todayLogs.reduce((a, l) => a + (l.marks_earned ?? 0), 0);

    // Points earned in the last 7 days.
    const { data: weekLogsRaw } = await supabase
      .from('activity_logs')
      .select('marks_earned')
      .eq('student_id', student.id)
      .gte('log_date', weekAgo);
    const weekPoints = ((weekLogsRaw ?? []) as Array<{ marks_earned: number | null }>)
      .reduce((a, l) => a + (l.marks_earned ?? 0), 0);

    // Streak: count consecutive days (ending today or yesterday) with a log.
    const { data: dateRows } = await supabase
      .from('activity_logs')
      .select('log_date')
      .eq('student_id', student.id)
      .order('log_date', { ascending: false });
    const dateSet = new Set(
      ((dateRows ?? []) as Array<{ log_date: string }>).map((d) => d.log_date),
    );
    let streak = 0;
    const cursor = new Date(today);
    if (!dateSet.has(today)) cursor.setDate(cursor.getDate() - 1);
    while (dateSet.has(cursor.toISOString().split('T')[0])) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }

    // Batch rank by all-time total marks.
    let batchRank = 0;
    if (student.batch_id) {
      const { data: matesRaw } = await supabase
        .from('students')
        .select('id')
        .eq('batch_id', student.batch_id);
      const mateIds = ((matesRaw ?? []) as Array<{ id: string }>).map((m) => m.id);
      if (mateIds.length > 0) {
        const { data: logsRaw } = await supabase
          .from('activity_logs')
          .select('student_id, marks_earned')
          .in('student_id', mateIds);
        const totals = new Map<string, number>();
        for (const id of mateIds) totals.set(id, 0);
        for (const l of (logsRaw ?? []) as Array<{
          student_id: string;
          marks_earned: number | null;
        }>) {
          totals.set(l.student_id, (totals.get(l.student_id) ?? 0) + (l.marks_earned ?? 0));
        }
        const ranked = [...totals.entries()].sort((a, b) => b[1] - a[1]);
        batchRank = ranked.findIndex(([id]) => id === student.id) + 1;
      }
    }

    res.json({
      success: true,
      data: {
        today_done: todayDone,
        today_total: totalActivities ?? 0,
        today_points: todayPoints,
        week_points: weekPoints,
        streak_days: streak,
        batch_rank: batchRank,
        batch_name: batchName,
      },
    });
  }),
);

/**
 * GET /api/students/me/leaderboard
 *
 * Real batch leaderboard for the authenticated student across four periods
 * (daily / weekly / monthly / all-time), computed from activity_logs.
 */
router.get(
  '/me/leaderboard',
  requireAuth,
  requireRole('student'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const userId = req.user!.profileId ?? req.user!.id!;

    const { data: meRow } = await supabase
      .from('students')
      .select('id, batch_id')
      .eq('profile_id', userId)
      .maybeSingle();
    if (!meRow) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }
    const me = meRow as { id: string; batch_id: string | null };
    const empty = { daily: [], weekly: [], monthly: [], all_time: [] };
    if (!me.batch_id) {
      return res.json({ success: true, data: empty });
    }

    const { data: matesRaw } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('batch_id', me.batch_id);
    const mates = (matesRaw ?? []) as Array<{ id: string; profile_id: string }>;
    if (mates.length === 0) {
      return res.json({ success: true, data: empty });
    }

    const { data: profsRaw } = await supabase
      .from('profiles')
      .select('id, full_name')
      .in(
        'id',
        mates.map((m) => m.profile_id),
      );
    const nameByProfile = new Map<string, string>();
    for (const p of (profsRaw ?? []) as Array<{ id: string; full_name: string | null }>) {
      nameByProfile.set(p.id, p.full_name ?? 'Student');
    }
    const nameByStudent = new Map<string, string>();
    for (const m of mates) {
      nameByStudent.set(m.id, nameByProfile.get(m.profile_id) ?? 'Student');
    }

    const ids = mates.map((m) => m.id);
    const { data: logsRaw } = await supabase
      .from('activity_logs')
      .select('student_id, marks_earned, log_date')
      .in('student_id', ids);
    const logs = (logsRaw ?? []) as Array<{
      student_id: string;
      marks_earned: number | null;
      log_date: string;
    }>;

    const today = new Date().toISOString().split('T')[0];
    const weekAgo = new Date(Date.now() - 6 * 86400000).toISOString().split('T')[0];
    const monthAgo = new Date(Date.now() - 29 * 86400000).toISOString().split('T')[0];

    const build = (keep: (logDate: string) => boolean) => {
      const marks = new Map<string, number>();
      const acts = new Map<string, number>();
      for (const id of ids) {
        marks.set(id, 0);
        acts.set(id, 0);
      }
      for (const l of logs) {
        if (!keep(l.log_date)) continue;
        marks.set(l.student_id, (marks.get(l.student_id) ?? 0) + (l.marks_earned ?? 0));
        acts.set(l.student_id, (acts.get(l.student_id) ?? 0) + 1);
      }
      return ids
        .map((id) => ({
          id,
          name: nameByStudent.get(id) ?? 'Student',
          marks: marks.get(id) ?? 0,
          activities: acts.get(id) ?? 0,
        }))
        .sort((a, b) => b.marks - a.marks)
        .map((r, i) => ({
          rank: i + 1,
          name: r.name,
          marks: r.marks,
          activities: r.activities,
          avatar: (r.name[0] ?? '?').toUpperCase(),
          me: r.id === me.id,
        }));
    };

    res.json({
      success: true,
      data: {
        daily: build((d) => d === today),
        weekly: build((d) => d >= weekAgo),
        monthly: build((d) => d >= monthAgo),
        all_time: build(() => true),
      },
    });
  }),
);

/**
 * GET /api/students/me/badges
 *
 * Real badge collection for the authenticated student: all active badges with
 * an `earned` flag and `earned_at` timestamp.
 */
router.get(
  '/me/badges',
  requireAuth,
  requireRole('student'),
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const userId = req.user!.profileId ?? req.user!.id!;

    const { data: meRow } = await supabase
      .from('students')
      .select('id')
      .eq('profile_id', userId)
      .maybeSingle();
    if (!meRow) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }
    const studentId = (meRow as { id: string }).id;

    const [{ data: allBadges }, { data: earnedRaw }] = await Promise.all([
      supabase
        .from('badges')
        .select('id, name, name_ml, description, icon')
        .eq('status', 'active')
        .order('created_at'),
      supabase
        .from('student_badges')
        .select('badge_id, earned_at')
        .eq('student_id', studentId),
    ]);

    const earnedMap = new Map(
      ((earnedRaw ?? []) as Array<{ badge_id: string; earned_at: string | null }>).map(
        (e) => [e.badge_id, e.earned_at],
      ),
    );
    const badges = ((allBadges ?? []) as Array<{
      id: string;
      name: string | null;
      name_ml: string | null;
      description: string | null;
      icon: string | null;
    }>).map((b) => ({
      id: b.id,
      name: b.name,
      name_ml: b.name_ml,
      description: b.description,
      icon: b.icon,
      earned: earnedMap.has(b.id),
      earned_at: earnedMap.get(b.id) ?? null,
    }));

    res.json({
      success: true,
      data: { earned_count: earnedMap.size, total: badges.length, badges },
    });
  }),
);

/**
 * PUT /api/students/me
 *
 * Allow an authenticated student to update their own profile (name + phone).
 * Resolves the student row from the auth token, so no id is needed.
 */
router.put(
  '/me',
  requireAuth,
  requireRole('student'),
  asyncHandler(async (req: Request, res: Response) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const supabase = getSupabaseClient();
    const userId = req.user!.profileId ?? req.user!.id!;

    // The auth id may be the student id or the linked profile id.
    let student: { id: string; profile_id: string } | null = null;
    const byId = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('id', userId)
      .maybeSingle();
    student = (byId.data as { id: string; profile_id: string } | null) ?? null;
    if (!student) {
      const byProfile = await supabase
        .from('students')
        .select('id, profile_id')
        .eq('profile_id', userId)
        .maybeSingle();
      student = (byProfile.data as { id: string; profile_id: string } | null) ?? null;
    }
    if (!student) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }

    // Name lives on the linked profile.
    const fullName = body.full_name ?? body.name;
    if (fullName !== undefined && String(fullName).trim() !== '') {
      const { error: profileError } = await supabase
        .from('profiles')
        .update({
          full_name: String(fullName).trim(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', student.profile_id);
      if (profileError) {
        return res.status(502).json({ success: false, error: profileError.message });
      }
    }

    // Phone is stored on the student row (parent/contact phone).
    const phone = body.parent_phone ?? body.phone;
    const studentPatch: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    if (phone !== undefined) studentPatch.parent_phone = String(phone).trim();

    const { data: updated, error: studentError } = await supabase
      .from('students')
      .update(studentPatch)
      .eq('id', student.id)
      .select()
      .single();
    if (studentError) {
      return res.status(502).json({ success: false, error: studentError.message });
    }

    res.status(200).json({ success: true, data: updated });
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
    const body = (req.body ?? {}) as Record<string, unknown>;

    const supabase = getSupabaseClient();

    // Find the student so we can also update the linked profile.
    const { data: existing, error: lookupError } = await supabase
      .from('students')
      .select('id, profile_id, email')
      .eq('id', studentId)
      .maybeSingle();

    if (lookupError) {
      return res.status(502).json({ success: false, error: lookupError.message });
    }
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Student not found' });
    }

    const existingStudent = existing as { profile_id: string; email?: string | null };

    // When the admin changes the login email, keep the Supabase auth user in
    // sync so the student can still sign in with the displayed email.
    if (body.email !== undefined) {
      const newEmail = String(body.email).trim().toLowerCase();
      if (newEmail !== '' && !isValidEmail(newEmail)) {
        return validationError(res, 'email is not a valid email address');
      }
      if (newEmail !== '' && newEmail !== (existingStudent.email ?? '').toLowerCase()) {
        const { error: authUpdateError } = await supabase.auth.admin.updateUserById(
          existingStudent.profile_id,
          { email: newEmail, email_confirm: true },
        );
        if (authUpdateError) {
          return res.status(502).json({ success: false, error: authUpdateError.message });
        }
      }
    }

    // Update the linked profile (name fields live on profiles).
    const fullName = body.full_name ?? body.name;
    if (fullName !== undefined || body.full_name_ml !== undefined) {
      const profilePatch: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
      };
      if (fullName !== undefined) profilePatch.full_name = String(fullName).trim();
      if (body.full_name_ml !== undefined) profilePatch.full_name_ml = body.full_name_ml;

      const { error: profileError } = await supabase
        .from('profiles')
        .update(profilePatch)
        .eq('id', existingStudent.profile_id);
      if (profileError) {
        return res.status(502).json({ success: false, error: profileError.message });
      }
    }

    // Update the student row.
    const studentPatch: Record<string, unknown> = {
      updated_at: new Date().toISOString(),
    };
    const parentPhone = body.parent_phone ?? body.phone;
    if (parentPhone !== undefined) studentPatch.parent_phone = String(parentPhone).trim();
    if (body.email !== undefined) studentPatch.email = String(body.email).trim() || null;
    if (body.father_name !== undefined) studentPatch.father_name = body.father_name;
    if (body.mother_name !== undefined) studentPatch.mother_name = body.mother_name;
    if (body.date_of_birth !== undefined) studentPatch.date_of_birth = toDateOnly(body.date_of_birth);
    if (body.gender !== undefined) studentPatch.gender = normaliseGender(body.gender);
    if (body.address !== undefined) studentPatch.address = body.address;
    if (body.status !== undefined) studentPatch.status = normaliseStatus(body.status);
    if (body.batch !== undefined) studentPatch.batch_id = await resolveBatchId(supabase, body.batch);

    const { data: student, error: studentError } = await supabase
      .from('students')
      .update(studentPatch)
      .eq('id', studentId)
      .select()
      .single();

    if (studentError) {
      return res.status(502).json({ success: false, error: studentError.message });
    }

    res.status(200).json({
      success: true,
      data: student,
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

    const { data: existing, error: lookupError } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('id', studentId)
      .maybeSingle();

    if (lookupError) {
      return res.status(502).json({ success: false, error: lookupError.message });
    }
    if (!existing) {
      return res.status(204).send();
    }

    // Deleting the auth user cascades to the profile, which cascades to the
    // student row (profiles.id -> auth.users, students.profile_id -> profiles).
    const profileId = (existing as { profile_id: string }).profile_id;
    const { error: deleteError } = await supabase.auth.admin.deleteUser(profileId);
    if (deleteError) {
      // Fall back to deleting the student row directly.
      const { error: rowError } = await supabase.from('students').delete().eq('id', studentId);
      if (rowError) {
        return res.status(502).json({ success: false, error: rowError.message });
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
    
    const mockStudents: any[] = [];
    
    res.status(200).json({
      success: true,
      data: mockStudents,
      pagination: {
        total: mockStudents.length,
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
    const { batch_id } = req.body;
    
    if (!batch_id) {
      return validationError(res, 'batch_id is required');
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
  })
);

export default router;