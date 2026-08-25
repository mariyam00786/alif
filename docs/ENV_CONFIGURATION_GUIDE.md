# Complete .env Configuration Guide

Step-by-step guide to configure all environment variables for the Alif Online Moral School backend.

## File Location

```
c:\Users\JAMSHEER\Desktop\alifschool\backend\.env
```

---

## Step 1: Create .env File

If `.env` doesn't exist, create it by copying the example:

```bash
cd c:\Users\JAMSHEER\Desktop\alifschool\backend
copy .env.example .env
```

Or create manually:
1. Open VS Code
2. Go to `backend` folder
3. Create new file: `.env`
4. Add the configuration below

---

## Step 2: Application Configuration

### 2.1 Node Environment

**What is it?** Tells the application whether it's in development or production mode.

```env
# Development mode (use this for local development)
NODE_ENV=development

# Or for production:
# NODE_ENV=production
```

**Options:**
- `development` - Shows detailed logs, relaxed validation
- `production` - Optimized, minimal logs, strict validation
- `test` - For testing

### 2.2 Port

**What is it?** The port number your backend API will run on.

```env
# Default port 3000
PORT=3000

# Or use any free port:
# PORT=5000
# PORT=8000
```

**How to check if port is available:**
```bash
# Windows
netstat -ano | findstr :3000

# If port is in use, choose a different number like 3001
```

### 2.3 Log Level

**What is it?** How detailed the console logs should be.

```env
# Options: error, warn, info, debug, trace
LOG_LEVEL=info

# Examples:
# LOG_LEVEL=debug    # Most detailed (development)
# LOG_LEVEL=warn     # Show warnings and errors
# LOG_LEVEL=error    # Only errors
```

---

## Step 3: Supabase Configuration

Get these from: **Supabase Dashboard → Settings → API**

### 3.1 Supabase URL

**What is it?** The endpoint URL for your Supabase project.

```env
SUPABASE_URL=https://your-project-id.supabase.co
```

**How to get it:**
1. Go to https://app.supabase.com
2. Click your project
3. Go to **Settings → API**
4. Copy **Project URL**
5. Looks like: `https://abcdefghijklmnop.supabase.co`

**Example:**
```env
SUPABASE_URL=https://alif-school-abc123.supabase.co
```

### 3.2 Supabase Anon Key

**What is it?** Public key for client-side access (with RLS policies).

```env
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**How to get it:**
1. Supabase Dashboard → **Settings → API**
2. Under **Project API keys** section
3. Find and copy **anon public** (Not the secret one!)
4. Long string starting with `eyJ...`

**Important:**
- ✅ Safe to use in frontend (with RLS policies)
- ✅ Safe to commit if using RLS
- It's a JWT token

**Example:**
```env
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzQ1Njc4MCwiZXhwIjoxOTM5MDMyNzgwfQ.abc123def456xyz789...
```

### 3.3 Supabase Service Role Key

**What is it?** Admin key for backend server access. Can bypass RLS policies.

```env
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**How to get it:**
1. Supabase Dashboard → **Settings → API**
2. Under **Project API keys** section
3. Find **service_role** (labeled as "Secret")
4. Copy this value
5. Long string starting with `eyJ...`

**⚠️ IMPORTANT - SECURITY:**
- ❌ NEVER expose this to frontend
- ❌ NEVER commit this to Git
- ❌ NEVER share this key
- ✅ Only use on backend (server-side)
- ✅ Treat like a password

**Example:**
```env
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjIzNDU2NzgwLCJleHAiOjE5MzkwMzI3ODB9.xyz789uvw012pqr345...
```

---

## Step 4: Firebase Configuration

Get these from: **Firebase Console → Project Settings → General**

### 4.1 Firebase API Key

**What is it?** Public API key for Firebase services.

```env
FIREBASE_API_KEY=AIzaSyDxx...
```

**How to get it:**
1. Go to https://console.firebase.google.com
2. Open your project
3. Click **⚙️ Project Settings**
4. Go to **General** tab
5. In the **Your apps** section, you'll see the web app configuration
6. Copy **apiKey** value

**Example:**
```env
FIREBASE_API_KEY=AIzaSyDxx-ABC123-XYZ789-def456
```

### 4.2 Firebase Auth Domain

**What is it?** Domain used for Firebase authentication.

```env
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. In web app configuration
3. Copy **authDomain** value
4. Format: `projectname.firebaseapp.com`

**Example:**
```env
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
```

### 4.3 Firebase Project ID

**What is it?** Unique identifier for your Firebase project.

```env
FIREBASE_PROJECT_ID=alif-school
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. In web app configuration
3. Copy **projectId** value
4. Same as your project name

**Example:**
```env
FIREBASE_PROJECT_ID=alif-school
```

### 4.4 Firebase Storage Bucket

**What is it?** Cloud storage bucket for file uploads.

