"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const activity_log_service_1 = require("../services/activity-logging/activity-log-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const activityLogService = new activity_log_service_1.ActivityLogService();
router.get('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({
        success: true,
        data: await activityLogService.list({
            studentId: typeof req.query.studentId === 'string' ? req.query.studentId : undefined,
            from: typeof req.query.from === 'string' ? req.query.from : undefined,
            to: typeof req.query.to === 'string' ? req.query.to : undefined,
        }),
    });
}));
router.post('/', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const activityLog = await activityLogService.upsert({
        studentId: (0, validation_1.getRequiredString)(body.studentId, 'studentId'),
        activityId: (0, validation_1.getRequiredString)(body.activityId, 'activityId'),
        logDate: (0, validation_1.getDateString)(body.logDate, 'logDate', true),
        quantity: (0, validation_1.getOptionalInteger)(body.quantity, 'quantity'),
        ratingId: (0, validation_1.getOptionalString)(body.ratingId, 'ratingId'),
        parentApproved: (0, validation_1.getOptionalBoolean)(body.parentApproved, 'parentApproved'),
        notes: (0, validation_1.getOptionalString)(body.notes, 'notes'),
    }, req.user);
    res.status(201).json({ success: true, data: activityLog });
}));
exports.default = router;
//# sourceMappingURL=activity-logs.js.map