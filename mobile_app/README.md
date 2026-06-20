# mobile_app

Flutter app for student and parent access.

## Google Sign-In Setup

The login page now uses Supabase Auth with Google provider and then exchanges the Supabase access token with the backend endpoint `POST /api/auth/supabase-signin`.

Run the app with Supabase values passed as Dart defines:

```bash
flutter run -d chrome --web-port 5092 \
	--dart-define=API_BASE_URL=http://localhost:3000/api \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Enable the Google provider in Supabase Auth and use a Google account that is mapped to a `student` or `parent` profile in Supabase.
