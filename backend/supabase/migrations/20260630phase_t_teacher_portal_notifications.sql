-- Phase T — Teacher Portal notifications + analytics helpers (2026-06-30)
--
-- Extends the existing `notifications` table so teacher-sent batch reminders,
-- motivational messages and achievement acknowledgements carry enough metadata
-- for the teacher + parent + student bells to render icons / colour / tone /
-- "by whom" without guessing from `target_type` alone.
--
-- Idempotent: safe to re-run. Applied directly to the live project via the
-- `pg` direct-host trick (db.<ref>.supabase.co:5432) when first introduced.

-- Optional category tag for grouping notifications in the UI
-- (batch_reminder | motivational | acknowledgement | announcement | general).
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'general';

-- Optional emoji / material icon key used by the bells.
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS icon TEXT;

-- Malayalam body for the bilingual bells (nullable — falls back to `body`).
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS body_ml TEXT;

-- Tracks the teacher who sent a batch/student notification so the teacher's
-- own bell can mark "sent by you" and so we never re-broadcast to them.
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS sent_by_teacher UUID REFERENCES teachers(id) ON DELETE SET NULL;

-- Index to quickly list a teacher's sent notifications + scoped reads.
CREATE INDEX IF NOT EXISTS idx_notifications_sent_by_teacher
  ON notifications(sent_by_teacher);
CREATE INDEX IF NOT EXISTS idx_notifications_target ON notifications(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
