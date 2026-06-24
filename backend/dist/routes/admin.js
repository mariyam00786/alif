"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const auth_1 = require("../middleware/auth");
const authorization_1 = require("../middleware/authorization");
const validation_1 = require("../utils/validation");
const admin_dashboard_service_1 = require("../services/admin/admin-dashboard-service");
const msghex_service_1 = require("../services/msghex/msghex-service");
const router = (0, express_1.Router)();
const adminDashboardService = new admin_dashboard_service_1.AdminDashboardService();
router.get('/overview', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await adminDashboardService.getSnapshot() });
}));
router.get('/whatsapp-status', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await (0, msghex_service_1.getSenderStatus)() });
}));
router.patch('/batches/:id/teacher', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    await adminDashboardService.assignTeacherToBatch(req.params.id, (0, validation_1.getRequiredString)(body.teacherId, 'teacherId'), req.user);
    res.json({ success: true });
}));
router.patch('/rating-rules/:id/primary', auth_1.requireAuth, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    await adminDashboardService.setPrimaryRule(req.params.id, (0, validation_1.getEnumValue)(body.ruleKind, 'ruleKind', ['rating', 'scoring'], true), req.user);
    res.json({ success: true });
}));
exports.default = router;
//# sourceMappingURL=admin.js.map