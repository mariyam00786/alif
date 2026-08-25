# Firebase Setup - Step by Step Guide

Complete guide to set up Firebase for the Alif Online Moral School application.

## Prerequisites

- Google account
- Firebase free tier account (at https://console.firebase.google.com)
- Web browser
- Internet connection

---

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console

1. Open https://console.firebase.google.com in your browser
2. Sign in with your Google account (create one if needed)
3. You should see the Firebase projects dashboard

### 1.2 Create New Project

1. Click **Create a project** button
2. Enter project name: `alif-school`
3. Click **Continue**

### 1.3 Configure Project

**Step 1 - Project Details:**
- Project name: `alif-school`
- Keep Analytics enabled (optional but recommended)
- Click **Continue**

**Step 2 - Google Analytics Configuration:**
- If you enabled analytics:
  - Select country/region
  - Click **Create project**
- If disabled: Just click **Create project**

### 1.4 Wait for Project Creation

- Firebase will set up your project (takes 2-5 minutes)
- You'll see a loading screen
- Once done, click **Continue** button
- You'll be taken to the project dashboard

✅ Firebase project is now created!

---

## Step 2: Register Web App

### 2.1 Add Firebase App

1. In Firebase project dashboard, look for **Get started** section
2. Click on the **Web** icon (looks like `</>`
3. Or click **Project Settings** → **General** → **Add app** → **Web**

### 2.2 Register App Details

Fill in:
- **App nickname**: `alif-school-api` (or any name)
- Check: "Also set up Firebase Hosting for this app" (optional)
- Click **Register app**

### 2.3 Copy Firebase Configuration

You'll see a code block like:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyDxx...",
  authDomain: "alif-school.firebaseapp.com",
  projectId: "alif-school",
  storageBucket: "alif-school.appspot.com",
  messagingSenderId: "12345678...",
  appId: "1:12345678:web:abc123...",
  measurementId: "G-ABC123..."
};
```

**Save these values.** You'll need them in Step 8.

---

## Step 3: Enable Phone Authentication

### 3.1 Go to Authentication

1. In Firebase console, go to left sidebar
2. Click **Authentication**
3. Click **Get Started** (if shown)
4. Click **Sign-in method** tab

### 3.2 Enable Phone Provider

1. Find **Phone** in the provider list
2. Click on it
3. Toggle the switch to **Enable** (turns blue)
4. Click **Save**

### 3.3 Configure Phone Provider (Optional)

1. You can add reCAPTCHA protection
2. For development, basic phone auth is fine
3. Click **Save**

✅ Phone authentication is now enabled!

---

## Step 4: Create Service Account

The service account is used by your backend to authenticate with Firebase.

### 4.1 Go to Project Settings

1. Click **Project Settings** (gear icon at top)
2. Go to **Service Accounts** tab

### 4.2 Generate Private Key

1. Click **Generate New Private Key** button
2. A JSON file will download automatically
3. **Important**: Save this file safely
   - Save as: `firebase-service-account.json`
   - Location: `c:\Users\JAMSHEER\Desktop\alifschool\backend\`

### 4.3 Keep File Safe

⚠️ **IMPORTANT:**
- Never commit this file to Git
- Never share this key
- Add to `.gitignore` (already done in our project)
- Treat it like a password

---

## Step 5: Get Service Account Credentials

### 5.1 View Service Account Key

The JSON file you downloaded contains:

```json
{
  "type": "service_account",
  "project_id": "alif-school",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxx@alif-school.iam.gserviceaccount.com",
  "client_id": "123456789...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://...",
  "client_x509_cert_url": "https://..."
}
```

### 5.2 Note Important Fields

You may need these later (they're in the JSON file):
- `project_id`: "alif-school"
- `private_key`: (Long string, starts with -----BEGIN PRIVATE KEY-----)
- `private_key_id`: (Short string)
- `client_email`: Firebase service account email

---

## Step 6: Enable Cloud Messaging (FCM)

FCM is used for push notifications.

### 6.1 Go to Cloud Messaging

1. In Firebase console, go to left sidebar
2. Click **Cloud Messaging** tab
3. Look for **Cloud Messaging API** in the settings

### 6.2 Enable the API

1. Click **Enable** if shown
2. Wait a moment for it to enable
3. Once enabled, you'll see:
   - **Server API Key**
   - **Sender ID**

### 6.3 Save Server Key and Sender ID

Keep these visible. You might need them:
- **Server Key**: Used for sending messages from backend
- **Sender ID**: Used in mobile/web apps

---

## Step 7: Configure Additional Settings (Optional)

### 7.1 Enable Firestore (Optional)

If you want to use Firestore database later:

1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select your region
5. Click **Enable**

### 7.2 Configure Storage (Optional)

If you want to use Firebase Storage:

1. Go to **Storage**
2. Click **Get Started**
3. Accept defaults
4. Click **Done**

---

## Step 8: Add Credentials to .env File

### 8.1 Open .env File

Navigate to: `c:\Users\JAMSHEER\Desktop\alifschool\backend\.env`

You should already have Supabase credentials. Now add Firebase credentials.

### 8.2 Add Firebase Configuration

From the Firebase config you saved in Step 2, add:

```env
# Firebase Configuration
FIREBASE_API_KEY=AIzaSyDxx...
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
FIREBASE_PROJECT_ID=alif-school
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789...
FIREBASE_APP_ID=1:123456789:web:abc123...
FIREBASE_MEASUREMENT_ID=G-ABC123...
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### 8.3 Complete .env Example

Your `.env` file should now look like:

```env
# Application
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Firebase Configuration
FIREBASE_API_KEY=AIzaSyDxx...
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
FIREBASE_PROJECT_ID=alif-school
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789...
FIREBASE_APP_ID=1:123456789:web:abc123...
FIREBASE_MEASUREMENT_ID=G-ABC123...
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# JWT Configuration
JWT_SECRET=your-jwt-secret-change-in-production
JWT_EXPIRES_IN=7d

# Email Configuration
EMAIL_PROVIDER=sendgrid
EMAIL_API_KEY=

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3001
CORS_CREDENTIALS=true

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 8.4 Save the File

Save your `.env` file.

---

## Step 9: Verify Configuration

### 9.1 Check File Placement

Verify the service account JSON file is in the correct location:

```
c:\Users\JAMSHEER\Desktop\alifschool\backend\firebase-service-account.json
```

### 9.2 Start Backend Server

```bash
cd backend
npm run dev
```

### 9.3 Check Firebase Initialization

You should see in the console:

```
🔄 Initializing Firebase...
✅ Firebase Admin SDK initialized
```

✅ If you see this message, Firebase is connected!

### 9.4 Check Health Endpoint

Open in browser: `http://localhost:3000/health`

Both Supabase and Firebase should now be working.

---

## Step 10: Additional Firebase Configuration (Optional)

### 10.1 Set Security Rules for Firestore (if enabled)

In Firebase console:

1. Go to **Firestore Database**
2. Click **Rules** tab
3. Update default rules for security
4. Click **Publish**

### 10.2 Set Storage Rules (if enabled)

In Firebase console:

1. Go to **Storage**
2. Click **Rules** tab
3. Set appropriate access rules
4. Click **Publish**

### 10.3 Configure Email Settings (Optional)

For email authentication or notifications:

1. Go to **Authentication**
2. Click **Templates** tab
3. Configure email templates as needed

---

## Troubleshooting

### Error: "Failed to initialize Firebase"

**Solution:**
1. Verify `FIREBASE_PROJECT_ID` in `.env`
2. Check `firebase-service-account.json` exists in backend directory
3. Verify the JSON file is valid (no corruption)
4. Check file permissions (should be readable)

### Error: "Service account not found"

**Solution:**
1. Verify path in `.env`: `FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json`
2. Make sure file is in: `c:\Users\JAMSHEER\Desktop\alifschool\backend\`
3. Restart backend server

### Phone Authentication Not Working

**Solution:**
1. Verify Phone provider is enabled (Step 3.2)
2. Check SMS quotas in Firebase console
3. Verify phone number format

### Project Not Found Error

**Solution:**
1. Verify project ID in `.env`
2. Check you're using correct Firebase account
3. Verify project still exists in Firebase console

### Configuration Shows in Error Logs

**Solution:**
1. This is normal in development mode
2. Logs may show which keys are missing
3. Fill in the missing keys and restart

---

## Security Checklist

Before deploying to production:

- [ ] Never commit `.env` file to Git
- [ ] Never commit `firebase-service-account.json` to Git
- [ ] Use strong `JWT_SECRET` value
- [ ] Rotate credentials regularly
- [ ] Use environment-specific credentials
- [ ] Enable Cloud Audit Logging
- [ ] Review IAM permissions
- [ ] Set up monitoring and alerts

---

## Next Steps

✅ Firebase is now configured!

Continue with:

1. **Backend Development** - Start implementing API routes
2. **Authentication Setup** - Configure OTP login flow
3. **Cloud Messaging** - Set up push notifications
4. **Firestore/Storage** - Set up data storage (if needed)

---

## Useful Firebase CLI Commands

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# Deploy to Firebase Hosting
firebase deploy

# View logs
firebase functions:log

# Emulate locally
firebase emulators:start
```

---

## Summary

| Step | Status | What You Did |
|------|--------|-------------|
| 1 | ✅ | Created Firebase project |
| 2 | ✅ | Registered Web app |
| 3 | ✅ | Enabled Phone authentication |
| 4 | ✅ | Created service account |
| 5 | ✅ | Got service account credentials |
| 6 | ✅ | Enabled Cloud Messaging |
| 7 | ✅ | Configured optional services |
| 8 | ✅ | Added credentials to .env |
| 9 | ✅ | Verified configuration |
| 10 | ✅ | Set up security rules |

---

## Credentials Location Reference

| Credential | Location in Firebase Console |
|-----------|------------------------------|
| Project ID | Project Settings → General |
| API Key | Project Settings → General |
| Auth Domain | Project Settings → General |
| Storage Bucket | Project Settings → General |
| Messaging Sender ID | Project Settings → Cloud Messaging |
| App ID | Project Settings → General |
| Service Account Key | Project Settings → Service Accounts |

---

**Firebase Setup Complete! 🎉**

Your authentication and messaging system is now ready for backend development.
