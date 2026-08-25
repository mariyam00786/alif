# Supabase Database Setup Guide

## Overview

This guide covers setting up Supabase for the Alif Online Moral School application.

## Prerequisites

- Supabase account (https://supabase.com)
- Supabase CLI installed (`npm install -g supabase`)
- PostgreSQL basics knowledge (optional but helpful)

## Setup Steps

### 1. Create Supabase Project

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in project details:
   - Name: `alif-school`
   - Database Password: Generate a strong password
   - Region: Select closest to your location
4. Wait for project to be created

### 2. Get Your Credentials

Once project is created:

1. Go to **Settings → API**
2. Copy:
   - `Project URL` → `SUPABASE_URL`
   - `anon public` → `SUPABASE_ANON_KEY`
   - `service_role` (Secret) → `SUPABASE_SERVICE_ROLE_KEY`

3. Add to `.env` file in backend directory

### 3. Initialize Supabase in Your Project

```bash
cd backend

# Initialize Supabase (if not already done)
npx supabase init

# Link to your remote Supabase project
npm run supabase:link
```

When prompted, select your Supabase project.

### 4. Create Database Schema

The schema is defined through migrations. Create the following tables:

#### Option A: Using SQL Editor (Manual)

Go to Supabase Dashboard → SQL Editor and run:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    full_name_ml TEXT,
    role TEXT CHECK (role IN ('student', 'parent', 'teacher', 'admin')),
    profile_photo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    parent_phone TEXT NOT NULL,
    father_name TEXT,
    mother_name TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female')),
    batch_id UUID,
    class_id UUID,
    address TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ... more tables (see complete schema below)
```

#### Option B: Using Migrations (Recommended)

```bash
# Create a new migration
npm run supabase:migration:new init_schema

# Edit the migration file created in supabase/migrations/
# Add SQL from the complete schema

# Push the migration
npm run supabase:db:push
```

### 5. Complete Database Schema

Run this SQL in Supabase SQL Editor:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    full_name_ml TEXT,
    role TEXT CHECK (role IN ('student', 'parent', 'teacher', 'admin')),
    profile_photo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_phone ON profiles(phone);
CREATE INDEX idx_profiles_role ON profiles(role);

-- Students Table
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    parent_phone TEXT NOT NULL,
    father_name TEXT,
    mother_name TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female')),
    batch_id UUID,
    class_id UUID,
    address TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_students_batch ON students(batch_id);
CREATE INDEX idx_students_profile ON students(profile_id);
CREATE INDEX idx_students_status ON students(status);

-- Batches Table
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    description TEXT,
    capacity INTEGER,
    timing TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_batches_status ON batches(status);

-- Classes Table
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    level TEXT CHECK (level IN ('beginner', 'intermediate', 'advanced')),
    batch_id UUID REFERENCES batches(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_classes_batch ON classes(batch_id);

-- Update Students to reference batches and classes
ALTER TABLE students 
ADD CONSTRAINT fk_students_batch FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL,
ADD CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL;

-- Teachers Table
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    email TEXT,
    qualification TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_teachers_status ON teachers(status);

-- Teacher-Batch Assignment
CREATE TABLE IF NOT EXISTS teacher_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    UNIQUE(teacher_id, batch_id)
);

CREATE INDEX idx_teacher_batches_batch ON teacher_batches(batch_id);

-- Activity Categories Table
CREATE TABLE IF NOT EXISTS activity_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    icon TEXT,
    display_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_categories_status ON activity_categories(status);

-- Activities Table
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES activity_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_ml TEXT,
    display_order INTEGER DEFAULT 0,
    has_quantity BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activities_category ON activities(category_id);
CREATE INDEX idx_activities_status ON activities(status);

-- Activity Ratings Table
CREATE TABLE IF NOT EXISTS activity_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    rating_name TEXT NOT NULL,
    rating_name_ml TEXT,
    marks INTEGER NOT NULL,
    color TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_ratings_activity ON activity_ratings(activity_id);

-- Activity Logs Table
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    rating_id UUID NOT NULL REFERENCES activity_ratings(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    quantity INTEGER,
    marks_earned INTEGER NOT NULL,
    parent_approved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, activity_id, log_date)
);

CREATE INDEX idx_activity_logs_student ON activity_logs(student_id);
CREATE INDEX idx_activity_logs_date ON activity_logs(log_date);
CREATE INDEX idx_activity_logs_student_date ON activity_logs(student_id, log_date);

-- Badges Table
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    description TEXT,
    icon TEXT,
    criteria JSONB,
    bonus_points INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_badges_status ON badges(status);

-- Student Badges Table
CREATE TABLE IF NOT EXISTS student_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, badge_id)
);

CREATE INDEX idx_student_badges_student ON student_badges(student_id);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT,
    target_type TEXT CHECK (target_type IN ('all', 'batch', 'class', 'student')),
    target_id UUID,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_sent ON notifications(sent_at);

-- Parent-Student Relationship
CREATE TABLE IF NOT EXISTS parent_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    relationship TEXT DEFAULT 'parent',
    UNIQUE(parent_profile_id, student_id)
);

CREATE INDEX idx_parent_students_parent ON parent_students(parent_profile_id);

-- Enable RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Profiles
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admin can view all profiles"
  ON profiles FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- RLS Policies for Activity Logs
CREATE POLICY "Students can view their own logs"
  ON activity_logs FOR SELECT
  USING (student_id IN (SELECT id FROM students WHERE profile_id = auth.uid()));

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
```

### 6. Create Storage Buckets

In Supabase Dashboard:

1. Go to **Storage**
2. Create new bucket: `student-photos`
3. Create new bucket: `badge-icons`
4. Create new bucket: `documents`

Set appropriate policies for each bucket.

### 7. Enable Authentication

1. Go to **Authentication → Settings**
2. Configure:
   - **Email**: Enable (if needed)
   - **Phone**: Enable for OTP
   - **Providers**: Configure as needed (Google, etc.)

## Local Development

### Start Local Supabase

```bash
npm run supabase:start
```

This starts a local Supabase instance for development.

### Sync with Remote

```bash
# Pull latest schema from remote
npm run supabase:db:pull

# Push local migrations to remote
npm run supabase:db:push
```

## Useful Supabase CLI Commands

```bash
# Start local instance
supabase start

# Stop local instance
supabase stop

# Link to remote project
supabase link

# Pull database schema from remote
supabase db pull

# Push migrations to remote
supabase db push

# Create new migration
supabase migration new [migration_name]

# View database status
supabase db remote set

# Generate TypeScript types
supabase gen types typescript --local > types/supabase.ts
```

## Troubleshooting

### Connection Issues
- Verify `SUPABASE_URL` and keys are correct
- Check network connectivity
- Ensure Supabase project is running

### Schema Mismatch
- Pull latest schema: `npm run supabase:db:pull`
- Check migrations in `supabase/migrations/`

### Local Development Issues
- Clear local instance: `supabase stop --clean-up`
- Restart: `supabase start`

## Security Best Practices

1. **Enable Row Level Security (RLS)** on all tables
2. **Create RLS policies** for data access control
3. **Use service role key** only on backend (never expose to frontend)
4. **Use anon key** for frontend with RLS policies
5. **Rotate keys regularly** in production
6. **Never commit** `.env` or credentials files

## References

- Supabase Documentation: https://supabase.com/docs
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- RLS Guide: https://supabase.com/docs/guides/auth/row-level-security
