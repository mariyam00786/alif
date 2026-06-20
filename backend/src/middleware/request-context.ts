import type { NextFunction, Request, Response } from 'express';
import { randomUUID } from 'crypto';

export function requestContextMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestIdHeader = req.header('x-request-id');
  const requestId = requestIdHeader && requestIdHeader.trim().length > 0
    ? requestIdHeader
    : randomUUID();

  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);
  next();
}