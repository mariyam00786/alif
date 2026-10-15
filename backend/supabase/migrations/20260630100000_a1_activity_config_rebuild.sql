-- A1: FRD §4.1.5/§4.1.6/§4.1.7 — Activity Category & Rating config rebuild
-- Safe additive migration: every column is ADD COLUMN IF NOT EXISTS, every
-- constraint / index is IF NOT EXISTS. Idempotent across re-runs.

-- ===========================================================================
-- 1. Category columns (FRD §4.1.5)
--    activity_categories already has: name, name_ml, icon, display_order, status
--    Add: name_en (canonical English label separate from display name),
--         parent_id NULL (reserved for future sub-category nesting).
-- ===========================================================================
ALTER TABLE activity_categories
  ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE activity_categories
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES activity_categories(id) ON DELETE SET NULL;

-- Backfill name_en from name for existing rows so the bilingual split works.
UPDATE activity_categories
SET name_en = name
WHERE name_en IS NULL AND name IS NOT NULL;

-- ===========================================================================
-- 2. Activity columns (FRD §4.1.7 — sub-activity fields)
--    activities already has: category_id, name, name_ml, display_order,
--                              has_quantity, status, created_at
--    Add: name_en, unit_label (for quantity activities e.g. "pages"),
--         max_quantity (FRD Quran pages max).
-- ===========================================================================
ALTER TABLE activities
  ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE activities
  ADD COLUMN IF NOT EXISTS unit_label TEXT;
ALTER TABLE activities
  ADD COLUMN IF NOT EXISTS max_quantity INTEGER;

UPDATE activities SET name_en = name WHERE name_en IS NULL AND name IS NOT NULL;

-- ===========================================================================
-- 3. Rating columns (FRD §4.1.6 — per-activity rating bands)
--    activity_ratings already has: activity_id, rating_name, rating_name_ml,
--                                   marks, color, display_order, created_at
--    Add: is_not_done (FRD "Not Done = 0" lock), is_default (default band).
-- ===========================================================================
ALTER TABLE activity_ratings
  ADD COLUMN IF NOT EXISTS is_not_done BOOLEAN DEFAULT FALSE;
ALTER TABLE activity_ratings
  ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT FALSE;

-- Mark existing rows with marks = 0 as "Not Done" band (FRD §4.1.6 Cat IV).
UPDATE activity_ratings
SET is_not_done = TRUE
WHERE marks = 0 AND is_not_done = FALSE;

-- ===========================================================================
-- 4. FRD §4.1.6 special scoring rules table (already exists as
--    activity_scoring_rules from migration 20260618091500; we only ensure
--    the FRD "tier" semantics columns: rule_type = 'tier', min_qty, max_qty).
--    If that table does not exist (fresh DB), create it here so this
--    migration is self-contained.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS activity_scoring_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  rule_type TEXT NOT NULL DEFAULT 'tier',
  label TEXT,
  label_ml TEXT,
  min_quantity INTEGER,
  max_quantity INTEGER,
  marks INTEGER NOT NULL,
  color TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_activity_scoring_rules_activity
  ON activity_scoring_rules(activity_id);

-- ===========================================================================
-- 4b. Normalize an EXISTING activity_scoring_rules table (created by the
--     earlier migration 20260618091500) so it supports the FRD §4.1.6
--     "special scoring rule" semantics: label/label_ml/color columns and a
--     permissive rule_type that allows 'tier' (in addition to the original
--     'rating'/'quantity' values). All statements are guarded with IF NOT
--     EXISTS so re-running is safe on either shape.
-- ===========================================================================
ALTER TABLE activity_scoring_rules ADD COLUMN IF NOT EXISTS label TEXT;
ALTER TABLE activity_scoring_rules ADD COLUMN IF NOT EXISTS label_ml TEXT;
ALTER TABLE activity_scoring_rules ADD COLUMN IF NOT EXISTS color TEXT;

-- Relax the rule_type CHECK to allow 'tier' (FRD "special rules" like
-- Jama'ah/On-time/Late and Quran-pages tiers). Drop the old constraint then
-- add a permissive one.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'activity_scoring_rules_rule_type_check'
      AND conrelid = 'activity_scoring_rules'::regclass
  ) THEN
    ALTER TABLE activity_scoring_rules DROP CONSTRAINT activity_scoring_rules_rule_type_check;
  END IF;
END $$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'activity_scoring_rules_rule_type_any'
      AND conrelid = 'activity_scoring_rules'::regclass
  ) THEN
    ALTER TABLE activity_scoring_rules
      ADD CONSTRAINT activity_scoring_rules_rule_type_any
      CHECK (rule_type IS NOT NULL);
  END IF;
END $$;

-- ===========================================================================
-- 5. FRD §4.1.7 default category seed
--    NOTE: the canonical FRD-default category + sub-activity tree is provided
--    by `backend/scripts/seed-activities.ts` (Prayer/Sunnah/Quran/Daily
--    Routine/Dua & Dhikr/Good Character) which is run as part of project
--    seeding. We deliberately do NOT bake a second seed into this migration
--    to avoid creating duplicate category rows when seed-activities has
--    already run. Run `npm run seed:activities` after migrations on a fresh
--    DB to populate the FRD defaults.
-- ===========================================================================

-- ===========================================================================
-- Done.
-- ===========================================================================
