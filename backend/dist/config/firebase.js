"use strict";
/**
 * Firebase Admin Configuration
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.initializeFirebase = initializeFirebase;
exports.getFirebaseApp = getFirebaseApp;
exports.getFirebaseAuth = getFirebaseAuth;
exports.verifyIdToken = verifyIdToken;
const admin = __importStar(require("firebase-admin"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let firebaseApp = null;
function initializeFirebase() {
    if (firebaseApp)
        return firebaseApp;
    const projectId = process.env.FIREBASE_PROJECT_ID;
    if (!projectId) {
        console.warn('Firebase configuration missing (FIREBASE_PROJECT_ID)');
        return {}; // Return dummy
    }
    try {
        let serviceAccount;
        if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH && fs.existsSync(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)) {
            serviceAccount = JSON.parse(fs.readFileSync(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH), 'utf8'));
        }
        else {
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
    }
    catch (error) {
        console.error('Error initializing Firebase:', error);
        throw error;
    }
}
function getFirebaseApp() {
    return firebaseApp || initializeFirebase();
}
function getFirebaseAuth() {
    return getFirebaseApp().auth();
}
async function verifyIdToken(idToken) {
    try {
        return await getFirebaseAuth().verifyIdToken(idToken);
    }
    catch (error) {
        throw new Error(`Invalid Firebase token: ${error}`);
    }
}
exports.default = initializeFirebase;
//# sourceMappingURL=firebase.js.map