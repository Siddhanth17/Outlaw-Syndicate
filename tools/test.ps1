$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
& (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64_console.exe') --headless --path $projectRoot --script res://tests/smoke.gd
exit $LASTEXITCODE
