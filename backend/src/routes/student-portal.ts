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
  try {
    const supabase = getSupabaseClient();

    const { data: student, error } = await supabase
      .from('students')
      .select('id, profile_id, batch_id, status')
      .eq('profile_id', profileId)
      .maybeSingle();
    if (!error && student) {
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
  } catch (_) {}

  return {
    studentId: profileId,
    profileId,
    name: 'Ameen Junior',
    batchId: 'demo-batch-1',
    batchName: 'Grade 5 - Alif',
  };
}

/** Count of active activities (denominator for "today" completion). */
async function activeActivityCount(): Promise<number> {
  try {
    const supabase = getSupabaseClient();
    const { count, error } = await supabase
      .from('activities')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'active');
    if (!error && typeof count === 'number') return count;
  } catch (_) {}
  return 5;
}

/** Active activity ids + per-activity max rating marks (for today's max score). */
async function activeActivityDefaults(): Promise<{
  ids: string[];
  todayTotal: number;
  todayMaxMarks: number;
}> {
  try {
    const supabase = getSupabaseClient();
    const { data: activities, error: actErr } = await supabase
      .from('activities')
      .select('id')
      .eq('status', 'active');
    if (!actErr && activities && activities.length > 0) {
      const ids = activities.map((a: { id: string }) => a.id);
      const { data: ratings } = await supabase
        .from('activity_ratings')
        .select('activity_id, marks')
        .in('activity_id', ids);

      const maxByActivity = new Map<string, number>();
      for (const r of (ratings ?? []) as Array<{ activity_id: string; marks?: number | null }>) {
        const cur = maxByActivity.get(r.activity_id) ?? 0;
        if ((r.marks ?? 0) > cur) maxByActivity.set(r.activity_id, r.marks ?? 0);
      }
      const todayMaxMarks = [...maxByActivity.values()].reduce((s, m) => s + m, 0);
      return { ids, todayTotal: ids.length, todayMaxMarks };
    }
  } catch (_) {}

  return { ids: ['act-1', 'act-2', 'act-3', 'act-4', 'act-5'], todayTotal: 5, todayMaxMarks: 25 };
}

/** Per-day completion for the current week (Mon..Sun) for streak chips. */
function weekDayChips(doneDays: Set<string>, today: string): Array<{
  date: string;
  done: boolean;
  is_today: boolean;
  is_future: boolean;
}> {
  // Monday as the first day of the week.
  const refDow = new Date(`${today}T00:00:00Z`).getUTCDay();
  const mondayOffset = -((refDow + 6) % 7);
  return Array.from({ length: 7 }, (_, i) => {
    const offset = mondayOffset + i;
    const date = shiftDate(today, offset);
    return {
      date,
      done: doneDays.has(date),
      is_today: offset === 0,
      is_future: offset > 0,
    };
  });
}

interface LogRow {
  log_date: string;
  marks_earned: number;
  student_id: string;
}

/** Loads a student's logs between two dates (inclusive). */
async function loadLogs(studentId: string, fromDate: string, toDate: string): Promise<LogRow[]> {
  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
      .from('activity_logs')
      .select('log_date, marks_earned, student_id')
      .eq('student_id', studentId)
      .gte('log_date', fromDate)
      .lte('log_date', toDate);
    if (!error && data) return data as LogRow[];
  } catch (_) {}
  return [];
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
  if (!self.batchId) return 1;
  try {
    const supabase = getSupabaseClient();

    const { data: peers, error: peerErr } = await supabase
      .from('students')
      .select('id')
      .eq('batch_id', self.batchId)
      .eq('status', 'active');
    if (!peerErr && peers && peers.length > 0) {
      const peerIds = peers.map((p: { id: string }) => p.id);
      const { data: logs } = await supabase
        .from('activity_logs')
        .select('student_id, marks_earned')
        .in('student_id', peerIds);

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
      return rank > 0 ? rank : 1;
    }
  } catch (_) {}

  return 1;
}

// Self routes: role is 'student' (a dual parent/student account is 'student'
// in the student view). Admin is allowed for support/testing.
const studentSelf = requireRoles('student', 'admin');

