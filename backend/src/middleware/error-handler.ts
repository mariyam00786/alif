/**
 * Error Handler Middleware
 * 
 * Centralized error handling for the Express application
 * 
 * Provides:
 * - Consistent error response format
 * - Error logging
 * - Status code mapping
 * - Async error wrapping
 */

import { Request, Response, NextFunction } from 'express';

/**
 * Error response format
 * 
 * All errors are returned in this standardized format:
 * ```json
 * {
 *   "success": false,
 *   "error": "ERROR_CODE",
 *   "message": "Human-readable message",
 *   "statusCode": 400,
 *   "timestamp": "2026-06-18T10:30:00Z"
 * }
 * ```
 */

export interface ApiErrorResponse {
  success: false;
  error: string;
  message: string;
  statusCode: number;
  timestamp: string;
  details?: any;
}

/**
 * Custom Error class for API errors
 * 
 * Usage:
 * ```typescript
 * throw new ApiError('INVALID_INPUT', 'Name is required', 400);
 * ```
 */
export class ApiError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number = 400,
    public details?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/**
 * Async handler wrapper
 * 
 * Wraps async route handlers to catch errors and pass to error middleware
 * 
 * Usage:
 * ```typescript
 * router.get('/path', asyncHandler(async (req, res) => {
 *   const data = await fetchData();
 *   res.json(data);
 * }));
 * ```
 */
export const asyncHandler = (fn: Function) => (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Send validation error response
 */
export const validationError = (
  res: Response,
  message: string,
  details?: any
) => {
  return res.status(400).json({
    success: false,
    error: 'VALIDATION_ERROR',
    message,
    statusCode: 400,
    timestamp: new Date().toISOString(),
    details,
  });
};

/**
 * Send not found error response
 */
export const notFoundError = (res: Response, resource: string) => {
  return res.status(404).json({
    success: false,
    error: 'NOT_FOUND',
    message: `${resource} not found`,
    statusCode: 404,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Send forbidden error response
 */
export const forbiddenError = (res: Response, message: string = 'Access denied') => {
  return res.status(403).json({
    success: false,
    error: 'FORBIDDEN',
    message,
    statusCode: 403,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Send unauthorized error response
 */
export const unauthorizedError = (res: Response, message: string = 'Unauthorized') => {
  return res.status(401).json({
    success: false,
    error: 'UNAUTHORIZED',
    message,
    statusCode: 401,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Send conflict error response
 */
export const conflictError = (res: Response, message: string) => {
  return res.status(409).json({
    success: false,
    error: 'CONFLICT',
    message,
    statusCode: 409,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Send internal server error response
 */
export const internalError = (res: Response, message: string = 'Internal server error') => {
  return res.status(500).json({
    success: false,
    error: 'INTERNAL_ERROR',
    message,
    statusCode: 500,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Global error handler middleware
 * 
 * Must be registered LAST in the middleware stack:
 * ```typescript
 * app.use(routes);
 * app.use(errorHandler);
 * ```
 * 
 * Handles:
 * - ApiError instances
 * - Database errors
 * - Validation errors
 * - Unknown errors
 */
export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const timestamp = new Date().toISOString();

  // Log error
  console.error(`[${timestamp}] Error:`, {
    name: err.name,
    message: err.message,
    code: err.code,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // ApiError with custom code and message
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      success: false,
      error: err.code,
      message: err.message,
      statusCode: err.statusCode,
      timestamp,
      details: err.details,
    });
  }

  // Supabase/PostgreSQL errors
  if (err.message?.includes('duplicate key')) {
    return res.status(409).json({
      success: false,
      error: 'DUPLICATE_ENTRY',
      message: 'Record already exists',
      statusCode: 409,
      timestamp,
    });
  }

  if (err.message?.includes('foreign key constraint')) {
    return res.status(400).json({
      success: false,
      error: 'INVALID_REFERENCE',
      message: 'Referenced record does not exist',
      statusCode: 400,
      timestamp,
    });
  }

  if (err.message?.includes('violates check constraint')) {
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Invalid data: ' + err.message,
      statusCode: 400,
      timestamp,
    });
  }

  // JWT/Auth errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      error: 'INVALID_TOKEN',
      message: 'Invalid authentication token',
      statusCode: 401,
      timestamp,
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      error: 'TOKEN_EXPIRED',
      message: 'Authentication token has expired',
      statusCode: 401,
      timestamp,
    });
  }

  // Validation errors (e.g., from request validation libraries)
  if (err.statusCode === 400 && err.validation) {
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      statusCode: 400,
      timestamp,
      details: err.validation,
    });
  }

  // Default: generic internal error
  res.status(500).json({
    success: false,
    error: 'INTERNAL_ERROR',
    message: process.env.NODE_ENV === 'production'
      ? 'An unexpected error occurred'
      : err.message || 'Internal server error',
    statusCode: 500,
    timestamp,
  });
};

/**
 * 404 Not Found handler
 * 
 * Should be registered before error handler:
 * ```typescript
 * app.use(routes);
 * app.use(notFoundHandler);
 * app.use(errorHandler);
 * ```
 */
export const notFoundHandler = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  res.status(404).json({
    success: false,
    error: 'NOT_FOUND',
    message: `Route ${req.method} ${req.path} not found`,
    statusCode: 404,
    timestamp: new Date().toISOString(),
  });
};
