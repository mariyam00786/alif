"use strict";
/**
 * Teacher Portal Endpoints (FRD §4.3, §6.4)
 *
 * Live data routes powering the mobile teacher portal. All queries run
 * against Supabase using the service-role client and are scoped to the
 * batches assigned to the authenticated teacher via the
 * `teachers` → `teacher_batches` relationship.
 *
 * Endpoints (mounted at /api/teacher):
 * - GET  /batches                       Assigned batches + completion stats
 * - GET  /students                      Students across assigned batches
 * - GET  /student/:id/progress?period=  Weekly/monthly progress + remarks
 * - POST /student/:id/remark            Add a remark/feedback for a student
 * - GET  /batch/:id/analytics           Batch analytics (top/improve)
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
// ===== Date helpers (UTC, aligned with seeded log_date) =====
function todayUtc() {
    return new Date().toISOString().slice(0, 10);
}
function shiftDate(dateStr, days) {
    const d = new Date(`${dateStr}T00:00:00Z`);
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
}
/** Returns YYYY-MM-DD strings ending at `end` going back `count` days (inclusive). */
function lastNDates(end, count) {
    const out = [];
    for (let i = count - 1; i >= 0; i -= 1) {
        out.push(shiftDate(end, -i));
    }
    return out;
}
function pct(part, whole) {
    if (whole <= 0)
        return 0;
    return Math.min(100, Math.round((part / whole) * 100));
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
    const { data: links, error: linkErr } = await supabase
        .from('teacher_batches')
        .select('batch_id')
        .eq('teacher_id', teacherId);
    if (linkErr)
        throw new http_error_1.HttpError(500, `Failed to load assignments: ${linkErr.message}`);
    const batchIds = (links ?? []).map((l) => l.batch_id).filter(Boolean);
    if (batchIds.length === 0)
        return [];
    const { data: batches, error: batchErr } = await supabase
        .from('batches')
        .select('id, name, name_ml')
        .in('id', batchIds);
    if (batchErr)
        throw new http_error_1.HttpError(500, `Failed to load batches: ${batchErr.message}`);
    return (batches ?? []).map((b) => ({ id: b.id, name: b.name, nameMl: b.name_ml ?? null }));
}
/** Loads active students for the given batch ids (with profile joined). */
async function loadStudents(batchIds) {
    if (batchIds.length === 0)
        return [];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: students, error: stuErr } = await supabase
        .from('students')
        .select('id, profile_id, batch_id, status')
        .in('batch_id', batchIds)
        .eq('status', 'active');
    if (stuErr)
        throw new http_error_1.HttpError(500, `Failed to load students: ${stuErr.message}`);
    const profileIds = (students ?? []).map((s) => s.profile_id);
    const { data: profiles } = profileIds.length
        ? await supabase
            .from('profiles')
            .select('id, full_name, full_name_ml, profile_photo')
            .in('id', profileIds)
        : { data: [] };
    const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
    return (students ?? []).map((s) => {
        const p = profileMap.get(s.profile_id);
        return {
            id: s.id,
            profileId: s.profile_id,
            name: p?.full_name ?? 'Student',
            nameMl: p?.full_name_ml ?? null,
            photo: p?.profile_photo ?? null,
            batchId: s.batch_id ?? null,
            status: s.status ?? 'active',
        };
    });
}
/** Count of active activities (denominator for completion %). */
async function activeActivityCount() {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { count, error } = await supabase
        .from('activities')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'active');
    if (error)
        throw new http_error_1.HttpError(500, `Failed to count activities: ${error.message}`);
    return count ?? 0;
}
/** Loads activity logs for a set of students between two dates (inclusive). */
async function loadLogs(studentIds, fromDate, toDate) {
    if (studentIds.length === 0)
        return [];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('activity_logs')
        .select('student_id, log_date, marks_earned, activity_id')
        .in('student_id', studentIds)
        .gte('log_date', fromDate)
        .lte('log_date', toDate);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load activity logs: ${error.message}`);
    return (data ?? []);
}
/** Average daily completion % over a window of dates (missing days = 0). */
function windowCompletion(logs, dates, totalActivities) {
    const byDate = new Map();
    for (const d of dates)
        byDate.set(d, { marks: 0, completed: 0 });
    for (const log of logs) {
        const bucket = byDate.get(log.log_date);
        if (!bucket)
            continue;
        bucket.marks += log.marks_earned ?? 0;
        if ((log.marks_earned ?? 0) > 0)
            bucket.completed += 1;
    }
    let totalMarks = 0;
    let pctSum = 0;
    for (const d of dates) {
        const bucket = byDate.get(d);
        totalMarks += bucket.marks;
        pctSum += pct(bucket.completed, totalActivities);
    }
    return { marks: totalMarks, avgPct: dates.length ? Math.round(pctSum / dates.length) : 0 };
}
/**
 * Computes per-student metrics from a month-window of logs, ranking each
 * student within its own batch. When `rankMarks` is provided, ranking uses
 * those all-time totals (consistent with the parent + student portals);
 * otherwise it falls back to the month-window marks.
 */
function computeMetrics(students, logs, totalActivities, today, rankMarks) {
    const logsByStudent = new Map();
    for (const s of students)
        logsByStudent.set(s.id, []);
    for (const log of logs) {
        const arr = logsByStudent.get(log.student_id);
        if (arr)
            arr.push(log);
    }
    const monthDates = lastNDates(today, 30);
    const weekDates = lastNDates(today, 7);
    const base = students.map((s) => {
        const studentLogs = logsByStudent.get(s.id) ?? [];
        const todayLogs = studentLogs.filter((l) => l.log_date === today);
        const todayMarks = todayLogs.reduce((sum, l) => sum + (l.marks_earned ?? 0), 0);
        const todayCompleted = todayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
        const week = windowCompletion(studentLogs, weekDates, totalActivities);
        const month = windowCompletion(studentLogs, monthDates, totalActivities);
        return {
            id: s.id,
            name: s.name,
            name_ml: s.nameMl,
            batch_id: s.batchId,
            today_marks: todayMarks,
            today_pct: pct(todayCompleted, totalActivities),
            week_pct: week.avgPct,
            month_pct: month.avgPct,
            month_marks: month.marks,
            logged_today: todayMarks > 0 || todayCompleted > 0,
        };
    });
    // Rank within each batch. Prefer all-time totals for cross-portal
    // consistency; fall back to the month window when not supplied.
    const byBatch = new Map();
    for (const m of base) {
        const key = m.batch_id ?? '_';
        if (!byBatch.has(key))
            byBatch.set(key, []);
        byBatch.get(key).push(m);
    }
    const rankMap = new Map();
    const markFor = (m) => rankMarks ? rankMarks.get(m.id) ?? 0 : m.month_marks;
    for (const group of byBatch.values()) {
        group
            .slice()
            .sort((a, b) => markFor(b) - markFor(a))
            .forEach((m, idx) => rankMap.set(m.id, idx + 1));
    }
    return base.map(({ month_marks, ...rest }) => ({ ...rest, rank: rankMap.get(rest.id) ?? 1 }));
}
// ===== Routes =====
/** GET /batches — assigned batches with completion stats. */
router.get('/batches', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    if (batches.length === 0) {
        res.json({ success: true, data: [] });
        return;
    }
    const batchIds = batches.map((b) => b.id);
    const students = await loadStudents(batchIds);
    const totalActivities = await activeActivityCount();
    const today = todayUtc();
    const logs = await loadLogs(students.map((s) => s.id), lastNDates(today, 30)[0], today);
    const metrics = computeMetrics(students, logs, totalActivities, today);
    const metricsByBatch = new Map();
    for (const m of metrics) {
        const key = m.batch_id ?? '_';
        if (!metricsByBatch.has(key))
            metricsByBatch.set(key, []);
        metricsByBatch.get(key).push(m);
    }
    const data = batches.map((b) => {
        const group = metricsByBatch.get(b.id) ?? [];
        const activeToday = group.filter((m) => m.logged_today).length;
        const avgCompletion = group.length
            ? Math.round(group.reduce((s, m) => s + m.week_pct, 0) / group.length)
            : 0;
        return {
            id: b.id,
            name: b.name,
            name_ml: b.nameMl,
            student_count: group.length,
            active_today: activeToday,
            avg_completion: avgCompletion,
        };
    });
    res.json({ success: true, data });
}));
/** GET /students — all students across assigned batches with metrics. */
router.get('/students', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const batchMap = new Map(batches.map((b) => [b.id, b]));
    const students = await loadStudents(batches.map((b) => b.id));
    if (students.length === 0) {
        res.json({ success: true, data: [] });
        return;
    }
    const totalActivities = await activeActivityCount();
    const today = todayUtc();
    const logs = await loadLogs(students.map((s) => s.id), lastNDates(today, 30)[0], today);
    // All-time marks per student → used for cross-portal-consistent ranking.
    const { data: allLogRows } = await (0, supabase_1.getSupabaseClient)()
        .from('activity_logs')
        .select('student_id, marks_earned')
        .in('student_id', students.map((s) => s.id));
    const allTimeMarks = new Map();
    for (const s of students)
        allTimeMarks.set(s.id, 0);
    for (const r of allLogRows ?? []) {
        const row = r;
        allTimeMarks.set(row.student_id, (allTimeMarks.get(row.student_id) ?? 0) + (row.marks_earned ?? 0));
    }
    const metrics = computeMetrics(students, logs, totalActivities, today, allTimeMarks);
    // Badge counts per student.
    const { data: badgeRows } = await (0, supabase_1.getSupabaseClient)()
        .from('student_badges')
        .select('student_id')
        .in('student_id', students.map((s) => s.id));
    const badgeCount = new Map();
    for (const r of badgeRows ?? []) {
        badgeCount.set(r.student_id, (badgeCount.get(r.student_id) ?? 0) + 1);
    }
    const data = metrics.map((m) => {
        const batch = m.batch_id ? batchMap.get(m.batch_id) : null;
        return {
            id: m.id,
            name: m.name,
            name_ml: m.name_ml,
            batch_id: m.batch_id,
            batch_name: batch?.name ?? '—',
            batch_name_ml: batch?.nameMl ?? batch?.name ?? '—',
            today_marks: m.today_marks,
            today_pct: m.today_pct,
            week_pct: m.week_pct,
            month_pct: m.month_pct,
            rank: m.rank,
            badges: badgeCount.get(m.id) ?? 0,
            logged_today: m.logged_today,
        };
    });
    res.json({ success: true, data });
}));
/** Ensures a student belongs to one of the teacher's assigned batches. */
async function requireStudentInScope(teacherId, studentId) {
    const batches = await loadAssignedBatches(teacherId);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: student, error } = await supabase
        .from('students')
        .select('id, profile_id, batch_id, status')
        .eq('id', studentId)
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load student: ${error.message}`);
    if (!student)
        throw new http_error_1.HttpError(404, 'Student not found.');
    const inScope = batches.some((b) => b.id === student.batch_id);
    if (!inScope)
        throw new http_error_1.HttpError(403, 'This student is not in one of your batches.');
    const { data: profile } = await supabase
        .from('profiles')
        .select('id, full_name, full_name_ml, profile_photo')
        .eq('id', student.profile_id)
        .maybeSingle();
    return {
        student: {
            id: student.id,
            profileId: student.profile_id,
            name: profile?.full_name ?? 'Student',
            nameMl: profile?.full_name_ml ?? null,
            photo: profile?.profile_photo ?? null,
            batchId: student.batch_id ?? null,
            status: student.status ?? 'active',
        },
        batches,
    };
}
/** GET /student/:id/progress?period=weekly|monthly — progress + remarks. */
router.get('/student/:id/progress', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const { student } = await requireStudentInScope(teacher.id, req.params.id);
    const period = String(req.query.period ?? 'weekly');
    const supabase = (0, supabase_1.getSupabaseClient)();
    const totalActivities = await activeActivityCount();
    const today = todayUtc();
    const span = period === 'monthly' ? 30 : 7;
    const dates = lastNDates(today, span);
    const logs = await loadLogs([student.id], dates[0], today);
    const series = dates.map((d) => {
        const dayLogs = logs.filter((l) => l.log_date === d);
        const marks = dayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
        const completed = dayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
        return { date: d, marks, completed, total: totalActivities, pct: pct(completed, totalActivities) };
    });
    // Category breakdown for the period.
    const activityIds = [...new Set(logs.map((l) => l.activity_id))];
    let breakdown = [];
    if (activityIds.length > 0) {
        const { data: acts } = await supabase
            .from('activities')
            .select('id, category_id')
            .in('id', activityIds);
        const catIds = [...new Set((acts ?? []).map((a) => a.category_id))];
        const { data: cats } = catIds.length
            ? await supabase.from('activity_categories').select('id, name, name_ml, icon').in('id', catIds)
            : { data: [] };
        const actCat = new Map((acts ?? []).map((a) => [a.id, a.category_id]));
        const catMap = new Map((cats ?? []).map((c) => [c.id, c]));
        const marksByCat = new Map();
        for (const log of logs) {
            const catId = actCat.get(log.activity_id);
            if (!catId)
                continue;
            marksByCat.set(catId, (marksByCat.get(catId) ?? 0) + (log.marks_earned ?? 0));
        }
        const maxMarks = Math.max(1, ...[...marksByCat.values()]);
        breakdown = [...marksByCat.entries()]
            .map(([catId, marks]) => ({
            category: catMap.get(catId)?.name ?? 'Other',
            category_ml: catMap.get(catId)?.name_ml ?? null,
            icon: catMap.get(catId)?.icon ?? null,
            marks,
            pct: pct(marks, maxMarks),
        }))
            .sort((a, b) => b.marks - a.marks);
    }
    // Remarks for the student (most recent first).
    const { data: remarkRows } = await supabase
        .from('student_remarks')
        .select('id, message, created_at')
        .eq('student_id', student.id)
        .order('created_at', { ascending: false });
    const totalMarks = series.reduce((s, d) => s + d.marks, 0);
    const completionPct = series.length ? Math.round(series.reduce((s, d) => s + d.pct, 0) / series.length) : 0;
    res.json({
        success: true,
        data: {
            student: { id: student.id, name: student.name, name_ml: student.nameMl },
            period,
            total_marks: totalMarks,
            completion_pct: completionPct,
            series,
            breakdown,
            remarks: (remarkRows ?? []).map((r) => ({
                id: r.id,
                message: r.message,
                created_at: r.created_at,
            })),
        },
    });
}));
/** POST /student/:id/remark — add a remark/feedback for a student. */
router.post('/student/:id/remark', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    await requireStudentInScope(teacher.id, req.params.id);
    const message = String((req.body ?? {}).message ?? '').trim();
    if (!message)
        throw new http_error_1.HttpError(400, 'A remark message is required.');
    const { data, error } = await (0, supabase_1.getSupabaseClient)()
        .from('student_remarks')
        .insert({ student_id: req.params.id, teacher_id: teacher.id, message })
        .select('id, message, created_at')
        .single();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to save remark: ${error.message}`);
    res.status(201).json({ success: true, data });
}));
/** GET /batch/:id/analytics — top performers + areas to improve. */
router.get('/batch/:id/analytics', authentication_1.authenticateRequest, teacherOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const teacher = await resolveTeacher(req.user.profileId);
    const batches = await loadAssignedBatches(teacher.id);
    const batch = batches.find((b) => b.id === req.params.id);
    if (!batch)
        throw new http_error_1.HttpError(403, 'This batch is not assigned to you.');
    const students = await loadStudents([batch.id]);
    const totalActivities = await activeActivityCount();
    const today = todayUtc();
    const monthDates = lastNDates(today, 30);
    const logs = await loadLogs(students.map((s) => s.id), monthDates[0], today);
    const metrics = computeMetrics(students, logs, totalActivities, today);
    const activeToday = metrics.filter((m) => m.logged_today).length;
    const avgCompletion = metrics.length
        ? Math.round(metrics.reduce((s, m) => s + m.week_pct, 0) / metrics.length)
        : 0;
    const topPerformers = metrics
        .slice()
        .sort((a, b) => b.month_pct - a.month_pct || b.today_marks - a.today_marks)
        .slice(0, 5)
        .map((m, idx) => ({
        id: m.id,
        name: m.name,
        name_ml: m.name_ml,
        pct: m.month_pct,
        position: idx + 1,
    }));
    // Areas to improve: category averages across the batch (lowest first).
    let areas = [];
    const activityIds = [...new Set(logs.map((l) => l.activity_id))];
    if (activityIds.length > 0) {
        const supabase = (0, supabase_1.getSupabaseClient)();
        const { data: acts } = await supabase
            .from('activities')
            .select('id, category_id')
            .in('id', activityIds);
        const catIds = [...new Set((acts ?? []).map((a) => a.category_id))];
        const { data: cats } = catIds.length
            ? await supabase.from('activity_categories').select('id, name, name_ml, icon').in('id', catIds)
            : { data: [] };
        const actCat = new Map((acts ?? []).map((a) => [a.id, a.category_id]));
        const catMap = new Map((cats ?? []).map((c) => [c.id, c]));
        const marksByCat = new Map();
        for (const log of logs) {
            const catId = actCat.get(log.activity_id);
            if (!catId)
                continue;
            marksByCat.set(catId, (marksByCat.get(catId) ?? 0) + (log.marks_earned ?? 0));
        }
        const maxMarks = Math.max(1, ...[...marksByCat.values()]);
        areas = [...marksByCat.entries()]
            .map(([catId, marks]) => ({
            category: catMap.get(catId)?.name ?? 'Other',
            category_ml: catMap.get(catId)?.name_ml ?? null,
            icon: catMap.get(catId)?.icon ?? null,
            pct: pct(marks, maxMarks),
        }))
            .sort((a, b) => a.pct - b.pct);
    }
    res.json({
        success: true,
        data: {
            id: batch.id,
            name: batch.name,
            name_ml: batch.nameMl,
            student_count: metrics.length,
            active_today: activeToday,
            avg_completion: avgCompletion,
            top_performers: topPerformers,
            areas_to_improve: areas,
        },
    });
}));
exports.default = router;
//# sourceMappingURL=teacher-portal.js.map