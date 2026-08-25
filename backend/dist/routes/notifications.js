"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const notification_service_1 = require("../services/notifications/notification-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const notificationService = new notification_service_1.NotificationService();
router.get('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await notificationService.list() });
}));
router.post('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const notification = await notificationService.create({
        title: (0, validation_1.getRequiredString)(body.title, 'title'),
        body: (0, validation_1.getOptionalString)(body.body, 'body'),
        target_type: (0, validation_1.getEnumValue)(body.target_type, 'target_type', ['all', 'batch', 'class', 'student'], true),
        target_id: (0, validation_1.getOptionalString)(body.target_id, 'target_id'),
        deviceToken: (0, validation_1.getOptionalString)(body.deviceToken, 'deviceToken'),
        topic: (0, validation_1.getOptionalString)(body.topic, 'topic'),
    }, req.user);
    res.status(201).json({ success: true, data: notification });
}));
router.patch('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    res.json({ success: true, data: await notificationService.update(req.params.id, body, req.user) });
}));
exports.default = router;
//# sourceMappingURL=notifications.js.map