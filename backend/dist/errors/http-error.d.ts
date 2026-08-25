export declare class HttpError extends Error {
    readonly statusCode: number;
    readonly details?: unknown | undefined;
    constructor(statusCode: number, message: string, details?: unknown | undefined);
}
export declare function isHttpError(error: unknown): error is HttpError;
//# sourceMappingURL=http-error.d.ts.map