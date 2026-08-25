import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { BatchService, ClassService } from '../services/academics/academic-service';
import { ensureObject } from '../utils/validation';

const router = Router();
const batchService = new BatchService();
const classService = new ClassService();

router.get('/batches', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await batchService.list('created_at') });
}));

router.post('/batches', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.status(201).json({ success: true, data: await batchService.create(ensureObject(req.body), req.user) });
}));

router.patch('/batches/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.json({ success: true, data: await batchService.update(req.params.id, ensureObject(req.body), req.user) });
}));

router.get('/classes', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await classService.list('created_at') });
}));

router.post('/classes', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.status(201).json({ success: true, data: await classService.create(ensureObject(req.body), req.user) });
}));

router.patch('/classes/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.json({ success: true, data: await classService.update(req.params.id, ensureObject(req.body), req.user) });
}));

export default router;