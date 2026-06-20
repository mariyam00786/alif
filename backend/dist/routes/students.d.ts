/**
 * Student Management Endpoints
 *
 * API routes for CRUD operations on students
 * Primarily for admin panel, restricted to admin role
 *
 * Endpoints:
 * - GET    /api/students - List all students (with filters)
 * - POST   /api/students - Create new student
 * - GET    /api/students/:studentId - Get student details
 * - PUT    /api/students/:studentId - Update student
 * - DELETE /api/students/:studentId - Delete student
 * - GET    /api/batches/:batchId/students - Get students in batch
 * - POST   /api/students/:studentId/assign-batch - Assign student to batch
 */
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=students.d.ts.map