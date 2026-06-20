"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = exports.errorHandler = exports.internalError = exports.conflictError = exports.unauthorizedError = exports.forbiddenError = exports.notFoundError = exports.validationError = exports.asyncHandler = exports.ApiError = void 0;
/**
 * Custom Error class for API errors
 *
 * Usage:
 * ```typescript
 * throw new ApiError('INVALID_INPUT', 'Name is required', 400);
 * ```
 */
class ApiError extends Error {
    constructor(code, message, statusCode = 400, details) {
        super(message);
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
        this.details = details;
        this.name = 'ApiError';
    }
}
exports.ApiError = ApiError;
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
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};
exports.asyncHandler = asyncHandler;
/**
 * Send validation error response
 */
const validationError = (res, message, details) => {
    return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message,
        statusCode: 400,
        timestamp: new Date().toISOString(),
        details,
    });
};
exports.validationError = validationError;
/**
 * Send not found error response
 */
const notFoundError = (res, resource) => {
    return res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: `${resource} not found`,
        statusCode: 404,
        timestamp: new Date().toISOString(),
    });
};
exports.notFoundError = notFoundError;
/**
 * Send forbidden error response
 */
const forbiddenError = (res, message = 'Access denied') => {
    return res.status(403).json({
        success: false,
        error: 'FORBIDDEN',
        message,
        statusCode: 403,
        timestamp: new Date().toISOString(),
    });
};
exports.forbiddenError = forbiddenError;
/**
 * Send unauthorized error response
 */
const unauthorizedError = (res, message = 'Unauthorized') => {
    return res.status(401).json({
        success: false,
        error: 'UNAUTHORIZED',
        message,
        statusCode: 401,
        timestamp: new Date().toISOString(),
    });
};
exports.unauthorizedError = unauthorizedError;
/**
 * Send conflict error response
 */
const conflictError = (res, message) => {
    return res.status(409).json({
        success: false,
        error: 'CONFLICT',
        message,
        statusCode: 409,
        timestamp: new Date().toISOString(),
    });
};
exports.conflictError = conflictError;
/**
 * Send internal server error response
 */
const internalError = (res, message = 'Internal server error') => {
    return res.status(500).json({
        success: false,
        error: 'INTERNAL_ERROR',
        message,
        statusCode: 500,
        timestamp: new Date().toISOString(),
    });
};
exports.internalError = internalError;
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
const errorHandler = (err, req, res, next) => {
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
exports.errorHandler = errorHandler;
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
const notFoundHandler = (req, res, next) => {
    res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: `Route ${req.method} ${req.path} not found`,
        statusCode: 404,
        timestamp: new Date().toISOString(),
    });
};
exports.notFoundHandler = notFoundHandler;
//# sourceMappingURL=error-handler.js.map