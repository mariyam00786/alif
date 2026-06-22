/**
 * Authentication Service
 * 
 * Handles user authentication using:
 * 1. Supabase Auth for OTP verification
 * 2. Firebase for supplementary auth
 * 3. JWT token generation for API
 * 
 * Features:
 * - Phone OTP verification
 * - Token creation and validation
 * - Role-based access control
 * - Session management
 */

import { randomInt, timingSafeEqual } from 'crypto';
import * as jwt from 'jsonwebtoken';
import config from '../config/config';
import { getSupabaseClient } from '../config/supabase';
import { sendWhatsAppMessage } from './msghex/msghex-service';
import { Profile } from '../types/database';

/**
 * Authentication token
 */
export interface AuthToken {
  access_token: string;
  refresh_token?: string;
  expires_in: number;
  token_type: 'Bearer';
}

/**
 * Authenticated user info
 */
export interface AuthUser {
  id: string;
  phone: string;
  role: 'student' | 'parent' | 'teacher' | 'admin';
  name: string;
  profile_id: string;
  /**
   * True when this account is also linked to one or more children via the
   * parent_students table, regardless of its primary `role`. Lets a single
   * sign-in switch into the parent view from inside the student portal.
   */
  has_parent_access?: boolean;
}

interface AppJwtPayload extends jwt.JwtPayload {
  sub: string;
  role: AuthUser['role'];
  phone: string;
  name: string;
  profile_id: string;
}

/**
 * OTP request response
 */
export interface OTPRequestResponse {
  success: boolean;
  message: string;
  session_id?: string;
}

/**
 * OTP verification response
 */
export interface OTPVerificationResponse {
  success: boolean;
  message: string;
  user?: AuthUser;
  token?: AuthToken;
  error?: string;
}

/**
 * Phone login uses MsgHex (WhatsApp) for OTP delivery and Supabase for the
 * user/profile store.
 */

/**
 * Server-side record of an OTP that has been issued to a phone number.
 */
interface OtpRecord {
  otp: string;
  expiresAt: number;
  attempts: number;
}

/**
 * In-memory store of pending OTPs keyed by phone number. Suitable for a single
 * backend instance; back this with a shared cache (e.g. Redis) when scaling
 * horizontally.
 */
const otpStore = new Map<string, OtpRecord>();

/**
 * Constant-time comparison of an expected and a supplied OTP code.
 */
function isOtpMatch(expected: string, supplied: string): boolean {
  const expectedBuffer = Buffer.from(expected, 'utf8');
  const suppliedBuffer = Buffer.from(supplied, 'utf8');

  if (expectedBuffer.length !== suppliedBuffer.length) {
    return false;
  }

  return timingSafeEqual(expectedBuffer, suppliedBuffer);
}

/**
 * Generates a numeric OTP of the configured length (e.g. "4821").
 */
function generateOtp(length: number): string {
  const digits = Math.max(4, Math.min(8, length));
  const max = 10 ** digits;
  return randomInt(0, max).toString().padStart(digits, '0');
}

/**
 * Request OTP for phone number
 * 
 * Sends a one-time password to the user's WhatsApp number via MsgHex.
 * 
 * @param phone - Phone number in format +91XXXXXXXXXX
 * @returns OTP request response with session ID
 * 
 * @example
 * const response = await requestOTP('+919876543210');
 * // { success: true, message: 'OTP sent', session_id: '...' }
 */
export async function requestOTP(phone: string): Promise<OTPRequestResponse> {
  try {
    // Validate phone format
    if (!phone.match(/^\+\d{1,3}\d{4,14}$/)) {
      return {
        success: false,
        message: 'Invalid phone number format. Use +CCCXXXXXXXXX',
      };
    }

    // Only registered students/parents/teachers/admins may log in.
    const profile = await getUserByPhone(phone);
    if (!profile) {
      return {
        success: false,
        message: 'No account is registered with this phone number.',
      };
    }

    // Generate a short OTP server-side and deliver it through MsgHex (WhatsApp)
    // as a plain text message, so we control the code length and format.
    const otp = generateOtp(config.msghex.otpLength);
    const message = config.msghex.messageTemplate.replace(/\{\{\s*otp\s*\}\}/g, otp);

    const result = await sendWhatsAppMessage(phone, message);
    if (!result.success) {
      return {
        success: false,
        message: result.message,
      };
    }

    // Bind the issued OTP to this phone number so verification is recipient
    // specific.
    otpStore.set(phone, {
      otp,
      expiresAt: Date.now() + config.msghex.otpTtlSeconds * 1000,
      attempts: 0,
    });

    return {
      success: true,
      message: 'OTP sent to your WhatsApp number.',
      session_id: result.messageId ?? `msghex_${Date.now()}`,
    };
  } catch (error) {
    return {
      success: false,
      message: `Failed to send OTP: ${(error as Error).message}`,
    };
  }
}

/**
 * Verify OTP and authenticate user
 * 
 * @param phone - Phone number that received OTP
 * @param code - OTP code
 * @returns Verification response with user and token if successful
 * 
 * @example
 * const response = await verifyOTP('+919876543210', '123456');
 * if (response.success) {
 *   console.log('User:', response.user);
 *   console.log('Token:', response.token);
 * }
 */
