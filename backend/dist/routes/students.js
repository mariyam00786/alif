"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
const crypto_1 = require("crypto");
const express_1 = require("express");
const auth_1 = require("../middleware/auth");
const error_handler_1 = require("../middleware/error-handler");
const supabase_1 = require("../config/supabase");
const router = (0, express_1.Router)();
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
/** Normalises the admin panel status (active/review/archived) to the DB enum. */
function normaliseStatus(value) {
    return value === 'active' ? 'active' : 'inactive';
}
/** Normalises a date value to a plain `YYYY-MM-DD` string (DATE column). */
function normaliseDate(value) {
    if (!value || typeof value !== 'string')
        return null;
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime()))
        return null;
    return parsed.toISOString().slice(0, 10);
}
/** Resolves a batch/class reference that may be either a UUID or a name. */
async function resolveReferenceId(table, value) {
    if (!value || typeof value !== 'string' || value.trim().length === 0) {
        return null;
    }
    const trimmed = value.trim();
    if (UUID_RE.test(trimmed))
        return trimmed;
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data } = await supabase
        .from(table)
        .select('id')
        .eq('name', trimmed)
        .maybeSingle();
    return data?.id ?? null;
}
/** Shapes a joined student + profile row for API responses. */
function shapeStudent(student, profile) {
    return {
        id: student.id,
        name: profile?.full_name ?? 'Unnamed student',
        nameMl: profile?.full_name_ml ?? '',
        mobile: student.parent_phone ?? profile?.phone ?? '',
        fatherName: student.father_name ?? '',
        motherName: student.mother_name ?? '',
        dateOfBirth: student.date_of_birth ?? null,
        gender: student.gender ?? 'male',
        batchId: student.batch_id ?? null,
        classId: student.class_id ?? null,
        address: student.address ?? '',
        status: student.status ?? 'active',
        createdAt: student.created_at ?? null,
    };
}
/**
 * GET /api/students
 *
 * List all students with optional filtering
 *
 * Query params:
 * - batchId: Filter by batch
 * - classId: Filter by class
 * - status: Filter by status (active, inactive)
 * - searchTerm: Search by name or phone
 * - limit: number (default: 50)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": "student-123",
 *       "name": "Ahmed",
 *       "email": "ahmed@example.com",
 *       "phone": "+966...",
 *       "batch_id": "batch-123",
 *       "class_id": "class-123",
 *       "status": "active",
 *       "created_at": "2026-06-01T..."
 *     },
 *     ...
 *   ],
 *   "pagination": {
 *     "total": 120,
 *     "limit": 50,
 *     "offset": 0
 *   }
 * }
 * ```
 */
