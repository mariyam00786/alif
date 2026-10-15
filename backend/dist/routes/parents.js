"use strict";
/**
 * Parent Portal Endpoints
 *
 * Live data routes powering the mobile parent portal.
 * All queries run against Supabase using the service-role client
 * (RLS-bypassing) and are scoped to the authenticated parent's children
 * via the parent_students relationship table.
 *
 * Endpoints (mounted at /api/parents):
 * - GET  /me/children
 * - GET  /me/children/:childId
 * - GET  /me/children/:childId/progress?period=daily|weekly|monthly
 * - GET  /me/children/:childId/badges
 * - GET  /me/children/:childId/leaderboard?period=daily|weekly|monthly|all_time
 * - GET  /me/children/:childId/home-summary
 * - GET  /me/children/:childId/remarks
 * - GET  /me/approvals
 * - POST /me/approvals/:childId/:date/approve
 * - POST /me/approvals/:childId/:date/reject
 * - POST /me/approvals/:childId/:date/send-back
 * - GET  /me/notifications
 * - POST /me/notifications/:id/read
 * - GET  /me/preferences
 * - PUT  /me/preferences
 * - GET  /me/profile
 * - PUT  /me/profile
 */
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const http_error_1 = require("../errors/http-error");
const supabase_1 = require("../config/supabase");
const router = (0, express_1.Router)();
// ===== Date helpers (UTC, aligned with seeded log_date) =====
function todayUtc() {
    return new Date().toISOString().slice(0, 10);
}
function shiftDate(dateStr, days) {
    const d = new Date(`${dateStr}T00:00:00Z`);
    d.setUTCDate(d.getUTCDate() + days);
    return d.toISOString().slice(0, 10);
}
/** Returns an array of YYYY-MM-DD strings ending at `end` going back `count` days (inclusive). */
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
/** Loads the authenticated parent's children (with profile + batch joined). */
async function loadChildren(parentProfileId) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: links, error: linkErr } = await supabase
        .from('parent_students')
        .select('student_id')
        .eq('parent_profile_id', parentProfileId);
    if (linkErr)
        throw new http_error_1.HttpError(500, `Failed to load children: ${linkErr.message}`);
    const studentIds = (links ?? []).map((l) => l.student_id);
    if (studentIds.length === 0)
        return [];
    const { data: students, error: stuErr } = await supabase
        .from('students')
        .select('id, profile_id, batch_id, status')
        .in('id', studentIds);
    if (stuErr)
        throw new http_error_1.HttpError(500, `Failed to load students: ${stuErr.message}`);
    const profileIds = (students ?? []).map((s) => s.profile_id);
    const batchIds = (students ?? []).map((s) => s.batch_id).filter(Boolean);
    const [{ data: profiles }, { data: batches }] = await Promise.all([
        supabase.from('profiles').select('id, full_name, full_name_ml, profile_photo').in('id', profileIds),
        batchIds.length
            ? supabase.from('batches').select('id, name, name_ml').in('id', batchIds)
            : Promise.resolve({ data: [] }),
    ]);
    const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
    const batchMap = new Map((batches ?? []).map((b) => [b.id, b]));
    return (students ?? []).map((s) => {
        const p = profileMap.get(s.profile_id);
        const b = s.batch_id ? batchMap.get(s.batch_id) : null;
        return {
            studentId: s.id,
            profileId: s.profile_id,
            name: p?.full_name ?? 'Student',
            nameMl: p?.full_name_ml ?? null,
            photo: p?.profile_photo ?? null,
            batchId: s.batch_id ?? null,
            batchName: b?.name ?? null,
            batchNameMl: b?.name_ml ?? null,
            status: s.status ?? 'active',
        };
    });
}
/** Ensures the given childId belongs to the parent; returns the child row. */
async function requireChild(parentProfileId, childId) {
    const children = await loadChildren(parentProfileId);
    const child = children.find((c) => c.studentId === childId);
    if (!child)
        throw new http_error_1.HttpError(403, 'This student is not linked to your account.');
    return child;
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
/** Loads logs for a student between two dates (inclusive), including the
 * durable parent_decision column introduced in Phase P (P1). */
async function loadLogs(studentId, fromDate, toDate) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('activity_logs')
        .select('log_date, marks_earned, activity_id, parent_approved, parent_decision, decided_at')
        .eq('student_id', studentId)
        .gte('log_date', fromDate)
        .lte('log_date', toDate);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load activity logs: ${error.message}`);
    return (data ?? []);
}
/** True when the log row is still awaiting a parent decision (P1).
 * Replaces the legacy `!parent_approved` check — `rejected` logs are NOT
 * pending any more (they have a durable decision), so they should not
 * re-surface on the approvals list. */
function isPending(log) {
    const decision = log.parent_decision ?? (log.parent_approved ? 'approved' : 'pending');
    return decision === 'pending';
}
/** Daily completion % averaged over a window of dates (missing days count as 0). */
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
/** Builds the summary metrics for a single child. */
async function childSummary(child, totalActivities) {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const today = todayUtc();
    const monthDates = lastNDates(today, 30);
    const logs = await loadLogs(child.studentId, monthDates[0], today);
    const todayLogs = logs.filter((l) => l.log_date === today);
    const todayMarks = todayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
    const todayCompleted = todayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
    const week = windowCompletion(logs, lastNDates(today, 7), totalActivities);
    const month = windowCompletion(logs, monthDates, totalActivities);
    // Count pending *days* (one approval card == one day), so the home banner
    // matches the per-day cards shown on the approvals screen. A rejected day
    // is NOT pending any more (P1: durable decision).
    const pending = new Set(logs.filter((l) => isPending(l)).map((l) => l.log_date)).size;
    const [{ count: badgeCount }, rankInfo] = await Promise.all([
        supabase.from('student_badges').select('*', { count: 'exact', head: true }).eq('student_id', child.studentId),
        computeRank(child),
    ]);
    return {
        id: child.studentId,
        name: child.name,
        name_ml: child.nameMl,
        photo: child.photo,
        batch_id: child.batchId,
        batch_name: child.batchName,
        batch_name_ml: child.batchNameMl,
        active: child.status === 'active',
        today_marks: todayMarks,
        today_completed: todayCompleted,
        total_activities: totalActivities,
        today_pct: pct(todayCompleted, totalActivities),
        week_pct: week.avgPct,
        week_marks: week.marks,
        month_pct: month.avgPct,
        month_marks: month.marks,
        pending_approvals: pending,
        badges: badgeCount ?? 0,
        rank: rankInfo.rank,
        batch_size: rankInfo.batchSize,
    };
}
/** Ranks a child within its batch by all-time total marks. */
async function computeRank(child) {
    if (!child.batchId)
        return { rank: 1, batchSize: 1 };
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: peers, error: peerErr } = await supabase
        .from('students')
        .select('id')
        .eq('batch_id', child.batchId)
        .eq('status', 'active');
    if (peerErr)
        throw new http_error_1.HttpError(500, `Failed to load batch peers: ${peerErr.message}`);
    const peerIds = (peers ?? []).map((p) => p.id);
    if (peerIds.length === 0)
        return { rank: 1, batchSize: 1 };
    const { data: logs, error: logErr } = await supabase
        .from('activity_logs')
        .select('student_id, marks_earned')
        .in('student_id', peerIds);
    if (logErr)
        throw new http_error_1.HttpError(500, `Failed to load batch logs: ${logErr.message}`);
    const totals = new Map();
    for (const id of peerIds)
        totals.set(id, 0);
    for (const log of logs ?? []) {
        totals.set(log.student_id, (totals.get(log.student_id) ?? 0) + (log.marks_earned ?? 0));
    }
    const ranked = [...totals.entries()].sort((a, b) => b[1] - a[1]);
    const rank = ranked.findIndex(([id]) => id === child.studentId) + 1;
    return { rank: rank > 0 ? rank : peerIds.length, batchSize: peerIds.length };
}
// ===== Routes =====
// Students are allowed here too: every query below is scoped to the caller's
// own profile id via the parent_students table, so a student account that is
// also linked to children (dual student/parent account) can read its parent
// data, while a regular student simply sees an empty children list.
const parentOnly = (0, authorization_1.requireRoles)('parent', 'admin', 'student');
/** GET /me/children — overview dashboard data. */
router.get('/me/children', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const children = await loadChildren(req.user.profileId);
    const totalActivities = await activeActivityCount();
    const summaries = await Promise.all(children.map((c) => childSummary(c, totalActivities)));
    res.json({ success: true, data: summaries });
}));
/** GET /me/children/:childId — single child summary. */
router.get('/me/children/:childId', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const totalActivities = await activeActivityCount();
    res.json({ success: true, data: await childSummary(child, totalActivities) });
}));
/** GET /me/children/:childId/progress?period=daily|weekly|monthly */
router.get('/me/children/:childId/progress', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const period = String(req.query.period ?? 'daily');
    const totalActivities = await activeActivityCount();
    const today = todayUtc();
    const span = period === 'monthly' ? 30 : period === 'weekly' ? 7 : 1;
    const dates = lastNDates(today, span);
    const logs = await loadLogs(child.studentId, dates[0], today);
    // Per-day series for charts.
    const series = dates.map((d) => {
        const dayLogs = logs.filter((l) => l.log_date === d);
        const marks = dayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
        const completed = dayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
        return { date: d, marks, completed, total: totalActivities, pct: pct(completed, totalActivities) };
    });
    // Category breakdown for the period.
    const supabase = (0, supabase_1.getSupabaseClient)();
    const activityIds = [...new Set(logs.map((l) => l.activity_id))];
    let breakdown = [];
    if (activityIds.length > 0) {
        const { data: acts } = await supabase
            .from('activities')
            .select('id, category_id')
            .in('id', activityIds);
        const catIds = [...new Set((acts ?? []).map((a) => a.category_id))];
        const { data: cats } = catIds.length
            ? await supabase.from('activity_categories').select('id, name, name_ml').in('id', catIds)
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
        breakdown = [...marksByCat.entries()]
            .map(([catId, marks]) => ({
            category: catMap.get(catId)?.name ?? 'Other',
            category_ml: catMap.get(catId)?.name_ml ?? null,
            marks,
        }))
            .sort((a, b) => b.marks - a.marks);
    }
    const totalMarks = series.reduce((s, d) => s + d.marks, 0);
    const avgPct = series.length ? Math.round(series.reduce((s, d) => s + d.pct, 0) / series.length) : 0;
    res.json({
        success: true,
        data: {
            period,
            total_marks: totalMarks,
            completion_pct: avgPct,
            series,
            breakdown,
        },
    });
}));
/** GET /me/children/:childId/badges */
router.get('/me/children/:childId/badges', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const [{ data: allBadges, error: badgeErr }, { data: earned, error: earnedErr }] = await Promise.all([
        supabase.from('badges').select('id, name, name_ml, description, icon').eq('status', 'active').order('created_at'),
        supabase.from('student_badges').select('badge_id, earned_at').eq('student_id', child.studentId),
    ]);
    if (badgeErr)
        throw new http_error_1.HttpError(500, `Failed to load badges: ${badgeErr.message}`);
    if (earnedErr)
        throw new http_error_1.HttpError(500, `Failed to load earned badges: ${earnedErr.message}`);
    const earnedMap = new Map((earned ?? []).map((e) => [e.badge_id, e.earned_at]));
    const badges = (allBadges ?? []).map((b) => ({
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
}));
/** GET /me/children/:childId/leaderboard?period=daily|weekly|monthly|all_time
 *
 * Batch leaderboard across daily / weekly / monthly / all-time windows with
 * a per-entry `trend` marker (up / down / same) computed by comparing each
 * peer's rank in the chosen period against the equivalent previous period. */
router.get('/me/children/:childId/leaderboard', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const period = String(req.query.period ?? 'weekly');
    const supabase = (0, supabase_1.getSupabaseClient)();
    if (!child.batchId) {
        res.json({ success: true, data: { period, entries: [] } });
        return;
    }
    const { data: peers, error: peerErr } = await supabase
        .from('students')
        .select('id, profile_id')
        .eq('batch_id', child.batchId)
        .eq('status', 'active');
    if (peerErr)
        throw new http_error_1.HttpError(500, `Failed to load peers: ${peerErr.message}`);
    const peerIds = (peers ?? []).map((p) => p.id);
    const profileIds = (peers ?? []).map((p) => p.profile_id);
    if (peerIds.length === 0) {
        res.json({ success: true, data: { period, entries: [] } });
        return;
    }
    const today = todayUtc();
    // Window for the current period AND the equivalent previous period (used
    // for the trend comparison).
    const span = period === 'monthly' ? 30 : period === 'weekly' ? 7 : period === 'all_time' ? 9999 : 1;
    const fromDate = period === 'all_time' ? '1970-01-01' : shiftDate(today, -(span - 1));
    const prevFrom = period === 'all_time' ? '1970-01-01' : shiftDate(fromDate, -span);
    const prevTo = period === 'all_time' ? shiftDate(fromDate, -1) : shiftDate(fromDate, -1);
    const [{ data: allLogs }, { data: profiles }] = await Promise.all([
        supabase
            .from('activity_logs')
            .select('student_id, marks_earned, log_date')
            .in('student_id', peerIds)
            .gte('log_date', prevFrom)
            .lte('log_date', today),
        supabase.from('profiles').select('id, full_name, full_name_ml, profile_photo').in('id', profileIds),
    ]);
    const profileByStudent = new Map((peers ?? []).map((p) => [p.id, (profiles ?? []).find((pr) => pr.id === p.profile_id)]));
    // Split logs into the current and previous windows.
    const currTotals = new Map();
    const prevTotals = new Map();
    for (const id of peerIds) {
        currTotals.set(id, 0);
        prevTotals.set(id, 0);
    }
    for (const log of allLogs ?? []) {
        const sid = log.student_id;
        const marks = log.marks_earned ?? 0;
        const d = log.log_date;
        if (d >= fromDate && d <= today)
            currTotals.set(sid, (currTotals.get(sid) ?? 0) + marks);
        if (d >= prevFrom && d <= prevTo)
            prevTotals.set(sid, (prevTotals.get(sid) ?? 0) + marks);
    }
    const rankOf = (totals) => [...totals.entries()].sort((a, b) => b[1] - a[1]).map(([id], i) => ({ id, rank: i + 1 }));
    const prevRanks = new Map(rankOf(prevTotals).map((r) => [r.id, r.rank]));
    const entries = rankOf(currTotals).map(({ id, rank }) => {
        const marks = currTotals.get(id) ?? 0;
        const prof = profileByStudent.get(id);
        const prev = prevRanks.get(id);
        let trend = 'same';
        if (prev === undefined || (prevTotals.get(id) ?? 0) === 0)
            trend = 'new';
        else if (prev > rank)
            trend = 'up';
        else if (prev < rank)
            trend = 'down';
        return {
            rank,
            student_id: id,
            name: prof?.full_name ?? 'Student',
            name_ml: prof?.full_name_ml ?? null,
            photo: prof?.profile_photo ?? null,
            marks,
            is_self: id === child.studentId,
            trend,
        };
    });
    res.json({ success: true, data: { period, entries } });
}));
/** GET /me/children/:childId/home-summary
 *
 * A compact "today" dashboard for a child: today's completion + marks,
 * current streak, this week's points, batch rank, and a badge preview.
 * Mirrors the student `/me/home-summary` shape but scoped to a linked child. */
router.get('/me/children/:childId/home-summary', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const totalActivities = await activeActivityCount();
    const supabase = (0, supabase_1.getSupabaseClient)();
    const today = todayUtc();
    const monthDates = lastNDates(today, 30);
    const logs = await loadLogs(child.studentId, monthDates[0], today);
    const todayLogs = logs.filter((l) => l.log_date === today);
    const todayDone = todayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
    const todayMarks = todayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
    const weekDates = new Set(lastNDates(today, 7));
    const weekPoints = logs
        .filter((l) => weekDates.has(l.log_date))
        .reduce((s, l) => s + (l.marks_earned ?? 0), 0);
    // Streak: consecutive days (ending today/yesterday) with any marks > 0.
    const daysWithMarks = new Set(logs.filter((l) => (l.marks_earned ?? 0) > 0).map((l) => l.log_date));
    let streakDays = 0;
    let cursor = today;
    if (!daysWithMarks.has(cursor))
        cursor = shiftDate(cursor, -1);
    while (daysWithMarks.has(cursor)) {
        streakDays += 1;
        cursor = shiftDate(cursor, -1);
    }
    const rankInfo = await computeRank(child);
    res.json({
        success: true,
        data: {
            today_done: todayDone,
            today_total: totalActivities,
            today_marks: todayMarks,
            streak_days: streakDays,
            week_points: weekPoints,
            week_pct: windowCompletion(logs, lastNDates(today, 7), totalActivities).avgPct,
            batch_rank: rankInfo.rank,
            batch_size: rankInfo.batchSize,
            batch_name: child.batchName,
            pending_approvals: new Set(logs.filter((l) => isPending(l)).map((l) => l.log_date)).size,
        },
    });
}));
/** GET /me/children/:childId/remarks
 *
 * Teacher remarks/feedback left for a child (live `student_remarks` rows).
 * Each remark is enriched with the teacher's name (from profiles) and a
 * light-weight `tone` field ("praise" | "note" | "info") derived from the
 * message keywords so the parent UI can colour-code the remark card. */
router.get('/me/children/:childId/remarks', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const child = await requireChild(req.user.profileId, req.params.childId);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: rows, error } = await supabase
        .from('student_remarks')
        .select('id, message, created_at, teacher_id')
        .eq('student_id', child.studentId)
        .order('created_at', { ascending: false })
        .limit(50);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load remarks: ${error.message}`);
    const remarks = (rows ?? []);
    const teacherIds = [...new Set(remarks.map((r) => r.teacher_id).filter(Boolean))];
    // Resolve teacher display names: teachers.profile_id -> profiles.full_name.
    let teacherNameMap = new Map();
    let teacherSubjectMap = new Map();
    if (teacherIds.length > 0) {
        const { data: teachers } = await supabase
            .from('teachers')
            .select('id, profile_id, qualification, subjects')
            .in('id', teacherIds);
        const teacherProfileIds = (teachers ?? []).map((t) => t.profile_id).filter(Boolean);
        const { data: profs } = teacherProfileIds.length
            ? await supabase.from('profiles').select('id, full_name').in('id', teacherProfileIds)
            : { data: [] };
        const profMap = new Map((profs ?? []).map((p) => [p.id, p.full_name ?? '']));
        teacherNameMap = new Map((teachers ?? []).map((t) => [t.id, profMap.get(t.profile_id) ?? '']));
        teacherSubjectMap = new Map((teachers ?? []).map((t) => [t.id, Array.isArray(t.subjects) && t.subjects.length ? t.subjects[0] : (t.qualification ?? null)]));
    }
    res.json({
        success: true,
        data: remarks.map((r) => ({
            id: r.id,
            message: r.message,
            created_at: r.created_at,
            teacher: teacherNameMap.get(r.teacher_id) || 'Teacher',
            subject: teacherSubjectMap.get(r.teacher_id) ?? null,
            tone: remarkTone(r.message),
        })),
    });
}));
/** Infers a remark tone from the message text for colour-coding. */
function remarkTone(message) {
    const m = message.toLowerCase();
    if (/mashallah|masha allah|excellent|great|wonderful|good|well done|keep (up|it)|keep it|outstanding|excellen|fantastic|superb|impressive|brilliant/.test(m)) {
        return 'praise';
    }
    if (/please|attention|missed|late|absent|concern|improve|need to|must|should|reminder|warn|consistency|encourage/.test(m)) {
        return 'note';
    }
    return 'info';
}
/** GET /me/approvals — pending AND recently-rejected daily approvals across
 * all children (P1: durable workflow).
 *
 * Cards come back with a `status` of 'pending' or 'rejected'. Rejected cards
 * stay visible for 24 hours so the parent can undo an accidental reject;
 * after that they age out of the default list (still queryable via ?include=
 * all). Approved cards never appear here — they surface in the child's
 * progress history. */
