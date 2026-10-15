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
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=student-portal.d.ts.map