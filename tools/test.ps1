$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$env:APPDATA = Join-Path $PSScriptRoot 'runtime-data'
foreach ($suite in @('smoke', 'production', 'mission_playthrough', 'realism', 'acting', 'living_city', 'mobility', 'ragdoll', 'metropolis', 'urban')) {
    & (Join-Path $PSScriptRoot 'engine/Godot_v4.6-stable_win64_console.exe') --headless --fixed-fps 60 --path $projectRoot --script "res://tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
exit 0