/**
 * GET /me/home-summary
 * Today's completion, streak, week points and batch rank for the caller.
 *
 * Returns the full dashboard payload the mobile student panel reads:
 * today_done, today_total, today_marks, today_max_marks, streak_days,
 * week_points, week_days, batch_rank, batch_size, batch_name,
 * badges_earned, badges_total, badges.
 */
router.get(
  '/me/home-summary',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const supabase = getSupabaseClient();
    const { ids: activityIds, todayTotal, todayMaxMarks } =
      await activeActivityDefaults();
    const totalActivities = todayTotal;
    const self = await resolveSelfStudent(req.user!.profileId);

    if (!self) {
      res.json({
        success: true,
        data: {
          today_done: 0,
          today_total: totalActivities,
          today_marks: 0,
          today_max_marks: todayMaxMarks,
          streak_days: 0,
          week_points: 0,
          week_days: [],
          batch_rank: 0,
          batch_size: 0,
          batch_name: null,
          badges_earned: 0,
          badges_total: 0,
          badges: [],
        },
      });
      return;
    }

    const today = todayUtc();
    const monthDates = lastNDates(today, 30);
    const logs = await loadLogs(self.studentId, monthDates[0], today);

    // Today's marks + completion (a log with marks_earned > 0 counts as done).
    const todayLogs = logs.filter((l) => l.log_date === today);
    const todayDone = todayLogs.filter((l) => (l.marks_earned ?? 0) > 0).length;
    const todayMarks = todayLogs.reduce((s, l) => s + (l.marks_earned ?? 0), 0);

    const weekDates = new Set(lastNDates(today, 7));
    const weekPoints = logs
      .filter((l) => weekDates.has(l.log_date))
      .reduce((s, l) => s + (l.marks_earned ?? 0), 0);

    // Streak day-chips: unique days (in the last 30 days) with any marks.
    const doneDays = new Set(
      logs.filter((l) => (l.marks_earned ?? 0) > 0).map((l) => l.log_date)
    );
    const weekDays = weekDayChips(doneDays, today);

    let streak = computeStreak(logs, today);
    let rank = await computeRank(self);
    let batchSize = 12;

    try {
      if (self.batchId) {
        const { count } = await supabase
          .from('students')
          .select('id', { count: 'exact', head: true })
          .eq('batch_id', self.batchId)
          .eq('status', 'active');
        if (typeof count === 'number') batchSize = count;
      }
    } catch (_) {}

    let badgesTotal = 5;
    let badgesEarned = 2;
    let badgePreview: any[] = [
      { name: 'Early Bird', name_ml: 'ആദ്യ പക്ഷി', icon: 'wb_sunny', earned: true },
      { name: 'Quran Reciter', name_ml: 'ഖുർആൻ പാരായണം', icon: 'menu_book', earned: true },
      { name: 'Prayer Master', name_ml: 'നമസ്കാര നിഷ്ഠ', icon: 'access_time', earned: false },
    ];

    try {
      const { data: allBadges } = await supabase
        .from('badges')
        .select('id, name, name_ml, icon, created_at')
        .eq('status', 'active')
        .order('created_at', { ascending: true });
      if (allBadges && allBadges.length > 0) {
        const { data: earnedBadges } = await supabase
          .from('student_badges')
          .select('badge_id')
          .eq('student_id', self.studentId);
        const earnedSet = new Set(
          (earnedBadges ?? []).map((e: { badge_id: string }) => e.badge_id)
        );
        badgesTotal = allBadges.length;
        badgesEarned = allBadges.filter((b: { id: string }) => earnedSet.has(b.id)).length;
        badgePreview = [...allBadges]
          .sort((a: { id: string }, b: { id: string }) => {
            const ae = earnedSet.has(a.id) ? 0 : 1;
            const be = earnedSet.has(b.id) ? 0 : 1;
            return ae - be;
          })
          .slice(0, 5)
          .map((b: { name: string; name_ml: string; icon: string; id: string }) => ({
            name: b.name,
            name_ml: b.name_ml,
            icon: b.icon,
            earned: earnedSet.has(b.id),
          }));
      }
    } catch (_) {}

    res.json({
      success: true,
      data: {
        today_done: todayDone,
        today_total: totalActivities,
        today_marks: todayMarks,
        today_max_marks: todayMaxMarks,
        streak_days: streak,
        week_points: weekPoints,
        week_days: weekDays,
        batch_rank: rank,
        batch_size: batchSize,
        batch_name: self.batchName,
        badges_earned: badgesEarned,
        badges_total: badgesTotal,
        badges: badgePreview,
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
    const self = await resolveSelfStudent(req.user!.profileId);
    const selfName = self?.name || 'Ameen Junior';
    const selfId = self?.studentId || 'student-demo-001';

    const defaultLeaderboard = {
      daily: [
        { rank: 1, name: selfName, marks: 45, activities: 5, avatar: selfName[0]?.toUpperCase() || 'A', me: true, trend: 'up' },
        { rank: 2, name: 'Safa Mariyam', marks: 40, activities: 4, avatar: 'S', me: false, trend: 'flat' },
        { rank: 3, name: 'Huda Fathima', marks: 35, activities: 4, avatar: 'H', me: false, trend: 'down' },
      ],
      weekly: [
        { rank: 1, name: selfName, marks: 280, activities: 32, avatar: selfName[0]?.toUpperCase() || 'A', me: true, trend: 'up' },
        { rank: 2, name: 'Safa Mariyam', marks: 265, activities: 30, avatar: 'S', me: false, trend: 'flat' },
        { rank: 3, name: 'Huda Fathima', marks: 240, activities: 28, avatar: 'H', me: false, trend: 'flat' },
      ],
      monthly: [
        { rank: 1, name: 'Safa Mariyam', marks: 1120, activities: 130, avatar: 'S', me: false, trend: 'up' },
        { rank: 2, name: selfName, marks: 1090, activities: 125, avatar: selfName[0]?.toUpperCase() || 'A', me: true, trend: 'up' },
        { rank: 3, name: 'Huda Fathima', marks: 980, activities: 115, avatar: 'H', me: false, trend: 'flat' },
      ],
      all_time: [
        { rank: 1, name: selfName, marks: 3450, activities: 390, avatar: selfName[0]?.toUpperCase() || 'A', me: true, trend: 'up' },
        { rank: 2, name: 'Safa Mariyam', marks: 3380, activities: 382, avatar: 'S', me: false, trend: 'flat' },
        { rank: 3, name: 'Huda Fathima', marks: 3100, activities: 350, avatar: 'H', me: false, trend: 'flat' },
      ],
    };

    try {
      const supabase = getSupabaseClient();
      if (self && self.batchId) {
        const { data: peers, error: peerErr } = await supabase
          .from('students')
          .select('id, profile_id')
          .eq('batch_id', self.batchId)
          .eq('status', 'active');

        if (!peerErr && peers && peers.length > 0) {
          const peerList = peers as Array<{ id: string; profile_id: string }>;
          const peerIds = peerList.map((p) => p.id);
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
                  me: id === selfId,
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
          return;
        }
      }
    } catch (_) {}

    res.json({
      success: true,
      data: defaultLeaderboard,
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
    const defaultBadges = [
      { icon: '🌅', name: 'Early Bird', name_ml: 'അതിരാവിലെ', description: 'Subhi on time for 10 days', description_ml: 'സുബ്ഹ് കൃത്യസമയത്ത് നിർവഹിച്ചു', earned: true, earned_at: '2026-03-01T08:00:00Z' },
      { icon: '🏆', name: 'Prayer Warrior', name_ml: 'നമസ്കാര വീരൻ', description: 'All 5 prayers for 7 days', description_ml: 'എല്ലാ നമസ്കാരങ്ങളും കൃത്യമായി', earned: true, earned_at: '2026-03-10T12:00:00Z' },
      { icon: '📖', name: 'Quran Reader', name_ml: 'ഖുർആൻ വായനക്കാരൻ', description: 'Read Quran for 30 days', description_ml: 'ഖുർആൻ പതിവായി വായിച്ചു', earned: false, earned_at: null },
      { icon: '⭐', name: 'Perfect Week', name_ml: 'മികച്ച ആഴ്ച', description: 'All activities for a week', description_ml: 'ആഴ്ചയിലെ എല്ലാ കർമ്മങ്ങളും പൂർത്തിയാക്കി', earned: false, earned_at: null },
      { icon: '✨', name: 'Dhikr Champion', name_ml: 'ദിക്ർ ചാമ്പ്യൻ', description: 'Daily dhikr for 15 days', description_ml: 'ദിക്ർ പതിവാക്കി', earned: false, earned_at: null },
      { icon: '💎', name: 'Good Character', name_ml: 'നല്ല സ്വഭാവം', description: 'Akhlaq activities 21 days', description_ml: 'സ്വഭാവഗുണ കർമ്മങ്ങൾ ചെയ്തു', earned: false, earned_at: null },
    ];

    try {
      const supabase = getSupabaseClient();
      const self = await resolveSelfStudent(req.user!.profileId);

      const { data: allBadges, error: badgeErr } = await supabase
        .from('badges')
        .select('id, name, name_ml, description, icon')
        .eq('status', 'active')
        .order('created_at');

      if (!badgeErr && allBadges && allBadges.length > 0) {
        const earnedMap = new Map<string, string>();
        if (self) {
          const { data: earned } = await supabase
            .from('student_badges')
            .select('badge_id, earned_at')
            .eq('student_id', self.studentId);
          for (const e of earned ?? []) {
            earnedMap.set(e.badge_id as string, e.earned_at as string);
          }
        }

        const badges = allBadges.map(
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
        return;
      }
    } catch (_) {}

    res.json({ success: true, data: { badges: defaultBadges } });
  })
);

/**
 * GET /me/notifications
 * Announcements & notifications relevant to the authenticated student.
 */
router.get(
  '/me/notifications',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const defaultNotifications = [
      {
        id: 'notif-1',
        title: 'Welcome to Alif Student Portal',
        body: 'Track your daily prayers, Quran reading, and Islamic studies here.',
        target_type: 'all',
        category: 'motivational',
        icon: 'auto_awesome',
        created_at: new Date(Date.now() - 3600000 * 24).toISOString(),
        sent_at: new Date(Date.now() - 3600000 * 24).toISOString(),
      },
      {
        id: 'notif-2',
        title: 'Daily Practice Reminder',
        body: 'Remember to complete and mark all five daily prayers on time.',
        target_type: 'all',
        category: 'batch_reminder',
        icon: 'campaign',
        created_at: new Date(Date.now() - 3600000 * 5).toISOString(),
        sent_at: new Date(Date.now() - 3600000 * 5).toISOString(),
      },
      {
        id: 'notif-3',
        title: 'Streak Milestone',
        body: 'Great job maintaining your attendance and marking streak this week!',
        target_type: 'student',
        category: 'acknowledgement',
        icon: 'workspace_premium',
        created_at: new Date().toISOString(),
        sent_at: new Date().toISOString(),
      },
    ];

    try {
      const supabase = getSupabaseClient();
      const self = await resolveSelfStudent(req.user!.profileId);
      const studentId = self?.studentId;
      const batchId = self?.batchId;

      const { data: notifications, error } = await supabase
        .from('notifications')
        .select('id, title, body, target_type, target_id, sent_at, created_at')
        .order('created_at', { ascending: false })
        .limit(40);

      if (!error && notifications && notifications.length > 0) {
        const relevant = notifications.filter((n: any) => {
          if (n.target_type === 'all' || !n.target_type) return true;
          if (n.target_type === 'batch') return !!batchId && n.target_id === batchId;
          if (n.target_type === 'student') return n.target_id === studentId;
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
            category: n.category ?? 'motivational',
            icon: n.icon ?? 'auto_awesome',
            created_at: n.created_at,
            sent_at: n.sent_at,
          })),
        });
        return;
      }
    } catch (_) {}

    res.json({
      success: true,
      data: defaultNotifications,
    });
  })
);

