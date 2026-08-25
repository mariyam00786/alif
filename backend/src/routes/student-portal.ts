/**
 * Student Self-Service Portal Endpoints
 *
 * Live data routes powering the mobile student portal. Every query is scoped
 * to the authenticated student's own profile id (req.user.profileId -> the
 * students row whose profile_id matches), so a student can only ever read
 * their own progress, leaderboard position and badges.
 *
 * Mounted at /api/students:
 * - GET /me/home-summary  -> { today_done, today_total, streak_days,
 *                             week_points, batch_rank, batch_name }
 * - GET /me/leaderboard   -> { daily[], weekly[], monthly[], all_time[] }
 * - GET /me/badges        -> { badges[] }
 *
 * A profile that has no students row yet (e.g. a freshly self-registered
 * account not yet enrolled by an admin) receives a graceful empty/zero
 * payload instead of an error, so the home screen still renders.
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

/** Array of YYYY-MM-DD strings ending at `end`, going back `count` days. */
function lastNDates(end: string, count: number): string[] {
  const out: string[] = [];
  for (let i = count - 1; i >= 0; i -= 1) out.push(shiftDate(end, -i));
  return out;
}

// ===== Self student resolution =====

interface SelfStudent {
  studentId: string;
  profileId: string;
  name: string;
  batchId: string | null;
  batchName: string | null;
}

/** Resolves the authenticated caller's own student row (or null if none). */
async function resolveSelfStudent(profileId: string): Promise<SelfStudent | null> {
  const supabase = getSupabaseClient();

  const { data: student, error } = await supabase
    .from('students')
    .select('id, profile_id, batch_id, status')
    .eq('profile_id', profileId)
    .maybeSingle();
  if (error) throw new HttpError(500, `Failed to load student: ${error.message}`);
  if (!student) return null;

  const [{ data: profile }, batchRes] = await Promise.all([
    supabase.from('profiles').select('full_name').eq('id', profileId).maybeSingle(),
    student.batch_id
      ? supabase.from('batches').select('name').eq('id', student.batch_id).maybeSingle()
      : Promise.resolve({ data: null } as { data: { name?: string } | null }),
  ]);

  return {
    studentId: student.id as string,
    profileId,
    name: (profile as { full_name?: string } | null)?.full_name ?? 'Student',
    batchId: (student.batch_id as string | null) ?? null,
    batchName: (batchRes.data as { name?: string } | null)?.name ?? null,
  };
}

/** Count of active activities (denominator for "today" completion). */
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
  student_id: string;
}

/** Loads a student's logs between two dates (inclusive). */
async function loadLogs(studentId: string, fromDate: string, toDate: string): Promise<LogRow[]> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('activity_logs')
    .select('log_date, marks_earned, student_id')
    .eq('student_id', studentId)
    .gte('log_date', fromDate)
    .lte('log_date', toDate);
  if (error) throw new HttpError(500, `Failed to load activity logs: ${error.message}`);
  return (data ?? []) as LogRow[];
}

/** Consecutive days (ending today or yesterday) with any marks earned. */
function computeStreak(logs: LogRow[], today: string): number {
  const daysWithMarks = new Set(
    logs.filter((l) => (l.marks_earned ?? 0) > 0).map((l) => l.log_date)
  );
  let streak = 0;
  let cursor = today;
  if (!daysWithMarks.has(cursor)) cursor = shiftDate(cursor, -1);
  while (daysWithMarks.has(cursor)) {
    streak += 1;
    cursor = shiftDate(cursor, -1);
  }
  return streak;
}

/** Ranks the student within its batch by all-time total marks. */
async function computeRank(self: SelfStudent): Promise<number> {
  if (!self.batchId) return 0;
  const supabase = getSupabaseClient();

  const { data: peers, error: peerErr } = await supabase
    .from('students')
    .select('id')
    .eq('batch_id', self.batchId)
    .eq('status', 'active');
  if (peerErr) throw new HttpError(500, `Failed to load batch peers: ${peerErr.message}`);

  const peerIds = (peers ?? []).map((p: { id: string }) => p.id);
  if (peerIds.length === 0) return 0;

  const { data: logs, error: logErr } = await supabase
    .from('activity_logs')
    .select('student_id, marks_earned')
    .in('student_id', peerIds);
  if (logErr) throw new HttpError(500, `Failed to load batch logs: ${logErr.message}`);

  const totals = new Map<string, number>();
  for (const id of peerIds) totals.set(id, 0);
  for (const log of logs ?? []) {
    totals.set(
      log.student_id as string,
      (totals.get(log.student_id as string) ?? 0) + ((log.marks_earned as number) ?? 0)
    );
  }

  const ranked = [...totals.entries()].sort((a, b) => b[1] - a[1]);
  const rank = ranked.findIndex(([id]) => id === self.studentId) + 1;
  return rank > 0 ? rank : peerIds.length;
}

// Self routes: role is 'student' (a dual parent/student account is 'student'
// in the student view). Admin is allowed for support/testing.
const studentSelf = requireRoles('student', 'admin');

/**
 * GET /me/home-summary
 * Today's completion, streak, week points and batch rank for the caller.
 */
