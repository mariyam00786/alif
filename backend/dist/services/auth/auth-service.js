"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const supabase_1 = require("../../config/supabase");
const firebase_1 = require("../../config/firebase");
const http_error_1 = require("../../errors/http-error");
const audit_log_service_1 = require("../audit/audit-log-service");
const auth_service_1 = require("../auth-service");
class AuthService {
    constructor() {
        this.auditLogService = new audit_log_service_1.AuditLogService();
    }
    async getSessionFromAccessToken(accessToken) {
        let supabaseUser = null;
        let supabaseError;
        try {
            const { data, error } = await (0, supabase_1.getSupabaseClient)().auth.getUser(accessToken);
            supabaseUser = data.user ?? null;
            supabaseError = error;
        }
        catch (error) {
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
        const jwtUser = await (0, auth_service_1.getUserFromToken)(accessToken);
        if (jwtUser) {
            let profile;
            try {
                profile = await this.getProfileById(jwtUser.profile_id);
            }
            catch {
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
        throw new http_error_1.HttpError(401, 'Invalid or expired access token.', supabaseError);
    }
    async getProfileById(profileId) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('profiles')
            .select('*')
            .eq('id', profileId)
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to load the user profile.', error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, 'Profile not found for authenticated user.');
        }
        return data;
    }
    async updateProfile(profileId, payload, actor) {
        if (actor.profileId !== profileId && actor.role !== 'admin') {
            throw new http_error_1.HttpError(403, 'You can only update your own profile.');
        }
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('profiles')
            .update({
            ...payload,
            updated_at: new Date().toISOString(),
        })
            .eq('id', profileId)
            .select('*')
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to update the profile.', error);
        }
        if (!data) {
            throw new http_error_1.HttpError(404, 'Profile not found.');
        }
        await this.auditLogService.log({
            actor,
            action: 'update-profile',
            entityType: 'profile',
            entityId: profileId,
            metadata: payload,
        });
        return data;
    }
    async verifyFirebaseToken(idToken) {
        const decodedToken = await (0, firebase_1.verifyIdToken)(idToken);
        return {
            uid: decodedToken.uid,
            email: decodedToken.email ?? null,
            phoneNumber: decodedToken.phone_number ?? null,
            firebase: decodedToken.firebase,
        };
    }
    async signInWithSupabaseAccessToken(accessToken) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)().auth.getUser(accessToken);
        const supabaseUser = data.user;
        if (error || !supabaseUser) {
            throw new http_error_1.HttpError(401, 'Invalid or expired Supabase access token.', error);
        }
        const profile = await this.getProfileForSupabaseUser(supabaseUser);
        const user = {
            id: supabaseUser.id,
            phone: profile.phone,
            role: profile.role,
            name: profile.full_name,
            profile_id: profile.id,
            has_parent_access: await this.profileHasChildren(profile.id),
        };
        return {
            token: (0, auth_service_1.createToken)(user).access_token,
            user,
            profile,
        };
    }
    async signInWithGoogle(idToken) {
        const decodedToken = await (0, firebase_1.verifyIdToken)(idToken);
        const googleEmail = decodedToken.email?.trim().toLowerCase();
        const profile = await this.getProfileForGoogleIdentity({
            firebaseUid: decodedToken.uid,
            googleEmail,
            phoneNumber: decodedToken.phone_number ?? undefined,
        });
        const user = {
            id: decodedToken.uid,
            phone: profile.phone,
            role: profile.role,
            name: profile.full_name,
            profile_id: profile.id,
            has_parent_access: await this.profileHasChildren(profile.id),
        };
        return {
            token: (0, auth_service_1.createToken)(user).access_token,
            user,
            profile,
        };
    }
    /**
     * Returns true when the given profile is linked to at least one student via
     * the parent_students table. This is independent of the profile's primary
     * `role`, so a student account that is also a parent can switch into the
     * parent view from a single sign-in.
     */
    async profileHasChildren(profileId) {
        const { count, error } = await (0, supabase_1.getSupabaseClient)()
            .from('parent_students')
            .select('student_id', { count: 'exact', head: true })
            .eq('parent_profile_id', profileId);
        if (error)
            return false;
        return (count ?? 0) > 0;
    }
    async getProfileForSupabaseUser(authUser) {
        try {
            return await this.getProfileById(authUser.id);
        }
        catch {
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
        throw new http_error_1.HttpError(403, 'No profile is linked to this Supabase Google account. Assign a matching profile before login.');
    }
    async getProfileForGoogleIdentity(identity) {
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
        throw new http_error_1.HttpError(403, 'No profile is linked to this Google account. Assign a matching profile before login.');
    }
    async findProfileByColumn(column, value) {
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('profiles')
            .select('*')
            .eq(column, value)
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, `Unable to load profile by ${column}.`, error);
        }
        return data ?? null;
    }
    async attachGoogleIdentity(profile, identity) {
        const normalizedEmail = identity.googleEmail?.trim().toLowerCase();
        const needsUpdate = profile.firebase_uid !== identity.firebaseUid ||
            (normalizedEmail != null && normalizedEmail.length > 0 && profile.google_email !== normalizedEmail);
        if (!needsUpdate) {
            return profile;
        }
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
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
            throw new http_error_1.HttpError(500, 'Unable to attach Google identity to profile.', error);
        }
        return data ?? profile;
    }
    async attachGoogleEmail(profile, googleEmail) {
        const normalizedEmail = googleEmail?.trim().toLowerCase();
        if (normalizedEmail == null || normalizedEmail.length == 0 || profile.google_email == normalizedEmail) {
            return profile;
        }
        const { data, error } = await (0, supabase_1.getSupabaseClient)()
            .from('profiles')
            .update({
            google_email: normalizedEmail,
            updated_at: new Date().toISOString(),
        })
            .eq('id', profile.id)
            .select('*')
            .maybeSingle();
        if (error) {
            throw new http_error_1.HttpError(500, 'Unable to attach Supabase Google email to profile.', error);
        }
        return data ?? profile;
    }
}
exports.AuthService = AuthService;
//# sourceMappingURL=auth-service.js.map