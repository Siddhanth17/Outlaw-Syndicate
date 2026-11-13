$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
& (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64.exe') --path $projectRoot
