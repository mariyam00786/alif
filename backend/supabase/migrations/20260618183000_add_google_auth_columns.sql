ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS google_email TEXT,
ADD COLUMN IF NOT EXISTS firebase_uid TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_google_email
ON profiles (google_email)
WHERE google_email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_firebase_uid
ON profiles (firebase_uid)
WHERE firebase_uid IS NOT NULL;