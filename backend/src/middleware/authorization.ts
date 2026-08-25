import type { RequestHandler } from 'express';
import type { UserRole } from '../types/domain';
import { HttpError } from '../errors/http-error';

export function requireRoles(...roles: UserRole[]): RequestHandler {
  return (req, _res, next) => {
    if (!req.user) {
      return next(new HttpError(401, 'Authentication is required.'));
    }

    if (!roles.includes(req.user.role)) {
      return next(new HttpError(403, 'You do not have access to this resource.'));
    }

    return next();
  };
}