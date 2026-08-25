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
export declare class ApiError extends Error {
    code: string;
    message: string;
    statusCode: number;
    details?: any | undefined;
    constructor(code: string, message: string, statusCode?: number, details?: any | undefined);
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
export declare const asyncHandler: (fn: Function) => (req: Request, res: Response, next: NextFunction) => void;
/**
 * Send validation error response
 */
export declare const validationError: (res: Response, message: string, details?: any) => Response<any, Record<string, any>>;
/**
 * Send not found error response
 */
export declare const notFoundError: (res: Response, resource: string) => Response<any, Record<string, any>>;
/**
 * Send forbidden error response
 */
export declare const forbiddenError: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Send unauthorized error response
 */
export declare const unauthorizedError: (res: Response, message?: string) => Response<any, Record<string, any>>;
/**
 * Send conflict error response
 */
export declare const conflictError: (res: Response, message: string) => Response<any, Record<string, any>>;
/**
 * Send internal server error response
 */
export declare const internalError: (res: Response, message?: string) => Response<any, Record<string, any>>;
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
export declare const errorHandler: (err: any, req: Request, res: Response, next: NextFunction) => Response<any, Record<string, any>> | undefined;
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
export declare const notFoundHandler: (req: Request, res: Response, next: NextFunction) => void;
//# sourceMappingURL=error-handler.d.ts.map