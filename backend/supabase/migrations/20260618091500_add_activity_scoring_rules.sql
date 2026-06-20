CREATE TABLE IF NOT EXISTS activity_scoring_rules (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
	rule_type TEXT NOT NULL CHECK (rule_type IN ('rating', 'quantity')),
	min_quantity INTEGER,
	max_quantity INTEGER,
	marks INTEGER NOT NULL,
	display_order INTEGER NOT NULL DEFAULT 0,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	CONSTRAINT activity_scoring_rules_quantity_range CHECK (
		rule_type <> 'quantity'
		OR min_quantity IS NOT NULL
	),
	CONSTRAINT activity_scoring_rules_valid_range CHECK (
		max_quantity IS NULL OR min_quantity <= max_quantity
	)
);

CREATE INDEX IF NOT EXISTS idx_activity_scoring_rules_activity
	ON activity_scoring_rules(activity_id, rule_type, display_order);

ALTER TABLE activity_logs
	ALTER COLUMN rating_id DROP NOT NULL;

CREATE TABLE IF NOT EXISTS audit_logs (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	actor_profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
	action TEXT NOT NULL,
	entity_type TEXT NOT NULL,
	entity_id UUID,
	metadata JSONB,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_created_at
	ON audit_logs(actor_profile_id, created_at DESC);

ALTER TABLE activity_scoring_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'activity_scoring_rules' AND policyname = 'Admins manage scoring rules'
	) THEN
		CREATE POLICY "Admins manage scoring rules"
		  ON activity_scoring_rules FOR ALL
		  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin')
		  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
	END IF;
END $$;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'audit_logs' AND policyname = 'Admins can read audit logs'
	) THEN
		CREATE POLICY "Admins can read audit logs"
		  ON audit_logs FOR SELECT
		  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
	END IF;
END $$;