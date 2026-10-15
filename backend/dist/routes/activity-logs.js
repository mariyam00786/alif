"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const activity_log_service_1 = require("../services/activity-logging/activity-log-service");
const supabase_1 = require("../config/supabase");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const activityLogService = new activity_log_service_1.ActivityLogService();
/**
 * Resolve the students.id row owned by the authenticated student so a student
 * can log their own activities without knowing their internal id.
 *
 * Some student accounts exist only as a `profiles` row (e.g. created through the
 * phone/OTP login flow) without a matching `students` record. Such a student can
 * sign in but previously could not save any marks ("Student profile not found").
 * To keep self-marking working for every authenticated student, a minimal
 * `students` row is provisioned on demand when one does not yet exist.
 */
async function resolveOwnStudentId(profileId, phone) {
    try {
        const supabase = (0, supabase_1.getSupabaseClient)();
        const { data, error } = await supabase
            .from('students')
            .select('id')
            .eq('profile_id', profileId)
            .maybeSingle();
        if (!error && data) {
            return data.id;
        }
        const { data: created, error: insertError } = await supabase
            .from('students')
            .insert({
            profile_id: profileId,
            parent_phone: phone && phone.trim() ? phone.trim() : 'unknown',
        })
            .select('id')
            .single();
        if (!insertError && created) {
            return created.id;
        }
    }
    catch (_) { }
    return profileId;
}
router.get('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    // A student may only read their own logs; the server resolves their internal
    // student id so they never have to (and cannot) request someone else's.
    const studentId = req.user.role === 'student'
        ? await resolveOwnStudentId(req.user.profileId, req.user.phone)
        : (typeof req.query.studentId === 'string' ? req.query.studentId : undefined);
    res.json({
        success: true,
        data: await activityLogService.list({
            studentId,
            from: typeof req.query.from === 'string' ? req.query.from : undefined,
            to: typeof req.query.to === 'string' ? req.query.to : undefined,
        }),
    });
}));
router.post('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    // A student always logs against their own record; everyone else must say who.
    const studentId = req.user.role === 'student'
        ? await resolveOwnStudentId(req.user.profileId, req.user.phone)
        : (0, validation_1.getRequiredString)(body.studentId, 'studentId');
    const activityLog = await activityLogService.upsert({
        studentId,
        activityId: (0, validation_1.getRequiredString)(body.activityId ?? body.activity_id, 'activityId'),
        logDate: (0, validation_1.getDateString)(body.logDate ?? body.log_date, 'logDate', true),
        quantity: (0, validation_1.getOptionalInteger)(body.quantity, 'quantity'),
        ratingId: (0, validation_1.getOptionalString)(body.ratingId ?? body.rating_id, 'ratingId'),
        parentApproved: (0, validation_1.getOptionalBoolean)(body.parentApproved ?? body.parent_approved, 'parentApproved'),
        notes: (0, validation_1.getOptionalString)(body.notes, 'notes'),
    }, req.user);
    res.status(201).json({ success: true, data: activityLog });
}));
exports.default = router;
//# sourceMappingURL=activity-logs.js.map