import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { ActivityLogService } from '../services/activity-logging/activity-log-service';
import { ensureObject, getDateString, getOptionalBoolean, getOptionalInteger, getOptionalString, getRequiredString } from '../utils/validation';

const router = Router();
const activityLogService = new ActivityLogService();

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
  const activityLog = await activityLogService.upsert({
    studentId: getRequiredString(body.studentId, 'studentId'),
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