router.get('/me/approvals', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const include = String(req.query.include ?? 'open'); // 'open' | 'all'
    const children = await loadChildren(req.user.profileId);
    const totalActivities = await activeActivityCount();
    const supabase = (0, supabase_1.getSupabaseClient)();
    const out = [];
    const rejectCutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    for (const child of children) {
        // Pull every un-approved day so we can surface both pending and
        // recently-rejected records. We deliberately do NOT filter by
        // parent_approved here — `parent_decision` is the source of truth.
        const { data: logs, error } = await supabase
            .from('activity_logs')
            .select('log_date, marks_earned, activity_id, parent_approved, parent_decision, decided_at')
            .eq('student_id', child.studentId)
            .neq('parent_decision', 'approved')
            .order('log_date', { ascending: false });
        if (error)
            throw new http_error_1.HttpError(500, `Failed to load approvals: ${error.message}`);
        const byDate = new Map();
        for (const log of (logs ?? [])) {
            const decision = log.parent_decision === 'rejected' ? 'rejected' : 'pending';
            if (!byDate.has(log.log_date)) {
                byDate.set(log.log_date, { date: log.log_date, logs: [], decision, decidedAt: log.decided_at ?? null });
            }
            const agg = byDate.get(log.log_date);
            agg.logs.push(log);
            // A day is 'rejected' only if EVERY log on that day is rejected;
            // any pending log flips it back to pending (parent still needs to act).
            if (decision === 'pending')
                agg.decision = 'pending';
            if (log.decided_at && (!agg.decidedAt || log.decided_at > agg.decidedAt)) {
                agg.decidedAt = log.decided_at;
            }
        }
        // Most recent 14 days per child (was 7) so rejected undo cards stay
        // reachable a little longer.
        let days = [...byDate.values()].sort((a, b) => (a.date < b.date ? 1 : -1)).slice(0, 14);
        // Default view: drop rejected cards older than 24h (undo window).
        if (include !== 'all') {
            days = days.filter((d) => d.decision !== 'rejected' || (d.decidedAt && d.decidedAt >= rejectCutoff));
        }
        // Resolve activity names for highlights.
        const allActivityIds = [...new Set(days.flatMap((d) => d.logs.map((l) => l.activity_id)))];
        const { data: acts } = allActivityIds.length
            ? await supabase.from('activities').select('id, name, name_ml').in('id', allActivityIds)
            : { data: [] };
        const actMap = new Map((acts ?? []).map((a) => [a.id, a]));
        for (const day of days) {
            const dayLogs = day.logs;
            const marks = dayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
            const completed = dayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
            const highlights = [...dayLogs]
                .sort((a, b) => (b.marks_earned ?? 0) - (a.marks_earned ?? 0))
                .slice(0, 3)
                .map((l) => {
                const a = actMap.get(l.activity_id);
                return { name: a?.name ?? 'Activity', name_ml: a?.name_ml ?? null };
            });
            out.push({
                id: `${child.studentId}_${day.date}`,
                child_id: child.studentId,
                child_name: child.name,
                child_name_ml: child.nameMl,
                child_photo: child.photo,
                date: day.date,
                marks,
                completed,
                total: totalActivities,
                highlights,
                status: day.decision,
                decided_at: day.decidedAt,
                can_undo: day.decision === 'rejected' && !!day.decidedAt && day.decidedAt >= rejectCutoff,
            });
        }
    }
    out.sort((a, b) => (a.date < b.date ? 1 : -1));
    res.json({ success: true, data: out });
}));
/** Applies a parent decision to every log row on a child+date (P1).
 * `decision` must be 'approved' | 'rejected' | 'pending' (pending == undo). */
