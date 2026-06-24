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
export declare function requestOTP(phone: string): Promise<OTPRequestResponse>;
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
export declare function verifyOTP(phone: string, code: string): Promise<OTPVerificationResponse>;
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
export declare function createToken(user: AuthUser, expiresIn?: number): AuthToken;
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
export declare function verifyToken(token: string): {
    userId: string;
    role: AuthUser['role'];
    phone: string;
    name: string;
    profile_id: string;
    expiresAt: number;
} | null;
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
export declare function getUserRole(userId: string): Promise<'student' | 'parent' | 'teacher' | 'admin' | null>;
/**
 * Gets complete user profile from token
 *
 * @param token - JWT token
 * @returns User profile or null if token invalid
 */
export declare function getUserFromToken(token: string): Promise<AuthUser | null>;
/**
 * Refreshes an expired token using refresh token
 *
 * @param refreshToken - Refresh token
 * @returns New access token or null if refresh failed
 */
export declare function refreshToken(refreshToken: string): AuthToken | null;
/**
 * Signs out user (invalidates token)
 *
 * In production: call Supabase signOut
 */
export declare function signOut(): Promise<void>;
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
//# sourceMappingURL=auth-service.d.ts.map