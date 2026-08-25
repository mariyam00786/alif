/**
 * Authentication Middleware
 *
 * Provides JWT token verification and role-based access control
 *
 * Features:
 * - JWT token verification
 * - Role extraction
 * - Role-based access control
 * - User context injection into req.user
 */
import { Request, Response, NextFunction } from 'express';
/**
 * Extract JWT token from request
 *
 * Supports:
 * - Authorization header: "Bearer <token>"
 * - Cookie: "authToken=<token>"
 * - Query param: "?token=<token>" (for WebSocket, use with caution)
 */
export declare const extractToken: (req: Request) => string | null;
/**
 * Require authentication middleware
 *
 * Verifies JWT token and injects user context
 *
 * Usage:
 * ```typescript
 * router.get('/protected', requireAuth, (req, res) => {
 *   console.log(req.user?.id);
 * });
 * ```
 *
 * Error: 401 Unauthorized (missing or invalid token)
 */
export declare const requireAuth: (req: Request, res: Response, next: NextFunction) => Promise<void | Response<any, Record<string, any>>>;
/**
 * Require specific role(s)
 *
 * Restricts access to authenticated users with specific roles
 *
 * Usage:
 * ```typescript
 * router.delete('/students/:id', requireAuth, requireRole('admin'), deleteStudent);
 * router.get('/reports', requireAuth, requireRole('admin', 'teacher'), getReports);
 * ```
 *
 * Error: 403 Forbidden (insufficient permissions)
 */
export declare const requireRole: (...allowedRoles: string[]) => (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
/**
 * Optional authentication middleware
 *
 * Verifies token if present, but allows unauthenticated requests
 * Useful for endpoints that work with or without authentication
 *
 * Usage:
 * ```typescript
 * router.get('/public', optionalAuth, (req, res) => {
 *   if (req.user) {
 *     // Personalized response
 *   } else {
 *     // Generic response
 *   }
 * });
 * ```
 */
export declare const optionalAuth: (req: Request, _res: Response, next: NextFunction) => Promise<void>;
/**
 * Admin-only middleware
 *
 * Shorthand for requireRole('admin')
 *
 * Usage:
 * ```typescript
 * router.delete('/system', requireAuth, adminOnly, deleteSystemConfig);
 * ```
 */
export declare const adminOnly: (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
/**
 * Teacher-only middleware
 *
 * Includes admin (admin has all permissions)
 */
export declare const teacherOnly: (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
/**
 * Student-only middleware
 *
 * Used for endpoints restricted to students
 */
export declare const studentOnly: (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
/**
 * Parent-only middleware
 *
 * Used for parent-specific endpoints
 */
export declare const parentOnly: (req: Request, res: Response, next: NextFunction) => void | Response<any, Record<string, any>>;
/**
 * Check ownership middleware
 *
 * Verifies that user is accessing their own resource
 * Allows admin to access any resource
 *
 * Usage:
 * ```typescript
 * router.get('/students/:studentId/records',
 *   requireAuth,
 *   checkOwnership('studentId'),
 *   getRecords
 * );
 * ```
 *
 * Checks:
 * - If admin: allow
 * - If student: only allow if :studentId matches req.user.id
 * - If parent: only allow if student is their child (requires db check)
 */
export declare const checkOwnership: (paramName: string) => (req: Request, res: Response, next: NextFunction) => Promise<void | Response<any, Record<string, any>>>;
/**
 * Rate limiting middleware (placeholder)
 *
 * In production, integrate with redis-rate-limit or similar
 *
 * Usage:
 * ```typescript
 * router.post('/auth/login', rateLimit('login', 5, 60), login);
 * ```
 */
export declare const rateLimit: (key: string, maxRequests: number, windowSeconds: number) => (_req: Request, _res: Response, next: NextFunction) => void;
/**
 * Request logging middleware
 *
 * Logs authenticated requests for audit trail
 *
 * Usage:
 * ```typescript
 * app.use(requestLogger);
 * ```
 */
export declare const requestLogger: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.d.ts.map