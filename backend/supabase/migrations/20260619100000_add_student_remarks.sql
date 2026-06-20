-- Student Remarks Table
-- Stores feedback/remarks left by teachers on individual students
-- (FRD §4.3.2 "Add remarks/feedback", API POST /teacher/student/:id/remark).

CREATE TABLE IF NOT EXISTS student_remarks (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
	teacher_id UUID REFERENCES teachers(id) ON DELETE SET NULL,
	message TEXT NOT NULL,
	created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_remarks_student ON student_remarks(student_id);
CREATE INDEX IF NOT EXISTS idx_student_remarks_teacher ON student_remarks(teacher_id);

ALTER TABLE student_remarks ENABLE ROW LEVEL SECURITY;
