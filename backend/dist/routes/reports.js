"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const report_service_1 = require("../services/reports/report-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const reportService = new report_service_1.ReportService();
router.get('/daily-summary', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const logDate = (0, validation_1.getDateString)(req.query.logDate, 'logDate', true);
    res.json({ success: true, data: await reportService.getDailySummary(logDate) });
}));
router.get('/student-progress/:studentId', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const from = (0, validation_1.getDateString)(req.query.from, 'from', true);
    const to = (0, validation_1.getDateString)(req.query.to, 'to', true);
    res.json({ success: true, data: await reportService.getStudentProgress(req.params.studentId, from, to) });
}));
exports.default = router;
//# sourceMappingURL=reports.js.map