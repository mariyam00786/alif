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
 * - GET  /me/children/:childId/leaderboard?period=daily|weekly
 * - GET  /me/approvals
 * - POST /me/approvals/:childId/:date/approve
 * - POST /me/approvals/:childId/:date/reject
 * - GET  /me/notifications
 */

import { Router, Request, Response } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { HttpError } from '../errors/http-error';
import { getSupabaseClient } from '../config/supabase';

const router = Router();

// ===== Date helpers (UTC, aligned with seeded log_date) =====

function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

function shiftDate(dateStr: string, days: number): string {
  const d = new Date(`${dateStr}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Returns an array of YYYY-MM-DD strings ending at `end` going back `count` days (inclusive). */
function lastNDates(end: string, count: number): string[] {
  const out: string[] = [];
  for (let i = count - 1; i >= 0; i -= 1) {
    out.push(shiftDate(end, -i));
  }
  return out;
}

function pct(part: number, whole: number): number {
  if (whole <= 0) return 0;
  return Math.min(100, Math.round((part / whole) * 100));
}

// ===== Shared data helpers =====

interface ChildRow {
  studentId: string;
  profileId: string;
  name: string;
  nameMl: string | null;
  photo: string | null;
  batchId: string | null;
  batchName: string | null;
  batchNameMl: string | null;
  status: string;
}

/** Loads the authenticated parent's children (with profile + batch joined). */
async function loadChildren(parentProfileId: string): Promise<ChildRow[]> {
  const supabase = getSupabaseClient();

  const { data: links, error: linkErr } = await supabase
    .from('parent_students')
    .select('student_id')
    .eq('parent_profile_id', parentProfileId);
  if (linkErr) throw new HttpError(500, `Failed to load children: ${linkErr.message}`);

  const studentIds = (links ?? []).map((l: any) => l.student_id);
  if (studentIds.length === 0) return [];

  const { data: students, error: stuErr } = await supabase
    .from('students')
    .select('id, profile_id, batch_id, status')
    .in('id', studentIds);
  if (stuErr) throw new HttpError(500, `Failed to load students: ${stuErr.message}`);

  const profileIds = (students ?? []).map((s: any) => s.profile_id);
  const batchIds = (students ?? []).map((s: any) => s.batch_id).filter(Boolean);

  const [{ data: profiles }, { data: batches }] = await Promise.all([
    supabase.from('profiles').select('id, full_name, full_name_ml, profile_photo').in('id', profileIds),
    batchIds.length
      ? supabase.from('batches').select('id, name, name_ml').in('id', batchIds)
      : Promise.resolve({ data: [] as any[] } as any),
  ]);

  const profileMap = new Map((profiles ?? []).map((p: any) => [p.id, p]));
  const batchMap = new Map((batches ?? []).map((b: any) => [b.id, b]));

  return (students ?? []).map((s: any) => {
    const p: any = profileMap.get(s.profile_id);
    const b: any = s.batch_id ? batchMap.get(s.batch_id) : null;
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
async function requireChild(parentProfileId: string, childId: string): Promise<ChildRow> {
  const children = await loadChildren(parentProfileId);
  const child = children.find((c) => c.studentId === childId);
  if (!child) throw new HttpError(403, 'This student is not linked to your account.');
  return child;
}

/** Count of active activities (denominator for completion %). */
async function activeActivityCount(): Promise<number> {
  const supabase = getSupabaseClient();
  const { count, error } = await supabase
    .from('activities')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'active');
  if (error) throw new HttpError(500, `Failed to count activities: ${error.message}`);
  return count ?? 0;
}

interface LogRow {
  log_date: string;
  marks_earned: number;
  activity_id: string;
  parent_approved: boolean;
}

/** Loads logs for a student between two dates (inclusive). */
async function loadLogs(studentId: string, fromDate: string, toDate: string): Promise<LogRow[]> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('activity_logs')
    .select('log_date, marks_earned, activity_id, parent_approved')
    .eq('student_id', studentId)
    .gte('log_date', fromDate)
    .lte('log_date', toDate);
  if (error) throw new HttpError(500, `Failed to load activity logs: ${error.message}`);
  return (data ?? []) as LogRow[];
}

/** Daily completion % averaged over a window of dates (missing days count as 0). */
function windowCompletion(logs: LogRow[], dates: string[], totalActivities: number): { marks: number; avgPct: number } {
  const byDate = new Map<string, { marks: number; completed: number }>();
  for (const d of dates) byDate.set(d, { marks: 0, completed: 0 });
  for (const log of logs) {
    const bucket = byDate.get(log.log_date);
    if (!bucket) continue;
    bucket.marks += log.marks_earned ?? 0;
    if ((log.marks_earned ?? 0) > 0) bucket.completed += 1;
  }
  let totalMarks = 0;
  let pctSum = 0;
  for (const d of dates) {
    const bucket = byDate.get(d)!;
    totalMarks += bucket.marks;
    pctSum += pct(bucket.completed, totalActivities);
  }
  return { marks: totalMarks, avgPct: dates.length ? Math.round(pctSum / dates.length) : 0 };
}

/** Builds the summary metrics for a single child. */
async function childSummary(child: ChildRow, totalActivities: number) {
  const supabase = getSupabaseClient();
  const today = todayUtc();
  const monthDates = lastNDates(today, 30);
  const logs = await loadLogs(child.studentId, monthDates[0], today);

  const todayLogs = logs.filter((l) => l.log_date === today);
  const todayMarks = todayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);
  const todayCompleted = todayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;

  const week = windowCompletion(logs, lastNDates(today, 7), totalActivities);
  const month = windowCompletion(logs, monthDates, totalActivities);

  const pending = logs.filter((l) => !l.parent_approved).length;

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
async function computeRank(child: ChildRow): Promise<{ rank: number; batchSize: number }> {
  if (!child.batchId) return { rank: 1, batchSize: 1 };
  const supabase = getSupabaseClient();

  const { data: peers, error: peerErr } = await supabase
    .from('students')
    .select('id')
    .eq('batch_id', child.batchId)
    .eq('status', 'active');
  if (peerErr) throw new HttpError(500, `Failed to load batch peers: ${peerErr.message}`);

  const peerIds = (peers ?? []).map((p: any) => p.id);
  if (peerIds.length === 0) return { rank: 1, batchSize: 1 };

  const { data: logs, error: logErr } = await supabase
    .from('activity_logs')
    .select('student_id, marks_earned')
    .in('student_id', peerIds);
  if (logErr) throw new HttpError(500, `Failed to load batch logs: ${logErr.message}`);

  const totals = new Map<string, number>();
  for (const id of peerIds) totals.set(id, 0);
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
const parentOnly = requireRoles('parent', 'admin', 'student');

/** GET /me/children — overview dashboard data. */
router.get(
  '/me/children',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const children = await loadChildren(req.user!.profileId);
    const totalActivities = await activeActivityCount();
    const summaries = await Promise.all(children.map((c) => childSummary(c, totalActivities)));
    res.json({ success: true, data: summaries });
  })
);

/** GET /me/children/:childId — single child summary. */
router.get(
  '/me/children/:childId',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const child = await requireChild(req.user!.profileId, req.params.childId);
    const totalActivities = await activeActivityCount();
    res.json({ success: true, data: await childSummary(child, totalActivities) });
  })
);

/** GET /me/children/:childId/progress?period=daily|weekly|monthly */
router.get(
  '/me/children/:childId/progress',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const child = await requireChild(req.user!.profileId, req.params.childId);
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
    const supabase = getSupabaseClient();
    const activityIds = [...new Set(logs.map((l) => l.activity_id))];
    let breakdown: Array<{ category: string; category_ml: string | null; marks: number }> = [];
    if (activityIds.length > 0) {
      const { data: acts } = await supabase
        .from('activities')
        .select('id, category_id')
        .in('id', activityIds);
      const catIds = [...new Set((acts ?? []).map((a: any) => a.category_id))];
      const { data: cats } = catIds.length
        ? await supabase.from('activity_categories').select('id, name, name_ml').in('id', catIds)
        : { data: [] as any[] };
      const actCat = new Map((acts ?? []).map((a: any) => [a.id, a.category_id]));
      const catMap = new Map((cats ?? []).map((c: any) => [c.id, c]));
      const marksByCat = new Map<string, number>();
      for (const log of logs) {
        const catId = actCat.get(log.activity_id);
        if (!catId) continue;
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
  })
);

/** GET /me/children/:childId/badges */
router.get(
  '/me/children/:childId/badges',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const child = await requireChild(req.user!.profileId, req.params.childId);
    const supabase = getSupabaseClient();

    const [{ data: allBadges, error: badgeErr }, { data: earned, error: earnedErr }] = await Promise.all([
      supabase.from('badges').select('id, name, name_ml, description, icon').eq('status', 'active').order('created_at'),
      supabase.from('student_badges').select('badge_id, earned_at').eq('student_id', child.studentId),
    ]);
    if (badgeErr) throw new HttpError(500, `Failed to load badges: ${badgeErr.message}`);
    if (earnedErr) throw new HttpError(500, `Failed to load earned badges: ${earnedErr.message}`);

    const earnedMap = new Map((earned ?? []).map((e: any) => [e.badge_id, e.earned_at]));
    const badges = (allBadges ?? []).map((b: any) => ({
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
  })
);

/** GET /me/children/:childId/leaderboard?period=daily|weekly */
router.get(
  '/me/children/:childId/leaderboard',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const child = await requireChild(req.user!.profileId, req.params.childId);
    const period = String(req.query.period ?? 'weekly');
    const supabase = getSupabaseClient();

    if (!child.batchId) {
      res.json({ success: true, data: { period, entries: [] } });
      return;
    }

    const { data: peers, error: peerErr } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('batch_id', child.batchId)
      .eq('status', 'active');
    if (peerErr) throw new HttpError(500, `Failed to load peers: ${peerErr.message}`);

    const peerIds = (peers ?? []).map((p: any) => p.id);
    const profileIds = (peers ?? []).map((p: any) => p.profile_id);
    if (peerIds.length === 0) {
      res.json({ success: true, data: { period, entries: [] } });
      return;
    }

    const today = todayUtc();
    const fromDate = period === 'daily' ? today : shiftDate(today, -6);

    const [{ data: logs }, { data: profiles }] = await Promise.all([
      supabase
        .from('activity_logs')
        .select('student_id, marks_earned')
        .in('student_id', peerIds)
        .gte('log_date', fromDate)
        .lte('log_date', today),
      supabase.from('profiles').select('id, full_name, full_name_ml, profile_photo').in('id', profileIds),
    ]);

    const profileByStudent = new Map(
      (peers ?? []).map((p: any) => [p.id, (profiles ?? []).find((pr: any) => pr.id === p.profile_id)])
    );

    const totals = new Map<string, number>();
    for (const id of peerIds) totals.set(id, 0);
    for (const log of logs ?? []) {
      totals.set(log.student_id, (totals.get(log.student_id) ?? 0) + (log.marks_earned ?? 0));
    }

    const entries = [...totals.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([studentId, marks], idx) => {
        const prof = profileByStudent.get(studentId);
        return {
          rank: idx + 1,
          student_id: studentId,
          name: prof?.full_name ?? 'Student',
          name_ml: prof?.full_name_ml ?? null,
          photo: prof?.profile_photo ?? null,
          marks,
          is_self: studentId === child.studentId,
        };
      });

    res.json({ success: true, data: { period, entries } });
  })
);

/** GET /me/approvals — pending daily approvals across all children. */
router.get(
  '/me/approvals',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const children = await loadChildren(req.user!.profileId);
    const totalActivities = await activeActivityCount();
    const supabase = getSupabaseClient();
    const out: any[] = [];

    for (const child of children) {
      const { data: logs, error } = await supabase
        .from('activity_logs')
        .select('log_date, marks_earned, activity_id, parent_approved')
        .eq('student_id', child.studentId)
        .eq('parent_approved', false)
        .order('log_date', { ascending: false });
      if (error) throw new HttpError(500, `Failed to load approvals: ${error.message}`);

      // Group unapproved logs by date.
      const byDate = new Map<string, LogRow[]>();
      for (const log of (logs ?? []) as LogRow[]) {
        if (!byDate.has(log.log_date)) byDate.set(log.log_date, []);
        byDate.get(log.log_date)!.push(log);
      }

      // Most recent 7 pending days per child.
      const dates = [...byDate.keys()].sort((a, b) => (a < b ? 1 : -1)).slice(0, 7);

      // Resolve activity names for highlights.
      const allActivityIds = [...new Set((logs ?? []).map((l: any) => l.activity_id))];
      const { data: acts } = allActivityIds.length
        ? await supabase.from('activities').select('id, name, name_ml').in('id', allActivityIds)
        : { data: [] as any[] };
      const actMap = new Map((acts ?? []).map((a: any) => [a.id, a]));

      for (const date of dates) {
        const dayLogs = byDate.get(date)!;
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
          id: `${child.studentId}_${date}`,
          child_id: child.studentId,
          child_name: child.name,
          child_name_ml: child.nameMl,
          child_photo: child.photo,
          date,
          marks,
          completed,
          total: totalActivities,
          highlights,
        });
      }
    }

    out.sort((a, b) => (a.date < b.date ? 1 : -1));
    res.json({ success: true, data: out });
  })
);

/** POST /me/approvals/:childId/:date/approve — approve all logs for a child+date. */
router.post(
  '/me/approvals/:childId/:date/approve',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const child = await requireChild(req.user!.profileId, req.params.childId);
    const date = req.params.date;
    const supabase = getSupabaseClient();

    const { data, error } = await supabase
      .from('activity_logs')
      .update({ parent_approved: true, updated_at: new Date().toISOString() })
      .eq('student_id', child.studentId)
      .eq('log_date', date)
      .select('id');
    if (error) throw new HttpError(500, `Failed to approve: ${error.message}`);

    res.json({ success: true, data: { approved: (data ?? []).length, date } });
  })
);

/** POST /me/approvals/:childId/:date/reject — send a day back (acknowledged, stays pending). */
router.post(
  '/me/approvals/:childId/:date/reject',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    await requireChild(req.user!.profileId, req.params.childId);
    // No schema flag for "sent back"; record stays unapproved and is removed
    // from the parent's pending list client-side after acknowledgement.
    res.json({ success: true, data: { date: req.params.date, status: 'sent_back' } });
  })
);

/** GET /me/notifications — announcements relevant to the parent's children. */
router.get(
  '/me/notifications',
  authenticateRequest,
  parentOnly,
  asyncHandler(async (req: Request, res: Response) => {
    const children = await loadChildren(req.user!.profileId);
    const childIds = children.map((c) => c.studentId);
    const batchIds = [...new Set(children.map((c) => c.batchId).filter(Boolean) as string[])];
    const supabase = getSupabaseClient();

    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('id, title, body, target_type, target_id, sent_at, created_at')
      .order('created_at', { ascending: false })
      .limit(40);
    if (error) throw new HttpError(500, `Failed to load notifications: ${error.message}`);

    const relevant = (notifications ?? []).filter((n: any) => {
      if (n.target_type === 'all' || !n.target_type) return true;
      if (n.target_type === 'batch') return n.target_id && batchIds.includes(n.target_id);
      if (n.target_type === 'student') return n.target_id && childIds.includes(n.target_id);
      if (n.target_type === 'class') return true;
      return false;
    });

    res.json({
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

export default router;