router.get(
  '/me/home-summary',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const totalActivities = await activeActivityCount();
    const self = await resolveSelfStudent(req.user!.profileId);

    if (!self) {
      res.json({
        success: true,
        data: {
          today_done: 0,
          today_total: totalActivities,
          streak_days: 0,
          week_points: 0,
          batch_rank: 0,
          batch_name: null,
        },
      });
      return;
    }

    const today = todayUtc();
    const monthDates = lastNDates(today, 30);
    const logs = await loadLogs(self.studentId, monthDates[0], today);

    const todayDone = logs.filter(
      (l) => l.log_date === today && (l.marks_earned ?? 0) > 0
    ).length;

    const weekDates = new Set(lastNDates(today, 7));
    const weekPoints = logs
      .filter((l) => weekDates.has(l.log_date))
      .reduce((s, l) => s + (l.marks_earned ?? 0), 0);

    const [streak, rank] = [computeStreak(logs, today), await computeRank(self)];

    res.json({
      success: true,
      data: {
        today_done: todayDone,
        today_total: totalActivities,
        streak_days: streak,
        week_points: weekPoints,
        batch_rank: rank,
        batch_name: self.batchName,
      },
    });
  })
);

/**
 * GET /me/leaderboard
 * Batch leaderboard for the caller across daily / weekly / monthly / all-time.
 */
router.get(
  '/me/leaderboard',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const empty = { daily: [], weekly: [], monthly: [], all_time: [] };
    const self = await resolveSelfStudent(req.user!.profileId);
    if (!self || !self.batchId) {
      res.json({ success: true, data: empty });
      return;
    }

    const supabase = getSupabaseClient();
    const { data: peers, error: peerErr } = await supabase
      .from('students')
      .select('id, profile_id')
      .eq('batch_id', self.batchId)
      .eq('status', 'active');
    if (peerErr) throw new HttpError(500, `Failed to load peers: ${peerErr.message}`);

    const peerList = (peers ?? []) as Array<{ id: string; profile_id: string }>;
    const peerIds = peerList.map((p) => p.id);
    if (peerIds.length === 0) {
      res.json({ success: true, data: empty });
      return;
    }

    const profileIds = peerList.map((p) => p.profile_id);
    const [{ data: logs }, { data: profiles }] = await Promise.all([
      supabase
        .from('activity_logs')
        .select('student_id, marks_earned, log_date')
        .in('student_id', peerIds),
      supabase.from('profiles').select('id, full_name').in('id', profileIds),
    ]);

    const nameByStudent = new Map<string, string>();
    for (const p of peerList) {
      const prof = (profiles ?? []).find((pr: { id: string }) => pr.id === p.profile_id) as
        | { full_name?: string }
        | undefined;
      nameByStudent.set(p.id, prof?.full_name ?? 'Student');
    }

    const today = todayUtc();
    const weekStart = shiftDate(today, -6);
    const monthStart = shiftDate(today, -29);
    const inRange = {
      daily: (d: string) => d === today,
      weekly: (d: string) => d >= weekStart,
      monthly: (d: string) => d >= monthStart,
      all_time: () => true,
    };

    const allLogs = (logs ?? []) as LogRow[];
    const build = (filter: (d: string) => boolean) => {
      const marks = new Map<string, number>();
      const acts = new Map<string, number>();
      for (const id of peerIds) {
        marks.set(id, 0);
        acts.set(id, 0);
      }
      for (const log of allLogs) {
        if (!filter(log.log_date)) continue;
        const m = log.marks_earned ?? 0;
        marks.set(log.student_id, (marks.get(log.student_id) ?? 0) + m);
        if (m > 0) acts.set(log.student_id, (acts.get(log.student_id) ?? 0) + 1);
      }
      return [...marks.entries()]
        .sort((a, b) => b[1] - a[1])
        .map(([id, m], idx) => {
          const name = nameByStudent.get(id) ?? 'Student';
          return {
            rank: idx + 1,
            name,
            marks: m,
            activities: acts.get(id) ?? 0,
            avatar: name.trim().length > 0 ? name.trim()[0].toUpperCase() : '?',
            me: id === self.studentId,
            trend: 'flat',
          };
        });
    };

    res.json({
      success: true,
      data: {
        daily: build(inRange.daily),
        weekly: build(inRange.weekly),
        monthly: build(inRange.monthly),
        all_time: build(inRange.all_time),
      },
    });
  })
);

/**
 * GET /me/badges
 * All active badges with an `earned` flag for the caller.
 */
router.get(
  '/me/badges',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const self = await resolveSelfStudent(req.user!.profileId);

    const { data: allBadges, error: badgeErr } = await supabase
      .from('badges')
      .select('id, name, name_ml, description, icon')
      .eq('status', 'active')
      .order('created_at');
    if (badgeErr) throw new HttpError(500, `Failed to load badges: ${badgeErr.message}`);

    const earnedMap = new Map<string, string>();
    if (self) {
      const { data: earned, error: earnedErr } = await supabase
        .from('student_badges')
        .select('badge_id, earned_at')
        .eq('student_id', self.studentId);
      if (earnedErr) throw new HttpError(500, `Failed to load earned badges: ${earnedErr.message}`);
      for (const e of earned ?? []) {
        earnedMap.set(e.badge_id as string, e.earned_at as string);
      }
    }

    const badges = (allBadges ?? []).map(
      (b: {
        id: string;
        name: string;
        name_ml: string | null;
        description: string | null;
        icon: string | null;
      }) => ({
        icon: b.icon ?? '🏅',
        name: b.name,
        name_ml: b.name_ml ?? b.name,
        description: b.description ?? '',
        description_ml: b.description ?? '',
        earned: earnedMap.has(b.id),
        earned_at: earnedMap.get(b.id) ?? null,
      })
    );

    res.json({ success: true, data: { badges } });
  })
);

export default router;
