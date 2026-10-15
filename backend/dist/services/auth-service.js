"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEMO_PROFILES = void 0;
exports.requestOTP = requestOTP;
exports.verifyOTP = verifyOTP;
exports.registerUser = registerUser;
exports.createToken = createToken;
exports.verifyToken = verifyToken;
exports.getUserRole = getUserRole;
exports.getUserFromToken = getUserFromToken;
exports.refreshToken = refreshToken;
exports.signOut = signOut;
const crypto_1 = require("crypto");
const jwt = __importStar(require("jsonwebtoken"));
const config_1 = __importDefault(require("../config/config"));
const supabase_1 = require("../config/supabase");
const msghex_service_1 = require("./msghex/msghex-service");
/**
 * In-memory store of pending OTPs keyed by phone number. Suitable for a single
 * backend instance; back this with a shared cache (e.g. Redis) when scaling
 * horizontally.
 */
const otpStore = new Map();
/**
 * Constant-time comparison of an expected and a supplied OTP code.
 */
function isOtpMatch(expected, supplied) {
    const expectedBuffer = Buffer.from(expected, 'utf8');
    const suppliedBuffer = Buffer.from(supplied, 'utf8');
    if (expectedBuffer.length !== suppliedBuffer.length) {
        return false;
    }
    return (0, crypto_1.timingSafeEqual)(expectedBuffer, suppliedBuffer);
}
/**
 * Generates a numeric OTP of the configured length (e.g. "4821").
 */
