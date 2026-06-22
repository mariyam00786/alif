-- Add an optional login/contact email to students.
-- This mirrors the student's Supabase auth login email so it can be displayed
-- and edited from the admin panel.
ALTER TABLE students ADD COLUMN IF NOT EXISTS email TEXT;
