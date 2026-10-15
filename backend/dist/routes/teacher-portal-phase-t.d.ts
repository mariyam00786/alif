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
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=teacher-portal-phase-t.d.ts.map