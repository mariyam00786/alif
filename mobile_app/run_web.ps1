Set-Location 'C:\Users\JAMSHEER\Desktop\alifschool\mobile_app'
$envFile = Get-Content 'C:\Users\JAMSHEER\Desktop\alifschool\backend\.env'
$vars = @{}
foreach ($l in $envFile) {
    if ($l -match '^(SUPABASE_URL|SUPABASE_ANON_KEY)=(.*)$') {
        $vars[$matches[1]] = $matches[2].Trim('"').Trim()
    }
}
flutter run -d web-server --web-port 5131 `
    --dart-define=SUPABASE_URL=$($vars['SUPABASE_URL']) `
    --dart-define=SUPABASE_ANON_KEY=$($vars['SUPABASE_ANON_KEY']) `
    --dart-define=API_BASE_URL=http://localhost:3000/api
