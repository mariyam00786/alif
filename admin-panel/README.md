# admin_panel

Flutter web admin app for Alif School.

## Google Sign-In Setup

The admin login now uses Supabase Auth with Google provider and then exchanges the Supabase access token with the backend endpoint `POST /api/auth/supabase-signin`.

All API/Supabase values live in the central env file `dart-defines.json` at the
repository root (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). Run the
app with that single file instead of repeating each define:

```bash
flutter run -d chrome --web-port 5070 \
	--dart-define-from-file=../dart-defines.json
```

In VS Code you can also just press F5 and pick the **admin-panel (web)** launch
configuration, which already loads `dart-defines.json`.

Enable the Google provider in Supabase Auth and use a Google account that is mapped to an `admin` profile in Supabase.
