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
 */
async function resolveOwnStudentId(profileId: string): Promise<string> {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('students')
    .select('id')
    .eq('profile_id', profileId)
    .maybeSingle();
  if (error) {
    throw new Error(error.message);
  }
  if (!data) {
    throw new Error('Student profile not found');
  }
  return (data as { id: string }).id;
}

router.get('/', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: await activityLogService.list({
      studentId: typeof req.query.studentId === 'string' ? req.query.studentId : undefined,
      from: typeof req.query.from === 'string' ? req.query.from : undefined,
      to: typeof req.query.to === 'string' ? req.query.to : undefined,
    }),
  });
}));

router.post('/', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);

  // A student always logs against their own record; everyone else must say who.
  const studentId = req.user!.role === 'student'
    ? await resolveOwnStudentId(req.user!.profileId)
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