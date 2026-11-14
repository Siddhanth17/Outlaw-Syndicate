$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
$buildDirectory = Join-Path $projectRoot 'builds/physics-acting-validated'
New-Item -ItemType Directory -Force $buildDirectory | Out-Null
New-Item -ItemType File -Force (Join-Path $projectRoot 'builds/.gdignore') | Out-Null
& (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64_console.exe') --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $buildDirectory 'OutlawSyndicate.exe')
exit $LASTEXITCODE