```env
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. Copy **storageBucket** value
3. Format: `projectname.appspot.com`

**Example:**
```env
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
```

### 4.5 Firebase Messaging Sender ID

**What is it?** ID for Firebase Cloud Messaging (push notifications).

```env
FIREBASE_MESSAGING_SENDER_ID=123456789...
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. Copy **messagingSenderId** value
3. Numeric ID

**Example:**
```env
FIREBASE_MESSAGING_SENDER_ID=123456789012
```

### 4.6 Firebase App ID

**What is it?** Unique identifier for your Firebase web app.

```env
FIREBASE_APP_ID=1:123456789:web:abc...
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. Copy **appId** value

**Example:**
```env
FIREBASE_APP_ID=1:123456789012:web:abcdef1234567890
```

### 4.7 Firebase Measurement ID (Optional)

**What is it?** Google Analytics measurement ID (optional).

```env
FIREBASE_MEASUREMENT_ID=G-ABC123...
```

**How to get it:**
1. Firebase Console → **Project Settings → General**
2. Copy **measurementId** (if shown)
3. Starts with `G-`

**Example:**
```env
FIREBASE_MEASUREMENT_ID=G-ABCDEF1234
```

### 4.8 Firebase Service Account Path

**What is it?** Path to the Firebase service account JSON file.

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

**How to set it up:**
1. Download service account JSON from Firebase
2. Place in: `c:\Users\JAMSHEER\Desktop\alifschool\backend\firebase-service-account.json`
3. Use relative path: `./firebase-service-account.json`

**Example:**
```env
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

---

## Step 5: JWT Configuration

**What is it?** Settings for JWT token authentication.

### 5.1 JWT Secret

**What is it?** Secret key for signing JWT tokens.

```env
JWT_SECRET=your-jwt-secret-change-in-production
```

**For development:**
```env
JWT_SECRET=my-super-secret-key-for-development-only
```

**For production:**
```bash
# Generate a strong random key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Output example:
```env
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0
```

**⚠️ IMPORTANT:**
- Change this for production!
- Use strong, random value
- Never share this key
- Different key for each environment

### 5.2 JWT Expires In

**What is it?** How long tokens are valid.

```env
# 7 days
JWT_EXPIRES_IN=7d

# Or other durations:
# JWT_EXPIRES_IN=24h    # 24 hours
# JWT_EXPIRES_IN=30d    # 30 days
# JWT_EXPIRES_IN=1h     # 1 hour
```

---

## Step 6: OTP Configuration

**What is it?** Settings for One-Time Password (OTP) login.

### 6.1 OTP Provider

**What is it?** Which service sends OTP.

```env
# Use Supabase (recommended)
OTP_PROVIDER=supabase

# Or use Twilio:
# OTP_PROVIDER=twilio
```

### 6.2 OTP Expiration Time

**What is it?** How long OTP code is valid (in seconds).

```env
# 10 minutes (default)
OTP_EXPIRATION_TIME=600

# Or other durations:
# OTP_EXPIRATION_TIME=300   # 5 minutes
# OTP_EXPIRATION_TIME=900   # 15 minutes
# OTP_EXPIRATION_TIME=1800  # 30 minutes
```

---

## Step 7: Twilio Configuration (Optional)

**Only needed if you're using Twilio for SMS instead of Supabase.**

### 7.1 Twilio Account SID

```env
TWILIO_ACCOUNT_SID=AC123456...
```

**How to get it:**
1. Go to https://www.twilio.com/console
2. Copy **Account SID**

### 7.2 Twilio Auth Token

```env
TWILIO_AUTH_TOKEN=abcdef123456...
```

**How to get it:**
1. Twilio Console
2. Copy **Auth Token**

### 7.3 Twilio From Number

```env
TWILIO_FROM_NUMBER=+12025551234
```

**How to get it:**
1. Twilio Console → **Phone Numbers**
2. Use your Twilio phone number

---

## Step 8: Email Configuration (Optional)

**What is it?** Settings for sending emails.

### 8.1 Email Provider

**What is it?** Which email service to use.

```env
# SendGrid (recommended)
EMAIL_PROVIDER=sendgrid

# Or SMTP:
# EMAIL_PROVIDER=smtp
```

### 8.2 Email API Key

```env
EMAIL_API_KEY=SG.abc123def456...
```

**How to get SendGrid key:**
1. Go to https://sendgrid.com
2. Create free account
3. Generate API key
4. Copy the key

### 8.3 Email From Address

```env
EMAIL_FROM=noreply@alifschool.com
```

### 8.4 Email From Name

```env
EMAIL_FROM_NAME=Alif School
```

---

## Step 9: Storage Configuration

**What is it?** Settings for file storage.

### 9.1 Storage Provider

**What is it?** Which cloud storage service to use.

```env
# Use Supabase (recommended)
STORAGE_PROVIDER=supabase

