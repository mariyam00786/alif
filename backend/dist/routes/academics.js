"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const academic_service_1 = require("../services/academics/academic-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const batchService = new academic_service_1.BatchService();
const classService = new academic_service_1.ClassService();
router.get('/batches', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await batchService.list('created_at') });
}));
router.post('/batches', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.status(201).json({ success: true, data: await batchService.create((0, validation_1.ensureObject)(req.body), req.user) });
}));
router.patch('/batches/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({ success: true, data: await batchService.update(req.params.id, (0, validation_1.ensureObject)(req.body), req.user) });
}));
router.get('/classes', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await classService.list('created_at') });
}));
router.post('/classes', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.status(201).json({ success: true, data: await classService.create((0, validation_1.ensureObject)(req.body), req.user) });
}));
router.patch('/classes/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({ success: true, data: await classService.update(req.params.id, (0, validation_1.ensureObject)(req.body), req.user) });
}));
exports.default = router;
//# sourceMappingURL=academics.js.map