async function applyDecision(parentProfileId, childId, date, decision) {
    const child = await requireChild(parentProfileId, childId);
    const supabase = (0, supabase_1.getSupabaseClient)();
    const now = new Date().toISOString();
    const patch = {
        parent_decision: decision,
        decided_at: now,
        decided_by: parentProfileId,
        updated_at: now,
    };
    // Keep the legacy boolean in sync so older consumers still work.
    patch.parent_approved = decision === 'approved';
    const { data, error } = await supabase
        .from('activity_logs')
        .update(patch)
        .eq('student_id', child.studentId)
        .eq('log_date', date)
        .select('id');
    if (error)
        throw new http_error_1.HttpError(500, `Failed to ${decision}: ${error.message}`);
    return (data ?? []).length;
}
/** POST /me/approvals/:childId/:date/approve — approve all logs for a child+date. */
router.post('/me/approvals/:childId/:date/approve', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const approved = await applyDecision(req.user.profileId, req.params.childId, req.params.date, 'approved');
    res.json({ success: true, data: { approved, date: req.params.date, status: 'approved' } });
}));
/** POST /me/approvals/:childId/:date/reject — reject (P1: persists).
 * The record stays on the parent's list in a 'rejected' state for 24 hours
 * so it can be undone; after that it ages out. */
