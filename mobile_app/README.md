# mobile_app

Flutter app for student and parent access.

## Google Sign-In Setup

The login page now uses Supabase Auth with Google provider and then exchanges the Supabase access token with the backend endpoint `POST /api/auth/supabase-signin`.

All API/Supabase values live in the central env file `dart-defines.json` at the
repository root (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). Run the
app with that single file instead of repeating each define:

```bash
flutter run -d chrome --web-port 5092 \
	--dart-define-from-file=../dart-defines.json
```

In VS Code you can also just press F5 and pick the **mobile_app** launch
configuration, which already loads `dart-defines.json`.

Enable the Google provider in Supabase Auth and use a Google account that is mapped to a `student` or `parent` profile in Supabase.
