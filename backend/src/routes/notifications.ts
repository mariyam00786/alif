import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { NotificationService } from '../services/notifications/notification-service';
import { ensureObject, getEnumValue, getOptionalString, getRequiredString } from '../utils/validation';

const router = Router();
const notificationService = new NotificationService();

router.get('/', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await notificationService.list() });
}));

router.post('/', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const notification = await notificationService.create({
    title: getRequiredString(body.title, 'title'),
    body: getOptionalString(body.body, 'body'),
    target_type: getEnumValue(body.target_type, 'target_type', ['all', 'batch', 'class', 'student'] as const, true)!,
    target_id: getOptionalString(body.target_id, 'target_id'),
    deviceToken: getOptionalString(body.deviceToken, 'deviceToken'),
    topic: getOptionalString(body.topic, 'topic'),
  }, req.user!);

  res.status(201).json({ success: true, data: notification });
}));

router.patch('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  res.json({ success: true, data: await notificationService.update(req.params.id, body, req.user) });
}));

export default router;