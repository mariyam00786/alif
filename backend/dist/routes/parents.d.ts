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
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=parents.d.ts.map