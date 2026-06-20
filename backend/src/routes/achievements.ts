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

router.post('/badges', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.status(201).json({ success: true, data: await badgeService.create(ensureObject(req.body), req.user) });
}));

router.patch('/badges/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.json({ success: true, data: await badgeService.update(req.params.id, ensureObject(req.body), req.user) });
}));

router.get('/leaderboards/weekly', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  const startDate = getDateString(req.query.startDate, 'startDate', true)!;
  const endDate = getDateString(req.query.endDate, 'endDate', true)!;

  res.json({ success: true, data: await leaderboardService.getWeeklyLeaderboard(startDate, endDate) });
}));

export default router;