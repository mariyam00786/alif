# Quick Setup Reference - Alif Online Moral School

**Quick checklist to set up Supabase and Firebase in the right order.**

---

## 🚀 Setup Order

Follow these steps in order. Do not skip steps.

---

## ✅ Step 1: Supabase Setup (10 minutes)

### 1a. Create Project
- Go to https://app.supabase.com
- Click "New Project"
- Name: `alif-school`
- Save database password securely
- Wait 2-5 minutes for creation

### 1b. Get Credentials
- Go to **Settings → API**
- Copy these 3 keys:
  1. **Project URL** → `SUPABASE_URL`
  2. **anon public key** → `SUPABASE_ANON_KEY`
  3. **service_role (Secret)** → `SUPABASE_SERVICE_ROLE_KEY`

### 1c. Create Database Schema
Choose ONE method:

**Method A - SQL Editor (Recommended first time):**
1. Go to **SQL Editor** in Supabase
2. Click **New Query**
3. Paste SQL from: [docs/SUPABASE_SETUP.md](./SUPABASE_SETUP.md#5-complete-database-schema)
4. Click **Run**
5. Wait for completion

**Method B - CLI (For migrations):**
```bash
cd backend
npm run supabase:migration:new init_schema
# Edit the file and paste SQL
npm run supabase:db:push
```

### 1d. Enable Phone Auth
- Supabase Dashboard → **Authentication**
- Click **Sign-in method**
- Find **Phone**, toggle to enable
- Click **Save**

### 1e. Create Storage Buckets
- **Storage** section
- Create 3 buckets:
  - `student-photos`
  - `badge-icons`
  - `documents`

✅ **Supabase is ready!**

---

## ✅ Step 2: Firebase Setup (10 minutes)

### 2a. Create Project
- Go to https://console.firebase.google.com
- Click "Create a project"
- Name: `alif-school`
- Wait 2-5 minutes

### 2b. Register Web App
- Click **⚙️ Project Settings**
- Go to **General** tab
- Scroll to **Your apps** section
- Click Web icon (`</>`)
- App name: `alif-school-api`
- Register

### 2c. Copy Firebase Config
- You'll see JavaScript config object
- Copy all values:
  - `apiKey` → `FIREBASE_API_KEY`
  - `authDomain` → `FIREBASE_AUTH_DOMAIN`
  - `projectId` → `FIREBASE_PROJECT_ID`
  - `storageBucket` → `FIREBASE_STORAGE_BUCKET`
  - `messagingSenderId` → `FIREBASE_MESSAGING_SENDER_ID`
  - `appId` → `FIREBASE_APP_ID`
  - `measurementId` → `FIREBASE_MEASUREMENT_ID`

### 2d. Create Service Account
- **Project Settings → Service Accounts** tab
- Click **Generate New Private Key**
- File downloads automatically
- Save as: `firebase-service-account.json`
- Location: `c:\Users\JAMSHEER\Desktop\alifschool\backend\`

⚠️ **Never commit this file to Git!**

### 2e. Enable Phone Auth
- **Authentication** section
- **Sign-in method** tab
- Find **Phone**, toggle enable
- Click **Save**

### 2f. Enable Cloud Messaging (Optional)
- **Cloud Messaging** section
- Click **Enable** if shown
- Note the Server API Key and Sender ID

✅ **Firebase is ready!**

---

## ✅ Step 3: Configure .env File (5 minutes)

### 3a. Create .env File

In `backend` directory:
```bash
cd c:\Users\JAMSHEER\Desktop\alifschool\backend
copy .env.example .env
```

### 3b. Fill in Supabase Section

Open `.env` and add Supabase credentials from Step 1:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

### 3c. Fill in Firebase Section

Add Firebase credentials from Step 2:

```env
FIREBASE_API_KEY=AIzaSy...
FIREBASE_AUTH_DOMAIN=alif-school.firebaseapp.com
FIREBASE_PROJECT_ID=alif-school
FIREBASE_STORAGE_BUCKET=alif-school.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789...
FIREBASE_APP_ID=1:123456789:web:abc...
FIREBASE_MEASUREMENT_ID=G-ABC...
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### 3d. Fill in Other Settings

Add other required settings:

```env
# Application
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# JWT
JWT_SECRET=your-very-strong-secret-key-here
JWT_EXPIRES_IN=7d

# OTP
OTP_PROVIDER=supabase
OTP_EXPIRATION_TIME=600

# Email (optional)
EMAIL_PROVIDER=sendgrid
EMAIL_API_KEY=
EMAIL_FROM=noreply@alifschool.com

# Storage
STORAGE_PROVIDER=supabase
STORAGE_BUCKET=alif-school

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:3001
CORS_CREDENTIALS=true

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3e. Save and Verify

1. Save `.env` file
2. Verify:
   - `.env` is in `backend/` directory
   - File is in `.gitignore`
   - All required fields are filled
   - No special characters around `=`

✅ **.env is configured!**

---

## ✅ Step 4: Verify Setup (5 minutes)

### 4a. Install Dependencies

```bash
cd backend
npm install
```

Wait for installation to complete.

### 4b. Start Server

```bash
npm run dev
```

### 4c. Check Console Output

You should see:

```
🔄 Connecting to Supabase...
✅ Supabase schema is initialized

🔄 Initializing Firebase...
✅ Firebase Admin SDK initialized

╔════════════════════════════════════════════════════════════╗
║  🕌 Alif Online Moral School API                          ║
║  Version: 1.0.0                                            ║
║  Environment: development                                 ║
║  Server running on: http://localhost:3000                 ║
║  Health Check: http://localhost:3000/health              ║
╚════════════════════════════════════════════════════════════╝
```

✅ **Both services initialized successfully!**

### 4d. Test Health Endpoint

Open browser: `http://localhost:3000/health`

You should see:
```json
{
  "status": "healthy",
  "timestamp": "2026-06-17T10:30:45.123Z",
  "version": "1.0.0"
}
```

✅ **Everything is working!**

---

## 📋 Complete Checklist

### Supabase
- [ ] Project created
- [ ] 3 API keys copied
- [ ] Database schema created
- [ ] Phone auth enabled
- [ ] 3 storage buckets created

### Firebase
- [ ] Project created
- [ ] Web app registered
- [ ] 7 config values copied
- [ ] Service account JSON downloaded
- [ ] Phone auth enabled

### .env File
- [ ] `.env` file created in `backend/`
- [ ] Supabase credentials added
- [ ] Firebase credentials added
- [ ] `firebase-service-account.json` in correct location
- [ ] Other settings configured
- [ ] `.env` is in `.gitignore`

### Server
- [ ] Dependencies installed
- [ ] Server starts without errors
- [ ] Health endpoint works
- [ ] Console shows both services initialized

---

## 🔗 Documentation References

For detailed information, see:

| Topic | Document |
|-------|----------|
| **Supabase Detailed Setup** | [SUPABASE_SETUP_STEP_BY_STEP.md](./SUPABASE_SETUP_STEP_BY_STEP.md) |
| **Firebase Detailed Setup** | [FIREBASE_SETUP_STEP_BY_STEP.md](./FIREBASE_SETUP_STEP_BY_STEP.md) |
| **Environment Variables** | [ENV_CONFIGURATION_GUIDE.md](./ENV_CONFIGURATION_GUIDE.md) |
| **Backend README** | [../backend/README.md](../backend/README.md) |

---

## ⚡ Quick Commands Reference

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Lint code
npm run lint

# Supabase commands
npm run supabase:link          # Link to Supabase project
npm run supabase:db:push       # Push migrations
npm run supabase:db:pull       # Pull current schema
npm run supabase:start         # Start local instance

# Firebase commands
firebase init                  # Initialize Firebase
firebase deploy               # Deploy to Firebase
```

---

## 🆘 Troubleshooting Quick Fix

### Issue: Port 3000 already in use
```bash
# Change port in .env
PORT=3001
```

### Issue: "Cannot find module"
```bash
# Reinstall dependencies
rm -r node_modules package-lock.json
npm install
```

### Issue: Supabase connection error
- Check `SUPABASE_URL` format (should have `.supabase.co`)
- Verify anon key is not service role key
- Check internet connection

### Issue: Firebase not initializing
- Verify `firebase-service-account.json` exists in `backend/`
- Check `FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json`
- Ensure JSON file is valid (open in VS Code to check)

---

## 📚 What's Next?

After setup is complete:

1. **Backend Development** - Start implementing API routes
2. **Admin Panel** - Create Flutter web dashboard
3. **Mobile App** - Create Flutter mobile application
4. **Database** - Add more tables and relationships
5. **Authentication** - Implement OTP login flow

---

## ⏱️ Estimated Time

| Step | Time |
|------|------|
| Supabase Setup | 10 min |
| Firebase Setup | 10 min |
| .env Configuration | 5 min |
| Verification | 5 min |
| **Total** | **30 min** |

---

## 🎉 Setup Complete!

Once you see the green checkmarks for all steps, your backend is ready for development.

Next: Start building API endpoints!

---

**Date:** June 17, 2026  
**Version:** 1.0.0  
**Status:** Ready for Development

