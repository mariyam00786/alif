import { HttpError } from '../errors/http-error';

type UnknownRecord = Record<string, unknown>;

function isRecord(value: unknown): value is UnknownRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function ensureObject(value: unknown, message = 'Request body must be a JSON object.'): UnknownRecord {
  if (!isRecord(value)) {
    throw new HttpError(400, message);
  }

  return value;
}

export function getRequiredString(value: unknown, fieldName: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpError(400, `${fieldName} is required.`);
  }

  return value.trim();
}

export function getOptionalString(value: unknown, fieldName: string): string | undefined {
  if (typeof value === 'undefined' || value === null || value === '') {
    return undefined;
  }

  if (typeof value !== 'string') {
    throw new HttpError(400, `${fieldName} must be a string.`);
  }

  return value.trim();
}

export function getOptionalInteger(value: unknown, fieldName: string): number | undefined {
  if (typeof value === 'undefined' || value === null || value === '') {
    return undefined;
  }

  if (typeof value !== 'number' || !Number.isInteger(value)) {
    throw new HttpError(400, `${fieldName} must be an integer.`);
  }

  return value;
}

export function getOptionalBoolean(value: unknown, fieldName: string): boolean | undefined {
  if (typeof value === 'undefined' || value === null || value === '') {
    return undefined;
  }

  if (typeof value !== 'boolean') {
    throw new HttpError(400, `${fieldName} must be a boolean.`);
  }

  return value;
}

export function getEnumValue<T extends string>(
  value: unknown,
  fieldName: string,
  allowedValues: readonly T[],
  required = false
): T | undefined {
  if (typeof value === 'undefined' || value === null || value === '') {
    if (required) {
      throw new HttpError(400, `${fieldName} is required.`);
    }

    return undefined;
  }

  if (typeof value !== 'string' || !allowedValues.includes(value as T)) {
    throw new HttpError(400, `${fieldName} must be one of: ${allowedValues.join(', ')}.`);
  }

  return value as T;
}

export function getDateString(value: unknown, fieldName: string, required = false): string | undefined {
  if (typeof value === 'undefined' || value === null || value === '') {
    if (required) {
      throw new HttpError(400, `${fieldName} is required.`);
    }

    return undefined;
  }

  if (typeof value !== 'string' || Number.isNaN(Date.parse(value))) {
    throw new HttpError(400, `${fieldName} must be a valid date string.`);
  }

  return value;
}

export function getPagination(query: UnknownRecord): { limit: number; page: number; offset: number } {
  const rawLimit = typeof query.limit === 'string' ? Number.parseInt(query.limit, 10) : 25;
  const rawPage = typeof query.page === 'string' ? Number.parseInt(query.page, 10) : 1;

  const limit = Number.isInteger(rawLimit) && rawLimit > 0 ? Math.min(rawLimit, 100) : 25;
  const page = Number.isInteger(rawPage) && rawPage > 0 ? rawPage : 1;

  return {
    limit,
    page,
    offset: (page - 1) * limit,
  };
}