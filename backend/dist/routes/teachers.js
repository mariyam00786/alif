"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const teacher_service_1 = require("../services/teachers/teacher-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const teacherService = new teacher_service_1.TeacherService();
router.get('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await teacherService.list('created_at') });
}));
router.get('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({ success: true, data: await teacherService.getById(req.params.id) });
}));
router.post('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    res.status(201).json({ success: true, data: await teacherService.create(body, req.user) });
}));
router.patch('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    res.json({ success: true, data: await teacherService.update(req.params.id, body, req.user) });
}));
exports.default = router;
//# sourceMappingURL=teachers.js.map