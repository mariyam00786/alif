# admin_panel

Flutter web admin app for Alif School.

## Google Sign-In Setup

The admin login now uses Supabase Auth with Google provider and then exchanges the Supabase access token with the backend endpoint `POST /api/auth/supabase-signin`.

Run the app with Supabase values passed as Dart defines:

```bash
flutter run -d chrome --web-port 5070 \
	--dart-define=API_BASE_URL=http://localhost:3000/api \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Enable the Google provider in Supabase Auth and use a Google account that is mapped to an `admin` profile in Supabase.