export async function verifyOTP(
  phone: string,
  code: string
): Promise<OTPVerificationResponse> {
  try {
    // Validate inputs
    if (!phone.match(/^\+\d{1,3}\d{4,14}$/)) {
      return {
        success: false,
        message: 'Invalid phone number',
        error: 'INVALID_PHONE',
      };
    }

    if (!code.match(/^\d{4,8}$/)) {
      return {
        success: false,
        message: 'Invalid OTP format',
        error: 'INVALID_OTP_FORMAT',
      };
    }

    const record = otpStore.get(phone);

    if (!record) {
      return {
        success: false,
        message: 'OTP has expired. Please request a new one.',
        error: 'OTP_EXPIRED',
      };
    }

    // Enforce expiry, attempt limits and constant-time comparison so the check
    // is bound to this specific phone number.
    if (Date.now() > record.expiresAt) {
      otpStore.delete(phone);
      return {
        success: false,
        message: 'OTP has expired. Please request a new one.',
        error: 'OTP_EXPIRED',
      };
    }

    record.attempts += 1;
    if (record.attempts > config.msghex.maxVerifyAttempts) {
      otpStore.delete(phone);
      return {
        success: false,
        message: 'Too many invalid attempts. Please request a new OTP.',
        error: 'TOO_MANY_ATTEMPTS',
      };
    }

    if (!isOtpMatch(record.otp, code)) {
      return {
        success: false,
        message: 'Invalid OTP',
        error: 'INVALID_OTP',
      };
    }

    otpStore.delete(phone);

    // OTP verified — load the user profile and issue an app session token.
    const profile = await getUserByPhone(phone);

    if (!profile) {
      return {
        success: false,
        message: 'User not found',
        error: 'USER_NOT_FOUND',
      };
    }

    const authenticatedUser: AuthUser = {
      id: profile.id,
      phone: profile.phone,
      role: profile.role,
      name: profile.full_name,
      profile_id: profile.id,
      has_parent_access: await profileHasChildren(profile.id),
    };
    const token = createToken(authenticatedUser);

    return {
      success: true,
      message: 'Authentication successful',
      user: authenticatedUser,
      token,
    };
  } catch (error) {
    return {
      success: false,
      message: `OTP verification failed: ${(error as Error).message}`,
      error: 'VERIFICATION_ERROR',
    };
  }
}

/**
 * Gets a user profile by phone number from Supabase.
 *
 * Profiles may store the phone with or without the leading '+', so both forms
 * are queried.
 */
async function getUserByPhone(phone: string): Promise<Profile | null> {
  const normalized = phone.startsWith('+') ? phone : `+${phone}`;
  const withoutPlus = normalized.slice(1);

  const { data, error } = await getSupabaseClient()
    .from('profiles')
    .select('*')
    .in('phone', [normalized, withoutPlus])
    .limit(1);

  if (error) {
    throw new Error(error.message);
  }

  return (data?.[0] as Profile) ?? null;
}

/**
 * Returns true when the profile is linked to at least one child via the
 * parent_students table, so a single sign-in can open the parent (multi-child)
 * view. Independent of the profile's primary role.
 */
async function profileHasChildren(profileId: string): Promise<boolean> {
  const { count, error } = await getSupabaseClient()
    .from('parent_students')
    .select('student_id', { count: 'exact', head: true })
    .eq('parent_profile_id', profileId);
  if (error) return false;
  return (count ?? 0) > 0;
}

/**
 * Mock: Gets user profile by user ID
 * In production: Query Supabase profiles table
 */
