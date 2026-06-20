/**
 * Firebase Admin Configuration
 */
import * as admin from 'firebase-admin';
export declare function initializeFirebase(): admin.app.App;
export declare function getFirebaseApp(): admin.app.App;
export declare function getFirebaseAuth(): admin.auth.Auth;
export declare function verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken>;
export default initializeFirebase;
//# sourceMappingURL=firebase.d.ts.map