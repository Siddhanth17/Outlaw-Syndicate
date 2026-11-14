$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
$buildDirectory = Join-Path $projectRoot 'builds/iron-harbor-production'
New-Item -ItemType Directory -Force $buildDirectory | Out-Null
& (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64_console.exe') --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $buildDirectory 'OutlawSyndicate.exe')
exit $LASTEXITCODE
