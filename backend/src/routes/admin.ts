import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { requireAuth } from '../middleware/auth';
import { requireRoles } from '../middleware/authorization';
import { ensureObject, getEnumValue, getRequiredString } from '../utils/validation';
import { AdminDashboardService } from '../services/admin/admin-dashboard-service';
import { getSenderStatus } from '../services/msghex/msghex-service';

const router = Router();
const adminDashboardService = new AdminDashboardService();

router.get('/overview', requireAuth, requireRoles('admin'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await adminDashboardService.getSnapshot() });
}));

router.get('/whatsapp-status', requireAuth, requireRoles('admin'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await getSenderStatus() });
}));

router.patch('/batches/:id/teacher', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  await adminDashboardService.assignTeacherToBatch(req.params.id, getRequiredString(body.teacherId, 'teacherId'), req.user);
  res.json({ success: true });
}));

router.patch('/rating-rules/:id/primary', requireAuth, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  await adminDashboardService.setPrimaryRule(
    req.params.id,
    getEnumValue(body.ruleKind, 'ruleKind', ['rating', 'scoring'] as const, true)!,
    req.user,
  );
  res.json({ success: true });
}));

export default router;