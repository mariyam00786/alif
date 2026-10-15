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
 * - GET  /badges                        Catalogue of awardable badges
 * - GET  /student/:id/badges            Badges already awarded to a student
 * - POST /student/:id/badge             Award a badge to a student
 * - GET  /batch/:id/attendance?date=    Students + attendance status for a day
 * - POST /batch/:id/attendance          Upsert attendance for a day
 */
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=teacher-portal.d.ts.map