router.get('/', auth_1.requireAuth, (0, auth_1.requireRole)('admin', 'teacher'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId, classId, status, limit = 100, offset = 0 } = req.query;
    const supabase = (0, supabase_1.getSupabaseClient)();
    let query = supabase.from('students').select('*', { count: 'exact' });
    if (batchId)
        query = query.eq('batch_id', batchId);
    if (classId)
        query = query.eq('class_id', classId);
    if (status)
        query = query.eq('status', status);
    const { data: students, count, error, } = await query
        .order('created_at', { ascending: false })
        .range(Number(offset), Number(offset) + Number(limit) - 1);
    if (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
    const profileIds = (students ?? []).map((s) => s.profile_id);
    const { data: profiles } = profileIds.length
        ? await supabase
            .from('profiles')
            .select('id, full_name, full_name_ml, phone')
            .in('id', profileIds)
        : { data: [] };
    const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
    res.status(200).json({
        success: true,
        data: (students ?? []).map((s) => shapeStudent(s, profileMap.get(s.profile_id))),
        pagination: {
            total: count ?? (students ?? []).length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/students
 *
 * Create a new student
 *
 * Request body:
 * ```json
 * {
 *   "name": "Ahmed Ali",
 *   "email": "ahmed@example.com",
 *   "phone": "+966501234567",
 *   "batch_id": "batch-123",
 *   "class_id": "class-123",
 *   "parent_id": "parent-123"
 * }
 * ```
 *
 * Response: 201 Created
 */
router.post('/', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const body = req.body ?? {};
    const fullName = (body.full_name ?? body.name ?? '').trim();
    const rawPhone = (body.parent_phone ??
        body.phone ??
        body.mobile ??
        '')
        .toString()
        .trim();
    if (!fullName || !rawPhone) {
        return (0, error_handler_1.validationError)(res, 'full_name and parent_phone are required');
    }
    const supabase = (0, supabase_1.getSupabaseClient)();
    // The login number belongs to the guardian. Store it in the canonical
    // '+CC...' form so it matches the OTP sign-in lookup.
    const phone = rawPhone.startsWith('+') ? rawPhone : `+${rawPhone}`;
    const phoneWithoutPlus = phone.slice(1);
    const [batchId, classId] = await Promise.all([
        resolveReferenceId('batches', body.batch_id ?? body.batch),
        resolveReferenceId('classes', body.class_id ?? body.class),
    ]);
    const guardianName = (body.guardian_name ?? body.father_name ?? body.mother_name ?? '')
        .toString()
        .trim() || `${fullName}'s guardian`;
    // ----- 1. Resolve (or create) the guardian login profile for this phone.
    // One phone number is a single sign-in account. Each child is a separate
    // student linked to that guardian via parent_students, so one login can
    // hold several students.
    const { data: existingProfiles, error: lookupErr } = await supabase
        .from('profiles')
        .select('id, role')
        .in('phone', [phone, phoneWithoutPlus])
        .limit(1);
    if (lookupErr) {
        return res.status(500).json({ success: false, error: lookupErr.message });
    }
    let parentProfileId;
    // Set only when we create a brand-new guardian, so it can be rolled back.
    let createdParentAuthId = null;
    if (existingProfiles && existingProfiles.length > 0) {
        const existing = existingProfiles[0];
        parentProfileId = existing.id;
        // A pre-multi-child profile (role 'student') becomes the shared guardian
        // login. Promote it and keep its own student record visible by linking
        // it. Teacher/admin/parent profiles keep their role.
        if (existing.role === 'student') {
            await supabase
                .from('profiles')
                .update({ role: 'parent' })
                .eq('id', existing.id);
            const { data: ownStudents } = await supabase
                .from('students')
                .select('id')
                .eq('profile_id', existing.id)
                .limit(1);
            const ownStudentId = ownStudents?.[0]
                ?.id;
            if (ownStudentId) {
                await supabase.from('parent_students').upsert({
                    parent_profile_id: existing.id,
                    student_id: ownStudentId,
                    relationship: 'parent',
                }, { onConflict: 'parent_profile_id,student_id' });
            }
        }
    }
    else {
        // Brand-new phone → provision a guardian login profile.
        const guardianEmail = `parent.${Date.now()}.${Math.floor(Math.random() * 1e6)}@parents.alif.local`;
        const { data: parentAuth, error: parentAuthErr } = await supabase.auth.admin.createUser({
            email: guardianEmail,
            password: (0, crypto_1.randomUUID)(),
            email_confirm: true,
            user_metadata: { full_name: guardianName, role: 'parent' },
        });
        if (parentAuthErr || !parentAuth?.user) {
            return res.status(500).json({
                success: false,
                error: parentAuthErr?.message ?? 'Failed to create guardian identity',
            });
        }
        createdParentAuthId = parentAuth.user.id;
        const { error: parentProfileErr } = await supabase
            .from('profiles')
            .insert({
            id: parentAuth.user.id,
            phone,
            full_name: guardianName,
            role: 'parent',
        });
        if (parentProfileErr) {
            await supabase.auth.admin
                .deleteUser(parentAuth.user.id)
                .catch(() => undefined);
            return res
                .status(500)
                .json({ success: false, error: parentProfileErr.message });
        }
        parentProfileId = parentAuth.user.id;
    }
    // ----- 2. Create the child's own profile (non-login). The login phone is
    // on the guardian, so the child profile gets a unique non-numeric
    // placeholder phone that can never be used to sign in.
    const childEmail = `student.${Date.now()}.${Math.floor(Math.random() * 1e6)}@students.alif.local`;
    const { data: childAuth, error: childAuthErr } = await supabase.auth.admin.createUser({
        email: childEmail,
        password: (0, crypto_1.randomUUID)(),
        email_confirm: true,
        user_metadata: { full_name: fullName, role: 'student' },
    });
    if (childAuthErr || !childAuth?.user) {
        if (createdParentAuthId) {
            await supabase.auth.admin
                .deleteUser(createdParentAuthId)
                .catch(() => undefined);
        }
        return res.status(500).json({
            success: false,
            error: childAuthErr?.message ?? 'Failed to create student identity',
        });
    }
    const childProfileId = childAuth.user.id;
    const { error: childProfileErr } = await supabase.from('profiles').insert({
        id: childProfileId,
        phone: `student:${childProfileId}`,
        full_name: fullName,
        full_name_ml: (body.full_name_ml ?? '').toString().trim() || null,
        role: 'student',
    });
    if (childProfileErr) {
        // Deleting the auth user cascades to the orphaned profile.
        await supabase.auth.admin
            .deleteUser(childProfileId)
            .catch(() => undefined);
        if (createdParentAuthId) {
            await supabase.auth.admin
                .deleteUser(createdParentAuthId)
                .catch(() => undefined);
        }
        return res
            .status(500)
            .json({ success: false, error: childProfileErr.message });
    }
    // ----- 3. Create the student record and link it to the guardian.
    const { data: student, error: studentErr } = await supabase
        .from('students')
        .insert({
        profile_id: childProfileId,
        parent_phone: phone,
        father_name: (body.father_name ?? '').toString().trim() || null,
        mother_name: (body.mother_name ?? '').toString().trim() || null,
        date_of_birth: normaliseDate(body.date_of_birth),
        gender: body.gender === 'female' ? 'female' : 'male',
        batch_id: batchId,
        class_id: classId,
        address: (body.address ?? '').toString().trim() || null,
        status: normaliseStatus(body.status),
    })
        .select('*')
        .single();
    if (studentErr || !student) {
        await supabase.auth.admin
            .deleteUser(childProfileId)
            .catch(() => undefined);
        if (createdParentAuthId) {
            await supabase.auth.admin
                .deleteUser(createdParentAuthId)
                .catch(() => undefined);
        }
        return res.status(500).json({
            success: false,
            error: studentErr?.message ?? 'Failed to create student',
        });
    }
    const { error: linkErr } = await supabase.from('parent_students').insert({
        parent_profile_id: parentProfileId,
        student_id: student.id,
        relationship: 'parent',
    });
    if (linkErr) {
        // Deleting the child auth user cascades to its profile + student row, so
        // the add can be retried cleanly.
        await supabase.auth.admin
            .deleteUser(childProfileId)
            .catch(() => undefined);
        if (createdParentAuthId) {
            await supabase.auth.admin
                .deleteUser(createdParentAuthId)
                .catch(() => undefined);
        }
        return res
            .status(500)
            .json({ success: false, error: linkErr.message });
    }
    res.status(201).json({
        success: true,
        data: shapeStudent(student, {
            full_name: fullName,
            full_name_ml: body.full_name_ml ?? '',
            phone,
        }),
    });
}));
/**
 * GET /api/students/:studentId
 *
 * Get detailed information about a student
 *
 * Response: 200 OK
 * ```json
 * {
 *   "success": true,
 *   "data": {
 *     "id": "student-123",
 *     "name": "Ahmed",
 *     "email": "ahmed@example.com",
 *     "phone": "+966...",
 *     "batch_id": "batch-123",
 *     "class_id": "class-123",
 *     "parent_id": "parent-123",
 *     "status": "active",
 *     "created_at": "2026-06-01T...",
 *     "updated_at": "2026-06-18T..."
 *   }
 * }
 * ```
 *
 * Error: 404 Not Found
 */
router.get('/:studentId', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: student, error } = await supabase
        .from('students')
        .select('*')
        .eq('id', studentId)
        .maybeSingle();
    if (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
    if (!student) {
        return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    // A student may only view their own record; admins/teachers may view all.
    if (req.user?.role === 'student' && req.user?.id !== student.profile_id) {
        return res.status(403).json({ success: false, error: 'FORBIDDEN' });
    }
    const { data: profile } = await supabase
        .from('profiles')
        .select('id, full_name, full_name_ml, phone')
        .eq('id', student.profile_id)
        .maybeSingle();
    res.status(200).json({
        success: true,
        data: shapeStudent(student, profile),
    });
}));
/**
 * PUT /api/students/:studentId
 *
 * Update student information
 *
 * Request body: Any fields to update
 *
 * Response: 200 OK
 * Error: 404 Not Found
 */
router.put('/:studentId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const body = req.body ?? {};
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: existing, error: lookupErr } = await supabase
        .from('students')
        .select('id, profile_id')
        .eq('id', studentId)
        .maybeSingle();
    if (lookupErr) {
        return res.status(500).json({ success: false, error: lookupErr.message });
    }
    if (!existing) {
        return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    const [batchId, classId] = await Promise.all([
        resolveReferenceId('batches', body.batch_id ?? body.batch),
        resolveReferenceId('classes', body.class_id ?? body.class),
    ]);
    const contactPhone = body.parent_phone ?? body.phone ?? body.mobile;
    const fullName = body.full_name ?? body.name ?? undefined;
    const profileUpdate = {
        updated_at: new Date().toISOString(),
    };
    if (fullName !== undefined)
        profileUpdate.full_name = fullName.trim();
    if (body.full_name_ml !== undefined) {
        profileUpdate.full_name_ml = body.full_name_ml.toString().trim() || null;
    }
    // The login phone lives on the guardian profile, not the child profile, so
    // editing a student's contact number only updates the student row's
    // parent_phone (below) — never the child profile's placeholder phone.
    const { error: profileErr } = await supabase
        .from('profiles')
        .update(profileUpdate)
        .eq('id', existing.profile_id);
    if (profileErr) {
        const conflict = profileErr.code === '23505';
        return res.status(conflict ? 409 : 500).json({
            success: false,
            error: conflict
                ? 'A profile with this phone number already exists.'
                : profileErr.message,
        });
    }
    const studentUpdate = {
        updated_at: new Date().toISOString(),
    };
    if (contactPhone)
        studentUpdate.parent_phone = contactPhone.toString().trim();
    if (body.father_name !== undefined) {
        studentUpdate.father_name = body.father_name.toString().trim() || null;
    }
    if (body.mother_name !== undefined) {
        studentUpdate.mother_name = body.mother_name.toString().trim() || null;
    }
    if (body.date_of_birth !== undefined) {
        studentUpdate.date_of_birth = normaliseDate(body.date_of_birth);
    }
    if (body.gender !== undefined) {
        studentUpdate.gender = body.gender === 'female' ? 'female' : 'male';
    }
    if (body.address !== undefined) {
        studentUpdate.address = body.address.toString().trim() || null;
    }
    if (body.status !== undefined) {
        studentUpdate.status = normaliseStatus(body.status);
    }
    if (batchId !== null)
        studentUpdate.batch_id = batchId;
    if (classId !== null)
        studentUpdate.class_id = classId;
    const { data: student, error: studentErr } = await supabase
        .from('students')
        .update(studentUpdate)
        .eq('id', studentId)
        .select('*')
        .single();
    if (studentErr || !student) {
        return res.status(500).json({
            success: false,
            error: studentErr?.message ?? 'Failed to update student',
        });
    }
    const { data: profile } = await supabase
        .from('profiles')
        .select('id, full_name, full_name_ml, phone')
        .eq('id', existing.profile_id)
        .maybeSingle();
    res.status(200).json({
        success: true,
        data: shapeStudent(student, profile),
    });
}));
/**
 * DELETE /api/students/:studentId
 *
 * Delete a student (soft delete - mark as inactive)
 *
 * Response: 204 No Content
 * Error: 404 Not Found
 */
