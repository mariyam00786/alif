-- Store the subjects a teacher handles as a text array on the teachers row.
-- (There is no separate subjects table; subjects are free-form labels chosen
-- in the admin panel.)
ALTER TABLE teachers ADD COLUMN IF NOT EXISTS subjects TEXT[] DEFAULT '{}';
