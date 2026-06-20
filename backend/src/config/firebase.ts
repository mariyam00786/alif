/**
 * Firebase Admin Configuration
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App {
  if (firebaseApp) return firebaseApp;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) {
    console.warn('Firebase configuration missing (FIREBASE_PROJECT_ID)');
    return {} as admin.app.App; // Return dummy
  }

  try {
    let serviceAccount: any;
    if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH && fs.existsSync(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)) {
      serviceAccount = JSON.parse(fs.readFileSync(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH), 'utf8'));
    } else {
      serviceAccount = {
        type: 'service_account',
        project_id: projectId,
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
      };
    }

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId,
    });
    return firebaseApp;
  } catch (error) {
    console.error('Error initializing Firebase:', error);
    throw error;
  }
}

export function getFirebaseApp(): admin.app.App {
  return firebaseApp || initializeFirebase();
}

export function getFirebaseAuth(): admin.auth.Auth {
  return getFirebaseApp().auth();
}

export async function verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
  try {
    return await getFirebaseAuth().verifyIdToken(idToken);
  } catch (error) {
    throw new Error(`Invalid Firebase token: ${error}`);
  }
}

export default initializeFirebase;
