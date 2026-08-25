"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../middleware/async-handler");
const authentication_1 = require("../middleware/authentication");
const auth_service_1 = require("../services/auth/auth-service");
const auth_service_2 = require("../services/auth-service");
const validation_1 = require("../utils/validation");
const router = (0, express_1.Router)();
const authService = new auth_service_1.AuthService();
router.post('/request-otp', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const phone = (0, validation_1.getRequiredString)(body.phone, 'phone');
    const result = await (0, auth_service_2.requestOTP)(phone);
    if (!result.success) {
        res.status(400).json({
            success: false,
            message: result.message,
        });
        return;
    }
    res.json({
        success: true,
        message: result.message,
        data: {
            sessionId: result.session_id,
        },
    });
}));
router.post('/verify-otp', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const phone = (0, validation_1.getRequiredString)(body.phone, 'phone');
    const otp = (0, validation_1.getRequiredString)(body.otp, 'otp');
    const result = await (0, auth_service_2.verifyOTP)(phone, otp);
    if (!result.success) {
        res.status(401).json({
            success: false,
            message: result.message,
            error: result.error,
        });
        return;
    }
    const token = result.token?.access_token ?? '';
    res.json({
        success: true,
        message: result.message,
        token,
        data: {
            token,
            user: result.user,
        },
    });
}));
router.post('/google-signin', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const idToken = (0, validation_1.getRequiredString)(body.idToken, 'idToken');
    const result = await authService.signInWithGoogle(idToken);
    res.json({
        success: true,
        message: 'Google sign-in successful.',
        token: result.token,
        data: {
            token: result.token,
            user: result.user,
            profile: result.profile,
        },
    });
}));
router.post('/supabase-signin', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const accessToken = (0, validation_1.getRequiredString)(body.accessToken, 'accessToken');
    const result = await authService.signInWithSupabaseAccessToken(accessToken);
    res.json({
        success: true,
        message: 'Sign-in successful.',
        token: result.token,
        data: {
            token: result.token,
            user: result.user,
            profile: result.profile,
        },
    });
}));
router.get('/session', authentication_1.authenticateRequest, (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({
        success: true,
        data: {
            user: req.user,
            profile: req.profile,
        },
    });
}));
router.get('/profile', authentication_1.authenticateRequest, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const profile = await authService.getProfileById(req.user.profileId);
    res.json({ success: true, data: profile });
}));
router.patch('/profile', authentication_1.authenticateRequest, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const profile = await authService.updateProfile(req.user.profileId, {
        phone: (0, validation_1.getOptionalString)(body.phone, 'phone'),
        full_name: (0, validation_1.getOptionalString)(body.full_name, 'full_name'),
        full_name_ml: (0, validation_1.getOptionalString)(body.full_name_ml, 'full_name_ml'),
        profile_photo: (0, validation_1.getOptionalString)(body.profile_photo, 'profile_photo'),
    }, req.user);
    res.json({ success: true, data: profile });
}));
router.post('/firebase/verify', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = (0, validation_1.ensureObject)(req.body);
    const tokenInfo = await authService.verifyFirebaseToken((0, validation_1.getRequiredString)(body.idToken, 'idToken'));
    res.json({ success: true, data: tokenInfo });
}));
router.post('/logout', authentication_1.authenticateRequest, (0, async_handler_1.asyncHandler)(async (req, res) => {
    res.json({
        success: true,
        message: `Session invalidation is handled client-side for access token ${req.user.authUserId}.`,
    });
}));
exports.default = router;
//# sourceMappingURL=auth.js.map