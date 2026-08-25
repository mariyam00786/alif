/**
 * Student Management Endpoints
 *
 * API routes for CRUD operations on students, backed by Supabase.
 * Primarily for the admin panel, restricted to the admin role.
 *
 * A "student" spans two tables:
 *   - profiles (id = auth.users.id, full_name, full_name_ml, phone, role)
 *   - students (profile_id, parent_phone, father/mother, dob, gender,
 *               batch_id, class_id, address, status)
 *
 * Endpoints:
 * - GET    /api/students - List all students (with filters)
 * - POST   /api/students - Create new student
 * - GET    /api/students/:studentId - Get student details
 * - PUT    /api/students/:studentId - Update student
 * - DELETE /api/students/:studentId - Delete student
 * - GET    /api/students/batch/:batchId/students - Get students in batch
 * - POST   /api/students/:studentId/assign-batch - Assign student to batch
 */
declare const router: import("express-serve-static-core").Router;
export default router;
//# sourceMappingURL=students.d.ts.map