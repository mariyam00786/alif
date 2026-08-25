import { Router } from 'express';
import { asyncHandler } from '../middleware/async-handler';
import { authenticateRequest } from '../middleware/authentication';
import { AuthService } from '../services/auth/auth-service';
import { registerUser, requestOTP, verifyOTP } from '../services/auth-service';
import { ensureObject, getOptionalString, getRequiredString } from '../utils/validation';

const router = Router();
const authService = new AuthService();

router.post('/register', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const method = getRequiredString(body.method, 'method');
  if (method !== 'phone' && method !== 'email') {
    res.status(400).json({ success: false, message: 'method must be "phone" or "email".' });
    return;
  }

  const result = await registerUser({
    method,
    fullName: getRequiredString(body.full_name, 'full_name'),
    role: getRequiredString(body.role, 'role') as 'student' | 'parent' | 'teacher',
    fullNameMl: getOptionalString(body.full_name_ml, 'full_name_ml'),
    phone: getOptionalString(body.phone, 'phone'),
    email: getOptionalString(body.email, 'email'),
    password: getOptionalString(body.password, 'password'),
  });

  if (!result.success) {
    res.status(400).json({ success: false, message: result.message });
    return;
  }

  res.json({
    success: true,
    message: result.message,
    data: { phone: result.phone },
  });
}));

router.post('/request-otp', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const phone = getRequiredString(body.phone, 'phone');
  const result = await requestOTP(phone);

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

router.post('/verify-otp', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const phone = getRequiredString(body.phone, 'phone');
  const otp = getRequiredString(body.otp, 'otp');
  const result = await verifyOTP(phone, otp);

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

router.post('/google-signin', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const idToken = getRequiredString(body.idToken, 'idToken');
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

router.post('/supabase-signin', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const accessToken = getRequiredString(body.accessToken, 'accessToken');
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

router.get('/session', authenticateRequest, asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: {
      user: req.user,
      profile: req.profile,
    },
  });
}));

router.get('/profile', authenticateRequest, asyncHandler(async (req, res) => {
  const profile = await authService.getProfileById(req.user!.profileId);

  res.json({ success: true, data: profile });
}));

router.patch('/profile', authenticateRequest, asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const profile = await authService.updateProfile(
    req.user!.profileId,
    {
      phone: getOptionalString(body.phone, 'phone'),
      full_name: getOptionalString(body.full_name, 'full_name'),
      full_name_ml: getOptionalString(body.full_name_ml, 'full_name_ml'),
      profile_photo: getOptionalString(body.profile_photo, 'profile_photo'),
    },
    req.user!
  );

  res.json({ success: true, data: profile });
}));

router.post('/firebase/verify', asyncHandler(async (req, res) => {
  const body = ensureObject(req.body);
  const tokenInfo = await authService.verifyFirebaseToken(getRequiredString(body.idToken, 'idToken'));

  res.json({ success: true, data: tokenInfo });
}));

router.post('/logout', authenticateRequest, asyncHandler(async (req, res) => {
  res.json({
    success: true,
    message: `Session invalidation is handled client-side for access token ${req.user!.authUserId}.`,
  });
}));

export default router;