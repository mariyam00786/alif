import type { AuthenticatedUser } from './domain';
import type { Profile } from './database';

declare global {
  namespace Express {
    interface Request {
      requestId?: string;
      accessToken?: string;
      user?: AuthenticatedUser;
      profile?: Profile;
    }
  }
}

export {};