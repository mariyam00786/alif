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
/**
 * Derives the DB `target_type` enum from either an explicit `target_type` field
 * or the admin panel's composed `audience` display string
 * (e.g. "Batch · Morning", "Class · 5A", "Student · Ali", "Parents · All").
 */
function resolveTargetType(body) {
    const explicit = (0, validation_1.getOptionalString)(body.target_type, 'target_type');
    if (explicit && ['all', 'batch', 'class', 'student'].includes(explicit)) {
        return explicit;
    }
    const audience = ((0, validation_1.getOptionalString)(body.audience, 'audience') ?? '').toLowerCase();
    if (audience.startsWith('batch'))
        return 'batch';
    if (audience.startsWith('class'))
        return 'class';
    if (audience.startsWith('student'))
        return 'student';
    return 'all';
}
/** Maps the admin panel campaign status to scheduled_at / sent_at timestamps. */
function resolveTimestamps(body) {
    const status = ((0, validation_1.getOptionalString)(body.status, 'status') ?? '').toLowerCase();
    const now = new Date().toISOString();
    if (status === 'sent')
        return { scheduled_at: null, sent_at: now };
    if (status === 'scheduled')
        return { scheduled_at: now, sent_at: null };
    return { scheduled_at: null, sent_at: null };
}
router.get('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await notificationService.list() });
}));
router.post('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const { scheduled_at, sent_at } = resolveTimestamps(body);
    const notification = await notificationService.create({
        title: (0, validation_1.getRequiredString)(body.title, 'title'),
        body: (0, validation_1.getOptionalString)(body.body, 'body') ?? (0, validation_1.getOptionalString)(body.message, 'message'),
        target_type: resolveTargetType(body),
        target_id: (0, validation_1.getOptionalString)(body.target_id, 'target_id'),
        scheduled_at,
        sent_at,
        deviceToken: (0, validation_1.getOptionalString)(body.deviceToken, 'deviceToken'),
        topic: (0, validation_1.getOptionalString)(body.topic, 'topic'),
    }, req.user);
    res.status(201).json({ success: true, data: notification });
}));
const updateHandler = (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const { scheduled_at, sent_at } = resolveTimestamps(body);
    const payload = {
        title: (0, validation_1.getRequiredString)(body.title, 'title'),
        body: (0, validation_1.getOptionalString)(body.body, 'body') ?? (0, validation_1.getOptionalString)(body.message, 'message') ?? null,
        target_type: resolveTargetType(body),
        target_id: (0, validation_1.getOptionalString)(body.target_id, 'target_id') ?? null,
        scheduled_at,
        sent_at,
    };
    res.json({ success: true, data: await notificationService.update(req.params.id, payload, req.user) });
});
router.patch('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), updateHandler);
router.put('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher'), updateHandler);
router.delete('/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    await notificationService.remove(req.params.id, req.user);
    res.json({ success: true });
}));
exports.default = router;
//# sourceMappingURL=notifications.js.map