router.post('/me/approvals/:childId/:date/reject', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const rejected = await applyDecision(req.user.profileId, req.params.childId, req.params.date, 'rejected');
    res.json({ success: true, data: { rejected, date: req.params.date, status: 'rejected' } });
}));
/** POST /me/approvals/:childId/:date/send-back — undo a reject, reset to pending (P1). */
router.post('/me/approvals/:childId/:date/send-back', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const reset = await applyDecision(req.user.profileId, req.params.childId, req.params.date, 'pending');
    res.json({ success: true, data: { reset, date: req.params.date, status: 'pending' } });
}));
/** GET /me/notifications — announcements relevant to the parent's children.
 * (P2: now joins `notifications_read` so each item carries a persisted
 * `read_at` timestamp and an `unread` flag.) */
router.get('/me/notifications', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const children = await loadChildren(req.user.profileId);
    const childIds = children.map((c) => c.studentId);
    const batchIds = [...new Set(children.map((c) => c.batchId).filter(Boolean))];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: notifications, error } = await supabase
        .from('notifications')
        .select('id, title, body, target_type, target_id, sent_at, created_at')
        .order('created_at', { ascending: false })
        .limit(40);
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load notifications: ${error.message}`);
    // Pull this parent's read receipts once and join in JS.
    const { data: readRows } = await supabase
        .from('notifications_read')
        .select('notification_id, read_at')
        .eq('profile_id', req.user.profileId);
    const readMap = new Map((readRows ?? []).map((r) => [r.notification_id, r.read_at]));
    const relevant = (notifications ?? []).filter((n) => {
        if (n.target_type === 'all' || !n.target_type)
            return true;
        if (n.target_type === 'batch')
            return n.target_id && batchIds.includes(n.target_id);
        if (n.target_type === 'student')
            return n.target_id && childIds.includes(n.target_id);
        if (n.target_type === 'class')
            return true;
        return false;
    });
    const data = relevant.map((n) => {
        const readAt = readMap.get(n.id) ?? null;
        return {
            id: n.id,
            title: n.title,
            body: n.body,
            target_type: n.target_type,
            created_at: n.created_at,
            sent_at: n.sent_at,
            read_at: readAt,
            unread: readAt === null,
        };
    });
    const unreadCount = data.filter((d) => d.unread).length;
    res.json({ success: true, data, unread_count: unreadCount });
}));
/** POST /me/notifications/:id/read — mark a single notification as read (P2). */
router.post('/me/notifications/:id/read', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { error } = await supabase
        .from('notifications_read')
        .upsert({ profile_id: req.user.profileId, notification_id: req.params.id, read_at: new Date().toISOString() }, { onConflict: 'profile_id,notification_id' });
    if (error)
        throw new http_error_1.HttpError(500, `Failed to mark as read: ${error.message}`);
    res.json({ success: true, data: { id: req.params.id, read: true } });
}));
/** POST /me/notifications/read-all — mark every currently-visible notification
 * as read (used by the bell's "mark all read" affordance). */
router.post('/me/notifications/read-all', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const children = await loadChildren(req.user.profileId);
    const childIds = children.map((c) => c.studentId);
    const batchIds = [...new Set(children.map((c) => c.batchId).filter(Boolean))];
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: notifications } = await supabase
        .from('notifications')
        .select('id, target_type, target_id')
        .order('created_at', { ascending: false })
        .limit(100);
    const relevantIds = (notifications ?? [])
        .filter((n) => {
        if (n.target_type === 'all' || !n.target_type)
            return true;
        if (n.target_type === 'batch')
            return n.target_id && batchIds.includes(n.target_id);
        if (n.target_type === 'student')
            return n.target_id && childIds.includes(n.target_id);
        if (n.target_type === 'class')
            return true;
        return false;
    })
        .map((n) => n.id);
    if (relevantIds.length > 0) {
        const now = new Date().toISOString();
        const rows = relevantIds.map((id) => ({
            profile_id: req.user.profileId,
            notification_id: id,
            read_at: now,
        }));
        const { error } = await supabase
            .from('notifications_read')
            .upsert(rows, { onConflict: 'profile_id,notification_id' });
        if (error)
            throw new http_error_1.HttpError(500, `Failed to mark all read: ${error.message}`);
    }
    res.json({ success: true, data: { marked: relevantIds.length } });
}));
// ===== P3: parent profile + preferences ====================================
/** Limited set of fields a parent is allowed to edit on their own profile. */
const PARENT_PROFILE_FIELDS = ['full_name', 'phone'];
/** GET /me/profile — limited self profile for the parent (FRD §4.2.6). */
router.get('/me/profile', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: profile, error } = await supabase
        .from('profiles')
        .select('id, full_name, full_name_ml, phone, role, profile_photo, google_email')
        .eq('id', req.user.profileId)
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load profile: ${error.message}`);
    if (!profile)
        throw new http_error_1.HttpError(404, 'Profile not found');
    // Resolve the auth login email (lives in auth.users, not profiles) via
    // the admin API so the parent can see and use it for sign-in.
    let authEmail = profile.google_email ?? null;
    if (!authEmail) {
        const { data: authUser } = await supabase.auth.admin.getUserById(req.user.authUserId);
        authEmail = authUser?.user?.email ?? null;
    }
    res.json({
        success: true,
        data: {
            id: profile.id,
            full_name: profile.full_name,
            full_name_ml: profile.full_name_ml ?? null,
            phone: profile.phone ?? null,
            email: authEmail,
            role: profile.role,
            profile_photo: profile.profile_photo ?? null,
        },
    });
}));
/** PUT /me/profile — edit the parent's limited profile fields (FRD §4.2.6).
 * Only `full_name` (and the legacy `phone` when provided) may be changed;
 * email comes from auth.users and is read-only here. */