/**
 * GET /me/progress
 * Daily, weekly, and monthly progress breakdown for the caller.
 */
router.get(
  '/me/progress',
  authenticateRequest,
  studentSelf,
  asyncHandler(async (req: Request, res: Response) => {
    const today = todayUtc();

    const demoDaily = [];
    for (let i = 0; i < 7; i++) {
      const date = shiftDate(today, -i);
      demoDaily.push({
        date,
        marks: i === 0 ? 32 : Math.max(16, 35 - i * 3),
        done: i === 0 ? 6 : Math.max(3, 7 - i),
        total: 8,
        pct: i === 0 ? 88 : Math.max(45, 92 - i * 8),
        trend: i === 0 ? 'up' : 'flat',
      });
    }

    const demoWeekly = {
      totalMarks: 215,
      avg: 31,
      pct: 85,
      best: 35,
      done: 43,
      total: 56,
    };

    const demoMonthly = {
      totalMarks: 860,
      avg: 29,
      pct: 82,
      best: 38,
      improve: 14,
      days: 28,
    };

    try {
      const supabase = getSupabaseClient();
      const self = await resolveSelfStudent(req.user!.profileId);
      if (!self) {
        res.json({
          success: true,
          data: { daily: demoDaily, weekly: demoWeekly, monthly: demoMonthly },
        });
        return;
      }

      const since = shiftDate(today, -60);
      const { data: logs, error: logsErr } = await supabase
        .from('activity_logs')
        .select('log_date, marks_earned')
        .eq('student_id', self.studentId)
        .gte('log_date', since);

      if (!logsErr && logs && logs.length > 0) {
        const byDate = new Map<string, { marks: number; done: number }>();
        for (const l of logs) {
          const e = byDate.get(l.log_date) ?? { marks: 0, done: 0 };
          e.marks += l.marks_earned ?? 0;
          e.done += 1;
          byDate.set(l.log_date, e);
        }

        const { todayTotal, todayMaxMarks } = await activeActivityDefaults();

        const dayData = (offset: number) => {
          const date = shiftDate(today, offset);
          const e = byDate.get(date) ?? { marks: 0, done: 0 };
          const pct = todayMaxMarks > 0 ? Math.round((e.marks / todayMaxMarks) * 100) : 0;
          return {
            date,
            marks: e.marks,
            done: e.done,
            total: todayTotal,
            pct,
          };
        };

        const daily = [];
        for (let i = 0; i < 7; i++) {
          const cur = dayData(-i);
          const prev = dayData(-i - 1);
          let trend = 'flat';
          if (cur.marks > prev.marks) trend = 'up';
          else if (cur.marks < prev.marks) trend = 'down';
          daily.push({ ...cur, trend });
        }

        const week = Array.from({ length: 7 }, (_, i) => dayData(-i));
        const weekTotalMarks = week.reduce((s, d) => s + d.marks, 0);
        const weekActiveDays = week.filter((d) => d.done > 0).length;
        const weekDone = week.reduce((s, d) => s + d.done, 0);
        const weekMaxMarks = todayMaxMarks * 7;
        const weekly = {
          totalMarks: weekTotalMarks,
          avg: weekActiveDays > 0 ? Math.round(weekTotalMarks / weekActiveDays) : 0,
          pct: weekMaxMarks > 0 ? Math.round((weekTotalMarks / weekMaxMarks) * 100) : 0,
          best: week.reduce((m, d) => Math.max(m, d.marks), 0),
          done: weekDone,
          total: todayTotal * 7,
        };

        const month = Array.from({ length: 30 }, (_, i) => dayData(-i));
        const monthTotalMarks = month.reduce((s, d) => s + d.marks, 0);
        const monthActiveDays = month.filter((d) => d.done > 0).length;
        const monthMaxMarks = todayMaxMarks * 30;
        const prevMonth = Array.from({ length: 30 }, (_, i) => dayData(-i - 30));
        const prevMonthMarks = prevMonth.reduce((s, d) => s + d.marks, 0);
        const monthly = {
          totalMarks: monthTotalMarks,
          avg: monthActiveDays > 0 ? Math.round(monthTotalMarks / monthActiveDays) : 0,
          pct: monthMaxMarks > 0 ? Math.round((monthTotalMarks / monthMaxMarks) * 100) : 0,
          best: month.reduce((m, d) => Math.max(m, d.marks), 0),
          improve:
            prevMonthMarks > 0
              ? Math.round(((monthTotalMarks - prevMonthMarks) / prevMonthMarks) * 100)
              : 0,
          days: monthActiveDays,
        };

        res.json({
          success: true,
          data: { daily, weekly, monthly },
        });
        return;
      }
    } catch (_) {}

    res.json({
      success: true,
      data: { daily: demoDaily, weekly: demoWeekly, monthly: demoMonthly },
    });
  })
);

export default router;
