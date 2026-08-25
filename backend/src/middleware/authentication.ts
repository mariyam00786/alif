import type { NextFunction, Request, Response } from 'express';
import { AuthService } from '../services/auth/auth-service';
import { HttpError } from '../errors/http-error';

const authService = new AuthService();

export async function authenticateRequest(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const authorizationHeader = req.header('authorization');

    if (!authorizationHeader?.startsWith('Bearer ')) {
      throw new HttpError(401, 'Missing Bearer access token.');
    }

    const accessToken = authorizationHeader.slice('Bearer '.length).trim();

    if (!accessToken) {
      throw new HttpError(401, 'Missing Bearer access token.');
    }

    const session = await authService.getSessionFromAccessToken(accessToken);

    req.accessToken = accessToken;
    req.user = session.user;
    req.profile = session.profile;

    next();
  } catch (error) {
    next(error);
  }
}