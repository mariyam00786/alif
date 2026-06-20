# Supabase Setup - Step by Step Guide

Complete guide to set up Supabase for the Alif Online Moral School application.

## Prerequisites

- Supabase account (free at https://supabase.com)
- Email and password for registration
- Web browser
- Internet connection

---

## Step 1: Create Supabase Project

### 1.1 Go to Supabase Website

1. Open https://app.supabase.com in your browser
2. You should see the Supabase dashboard

### 1.2 Sign Up (if you don't have account)

1. Click "Sign up"
2. Enter your email
3. Create a strong password
4. Verify your email

### 1.3 Create New Project

1. Click "New Project" button
2. Select your preferred organization (or create new one)
3. Fill in the project details:

**Project Details Form:**

| Field | Value | Notes |
|-------|-------|-------|
| **Project Name** | `alif-school` | or any name you prefer |
| **Database Password** | Generate strong password | Save this securely! You'll need it |
| **Region** | Choose closest to your location | For better performance |
| **Pricing Plan** | Free (for development) | Upgrade to Pro later if needed |

Click "Create new project"

### 1.4 Wait for Project Creation

- The project will be created (takes 1-2 minutes)
- You'll see a loading screen
- Once done, you'll be redirected to the project dashboard

---

## Step 2: Get Your Supabase Credentials

### 2.1 Navigate to Settings

1. In the left sidebar, click **Settings** (gear icon)
2. Go to **API** tab
3. You'll see your API credentials

### 2.2 Copy Your Keys

You need three pieces of information:

#### A. Project URL
```
Location: Settings → API → Project URL
Example: https://your-project-id.supabase.co
Copy this value → SUPABASE_URL
```

#### B. Anon Public Key
```
Location: Settings → API → Project API keys → anon public
Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Copy this value → SUPABASE_ANON_KEY
```

#### C. Service Role Key (SECRET - Backend Only!)
```
Location: Settings → API → Project API keys → service_role (labeled as "Secret")
Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Copy this value → SUPABASE_SERVICE_ROLE_KEY
⚠️ NEVER expose this key to frontend or commit to Git!
```

### 2.3 Verify You Have All Three

By the end of this step, you should have:
- ✅ Project URL (https://xxx.supabase.co)
- ✅ Anon Key (long string starting with eyJ...)
- ✅ Service Role Key (long string, marked as Secret)

---

## Step 3: Initialize Supabase in Your Project

### 3.1 Open Terminal

Navigate to your backend directory:

```bash
cd c:\Users\JAMSHEER\Desktop\alifschool\backend
```

### 3.2 Install Supabase CLI (if not already installed)

```bash
npm install -g supabase
```

Verify installation:
```bash
supabase --version
```

### 3.3 Link to Your Supabase Project

```bash
supabase link
```

When prompted:
1. **Enter your Supabase database password**: Enter the password you created in Step 1.3
2. **Select project**: Choose your `alif-school` project
3. Press Enter to confirm

You should see:
```
✅ Supabase project linked successfully
```

---

## Step 4: Create Database Schema

### 4.1 Option A: Using Supabase Dashboard (Recommended for First Time)

1. Go back to Supabase Dashboard
2. In the left sidebar, click **SQL Editor**
3. Click **New Query**
4. Copy the entire SQL from [SUPABASE_SETUP.md](./SUPABASE_SETUP.md#5-complete-database-schema)
5. Paste into the SQL editor
6. Click **Run** button
7. Wait for completion (you should see "Query completed successfully")

### 4.2 Option B: Using CLI (For Future Migrations)

#### Create Migration File

```bash
npm run supabase:migration:new init_schema
```

This creates: `supabase/migrations/[timestamp]_init_schema.sql`

#### Edit Migration File

1. Open the created file
2. Paste the SQL from [SUPABASE_SETUP.md](./SUPABASE_SETUP.md#5-complete-database-schema)
3. Save the file

#### Push Migration

```bash
npm run supabase:db:push
```

Wait for confirmation.

### 4.3 Verify Schema Creation

1. Go to Supabase Dashboard
2. Click **Table Editor** in left sidebar
3. You should see these tables:
   - profiles
   - students
   - teachers
   - batches
   - classes
   - activity_categories
   - activities
   - activity_ratings
   - activity_logs
   - badges
   - student_badges
   - notifications
   - parent_students
   - teacher_batches

✅ If all tables exist, your schema is set up correctly!

---

## Step 5: Enable Authentication

### 5.1 Enable Phone Authentication

1. In Supabase Dashboard, click **Authentication** in left sidebar
2. Click **Providers** tab
3. Find **Phone** provider
4. Click the toggle to **Enable**
5. Click **Save**

### 5.2 Configure OTP Settings (Optional)

1. Still in **Authentication** section
2. Click **Settings** tab
3. Look for **User Signups** section
4. Configure as needed:
   - Auto-confirm users: Off (for phone verification)
   - Double confirm changes: On (for security)

---

## Step 6: Create Storage Buckets

These are for file uploads (photos, documents, icons).

### 6.1 Create Student Photos Bucket

1. In Supabase Dashboard, click **Storage** in left sidebar
2. Click **New bucket**
3. Bucket name: `student-photos`
4. Keep default settings
5. Click **Create bucket**

### 6.2 Create Badge Icons Bucket

1. Click **New bucket** again
2. Bucket name: `badge-icons`
3. Click **Create bucket**

### 6.3 Create Documents Bucket

1. Click **New bucket** again
2. Bucket name: `documents`
3. Click **Create bucket**

✅ You should now have 3 buckets in the Storage section.

---

## Step 7: Add Credentials to .env File

### 7.1 Open .env File

Navigate to: `c:\Users\JAMSHEER\Desktop\alifschool\backend\.env`

If it doesn't exist, copy from `.env.example`:
```bash
cp .env.example .env
```

### 7.2 Fill in Supabase Credentials

Edit the `.env` file and update these variables:

```env
# From Step 2.2 - Project URL
SUPABASE_URL=https://your-project-id.supabase.co

# From Step 2.2 - Anon Key
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# From Step 2.2 - Service Role Key (SECRET!)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Example .env file:**
```env
NODE_ENV=development
PORT=3000

# Supabase Configuration
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzQ1Njc4MCwiZXhwIjoxOTM5MDMyNzgwfQ.abc123...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjIzNDU2NzgwLCJleHAiOjE5MzkwMzI3ODB9.xyz789...

# Rest of configuration...
```

### 7.3 Save the File

Save your `.env` file.

---

## Step 8: Test Connection

### 8.1 Start Backend Server

```bash
cd backend
npm run dev
```

### 8.2 Check Console Output

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

✅ If you see this, Supabase is connected!

### 8.3 Test Health Endpoint

Open in browser: `http://localhost:3000/health`

You should see:
```json
{
  "status": "healthy",
  "timestamp": "2026-06-17T10:30:45.123Z",
  "version": "1.0.0"
}
```

---

## Step 9: Enable Row Level Security (RLS)

RLS protects your data by enforcing access policies.

### 9.1 Enable RLS on Tables

1. Go to Supabase Dashboard
2. Click **Authentication** → **Policies**
3. Select table: `profiles`
4. Click **Create policy**
5. Policy name: `Users can view own profile`
6. Policy type: `SELECT`
7. Using expression: `auth.uid() = id`
8. Click **Create**

### 9.2 Enable on Activity Logs Table

1. Select table: `activity_logs`
2. Click **Create policy**
3. Policy name: `Students can view own logs`
4. Policy type: `SELECT`
5. Using expression: `student_id IN (SELECT id FROM students WHERE profile_id = auth.uid())`
6. Click **Create**

---

## Troubleshooting

### Connection Error: "Could not connect to Supabase"

**Solution:**
1. Verify `SUPABASE_URL` is correct in `.env`
2. Verify `SUPABASE_SERVICE_ROLE_KEY` is correct
3. Check your internet connection
4. Restart the backend server

### Error: "Table does not exist"

**Solution:**
1. Verify schema was created successfully
2. Check Supabase dashboard → Table Editor
3. If tables missing, re-run the SQL schema

### Supabase CLI Not Found

**Solution:**
```bash
npm install -g supabase
supabase --version
```

### Wrong Credentials Error

**Solution:**
1. Double-check all three keys from Supabase dashboard
2. Copy each value carefully (no extra spaces)
3. Verify you're using service role key, not anon key

---

## Next Steps

✅ Supabase is now configured!

Continue with:
1. **Firebase Setup** - [See FIREBASE_SETUP_STEP_BY_STEP.md](./FIREBASE_SETUP_STEP_BY_STEP.md)
2. **Database Configuration** - [See SUPABASE_SETUP.md](./SUPABASE_SETUP.md)
3. **Backend Development** - Start implementing API routes

---

## Summary

| Step | Status | What You Did |
|------|--------|-------------|
| 1 | ✅ | Created Supabase project |
| 2 | ✅ | Got API credentials |
| 3 | ✅ | Linked to your project |
| 4 | ✅ | Created database schema |
| 5 | ✅ | Enabled authentication |
| 6 | ✅ | Created storage buckets |
| 7 | ✅ | Added credentials to .env |
| 8 | ✅ | Tested connection |
| 9 | ✅ | Enabled security policies |

---

**Supabase Setup Complete! 🎉**

Your database is now ready for backend development.
