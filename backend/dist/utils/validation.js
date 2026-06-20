"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureObject = ensureObject;
exports.getRequiredString = getRequiredString;
exports.getOptionalString = getOptionalString;
exports.getOptionalInteger = getOptionalInteger;
exports.getOptionalBoolean = getOptionalBoolean;
exports.getEnumValue = getEnumValue;
exports.getDateString = getDateString;
exports.getPagination = getPagination;
const http_error_1 = require("../errors/http-error");
function isRecord(value) {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}
function ensureObject(value, message = 'Request body must be a JSON object.') {
    if (!isRecord(value)) {
        throw new http_error_1.HttpError(400, message);
    }
    return value;
}
function getRequiredString(value, fieldName) {
    if (typeof value !== 'string' || value.trim().length === 0) {
        throw new http_error_1.HttpError(400, `${fieldName} is required.`);
    }
    return value.trim();
}
function getOptionalString(value, fieldName) {
    if (typeof value === 'undefined' || value === null || value === '') {
        return undefined;
    }
    if (typeof value !== 'string') {
        throw new http_error_1.HttpError(400, `${fieldName} must be a string.`);
    }
    return value.trim();
}
function getOptionalInteger(value, fieldName) {
    if (typeof value === 'undefined' || value === null || value === '') {
        return undefined;
    }
    if (typeof value !== 'number' || !Number.isInteger(value)) {
        throw new http_error_1.HttpError(400, `${fieldName} must be an integer.`);
    }
    return value;
}
function getOptionalBoolean(value, fieldName) {
    if (typeof value === 'undefined' || value === null || value === '') {
        return undefined;
    }
    if (typeof value !== 'boolean') {
        throw new http_error_1.HttpError(400, `${fieldName} must be a boolean.`);
    }
    return value;
}
function getEnumValue(value, fieldName, allowedValues, required = false) {
    if (typeof value === 'undefined' || value === null || value === '') {
        if (required) {
            throw new http_error_1.HttpError(400, `${fieldName} is required.`);
        }
        return undefined;
    }
    if (typeof value !== 'string' || !allowedValues.includes(value)) {
        throw new http_error_1.HttpError(400, `${fieldName} must be one of: ${allowedValues.join(', ')}.`);
    }
    return value;
}
function getDateString(value, fieldName, required = false) {
    if (typeof value === 'undefined' || value === null || value === '') {
        if (required) {
            throw new http_error_1.HttpError(400, `${fieldName} is required.`);
        }
        return undefined;
    }
    if (typeof value !== 'string' || Number.isNaN(Date.parse(value))) {
        throw new http_error_1.HttpError(400, `${fieldName} must be a valid date string.`);
    }
    return value;
}
function getPagination(query) {
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
//# sourceMappingURL=validation.js.map