router.delete('/:studentId', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: existing, error: lookupErr } = await supabase
        .from('students')
        .select('id, profile_id')
        .eq('id', studentId)
        .maybeSingle();
    if (lookupErr) {
        return res.status(500).json({ success: false, error: lookupErr.message });
    }
    if (!existing) {
        return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    // Removing the auth user cascades to its profile and student rows
    // (profiles.id -> auth.users ON DELETE CASCADE,
    //  students.profile_id -> profiles ON DELETE CASCADE).
    const { error: deleteErr } = await supabase.auth.admin.deleteUser(existing.profile_id);
    if (deleteErr) {
        // Fall back to deleting the student row directly.
        const { error: rowErr } = await supabase
            .from('students')
            .delete()
            .eq('id', studentId);
        if (rowErr) {
            return res.status(500).json({ success: false, error: rowErr.message });
        }
    }
    res.status(204).send();
}));
/**
 * GET /api/batches/:batchId/students
 *
 * Get all students in a specific batch
 *
 * Query params:
 * - classId: Filter by class
 * - status: Filter by status
 * - limit: number (default: 100)
 * - offset: number (default: 0)
 *
 * Response: 200 OK
 */
router.get('/batch/:batchId/students', auth_1.requireAuth, (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { batchId } = req.params;
    const { classId, status = 'active', limit = 100, offset = 0 } = req.query;
    const supabase = (0, supabase_1.getSupabaseClient)();
    let query = supabase
        .from('students')
        .select('*', { count: 'exact' })
        .eq('batch_id', batchId)
        .eq('status', status);
    if (classId)
        query = query.eq('class_id', classId);
    const { data: students, count, error, } = await query.range(Number(offset), Number(offset) + Number(limit) - 1);
    if (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
    const profileIds = (students ?? []).map((s) => s.profile_id);
    const { data: profiles } = profileIds.length
        ? await supabase
            .from('profiles')
            .select('id, full_name, full_name_ml, phone')
            .in('id', profileIds)
        : { data: [] };
    const profileMap = new Map((profiles ?? []).map((p) => [p.id, p]));
    res.status(200).json({
        success: true,
        data: (students ?? []).map((s) => shapeStudent(s, profileMap.get(s.profile_id))),
        pagination: {
            total: count ?? (students ?? []).length,
            limit: Number(limit),
            offset: Number(offset),
        },
    });
}));
/**
 * POST /api/students/:studentId/assign-batch
 *
 * Assign student to a batch
 *
 * Request body:
 * ```json
 * {
 *   "batch_id": "batch-456"
 * }
 * ```
 *
 * Response: 200 OK
 */
router.post('/:studentId/assign-batch', auth_1.requireAuth, (0, auth_1.requireRole)('admin'), (0, error_handler_1.asyncHandler)(async (req, res) => {
    const { studentId } = req.params;
    const batchId = await resolveReferenceId('batches', req.body?.batch_id ?? req.body?.batch);
    if (!batchId) {
        return (0, error_handler_1.validationError)(res, 'A valid batch_id is required');
    }
    const supabase = (0, supabase_1.getSupabaseClient)();
    const { data: student, error } = await supabase
        .from('students')
        .update({ batch_id: batchId, updated_at: new Date().toISOString() })
        .eq('id', studentId)
        .select('*')
        .single();
    if (error || !student) {
        return res.status(500).json({
            success: false,
            error: error?.message ?? 'Failed to assign batch',
        });
    }
    res.status(200).json({ success: true, data: shapeStudent(student) });
}));
exports.default = router;
//# sourceMappingURL=students.js.map