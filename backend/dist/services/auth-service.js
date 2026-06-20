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
exports.requestOTP = requestOTP;
exports.verifyOTP = verifyOTP;
exports.createToken = createToken;
exports.verifyToken = verifyToken;
exports.getUserRole = getUserRole;
exports.getUserFromToken = getUserFromToken;
exports.refreshToken = refreshToken;
exports.signOut = signOut;
const jwt = __importStar(require("jsonwebtoken"));
const config_1 = __importDefault(require("../config/config"));
/**
 * Mock implementation of Supabase Auth
 * In production, replace with actual Supabase client
 */
/**
 * Request OTP for phone number
 *
 * Calls Supabase to send OTP to the phone
 * In production: Use supabase.auth.signInWithOtp({ phone })
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
        // In production:
        // const { data, error } = await supabaseClient.auth.signInWithOtp({
        //   phone: phone,
        // });
        // if (error) throw error;
        // Mock: Generate session ID
        const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        console.log(`[MOCK] OTP sent to ${phone}. Session: ${sessionId}`);
        return {
            success: true,
            message: 'OTP sent to your phone. Valid for 10 minutes.',
            session_id: sessionId,
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
 * @param code - OTP code (6 digits)
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
        if (!code.match(/^\d{6}$/)) {
            return {
                success: false,
                message: 'OTP must be 6 digits',
                error: 'INVALID_OTP_FORMAT',
            };
        }
        // In production:
        // const { data, error } = await supabaseClient.auth.verifyOtp({
        //   phone: phone,
        //   token: code,
        //   type: 'sms',
        // });
        // if (error) throw error;
        // const user = data.user;
        // Mock: Verify against hardcoded test OTP
        if (code !== '000000') {
            return {
                success: false,
                message: 'Invalid OTP',
                error: 'INVALID_OTP',
            };
        }
        // Mock: Get user from database (fetch profile by phone)
        const mockUser = await getUserByPhone(phone);
        if (!mockUser) {
            return {
                success: false,
                message: 'User not found',
                error: 'USER_NOT_FOUND',
            };
        }
        // Create JWT token
        const authenticatedUser = {
            id: mockUser.id,
            phone: mockUser.phone,
            role: mockUser.role,
            name: mockUser.full_name,
            profile_id: mockUser.id,
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
 * Mock: Gets user profile by phone
 * In production: Query Supabase profiles table
 */
async function getUserByPhone(phone) {
    // In production:
    // const { data } = await supabaseClient
    //   .from('profiles')
    //   .select('*')
    //   .eq('phone', phone)
    //   .single();
    // return data;
    // Mock users
    const mockUsers = {
        '+919876543210': {
            id: 'user-001',
            phone: '+919876543210',
            full_name: 'Amir Ahmed',
            full_name_ml: 'അമീർ അഹമ്മദ്',
            role: 'student',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
        },
        '+919876543211': {
            id: 'user-002',
            phone: '+919876543211',
            full_name: 'Fatima Khan',
            full_name_ml: 'ഫാത്തിമ ഖാൻ',
            role: 'parent',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
        },
        '+966501234567': {
            id: 'user-admin-001',
            phone: '+966501234567',
            full_name: 'Admin User',
            full_name_ml: 'അഡ്മിൻ ഉപയോഗിക്കുന്നു',
            role: 'admin',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
        },
    };
    return mockUsers[phone] || null;
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