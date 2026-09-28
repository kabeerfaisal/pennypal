# Regenerates the runtime config files from .env.
#
# The app reads its config at startup, so these two files must exist before a
# run or release build:
#   assets/env.txt  - bundled into the APK and the web build, the only source
#                     that exists on Android and on a deployed site
#   web/env.js      - sets window.env, loaded by web/index.html
#
# Run this after every .env change, then do a full restart (not hot reload).

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'No .env found in the project root.' -ForegroundColor Red
    exit 1
}

$pairs = @()
foreach ($line in Get-Content $envFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
    $split = $trimmed -split '=', 2
    if ($split.Count -ne 2) { continue }
    $key = $split[0].Trim()
    $value = $split[1].Trim()
    if ($key -eq '' -or $value -eq '') { continue }
    $pairs += [pscustomobject]@{ Key = $key; Value = $value }
}

if ($pairs.Count -eq 0) {
    Write-Host '.env has no KEY=value pairs.' -ForegroundColor Red
    exit 1
}

# assets/env.txt - plain KEY=value, read by lib/utils/env_config.dart
$assetsDir = Join-Path $PSScriptRoot 'assets'
if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}
$lines = @('# Generated from .env by sync-env.ps1. Do not edit by hand.')
foreach ($p in $pairs) { $lines += "$($p.Key)=$($p.Value)" }
Set-Content -Path (Join-Path $assetsDir 'env.txt') -Value $lines -Encoding utf8

# web/env.js - window.env, read by web/index.html before Flutter boots
$jsPairs = $pairs | ForEach-Object {
    $escaped = $_.Value.Replace('\', '\\').Replace("'", "\'")
    "  `"$($_.Key)`": '$escaped'"
}
$js = @(
    '// Generated from .env by sync-env.ps1. Do not edit by hand.'
    'window.env = {'
    ($jsPairs -join ",`n")
    '};'
) -join "`n"
Set-Content -Path (Join-Path $PSScriptRoot 'web\env.js') -Value $js -Encoding utf8

Write-Host "assets\env.txt and web\env.js updated with $($pairs.Count) value(s)" -ForegroundColor DarkGreen
Write-Host 'Restart the app (full stop and run again) for the change to apply.' -ForegroundColor DarkGray
