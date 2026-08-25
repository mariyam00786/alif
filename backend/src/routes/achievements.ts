import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { BadgeService, LeaderboardService } from '../services/achievements/achievement-service';
import { ensureObject, getDateString } from '../utils/validation';

const router = Router();
const badgeService = new BadgeService();
const leaderboardService = new LeaderboardService();

router.get('/badges', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await badgeService.list('created_at') });
}));

/** Keeps only columns that exist on the `badges` table. */
function shapeBadgePayload(body: Record<string, unknown>): Record<string, unknown> {
  const payload: Record<string, unknown> = {};
  if (body.name !== undefined) payload.name = body.name;
  if (body.name_ml !== undefined) payload.name_ml = body.name_ml;
  if (body.description !== undefined) payload.description = body.description;
  if (body.icon !== undefined) payload.icon = body.icon;
  if (body.criteria !== undefined) payload.criteria = body.criteria;
  if (body.bonus_points !== undefined) payload.bonus_points = body.bonus_points;
  if (body.status !== undefined) payload.status = body.status === 'inactive' ? 'inactive' : 'active';
  return payload;
}

router.post('/badges', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.status(201).json({ success: true, data: await badgeService.create(shapeBadgePayload(ensureObject(req.body)), req.user) });
}));

const badgeUpdateHandler = asyncHandler(async (req: any, res: any) => {
  res.json({ success: true, data: await badgeService.updateBadge(req.params.id, shapeBadgePayload(ensureObject(req.body))) });
});

router.patch('/badges/:id', authenticateRequest, requireRoles('admin'), badgeUpdateHandler);
router.put('/badges/:id', authenticateRequest, requireRoles('admin'), badgeUpdateHandler);

router.delete('/badges/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  await badgeService.remove(req.params.id);
  res.json({ success: true });
}));

router.get('/leaderboards/weekly', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  const startDate = getDateString(req.query.startDate, 'startDate', true)!;
  const endDate = getDateString(req.query.endDate, 'endDate', true)!;

  res.json({ success: true, data: await leaderboardService.getWeeklyLeaderboard(startDate, endDate) });
}));

export default router;