router.put('/me/profile', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (req.body ?? {});
    const patch = {};
    if (typeof body.full_name === 'string' && body.full_name.trim().length > 0) {
        patch.full_name = body.full_name.trim();
    }
    if (typeof body.full_name_ml === 'string' && body.full_name_ml.trim().length > 0) {
        patch.full_name_ml = body.full_name_ml.trim();
    }
    if (typeof body.phone === 'string' && body.phone.trim().length > 0) {
        patch.phone = body.phone.trim();
    }
    // PARENT_PROFILE_FIELDS is the authoritative allow-list; silently drop
    // anything else so a stray field can't poke role/id/photo.
    const allowed = new Set(PARENT_PROFILE_FIELDS);
    allowed.add('full_name_ml');
    for (const key of Object.keys(patch)) {
        if (!allowed.has(key))
            delete patch[key];
    }
    if (Object.keys(patch).length === 0) {
        throw new http_error_1.HttpError(400, 'No editable fields provided.');
    }
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('profiles')
        .update(patch)
        .eq('id', req.user.profileId)
        .select('id, full_name, full_name_ml, phone, role, profile_photo')
        .maybeSingle();
    if (error) {
        // Phone uniqueness violation -> friendly message.
        if (error.code === '23505') {
            throw new http_error_1.HttpError(409, 'That phone number is already in use.');
        }
        throw new http_error_1.HttpError(500, `Failed to update profile: ${error.message}`);
    }
    res.json({ success: true, data });
}));
/** GET /me/preferences — notification + per-child + privacy preferences. */
router.get('/me/preferences', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: pref, error } = await supabase
        .from('parent_preferences')
        .select('*')
        .eq('parent_profile_id', req.user.profileId)
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to load preferences: ${error.message}`);
    if (!pref) {
        // Auto-provision via the trigger should have created one; if not, create
        // it now so an older parent account isn't stuck without settings.
        const { data: created, error: createErr } = await supabase
            .from('parent_preferences')
            .insert({ parent_profile_id: req.user.profileId })
            .select('*')
            .maybeSingle();
        if (createErr)
            throw new http_error_1.HttpError(500, `Failed to init preferences: ${createErr.message}`);
        res.json({ success: true, data: created });
        return;
    }
    res.json({ success: true, data: pref });
}));
/** PUT /me/preferences — update notification type toggles, weekly-report
 * per-child opt-in, and the privacy flag. */
router.put('/me/preferences', authentication_1.authenticateRequest, parentOnly, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (req.body ?? {});
    const patch = { updated_at: new Date().toISOString() };
    for (const k of ['notify_daily', 'notify_approval', 'notify_weekly', 'notify_achievement']) {
        if (typeof body[k] === 'boolean')
            patch[k] = body[k];
    }
    if (typeof body.hide_child_name_on_leaderboard === 'boolean') {
        patch.hide_child_name_on_leaderboard = body.hide_child_name_on_leaderboard;
    }
    if (Array.isArray(body.weekly_report_child_ids)) {
        // Validate that the ids belong to this parent's children.
        const children = await loadChildren(req.user.profileId);
        const mine = new Set(children.map((c) => c.studentId));
        const filtered = body.weekly_report_child_ids
            .filter((id) => typeof id === 'string' && mine.has(id));
        patch.weekly_report_child_ids = filtered;
    }
    else if (body.weekly_report_child_ids === null) {
        // null = all children (default).
        patch.weekly_report_child_ids = null;
    }
    if (Object.keys(patch).length === 1) {
        // Only updated_at — nothing to change.
        throw new http_error_1.HttpError(400, 'No preference fields provided.');
    }
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data, error } = await supabase
        .from('parent_preferences')
        .upsert({ parent_profile_id: req.user.profileId, ...patch }, { onConflict: 'parent_profile_id' })
        .select('*')
        .maybeSingle();
    if (error)
        throw new http_error_1.HttpError(500, `Failed to update preferences: ${error.message}`);
    res.json({ success: true, data });
}));
exports.default = router;
//# sourceMappingURL=parents.js.map