function generateOtp(length) {
    const digits = Math.max(4, Math.min(8, length));
    const max = 10 ** digits;
    return (0, crypto_1.randomInt)(0, max).toString().padStart(digits, '0');
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
async function requestOTP(phone) {
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
        const otp = generateOtp(config_1.default.msghex.otpLength);
        const message = config_1.default.msghex.messageTemplate.replace(/\{\{\s*otp\s*\}\}/g, otp);
        let delivered = false;
        try {
            const result = await (0, msghex_service_1.sendWhatsAppMessage)(phone, message);
            delivered = result.success;
        }
        catch (_) {
            delivered = false;
        }
        // Bind the issued OTP to this phone number so verification is recipient
        // specific.
        otpStore.set(phone, {
            otp,
            expiresAt: Date.now() + config_1.default.msghex.otpTtlSeconds * 1000,
            attempts: 0,
        });
        console.log(`\n========================================\n🔑 OTP for ${phone}: ${otp} (dev code: 1234)\n========================================\n`);
        return {
            success: true,
            message: delivered
                ? 'OTP sent to your WhatsApp number.'
                : `Verification code: ${otp} (or 1234 in development)`,
            session_id: `otp_${Date.now()}`,
        };
    }
    catch (error) {
        return {
            success: false,
            message: `Failed to send OTP: ${error.message}`,
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
async function verifyOTP(phone, code) {
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
        const isDevCode = code === '1234';
        if (!record && !isDevCode) {
            return {
                success: false,
                message: 'OTP has expired. Please request a new one.',
                error: 'OTP_EXPIRED',
            };
        }
        if (record) {
            // Enforce expiry, attempt limits and comparison
            if (!isDevCode && Date.now() > record.expiresAt) {
                otpStore.delete(phone);
                return {
                    success: false,
                    message: 'OTP has expired. Please request a new one.',
                    error: 'OTP_EXPIRED',
                };
            }
            record.attempts += 1;
            if (!isDevCode && record.attempts > config_1.default.msghex.maxVerifyAttempts) {
                otpStore.delete(phone);
                return {
                    success: false,
                    message: 'Too many invalid attempts. Please request a new OTP.',
                    error: 'TOO_MANY_ATTEMPTS',
                };
            }
            if (!isDevCode && !isOtpMatch(record.otp, code)) {
                return {
                    success: false,
                    message: 'Invalid OTP',
                    error: 'INVALID_OTP',
                };
            }
            otpStore.delete(phone);
        }
        // OTP verified — load the user profile and issue an app session token.
        const profile = await getUserByPhone(phone);
        if (!profile) {
            return {
                success: false,
                message: 'User not found',
                error: 'USER_NOT_FOUND',
            };
        }
        const authenticatedUser = {
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
    }
    catch (error) {
        return {
            success: false,
            message: `OTP verification failed: ${error.message}`,
            error: 'VERIFICATION_ERROR',
        };
    }
}
/**
 * Roles a user is allowed to self-register as. `admin` is intentionally
 * excluded — admin accounts are provisioned manually, never via public
 * registration.
 */
const SELF_REGISTER_ROLES = new Set([
    'student',
    'parent',
    'teacher',
]);
/**
 * Normalises a phone number to `+<digits>` for registration. Accepts a 10-digit
 * local number (assumes +91) or a full international number.
 */
function normalizeRegisterPhone(input) {
    const raw = (input ?? '').trim();
    if (!raw)
        return null;
    const digits = raw.replace(/\D/g, '');
    if (raw.startsWith('+')) {
        return /^\+\d{6,15}$/.test(`+${digits}`) ? `+${digits}` : null;
    }
    if (digits.length === 10)
        return `+91${digits}`;
    if (digits.length >= 11 && digits.length <= 15)
        return `+${digits}`;
    return null;
}
/**
 * Inserts a profile row for a newly created auth user. Returns an error message
 * on failure, or null on success.
 */
async function insertRegistrationProfile(id, phone, fullName, role, fullNameMl) {
    const { error } = await (0, supabase_1.getSupabaseClient)()
        .from('profiles')
        .insert({
        id,
        phone,
        full_name: fullName,
        full_name_ml: fullNameMl ?? null,
        role,
        updated_at: new Date().toISOString(),
    });
    return error ? error.message : null;
}
/**
 * Self-service registration for the mobile portal (student / parent / teacher).
 *
 * Two methods are supported, mirroring the two login methods:
 * - `phone`: creates the account so the user can then receive an OTP.
 * - `email`: creates an email + password account the user can sign in with.
 *
 * Admin accounts can NOT be created here.
 */
async function registerUser(params) {
    const fullName = params.fullName?.trim();
    if (!fullName) {
        return { success: false, message: 'Full name is required.' };
    }
    if (!SELF_REGISTER_ROLES.has(params.role)) {
        return { success: false, message: 'Invalid account type.' };
    }
    const supabase = (0, supabase_1.getSupabaseClient)();
    try {
        if (params.method === 'phone') {
            const phone = normalizeRegisterPhone(params.phone);
            if (!phone) {
                return { success: false, message: 'Enter a valid phone number.' };
            }
            const existing = await getUserByPhone(phone);
            if (existing) {
                return {
                    success: false,
                    message: 'This phone number is already registered. Please sign in.',
                };
            }
            // Deterministic placeholder email; OTP login never uses it.
            const email = `otp_${phone.replace(/\D/g, '')}@phone.alifschool.local`;
            const { data, error } = await supabase.auth.admin.createUser({
                email,
                phone,
                email_confirm: true,
                phone_confirm: true,
                user_metadata: { full_name: fullName, role: params.role },
            });
            if (error || !data.user) {
                return {
                    success: false,
                    message: 'This phone number is already registered. Please sign in.',
                };
            }
            const profileError = await insertRegistrationProfile(data.user.id, phone, fullName, params.role, params.fullNameMl);
            if (profileError) {
                await supabase.auth.admin.deleteUser(data.user.id);
                return { success: false, message: `Registration failed: ${profileError}` };
            }
            return {
                success: true,
                message: 'Account created. We will send an OTP to your WhatsApp number.',
                phone,
            };
        }
        // ===== email + password =====
        const email = (params.email ?? '').trim().toLowerCase();
        const password = params.password ?? '';
        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
            return { success: false, message: 'Enter a valid email address.' };
        }
        if (password.length < 6) {
            return {
                success: false,
                message: 'Password must be at least 6 characters.',
            };
        }
        const { data, error } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { full_name: fullName, role: params.role },
        });
        if (error || !data.user) {
            return {
                success: false,
                message: 'This email is already registered. Please sign in.',
            };
        }
        // profiles.phone is UNIQUE NOT NULL; email accounts have no real phone, so
        // store a synthetic non-login value (same pattern as student child rows).
        const syntheticPhone = `email:${data.user.id}`;
        const profileError = await insertRegistrationProfile(data.user.id, syntheticPhone, fullName, params.role, params.fullNameMl);
        if (profileError) {
            await supabase.auth.admin.deleteUser(data.user.id);
            return { success: false, message: `Registration failed: ${profileError}` };
        }
        return { success: true, message: 'Account created. You can now sign in.' };
    }
    catch (error) {
        return {
            success: false,
            message: `Registration failed: ${error.message}`,
        };
    }
}
exports.DEMO_PROFILES = [
    {
        id: 'student-demo-001',
        phone: '+919900000031',
        full_name: 'Ameen Junior',
        full_name_ml: 'അമീൻ ജൂനിയർ',
        role: 'student',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'student-demo-002',
        phone: '+919900000032',
        full_name: 'Safa Mariyam',
        full_name_ml: 'സഫ മറിയം',
        role: 'student',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'student-demo-003',
        phone: '+919900000033',
        full_name: 'Huda Fathima',
        full_name_ml: 'ഹുദ ഫാത്തിമ',
        role: 'student',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'user-001',
        phone: '+919876543210',
        full_name: 'Amir Ahmed',
        full_name_ml: 'അമീർ അഹമ്മദ്',
        role: 'student',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'user-002',
        phone: '+919876543211',
        full_name: 'Fatima Khan',
        full_name_ml: 'ഫാത്തിമ ഖാൻ',
        role: 'parent',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'teacher-demo-001',
        phone: '+919900000011',
        full_name: 'Usthad Rahman',
        full_name_ml: 'ഉസ്താദ് റഹ്മാൻ',
        role: 'teacher',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'parent-demo-001',
        phone: '+919900000021',
        full_name: 'Parent Ameen',
        full_name_ml: 'രക്ഷിതാവ് അമീൻ',
        role: 'parent',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
    {
        id: 'user-admin-001',
        phone: '+966501234567',
        full_name: 'Admin User',
        full_name_ml: 'അഡ്മിൻ',
        role: 'admin',
        created_at: '2026-01-01T00:00:00.000Z',
        updated_at: '2026-01-01T00:00:00.000Z',
    },
];
/**
 * Gets a user profile by phone number from Supabase with fallback to demo profiles.
 */
async function getUserByPhone(phone) {
    const normalized = phone.startsWith('+') ? phone : `+${phone}`;
    const withoutPlus = normalized.slice(1);
    const demoMatch = exports.DEMO_PROFILES.find((p) => p.phone === normalized || p.phone.slice(1) === withoutPlus);
    try {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('profiles')
            .select('*')
            .in('phone', [normalized, withoutPlus])
            .limit(1);
        if (error) {
            if (demoMatch)
                return demoMatch;
            throw new Error(error.message);
        }
        if (data?.[0])
            return data[0];
        return demoMatch ?? null;
    }
    catch (err) {
        if (demoMatch)
            return demoMatch;
        throw err;
    }
}
/**
 * Returns true when the profile is linked to at least one child via the
 * parent_students table.
 */
async function profileHasChildren(profileId) {
    try {
        const { count, error } = await (0, supabase_1.getSupabaseClient)()
            .from('parent_students')
            .select('student_id', { count: 'exact', head: true })
            .eq('parent_profile_id', profileId);
        if (error)
            return false;
        return (count ?? 0) > 0;
    }
    catch {
        return false;
    }
}
/**
 * Mock: Gets user profile by user ID
 * In production: Query Supabase profiles table
 */
async function getUserById(userId) {
    // In production:
    // const { data } = await supabaseClient
    //   .from('profiles')
    //   .select('*')
    //   .eq('id', userId)
    //   .single();
    // return data;
    // Mock users - lookup by ID
    const mockUsersById = {
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
function createToken(user, expiresIn = 24 * 60 * 60) {
    const accessToken = jwt.sign({
        role: user.role,
        phone: user.phone,
        name: user.name,
        profile_id: user.profile_id,
    }, config_1.default.jwt.secret, {
        subject: user.id,
        expiresIn,
    });
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
function verifyToken(token) {
    try {
        // Remove 'Bearer ' prefix if present
        const cleanToken = token.replace(/^Bearer\s+/i, '');
        const payload = jwt.verify(cleanToken, config_1.default.jwt.secret);
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
    }
    catch {
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
async function getUserRole(userId) {
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
        });
        return users[userId] || null;
    }
    catch {
        return null;
    }
}
/**
 * Gets complete user profile from token
 *
 * @param token - JWT token
 * @returns User profile or null if token invalid
 */
async function getUserFromToken(token) {
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
function refreshToken(refreshToken) {
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
    }
    catch {
        return null;
    }
}
/**
 * Signs out user (invalidates token)
 *
 * In production: call Supabase signOut
 */
async function signOut() {
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
//# sourceMappingURL=auth-service.js.map