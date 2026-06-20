import type { User } from '@supabase/supabase-js';
import { getSupabaseClient } from '../../config/supabase';
import { verifyIdToken } from '../../config/firebase';
import { HttpError } from '../../errors/http-error';
import type { Profile } from '../../types/database';
import type { AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';
import { createToken, getUserFromToken, type AuthUser } from '../auth-service';

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

export class AuthService {
  private readonly auditLogService = new AuditLogService();

  async getSessionFromAccessToken(accessToken: string): Promise<AuthSession> {
    let supabaseUser: User | null = null;
    let supabaseError: unknown;

    try {
      const { data, error } = await getSupabaseClient().auth.getUser(accessToken);
      supabaseUser = data.user ?? null;
      supabaseError = error;
    } catch (error) {
      supabaseError = error;
    }

    if (supabaseUser) {
      const profile = await this.getProfileById(supabaseUser.id);

      return {
        authUser: supabaseUser,
        user: {
          profileId: profile.id,
          authUserId: supabaseUser.id,
          role: profile.role,
          phone: profile.phone,
        },
        profile,
      };
    }

    // Fallback for JWT tokens issued by the OTP login flow.
    const jwtUser = await getUserFromToken(accessToken);
    if (jwtUser) {
      let profile: Profile;
      try {
        profile = await this.getProfileById(jwtUser.profile_id);
      } catch {
        const now = new Date().toISOString();
        profile = {
          id: jwtUser.profile_id,
          phone: jwtUser.phone,
          full_name: jwtUser.name,
          role: jwtUser.role,
          created_at: now,
          updated_at: now,
        };
      }

      return {
        authUser: null,
        user: {
          profileId: profile.id,
          authUserId: jwtUser.id,
          role: jwtUser.role,
          phone: jwtUser.phone,
        },
        profile,
      };
    }

    throw new HttpError(401, 'Invalid or expired access token.', supabaseError);
  }

  async getProfileById(profileId: string): Promise<Profile> {
    const { data, error } = await getSupabaseClient()
      .from('profiles')
      .select('*')
      .eq('id', profileId)
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to load the user profile.', error);
    }

    if (!data) {
      throw new HttpError(404, 'Profile not found for authenticated user.');
    }

    return data as Profile;
  }

  async updateProfile(
    profileId: string,
    payload: ProfileUpdateInput,
    actor: AuthenticatedUser
  ): Promise<Profile> {
    if (actor.profileId !== profileId && actor.role !== 'admin') {
      throw new HttpError(403, 'You can only update your own profile.');
    }

    const { data, error } = await getSupabaseClient()
      .from('profiles')
      .update({
        ...payload,
        updated_at: new Date().toISOString(),
      })
      .eq('id', profileId)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to update the profile.', error);
    }

    if (!data) {
      throw new HttpError(404, 'Profile not found.');
    }

    await this.auditLogService.log({
      actor,
      action: 'update-profile',
      entityType: 'profile',
      entityId: profileId,
      metadata: payload as Record<string, unknown>,
    });

    return data as Profile;
  }

  async verifyFirebaseToken(idToken: string): Promise<Record<string, unknown>> {
    const decodedToken = await verifyIdToken(idToken);

    return {
      uid: decodedToken.uid,
      email: decodedToken.email ?? null,
      phoneNumber: decodedToken.phone_number ?? null,
      firebase: decodedToken.firebase,
    };
  }

  async signInWithSupabaseAccessToken(accessToken: string): Promise<{
    token: string;
    user: AuthUser;
    profile: Profile;
  }> {
    const { data, error } = await getSupabaseClient().auth.getUser(accessToken);
    const supabaseUser = data.user;

    if (error || !supabaseUser) {
      throw new HttpError(401, 'Invalid or expired Supabase access token.', error);
    }

    const profile = await this.getProfileForSupabaseUser(supabaseUser);
    const user: AuthUser = {
      id: supabaseUser.id,
      phone: profile.phone,
      role: profile.role,
      name: profile.full_name,
      profile_id: profile.id,
    };

    return {
      token: createToken(user).access_token,
      user,
      profile,
    };
  }

  async signInWithGoogle(idToken: string): Promise<{
    token: string;
    user: AuthUser;
    profile: Profile;
  }> {
    const decodedToken = await verifyIdToken(idToken);
    const googleEmail = decodedToken.email?.trim().toLowerCase();

    const profile = await this.getProfileForGoogleIdentity({
      firebaseUid: decodedToken.uid,
      googleEmail,
      phoneNumber: decodedToken.phone_number ?? undefined,
    });

    const user: AuthUser = {
      id: decodedToken.uid,
      phone: profile.phone,
      role: profile.role,
      name: profile.full_name,
      profile_id: profile.id,
    };

    return {
      token: createToken(user).access_token,
      user,
      profile,
    };
  }

  private async getProfileForSupabaseUser(authUser: User): Promise<Profile> {
    try {
      return await this.getProfileById(authUser.id);
    } catch {
      // Fall back to business-profile lookup for seeded data that predates auth.users linkage.
    }

    const googleEmail = authUser.email?.trim().toLowerCase();
    if (googleEmail) {
      const byEmail = await this.findProfileByColumn('google_email', googleEmail);
      if (byEmail) {
        return this.attachGoogleEmail(byEmail, googleEmail);
      }
    }

    const phoneNumber = authUser.phone?.trim();
    if (phoneNumber) {
      const byPhone = await this.findProfileByColumn('phone', phoneNumber);
      if (byPhone) {
        return this.attachGoogleEmail(byPhone, googleEmail);
      }
    }

    throw new HttpError(
      403,
      'No profile is linked to this Supabase Google account. Assign a matching profile before login.'
    );
  }

  private async getProfileForGoogleIdentity(identity: {
    firebaseUid: string;
    googleEmail?: string;
    phoneNumber?: string;
  }): Promise<Profile> {
    const byFirebaseUid = await this.findProfileByColumn('firebase_uid', identity.firebaseUid);
    if (byFirebaseUid) {
      return this.attachGoogleIdentity(byFirebaseUid, identity);
    }

    if (identity.googleEmail) {
      const byEmail = await this.findProfileByColumn('google_email', identity.googleEmail);
      if (byEmail) {
        return this.attachGoogleIdentity(byEmail, identity);
      }
    }

    if (identity.phoneNumber) {
      const byPhone = await this.findProfileByColumn('phone', identity.phoneNumber);
      if (byPhone) {
        return this.attachGoogleIdentity(byPhone, identity);
      }
    }

    throw new HttpError(
      403,
      'No profile is linked to this Google account. Assign a matching profile before login.'
    );
  }

  private async findProfileByColumn(
    column: 'firebase_uid' | 'google_email' | 'phone',
    value: string
  ): Promise<Profile | null> {
    const { data, error } = await getSupabaseClient()
      .from('profiles')
      .select('*')
      .eq(column, value)
      .maybeSingle();

    if (error) {
      throw new HttpError(500, `Unable to load profile by ${column}.`, error);
    }

    return (data as Profile | null) ?? null;
  }

  private async attachGoogleIdentity(
    profile: Profile,
    identity: {
      firebaseUid: string;
      googleEmail?: string;
    }
  ): Promise<Profile> {
    const normalizedEmail = identity.googleEmail?.trim().toLowerCase();
    const needsUpdate =
      profile.firebase_uid !== identity.firebaseUid ||
      (normalizedEmail != null && normalizedEmail.length > 0 && profile.google_email !== normalizedEmail);

    if (!needsUpdate) {
      return profile;
    }

    const { data, error } = await getSupabaseClient()
      .from('profiles')
      .update({
        firebase_uid: identity.firebaseUid,
        google_email: normalizedEmail ?? profile.google_email ?? null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', profile.id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to attach Google identity to profile.', error);
    }

    return (data as Profile | null) ?? profile;
  }

  private async attachGoogleEmail(
    profile: Profile,
    googleEmail?: string,
  ): Promise<Profile> {
    const normalizedEmail = googleEmail?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.length == 0 || profile.google_email == normalizedEmail) {
      return profile;
    }

    const { data, error } = await getSupabaseClient()
      .from('profiles')
      .update({
        google_email: normalizedEmail,
        updated_at: new Date().toISOString(),
      })
      .eq('id', profile.id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, 'Unable to attach Supabase Google email to profile.', error);
    }

    return (data as Profile | null) ?? profile;
  }
}