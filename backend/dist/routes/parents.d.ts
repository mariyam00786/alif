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
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=parents.d.ts.map