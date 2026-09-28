# Runs the app with every key read from .env, so you never have to type
# --dart-define again.
#
#   .\run.ps1              -> run on the last used device
#   .\run.ps1 chrome       -> run on Chrome
#   .\run.ps1 apk          -> build a release APK
#   .\run.ps1 web          -> build for web
#
# This also regenerates assets\env.txt and web\env.js, so a plain
# `flutter run` or the Android Studio Run button picks the keys up too.

param(
    [string]$Mode = 'run'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'No .env found. Copy .env.example to .env and fill in your keys.' -ForegroundColor Red
    exit 1
}

# Keep the bundled copies in step with .env before anything is built.
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'sync-env.ps1')
if ($LASTEXITCODE -ne 0) { exit 1 }

# Parse KEY=value lines, ignoring comments and blank lines.
$values = @{}
foreach ($line in Get-Content $envFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
    $split = $trimmed -split '=', 2
    if ($split.Count -ne 2) { continue }
    $values[$split[0].Trim()] = $split[1].Trim()
}

if (-not $values.ContainsKey('GROQ_API_KEY') -or $values['GROQ_API_KEY'] -eq '') {
    Write-Host 'GROQ_API_KEY is missing from .env' -ForegroundColor Red
    exit 1
}

# Never print the key itself, only that it was found.
Write-Host "Loaded $($values.Count) value(s) from .env (key hidden)" -ForegroundColor DarkGreen

$defines = @()
foreach ($key in $values.Keys) {
    $defines += "--dart-define=$key=$($values[$key])"
}

switch ($Mode) {
    'chrome'   { & flutter run -d chrome @defines }
    'apk'      { & flutter build apk --release @defines }
    'web'      { & flutter build web @defines }
    'webserve' { & flutter run -d web-server @defines }
    'test'     { & flutter test @defines }
    default    { & flutter run @defines }
}
