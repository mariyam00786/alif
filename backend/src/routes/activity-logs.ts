import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { ActivityLogService } from '../services/activity-logging/activity-log-service';
import { getSupabaseClient } from '../config/supabase';
import { ensureObject, getDateString, getOptionalBoolean, getOptionalInteger, getOptionalString, getRequiredString } from '../utils/validation';

const router = Router();
const activityLogService = new ActivityLogService();

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
async function resolveOwnStudentId(profileId: string, phone?: string): Promise<string> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('students')
    .select('id')
    .eq('profile_id', profileId)
    .maybeSingle();
  if (error) {
    throw new Error(error.message);
  }
  if (data) {
    return (data as { id: string }).id;
  }

  // No students row yet — provision a minimal one linked to this profile.
  // parent_phone is NOT NULL, so fall back to the student's own phone.
  const { data: created, error: insertError } = await supabase
    .from('students')
    .insert({
      profile_id: profileId,
      parent_phone: phone && phone.trim() ? phone.trim() : 'unknown',
    })
    .select('id')
    .single();
  if (insertError || !created) {
    throw new Error(insertError?.message ?? 'Could not provision student record');
  }
  return (created as { id: string }).id;
}

router.get('/', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  // A student may only read their own logs; the server resolves their internal
  // student id so they never have to (and cannot) request someone else's.
  const studentId = req.user!.role === 'student'
    ? await resolveOwnStudentId(req.user!.profileId, req.user!.phone)
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

router.post('/', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);

  // A student always logs against their own record; everyone else must say who.
  const studentId = req.user!.role === 'student'
    ? await resolveOwnStudentId(req.user!.profileId, req.user!.phone)
    : getRequiredString(body.studentId, 'studentId');

  const activityLog = await activityLogService.upsert({
    studentId,
    activityId: getRequiredString(body.activityId, 'activityId'),
    logDate: getDateString(body.logDate, 'logDate', true)!,
    quantity: getOptionalInteger(body.quantity, 'quantity'),
    ratingId: getOptionalString(body.ratingId, 'ratingId'),
    parentApproved: getOptionalBoolean(body.parentApproved, 'parentApproved'),
    notes: getOptionalString(body.notes, 'notes'),
  }, req.user!);

  res.status(201).json({ success: true, data: activityLog });
}));

export default router;