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
import { unauthorizedError, forbiddenError } from './error-handler';
import { verifyToken, getUserFromToken } from '../services/auth-service';

/**
 * Extract JWT token from request
 * 
 * Supports:
 * - Authorization header: "Bearer <token>"
 * - Cookie: "authToken=<token>"
 * - Query param: "?token=<token>" (for WebSocket, use with caution)
 */
export const extractToken = (req: Request): string | null => {
  // Authorization header
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    return authHeader.slice(7);
  }

  // Cookie
  if (req.cookies?.authToken) {
    return req.cookies.authToken;
  }

  // Query parameter (for WebSocket)
  if (req.query.token && typeof req.query.token === 'string') {
    return req.query.token;
  }

  return null;
};

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
export const requireAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const token = extractToken(req);

  if (!token) {
    return unauthorizedError(res, 'Missing authentication token');
  }

  try {
    // Verify token
    const decoded = verifyToken(token);
    if (!decoded) {
      return unauthorizedError(res, 'Invalid authentication token');
    }

    // Get full user from database
    const user = await getUserFromToken(token);
    if (!user) {
      return unauthorizedError(res, 'User not found');
    }

    // Inject user context
    req.user = {
      profileId: user.profile_id,
      authUserId: user.id,
      role: user.role,
      phone: user.phone,
      id: user.id,
      profile_id: user.profile_id,
      name: user.name,
    };
    req.accessToken = token;

    return next();
  } catch (error: any) {
    if (error.message === 'Token expired' || error.name === 'TokenExpiredError') {
      return unauthorizedError(res, 'Authentication token has expired');
    }

    console.error('[Auth Error]', error.message);
    return unauthorizedError(res, 'Authentication failed');
  }
};

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
export const requireRole = (...allowedRoles: string[]) => (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user) {
    return unauthorizedError(res, 'Authentication required');
  }

  if (!allowedRoles.includes(req.user.role)) {
    return forbiddenError(
      res,
      `This action requires one of these roles: ${allowedRoles.join(', ')}`
    );
  }

  return next();
};

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
export const optionalAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
) => {
  const token = extractToken(req);

  if (token) {
    try {
      const decoded = verifyToken(token);
      if (decoded) {
        const user = await getUserFromToken(token);
        if (user) {
          req.user = {
            profileId: user.profile_id,
            authUserId: user.id,
            role: user.role,
            phone: user.phone,
            id: user.id,
            profile_id: user.profile_id,
            name: user.name,
          };
          req.accessToken = token;
        }
      }
    } catch (error) {
      console.warn('[Optional Auth]', 'Failed to verify token, continuing as unauthenticated');
    }
  }

  return next();
};

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
export const adminOnly = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user || req.user.role !== 'admin') {
    return forbiddenError(res, 'Admin access required');
  }
  return next();
};

/**
 * Teacher-only middleware
 * 
 * Includes admin (admin has all permissions)
 */
export const teacherOnly = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user || !['teacher', 'admin'].includes(req.user.role)) {
    return forbiddenError(res, 'Teacher or Admin access required');
  }
  return next();
};

/**
 * Student-only middleware
 * 
 * Used for endpoints restricted to students
 */
export const studentOnly = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user || req.user.role !== 'student') {
    return forbiddenError(res, 'Student access required');
  }
  return next();
};

/**
 * Parent-only middleware
 * 
 * Used for parent-specific endpoints
 */
export const parentOnly = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user || req.user.role !== 'parent') {
    return forbiddenError(res, 'Parent access required');
  }
  return next();
};

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
export const checkOwnership = (paramName: string) => async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!req.user) {
    return unauthorizedError(res);
  }

  const resourceId = req.params[paramName];
  if (!resourceId) {
    return forbiddenError(res, 'Resource ID not found');
  }

  // Admin can access anything
  if (req.user.role === 'admin') {
    return next();
  }

  // Student can only access their own resources
  if (req.user.role === 'student') {
    if ((req.user.profileId ?? req.user.id) !== resourceId) {
      return forbiddenError(res, 'Cannot access other students\' resources');
    }
    return next();
  }

  // Parent can access child's resources
  if (req.user.role === 'parent') {
    // TODO: Verify that resourceId is a child of req.user.id
    // For now, allow - implement parent-child relationship check in production
    return next();
  }

  // Teacher can access batch students
  if (req.user.role === 'teacher') {
    // TODO: Verify that resourceId is in teacher's batch
    return next();
  }

  return forbiddenError(res, 'Access denied');
};

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
export const rateLimit = (key: string, maxRequests: number, windowSeconds: number) => (
  _req: Request,
  _res: Response,
  next: NextFunction
) => {
  // TODO: Implement with Redis
  void key;
  void maxRequests;
  void windowSeconds;
  next();
};

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
export const requestLogger = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const startTime = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const userId = req.user?.id || 'anonymous';
    const userRole = req.user?.role || 'guest';

    console.log(
      `[${new Date().toISOString()}] ${req.method} ${req.path} | ` +
      `User: ${userId} (${userRole}) | ` +
      `Status: ${res.statusCode} | ` +
      `Duration: ${duration}ms`
    );

    // TODO: Log to database for audit trail
    // await supabase.from('audit_logs').insert({
    //   user_id: req.user?.id,
    //   action: `${req.method} ${req.path}`,
    //   status_code: res.statusCode,
    //   timestamp: new Date()
    // });
  });

  next();
};
