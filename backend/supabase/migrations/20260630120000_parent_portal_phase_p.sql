-- Phase P — Parent Portal completion (June 30, 2026)
--
-- P1: Durable approval workflow
--   Adds `parent_decision` (approved/rejected/pending) and `decided_at` on
--   `activity_logs` so a parent's REJECT verdict persists (previously reject
--   only cleared the in-memory client list; the rows stayed parent_approved=
--   false and re-appeared on reload). `/send-back` resets to pending.
--
-- P2: Notification read state
--   Adds `notifications_read` table mapping (profile_id, notification_id) ->
--   read_at. A join against this table gives the bell a persisted unread
--   count + per-item read flag without mutating the source `notifications`
--   row (which is shared across audiences).
--
-- P3: Parent profile & settings (FRD §4.2.6)
--   Adds `parent_preferences` (one row per parent profile) covering
--   notification type toggles, per-child weekly-report opt-in, and a
--   privacy flag to hide a child's name on the leaderboard. NULLable
--   columns default to sensible opt-ins so existing parents get the
--   current behaviour until they edit.

-- ===== P1: durable approval decision =======================================

ALTER TABLE activity_logs
  ADD COLUMN IF NOT EXISTS parent_decision TEXT NOT NULL DEFAULT 'pending'
    CHECK (parent_decision IN ('pending', 'approved', 'rejected'));

ALTER TABLE activity_logs
  ADD COLUMN IF NOT EXISTS decided_at TIMESTAMPTZ;

ALTER TABLE activity_logs
  ADD COLUMN IF NOT EXISTS decided_by UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Backfill existing approved rows so the new enum reflects prior state.
UPDATE activity_logs
   SET parent_decision = 'approved',
       decided_at      = updated_at
 WHERE parent_approved = true
   AND parent_decision = 'pending';

CREATE INDEX IF NOT EXISTS idx_activity_logs_parent_decision
  ON activity_logs(parent_decision);

CREATE INDEX IF NOT EXISTS idx_activity_logs_student_decision
  ON activity_logs(student_id, parent_decision, log_date);

-- ===== P2: notification read state =========================================

CREATE TABLE IF NOT EXISTS notifications_read (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id, notification_id)
);

CREATE INDEX IF NOT EXISTS idx_notifications_read_profile
  ON notifications_read(profile_id);

CREATE INDEX IF NOT EXISTS idx_notifications_read_notification
  ON notifications_read(notification_id);

-- ===== P3: parent preferences ==============================================

CREATE TABLE IF NOT EXISTS parent_preferences (
  parent_profile_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,

  -- Notification type opt-ins (default all ON to preserve current behaviour).
  notify_daily        BOOLEAN NOT NULL DEFAULT true,
  notify_approval     BOOLEAN NOT NULL DEFAULT true,
  notify_weekly       BOOLEAN NOT NULL DEFAULT true,
  notify_achievement  BOOLEAN NOT NULL DEFAULT true,

  -- Per-child weekly-report opt-in, stored as a JSON array of student ids
  -- belonging to this parent. NULL = "all children" (default on).
  weekly_report_child_ids JSONB,

  -- Privacy: when true, the parent's children's names are hidden from the
  -- public batch leaderboard (masked as "Student"). Default false.
  hide_child_name_on_leaderboard BOOLEAN NOT NULL DEFAULT false,

  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-provision a preferences row whenever a parent profile is created.
CREATE OR REPLACE FUNCTION fn_ensure_parent_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.role = 'parent' THEN
    INSERT INTO parent_preferences (parent_profile_id)
    VALUES (NEW.id)
    ON CONFLICT (parent_profile_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_parent_preferences ON profiles;
CREATE TRIGGER trg_ensure_parent_preferences
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION fn_ensure_parent_preferences();

-- Backfill preferences for existing parents.
INSERT INTO parent_preferences (parent_profile_id)
SELECT id FROM profiles WHERE role = 'parent'
ON CONFLICT (parent_profile_id) DO NOTHING;