# Or AWS S3:
# STORAGE_PROVIDER=aws-s3
```

### 9.2 Storage Bucket

```env
# Name of your storage bucket
STORAGE_BUCKET=alif-school
```

---

## Step 10: CORS Configuration

**What is it?** Which domains can access your API.

### 10.1 CORS Origins

```env
# Multiple origins separated by commas
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,https://yourdomain.com
```

**Common development settings:**
```env
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:5173
```

**Production setting:**
```env
CORS_ORIGINS=https://admin.alifschool.com,https://app.alifschool.com
```

### 10.2 CORS Credentials

```env
# Allow credentials (cookies, auth headers)
CORS_CREDENTIALS=true

# Or disable:
# CORS_CREDENTIALS=false
```

---

## Step 11: Rate Limiting Configuration

**What is it?** Settings to prevent abuse.

### 11.1 Rate Limit Window

```env
# Time window in milliseconds
# 900000 = 15 minutes
RATE_LIMIT_WINDOW_MS=900000

# Examples:
# 60000 = 1 minute
# 300000 = 5 minutes
# 1800000 = 30 minutes
```

### 11.2 Max Requests

```env
# Maximum requests per window
# 100 requests per 15 minutes
RATE_LIMIT_MAX_REQUESTS=100
```

---

## Complete .env Example

Here's a complete example with all variables filled in:

```env
# ============================================
# APPLICATION
# ============================================
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# ============================================
# SUPABASE CONFIGURATION
# ============================================
SUPABASE_URL=https://alif-school-abc123.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzQ1Njc4MCwiZXhwIjoxOTM5MDMyNzgwfQ.abc123def456xyz789
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjIzNDU2NzgwLCJleHAiOjE5MzkwMzI3ODB9.xyz789uvw012pqr345

# ============================================
# FIREBASE CONFIGURATION
# ============================================
FIREBASE_API_KEY=AIzaSyDxx-ABC123-XYZ789-def456
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
FIREBASE_PROJECT_ID=alif-school
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_APP_ID=1:123456789012:web:abcdef1234567890
FIREBASE_MEASUREMENT_ID=G-ABCDEF1234
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# ============================================
# JWT CONFIGURATION
# ============================================
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0
JWT_EXPIRES_IN=7d

# ============================================
# OTP CONFIGURATION
# ============================================
OTP_PROVIDER=supabase
OTP_EXPIRATION_TIME=600

# ============================================
# TWILIO CONFIGURATION (Optional)
# ============================================
# TWILIO_ACCOUNT_SID=AC123456...
# TWILIO_AUTH_TOKEN=abcdef123456...
# TWILIO_FROM_NUMBER=+12025551234

# ============================================
# EMAIL CONFIGURATION
# ============================================
EMAIL_PROVIDER=sendgrid
EMAIL_API_KEY=SG.abc123def456...
EMAIL_FROM=noreply@alifschool.com
EMAIL_FROM_NAME=Alif School

# ============================================
# STORAGE CONFIGURATION
# ============================================
STORAGE_PROVIDER=supabase
STORAGE_BUCKET=alif-school

# ============================================
# CORS CONFIGURATION
# ============================================
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:5173
CORS_CREDENTIALS=true

# ============================================
# RATE LIMITING
# ============================================
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# ============================================
# DATABASE
# ============================================
DB_POOL_MIN=2
DB_POOL_MAX=10
```

---

## Verification Checklist

Before starting the server, verify:

- [ ] ✅ `.env` file is in `backend/` directory
- [ ] ✅ All required Supabase keys are filled
- [ ] ✅ All required Firebase keys are filled
- [ ] ✅ `firebase-service-account.json` file exists
- [ ] ✅ `.env` file is in `.gitignore`
- [ ] ✅ No extra spaces around `=` signs
- [ ] ✅ All URLs are correct (no typos)
- [ ] ✅ JWT_SECRET is a strong value
- [ ] ✅ Credentials are from correct environments (dev/prod)

---

## Start Backend Server

Once `.env` is configured:

```bash
cd backend
npm install      # If not already done
npm run dev      # Start development server
```

You should see:
```
✅ Supabase schema is initialized
✅ Firebase Admin SDK initialized
🕌 Alif Online Moral School API running on http://localhost:3000
```

---

## Troubleshooting

### Error: "SUPABASE_URL is required"
- Check `SUPABASE_URL` is filled in `.env`
- Make sure no typos
- Value should start with `https://`

### Error: "Firebase configuration is missing"
- Check all `FIREBASE_*` variables are filled
- Verify `firebase-service-account.json` exists
- Check file path is correct

### Server won't start
- Check all required variables are present
- No special characters in values
- No extra spaces around `=`

### Connection refused
- Check `PORT=3000` is not already in use
- Try `PORT=3001` if 3000 is taken
- Check firewall settings

---

## Next Steps

1. ✅ Complete this configuration
2. ✅ Verify with checklist above
3. ✅ Start backend server: `npm run dev`
4. ✅ Test health endpoint: `http://localhost:3000/health`
5. ✅ Begin API development

---

**Configuration Complete! 🎉**

Your backend is now ready for development.
