$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
foreach ($suite in @('smoke', 'production', 'mission_playthrough', 'realism')) {
    & (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64_console.exe') --headless --path $projectRoot --script "res://tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
exit 0
