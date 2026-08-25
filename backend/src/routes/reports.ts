import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { requireRoles } from '../middleware/authorization';
import { ReportService } from '../services/reports/report-service';
import { getDateString } from '../utils/validation';

const router = Router();
const reportService = new ReportService();

router.get('/daily-summary', authenticateRequest, requireRoles('admin', 'teacher'), asyncHandler(async (req, res) => {
  const logDate = getDateString(req.query.logDate, 'logDate', true)!;
  res.json({ success: true, data: await reportService.getDailySummary(logDate) });
}));

router.get('/student-progress/:studentId', authenticateRequest, requireRoles('admin', 'teacher', 'parent', 'student'), asyncHandler(async (req, res) => {
  const from = getDateString(req.query.from, 'from', true)!;
  const to = getDateString(req.query.to, 'to', true)!;

  res.json({ success: true, data: await reportService.getStudentProgress(req.params.studentId, from, to) });
}));

export default router;