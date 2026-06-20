import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { TeacherService } from '../services/teachers/teacher-service';
import { ensureObject } from '../utils/validation';

const router = Router();
const teacherService = new TeacherService();

router.get('/', authenticateRequest, requireRoles('admin'), asyncHandler(async (_req, res) => {
  res.json({ success: true, data: await teacherService.list('created_at') });
}));

router.get('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  res.json({ success: true, data: await teacherService.getById(req.params.id) });
}));

router.post('/', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  res.status(201).json({ success: true, data: await teacherService.create(body, req.user) });
}));

router.patch('/:id', authenticateRequest, requireRoles('admin'), asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  res.json({ success: true, data: await teacherService.update(req.params.id, body, req.user) });
}));

export default router;