# OUTLAW SYNDICATE

The City That Sold Its Soul — an in-development Godot 4.6/Jolt third-person crime game for Windows.

**Current delivery: early gameplay blockout. The complete game and ten-hour campaign do not exist yet.**

## Play

Open `project.godot` in Godot **4.6 stable** and press F6 on `scenes/main.tscn`, or F5. The local engine is excluded from Git; on this development machine run `./tools/play.ps1`. A locally exported executable, when present, is `builds/windows/OutlawSyndicate.exe`; keep its adjacent PCK file beside it.

WASD moves or drives; mouse looks; Shift sprints; Ctrl slows movement; Space jumps or brakes. E interacts or enters/exits the car (exit requires low speed). Click shoots targets. F5 saves, F9 loads, Esc opens the pause menu. Controller left/right sticks, A, Y, right shoulder and Start have basic mappings; full controller menu navigation is pending.

Follow amber markers through The Last Address: meet Dante, take the red car to the warehouse, leave the car and collect the ledger, escape the search area, return to the garage on foot. Dialogue appears as subtitles. Search is currently a proximity-and-timer mechanic, not police AI.

## Validation

`./tools/test.ps1` runs engine-backed smoke checks. It uses isolated development save data under ignored `tools/runtime-data`. Tests overwrite this test save. Use a separate APPDATA when running your own saves. Export using the Windows Desktop preset after obtaining matching official templates; its custom template paths point to ignored `tools/templates`.

See `docs/development-progress.md` for truthful scope and continuation tasks, `docs/testing-report.md` for evidence, and `docs/asset-licenses.md` for provenance. No third-party art or commercial brands are bundled.
