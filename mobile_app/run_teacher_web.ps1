$envFile = "C:\Users\JAMSHEER\Desktop\alifschool\backend\.env"
$cfg = @{}
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*([^#=]+)=(.*)$') { $cfg[$matches[1].Trim()] = $matches[2].Trim().Trim('"') }
}
$su = $cfg['SUPABASE_URL']
$ak = $cfg['SUPABASE_ANON_KEY']
$cmd = "flutter run -d web-server --web-port 5132 " +
  "--dart-define=SUPABASE_URL=$su " +
  "--dart-define=SUPABASE_ANON_KEY=$ak " +
  "--dart-define=API_BASE_URL=http://localhost:3000/api " +
  "> flutter_run.out.log 2> flutter_run.err.log"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd `
  -WorkingDirectory "C:\Users\JAMSHEER\Desktop\alifschool\mobile_app" -WindowStyle Minimized
Write-Output "launched on 5132"
