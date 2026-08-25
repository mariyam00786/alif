-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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

CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

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

CREATE INDEX IF NOT EXISTS idx_students_batch ON students(batch_id);
CREATE INDEX IF NOT EXISTS idx_students_profile ON students(profile_id);
CREATE INDEX IF NOT EXISTS idx_students_status ON students(status);

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

CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);

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

CREATE INDEX IF NOT EXISTS idx_classes_batch ON classes(batch_id);

-- Update Students to reference batches and classes
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_batch'
	) THEN
		ALTER TABLE students
		ADD CONSTRAINT fk_students_batch FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL;
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'fk_students_class'
	) THEN
		ALTER TABLE students
		ADD CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL;
	END IF;
END $$;

-- Teachers Table
CREATE TABLE IF NOT EXISTS teachers (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
	email TEXT,
	qualification TEXT,
	status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teachers_status ON teachers(status);

-- Teacher-Batch Assignment
CREATE TABLE IF NOT EXISTS teacher_batches (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
	batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
	UNIQUE(teacher_id, batch_id)
);

CREATE INDEX IF NOT EXISTS idx_teacher_batches_batch ON teacher_batches(batch_id);

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

CREATE INDEX IF NOT EXISTS idx_activity_categories_status ON activity_categories(status);

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

CREATE INDEX IF NOT EXISTS idx_activities_category ON activities(category_id);
CREATE INDEX IF NOT EXISTS idx_activities_status ON activities(status);

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

CREATE INDEX IF NOT EXISTS idx_activity_ratings_activity ON activity_ratings(activity_id);

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

CREATE INDEX IF NOT EXISTS idx_activity_logs_student ON activity_logs(student_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_date ON activity_logs(log_date);
CREATE INDEX IF NOT EXISTS idx_activity_logs_student_date ON activity_logs(student_id, log_date);

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

CREATE INDEX IF NOT EXISTS idx_badges_status ON badges(status);

-- Student Badges Table
CREATE TABLE IF NOT EXISTS student_badges (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
	badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
	earned_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(student_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_student_badges_student ON student_badges(student_id);

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

CREATE INDEX IF NOT EXISTS idx_notifications_sent ON notifications(sent_at);

-- Parent-Student Relationship
CREATE TABLE IF NOT EXISTS parent_students (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	parent_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
	student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
	relationship TEXT DEFAULT 'parent',
	UNIQUE(parent_profile_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_students_parent ON parent_students(parent_profile_id);

-- Enable RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Profiles
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'Users can view their own profile'
	) THEN
		CREATE POLICY "Users can view their own profile"
		  ON profiles FOR SELECT
		  USING (auth.uid() = id);
	END IF;
END $$;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'Admin can view all profiles'
	) THEN
		CREATE POLICY "Admin can view all profiles"
		  ON profiles FOR SELECT
		  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
	END IF;
END $$;

-- RLS Policies for Activity Logs
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'activity_logs' AND policyname = 'Students can view their own logs'
	) THEN
		CREATE POLICY "Students can view their own logs"
		  ON activity_logs FOR SELECT
		  USING (student_id IN (SELECT id FROM students WHERE profile_id = auth.uid()));
	END IF;
END $$;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
