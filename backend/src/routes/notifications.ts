import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { NotificationService } from '../services/notifications/notification-service';
import { ensureObject, getOptionalString, getRequiredString } from '../utils/validation';

const router = Router();
const notificationService = new NotificationService();

type TargetType = 'all' | 'batch' | 'class' | 'student';

/**
 * Derives the DB `target_type` enum from either an explicit `target_type` field
 * or the admin panel's composed `audience` display string
 * (e.g. "Batch · Morning", "Class · 5A", "Student · Ali", "Parents · All").
 */
function resolveTargetType(body: Record<string, unknown>): TargetType {
  const explicit = getOptionalString(body.target_type, 'target_type');
  if (explicit && ['all', 'batch', 'class', 'student'].includes(explicit)) {
    return explicit as TargetType;
  }
  const audience = (getOptionalString(body.audience, 'audience') ?? '').toLowerCase();
  if (audience.startsWith('batch')) return 'batch';
  if (audience.startsWith('class')) return 'class';
  if (audience.startsWith('student')) return 'student';
  return 'all';
}

/** Maps the admin panel campaign status to scheduled_at / sent_at timestamps. */
function resolveTimestamps(body: Record<string, unknown>): { scheduled_at: string | null; sent_at: string | null } {
  const status = (getOptionalString(body.status, 'status') ?? '').toLowerCase();
  const now = new Date().toISOString();
  if (status === 'sent') return { scheduled_at: null, sent_at: now };
  if (status === 'scheduled') return { scheduled_at: now, sent_at: null };
  return { scheduled_at: null, sent_at: null };
}

router.get('/', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await notificationService.list() });
}));

router.post('/', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const { scheduled_at, sent_at } = resolveTimestamps(body);
  const notification = await notificationService.create({
    title: getRequiredString(body.title, 'title'),
    body: getOptionalString(body.body, 'body') ?? getOptionalString(body.message, 'message'),
    target_type: resolveTargetType(body),
    target_id: getOptionalString(body.target_id, 'target_id'),
    scheduled_at,
    sent_at,
    deviceToken: getOptionalString(body.deviceToken, 'deviceToken'),
    topic: getOptionalString(body.topic, 'topic'),
  }, req.user!);

  res.status(201).json({ success: true, data: notification });
}));

const updateHandler = asyncHandler(async (req: any, res: any) => {
  const body = ensureObject(req.body);
  const { scheduled_at, sent_at } = resolveTimestamps(body);
  const payload: Record<string, unknown> = {
    title: getRequiredString(body.title, 'title'),
    body: getOptionalString(body.body, 'body') ?? getOptionalString(body.message, 'message') ?? null,
    target_type: resolveTargetType(body),
    target_id: getOptionalString(body.target_id, 'target_id') ?? null,
    scheduled_at,
    sent_at,
  };
  res.json({ success: true, data: await notificationService.update(req.params.id, payload, req.user) });
});

router.patch('/:id', authenticateRequest, requireRoles('admin', 'teacher'), updateHandler);
router.put('/:id', authenticateRequest, requireRoles('admin', 'teacher'), updateHandler);

router.delete('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  await notificationService.remove(req.params.id, req.user);
  res.json({ success: true });
}));

export default router;