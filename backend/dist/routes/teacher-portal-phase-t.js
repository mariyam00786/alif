"use strict";
/**
 * Teacher Portal — Phase T additions (2026-06-30)
 *
 * Split into its own module so the existing teacher-portal.ts stays focused on
 * the core batches/students/progress/badges/attendance routes. Mounted at the
 * SAME `/api/teacher` prefix in app.ts; Express routes are matched in order of
 * registration, so these new routes sit alongside the original ones.
 *
 * Endpoints (Phase T):
 * - POST /batch/:id/notify              Send a batch reminder / motivational /
 *                                       acknowledgement (FRD §4.3.4)
 * - GET  /me/notifications              Live bell feed for the teacher (T2)
 * - GET  /student/:id/attendance?days=  Last N days attendance for a student (T4)
 * - GET  /classes                       Classes for the teacher's batches (T5)
 * - GET  /class/:id                     Class roster + attendance for a day (T5)
 *
 * All routes are role-gated teacher+admin and reuse the same service-role
 * Supabase client + auth middleware as the rest of the teacher portal.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const http_error_1 = require("../errors/http-error");
const supabase_1 = require("../config/supabase");
const router = (0, express_1.Router)();
const teacherOnly = (0, authorization_1.requireRoles)('teacher', 'admin');
// ===== Date helpers (UTC, mirrors teacher-portal.ts) =====
function todayUtc() {
    return new Date().toISOString().slice(0, 10);
}
function shiftDate(dateStr, days) {
    const d = new Date(`${dateStr}T00:00:00Z`);
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
}
/** Resolves the teacher record for the authenticated profile. */
async function resolveTeacher(profileId) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('teachers')
        .select('id, profile_id')
        .eq('profile_id', profileId)
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load teacher: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'No teacher record is linked to your account.');
    return { id: data.id, profileId: data.profile_id };
}
/** Loads the batches assigned to a teacher. */
async function loadAssignedBatches(teacherId) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('teacher_batches')
        .select('batch_id, batches(id, name, name_ml)')
        .eq('teacher_id', teacherId);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load batches: ${error.message}`);
    return (data ?? [])
        .map((row) => row.batches)
        .filter((b) => b)
        .map((b) => ({ id: b.id, name: b.name, nameMl: b.name_ml ?? null }));
}
/** Ensures a student belongs to one of the teacher's assigned batches. */
async function requireStudentInScope(teacherId, studentId) {
    const batches = await loadAssignedBatches(teacherId);
    if (batches.length === 0)
        throw new http_error_1.HttpError(403, 'This student is not in any of your batches.');
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('students')
        .select('batch_id')
        .eq('id', studentId)
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to verify student: ${error.message}`);
    if (!data)
        throw new http_error_1.HttpError(404, 'Student not found.');
    const batchId = data.batch_id;
    if (!batchId || !batches.some((b) => b.id === batchId)) {
        throw new http_error_1.HttpError(403, 'This student is not in any of your batches.');
    }
}
/** Loads the classes attached to a teacher's assigned batches. */
async function loadAssignedClasses(batches) {
    if (batches.length === 0)
        return [];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('classes')
        .select('id, name, name_ml, level, batch_id, status')
        .in('batch_id', batches.map((b) => b.id))
        .eq('status', 'active')
        .order('name', { ascending: true });
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load classes: ${error.message}`);
    const batchMap = new Map(batches.map((b) => [b.id, b]));
    return (data ?? []).map((c) => {
        const b = c.batch_id ? batchMap.get(c.batch_id) : null;
        return {
            id: c.id,
            name: c.name ?? 'Class',
            nameMl: c.name_ml ?? null,
            level: c.level ?? null,
            batchId: c.batch_id ?? null,
            batchName: b?.name ?? null,
            batchNameMl: b?.nameMl ?? null,
        };
    });
}
// ===== Notifications helpers =====
const NOTIFY_TYPES = ['batch_reminder', 'motivational', 'acknowledgement'];
const NOTIFY_PRESETS = {
    batch_reminder: { category: 'batch_reminder', icon: 'campaign', titleFallback: 'Batch reminder' },
    motivational: { category: 'motivational', icon: 'auto_awesome', titleFallback: 'Motivational note' },
    acknowledgement: { category: 'acknowledgement', icon: 'workspace_premium', titleFallback: 'Achievement' },
};
function mapNotificationRow(n) {
    return {
        id: n.id,
        title: n.title,
        body: n.body,
        body_ml: n.body_ml ?? null,
        target_type: n.target_type ?? null,
        target_id: n.target_id ?? null,
        category: n.category ?? null,
        icon: n.icon ?? null,
        created_at: n.created_at,
        sent_at: n.sent_at ?? null,
        sent_by_teacher: n.sent_by_teacher ?? null,
    };
}
// Best-effort FCM dispatch. The project has no fcm_tokens table yet and
// Firebase is not configured in dev, so this is a silent no-op there; the
// persisted notifications row is what the bells surface in either case.
async function maybeDispatchFcmForBatch(batchId, msg) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    let tokens = [];
    try {
        const res = await supabase
            .from('fcm_tokens')
            .select('token')
            .eq('batch_id', batchId)
            .eq('active', true);
        tokens = (res.data ?? []).map((r) => r.token).filter(Boolean);
    }
    catch {
        return; // table absent in this project — skip silently
    }
    if (tokens.length === 0)
        return;
    const { getMessaging } = await import('firebase-admin/messaging');
    const messaging = getMessaging();
    await Promise.all(tokens.map((token) => messaging.send({ notification: { title: msg.title, body: msg.body }, token }).catch(() => {
        /* drop individual failures */
    })));
}
/** Persists a batch-scoped notification on behalf of a teacher. */
async function persistBatchNotification(teacherId, batchId, payload) {
    const preset = NOTIFY_PRESETS[payload.type];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: students, error: stuErr } = await supabase
        .from('students')
        .select('id')
        .eq('batch_id', batchId)
        .eq('status', 'active');
    if (stuErr)
        throw new http_error_1.HttpError(500, `Failed to resolve batch students: ${stuErr.message}`);
    const recipients = (students ?? []).length;
    const { data, error } = await supabase
        .from('notifications')
        .insert({
        title: payload.title.trim() || preset.titleFallback,
        body: payload.body.trim(),
        body_ml: null,
        target_type: 'batch',
        target_id: batchId,
        category: preset.category,
        icon: preset.icon,
        sent_at: new Date().toISOString(),
        sent_by_teacher: teacherId,
    })
        .select('id')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to send notification: ${error.message}`);
    try {
        await maybeDispatchFcmForBatch(batchId, {
            title: payload.title.trim() || preset.titleFallback,
            body: payload.body.trim(),
        });
    }
    catch (err) {
        console.warn('[teacher-portal-phase-t] FCM dispatch skipped:', err.message);
    }
    return { id: data.id, recipients };
}
// ===== Routes =====
/** POST /batch/:id/notify — send a notification to a batch (FRD §4.3.4). */
router.post('/batch/:id/notify', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const batch = batches.find((b) => b.id === req.params.id);
    if (!batch)
        throw new http_error_1.HttpError(403, 'This batch is not assigned to you.');
    const body = req.body ?? {};
    const title = String(body.title ?? '').trim();
    const messageBody = String(body.body ?? body.message ?? '').trim();
    const type = String(body.type ?? 'batch_reminder');
    if (!messageBody)
        throw new http_error_1.HttpError(400, 'A message body is required.');
    if (!NOTIFY_TYPES.includes(type)) {
        throw new http_error_1.HttpError(400, `type must be one of: ${NOTIFY_TYPES.join(', ')}.`);
    }
    const { id, recipients } = await persistBatchNotification(teacher.id, batch.id, {
        title,
        body: messageBody,
        type,
    });
    res.status(201).json({
        success: true,
        data: {
            id,
            batch_id: batch.id,
            recipients,
            title: title || NOTIFY_PRESETS[type].titleFallback,
            body: messageBody,
            type,
        },
    });
}));
/** GET /me/notifications — announcements + batch reminders for this teacher. */
router.get('/me/notifications', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const batchIds = batches.map((b) => b.id);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: all, error } = await supabase
        .from('notifications')
        .select('id, title, body, body_ml, target_type, target_id, category, icon, created_at, sent_at, sent_by_teacher')
        .order('created_at', { ascending: false })
        .limit(40);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load notifications: ${error.message}`);
    const relevant = (all ?? []).filter((n) => {
        if (n.target_type == null || n.target_type === 'all')
            return true;
        if (n.target_type === 'batch')
            return n.target_id && batchIds.includes(n.target_id);
        if (n.target_type === 'class')
            return true; // classes roll up under batches
        if (n.sent_by_teacher === teacher.id)
            return true; // echo what this teacher sent
        return false;
    });
    res.json({ success: true, data: relevant.map(mapNotificationRow) });
}));
// ===== Per-student monitoring extras (T4) =====
/** GET /student/:id/attendance?days=30 — last N days attendance for a student. */
router.get('/student/:id/attendance', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    await requireStudentInScope(teacher.id, req.params.id);
    const days = Math.max(1, Math.min(90, Number(req.query.days ?? 30) || 30));
    const today = todayUtc();
    const fromDate = shiftDate(today, -(days - 1));
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: rows, error } = await supabase
        .from('attendance')
        .select('attendance_date, status, notes, marked_by')
        .eq('student_id', req.params.id)
        .gte('attendance_date', fromDate)
        .lte('attendance_date', today)
        .order('attendance_date', { ascending: false });
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load attendance: ${error.message}`);
    // Resolve marker names (teachers → profiles.full_name) for "who marked".
    const markerIds = [...new Set((rows ?? [])
            .map((r) => r.marked_by)
            .filter((id) => Boolean(id)))];
    let markerMap = new Map();
    if (markerIds.length) {
        const tRes = await supabase.from('teachers').select('id, profile_id').in('id', markerIds);
        const teacherRows = (tRes.data ?? []);
        const profileIds = teacherRows.map((t) => t.profile_id).filter(Boolean);
        if (profileIds.length) {
            const pRes = await supabase.from('profiles').select('id, full_name').in('id', profileIds);
            const nameByProfile = new Map((pRes.data ?? []).map((p) => [p.id, p.full_name ?? 'Teacher']));
            markerMap = new Map(teacherRows.map((t) => [t.id, nameByProfile.get(t.profile_id) ?? 'Teacher']));
        }
        else {
            markerMap = new Map(teacherRows.map((t) => [t.id, 'Teacher']));
        }
    }
    const data = (rows ?? []).map((r) => ({
        date: r.attendance_date,
        status: r.status,
        notes: r.notes ?? null,
        marked_by: r.marked_by ?? null,
        marked_by_name: r.marked_by ? markerMap.get(r.marked_by) ?? 'Teacher' : null,
    }));
    const present = data.filter((d) => d.status === 'present' || d.status === 'late').length;
    res.json({
        success: true,
        data: {
            student_id: req.params.id,
            from_date: fromDate,
            to_date: today,
            present_count: present,
            total_marked: data.length,
            entries: data,
        },
    });
}));
// ===== Class management (T5) =====
/** GET /classes — classes for the teacher's assigned batches. */
router.get('/classes', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const classes = await loadAssignedClasses(batches);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const classIds = classes.map((c) => c.id);
    const countsRes = classIds.length
        ? await supabase
            .from('students')
            .select('class_id')
            .in('class_id', classIds)
            .eq('status', 'active')
        : { data: [] };
    const countMap = new Map();
    for (const r of countsRes.data ?? []) {
        const cid = r.class_id;
        if (cid)
            countMap.set(cid, (countMap.get(cid) ?? 0) + 1);
    }
    const data = classes.map((c) => ({
        id: c.id,
        name: c.name,
        name_ml: c.nameMl ?? c.name,
        level: c.level,
        batch_id: c.batchId,
        batch_name: c.batchName,
        batch_name_ml: c.batchNameMl,
        student_count: countMap.get(c.id) ?? 0,
    }));
    res.json({ success: true, data });
}));
/** GET /class/:id — roster for a class (+ attendance for a day, default today). */
router.get('/class/:id', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const classes = await loadAssignedClasses(batches);
    const cls = classes.find((c) => c.id === req.params.id);
    if (!cls)
        throw new http_error_1.HttpError(403, 'This class is not assigned to you.');
    const supabase = (0, supabase_1.getSupabaseClient)();
    const date = String(req.query.date ?? todayUtc()).slice(0, 10);
    const { data: studentsRaw, error: stuErr } = await supabase
        .from('students')
        .select('id, profile_id, status')
        .eq('class_id', cls.id)
        .eq('status', 'active');
    if (stuErr)
        throw new http_error_1.HttpError(500, `Failed to load roster: ${stuErr.message}`);
    const studentRows = (studentsRaw ?? []);
    const profileIds = studentRows.map((s) => s.profile_id).filter(Boolean);
    const studentIds = studentRows.map((s) => s.id);
    const [{ data: profiles }, { data: attRows }] = await Promise.all([
        profileIds.length
            ? supabase.from('profiles').select('id, full_name, full_name_ml, profile_photo').in('id', profileIds)
            : Promise.resolve({ data: [] }),
        studentIds.length
            ? supabase
                .from('attendance')
                .select('student_id, status, notes')
                .eq('attendance_date', date)
                .in('student_id', studentIds)
            : Promise.resolve({ data: [] }),
    ]);
    const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
    const statusMap = new Map((attRows ?? []).map((r) => [r.student_id, r]));
    const data = studentRows.map((s) => {
        const p = profileMap.get(s.profile_id);
        const att = statusMap.get(s.id);
        return {
            id: s.id,
            name: p?.full_name ?? 'Student',
            name_ml: p?.full_name_ml ?? null,
            photo: p?.profile_photo ?? null,
            status: att?.status ?? null,
            notes: att?.notes ?? null,
        };
    });
    const present = data.filter((d) => d.status === 'present' || d.status === 'late').length;
    res.json({
        success: true,
        data: {
            class_id: cls.id,
            class_name: cls.name,
            class_name_ml: cls.nameMl ?? cls.name,
            level: cls.level,
            batch_id: cls.batchId,
            batch_name: cls.batchName,
            date,
            present_count: present,
            total: data.length,
            students: data,
        },
    });
}));
exports.default = router;
//# sourceMappingURL=teacher-portal-phase-t.js.map