-- Attendance Table (FRD §4.3 — teacher marks daily attendance per student)
--
-- A teacher records each student's presence for a given day. One row per
-- (student, date); re-marking updates the existing row via UNIQUE upsert.

CREATE TABLE IF NOT EXISTS attendance (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
	batch_id UUID REFERENCES batches(id) ON DELETE SET NULL,
	attendance_date DATE NOT NULL,
	status TEXT NOT NULL DEFAULT 'present'
		CHECK (status IN ('present', 'absent', 'late', 'excused')),
	marked_by UUID REFERENCES teachers(id) ON DELETE SET NULL,
	notes TEXT,
	created_at TIMESTAMPTZ DEFAULT NOW(),
	updated_at TIMESTAMPTZ DEFAULT NOW(),
	UNIQUE(student_id, attendance_date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_batch_date ON attendance(batch_id, attendance_date);

-- Track which teacher awarded a badge (for teacher-driven recognition).
ALTER TABLE student_badges
	ADD COLUMN IF NOT EXISTS awarded_by UUID REFERENCES teachers(id) ON DELETE SET NULL;
