import type { User } from '@supabase/supabase-js';
import type { Profile } from '../../types/database';
import type { AuthenticatedUser } from '../../types/domain';
import { type AuthUser } from '../auth-service';
interface AuthSession {
    authUser: User | null;
    user: AuthenticatedUser;
    profile: Profile;
}
interface ProfileUpdateInput {
    phone?: string;
    full_name?: string;
    full_name_ml?: string;
    profile_photo?: string;
}
export declare class AuthService {
    private readonly auditLogService;
    getSessionFromAccessToken(accessToken: string): Promise<AuthSession>;
    getProfileById(profileId: string): Promise<Profile>;
    updateProfile(profileId: string, payload: ProfileUpdateInput, actor: AuthenticatedUser): Promise<Profile>;
    verifyFirebaseToken(idToken: string): Promise<Record<string, unknown>>;
    signInWithSupabaseAccessToken(accessToken: string): Promise<{
        token: string;
        user: AuthUser;
        profile: Profile;
    }>;
    signInWithGoogle(idToken: string): Promise<{
        token: string;
        user: AuthUser;
        profile: Profile;
    }>;
    private getProfileForSupabaseUser;
    private getProfileForGoogleIdentity;
    private findProfileByColumn;
    private attachGoogleIdentity;
    private attachGoogleEmail;
}
export {};
//# sourceMappingURL=auth-service.d.ts.map