async function getUserById(userId: string): Promise<Profile | null> {
  // In production:
  // const { data } = await supabaseClient
  //   .from('profiles')
  //   .select('*')
  //   .eq('id', userId)
  //   .single();
  // return data;
  
  // Mock users - lookup by ID
  const mockUsersById: Record<string, Profile> = {
    'user-001': {
      id: 'user-001',
      phone: '+919876543210',
      full_name: 'Amir Ahmed',
      full_name_ml: 'അമീർ അഹമ്മദ്',
      role: 'student',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    'user-002': {
      id: 'user-002',
      phone: '+919876543211',
      full_name: 'Fatima Khan',
      full_name_ml: 'ഫാത്തിമ ഖാൻ',
      role: 'parent',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    'user-admin-001': {
      id: 'user-admin-001',
      phone: '+966501234567',
      full_name: 'Admin User',
      full_name_ml: 'അഡ്മിൻ ഉപയോഗിക്കുന്നു',
      role: 'admin',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  };
  
  return mockUsersById[userId] || null;
}

/**
 * Creates JWT token for authenticated user
 * 
 * @param userId - User ID
 * @param role - User role
 * @param expiresIn - Token expiration in seconds (default: 24 hours)
 * @returns JWT token object
 * 
 * In production, use a proper JWT library:
 * ```
 * import jwt from 'jsonwebtoken';
 * 
 * const token = jwt.sign(
 *   { userId, role, iat: Math.floor(Date.now() / 1000) },
 *   process.env.JWT_SECRET!,
 *   { expiresIn: `${expiresIn}s` }
 * );
 * ```
 */
export function createToken(
  user: AuthUser,
  expiresIn: number = 24 * 60 * 60
): AuthToken {
  const accessToken = jwt.sign(
    {
      role: user.role,
      phone: user.phone,
      name: user.name,
      profile_id: user.profile_id,
    },
    config.jwt.secret,
    {
      subject: user.id,
      expiresIn,
    }
  );

  return {
    access_token: accessToken,
    refresh_token: `refresh_${Date.now()}`,
    expires_in: expiresIn,
    token_type: 'Bearer',
  };
}

/**
 * Verifies a JWT token and extracts user info
 * 
 * @param token - JWT token to verify
 * @returns User info if valid, null if invalid
 * 
 * In production:
 * ```
 * import jwt from 'jsonwebtoken';
 * try {
 *   const decoded = jwt.verify(token, process.env.JWT_SECRET!);
 *   return decoded;
 * } catch {
 *   return null;
 * }
 * ```
 */
export function verifyToken(
  token: string
): {
  userId: string;
  role: AuthUser['role'];
  phone: string;
  name: string;
  profile_id: string;
  expiresAt: number;
} | null {
  try {
    // Remove 'Bearer ' prefix if present
    const cleanToken = token.replace(/^Bearer\s+/i, '');
    const payload = jwt.verify(cleanToken, config.jwt.secret) as AppJwtPayload;

    if (!payload.sub || !payload.role || !payload.phone || !payload.name || !payload.profile_id) {
      return null;
    }
    
    return {
      userId: payload.sub,
      role: payload.role,
      phone: payload.phone,
      name: payload.name,
      profile_id: payload.profile_id,
      expiresAt: payload.exp ?? 0,
    };
  } catch {
    return null;
  }
}

/**
 * Gets user role from database
 * 
 * @param userId - User ID
 * @returns User role or null if not found
 * 
 * @example
 * const role = await getUserRole('user-123');
 * // 'student' | 'parent' | 'teacher' | 'admin'
 */
export async function getUserRole(
  userId: string
): Promise<'student' | 'parent' | 'teacher' | 'admin' | null> {
  try {
    // In production:
    // const { data } = await supabaseClient
    //   .from('profiles')
    //   .select('role')
    //   .eq('id', userId)
    //   .single();
    // return data?.role || null;
    
    // Mock
    const users = await Promise.resolve({
      'user-001': 'student',
      'user-002': 'parent',
    } as Record<string, any>);
    
    return users[userId] || null;
  } catch {
    return null;
  }
}

/**
 * Gets complete user profile from token
 * 
 * @param token - JWT token
 * @returns User profile or null if token invalid
 */
export async function getUserFromToken(token: string): Promise<AuthUser | null> {
  const decoded = verifyToken(token);
  
  if (!decoded) {
    return null;
  }

  return {
    id: decoded.userId,
    phone: decoded.phone,
    role: decoded.role,
    name: decoded.name,
    profile_id: decoded.profile_id,
  };
}

/**
 * Refreshes an expired token using refresh token
 * 
 * @param refreshToken - Refresh token
 * @returns New access token or null if refresh failed
 */
export function refreshToken(refreshToken: string): AuthToken | null {
  try {
    // In production:
    // const { data, error } = await supabaseClient.auth.refreshSession();
    // if (error) return null;
    // return mapToAuthToken(data.session);
    
    // Mock: always succeeds
    if (refreshToken.startsWith('refresh_')) {
      return createToken({
        id: 'user-001',
        phone: '+919876543210',
        role: 'student',
        name: 'Amir Ahmed',
        profile_id: 'user-001',
      });
    }
    
    return null;
  } catch {
    return null;
  }
}

/**
 * Signs out user (invalidates token)
 * 
 * In production: call Supabase signOut
 */
export async function signOut(): Promise<void> {
  // In production:
  // await supabaseClient.auth.signOut();
  
  // Mock: no-op
  console.log('[MOCK] User signed out');
}

/**
 * Authentication Service Summary
 * 
 * ============================================
 * Flow
 * ============================================
 * 1. Client requests OTP for phone number
 *    → requestOTP('+919876543210')
 * 2. User receives OTP via SMS
 * 3. Client submits phone + OTP
 *    → verifyOTP('+919876543210', '123456')
 * 4. Service returns JWT token if valid
 * 5. Client uses token for all API requests
 *    → Header: Authorization: Bearer {token}
 * 
 * ============================================
 * Security Notes
 * ============================================
 * - OTP valid for 10 minutes only
 * - JWT tokens expire after 24 hours
 * - Use refresh tokens to extend session
 * - Always use HTTPS for token transmission
 * - Store tokens securely (HttpOnly cookies recommended)
 * - Validate role on every protected endpoint
 * 
 * ============================================
 * Role-Based Access
 * ============================================
 * - student: Can only access own records
 * - parent: Can access child's records
 * - teacher: Can access batch records
 * - admin: Full access
 * 
 * Enforce via middleware on routes
 */
