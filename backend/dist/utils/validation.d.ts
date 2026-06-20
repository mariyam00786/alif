type UnknownRecord = Record<string, unknown>;
export declare function ensureObject(value: unknown, message?: string): UnknownRecord;
export declare function getRequiredString(value: unknown, fieldName: string): string;
export declare function getOptionalString(value: unknown, fieldName: string): string | undefined;
export declare function getOptionalInteger(value: unknown, fieldName: string): number | undefined;
export declare function getOptionalBoolean(value: unknown, fieldName: string): boolean | undefined;
export declare function getEnumValue<T extends string>(value: unknown, fieldName: string, allowedValues: readonly T[], required?: boolean): T | undefined;
export declare function getDateString(value: unknown, fieldName: string, required?: boolean): string | undefined;
export declare function getPagination(query: UnknownRecord): {
    limit: number;
    page: number;
    offset: number;
};
export {};
//# sourceMappingURL=validation.d.ts.map