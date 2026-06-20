"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const authorization_1 = require("../middleware/authorization");
const achievement_service_1 = require("../services/achievements/achievement-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const badgeService = new achievement_service_1.BadgeService();
const leaderboardService = new achievement_service_1.LeaderboardService();
router.get('/badges', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ success: true, data: await badgeService.list('created_at') });
}));
router.post('/badges', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.status(201).json({ success: true, data: await badgeService.create((0, validation_1.ensureObject)(req.body), req.user) });
}));
router.patch('/badges/:id', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({ success: true, data: await badgeService.update(req.params.id, (0, validation_1.ensureObject)(req.body), req.user) });
}));
router.get('/leaderboards/weekly', authentication_1.authenticateRequest, (0, authorization_1.requireRoles)('admin', 'teacher', 'parent', 'student'), (0, async_handler_1.asyncHandler)(async (req, res) => {
    const startDate = (0, validation_1.getDateString)(req.query.startDate, 'startDate', true);
    const endDate = (0, validation_1.getDateString)(req.query.endDate, 'endDate', true);
    res.json({ success: true, data: await leaderboardService.getWeeklyLeaderboard(startDate, endDate) });
}));
exports.default = router;
//# sourceMappingURL=achievements.js.map