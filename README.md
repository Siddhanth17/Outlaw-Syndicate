# OUTLAW SYNDICATE

Godot 4.6 / Jolt, Windows-first third-person crime game in active production.

**Current build: reference-directed realism refinement. One short opening mission, not the complete game or a ten-hour campaign.**

## Play the new build

On this development machine run `D:/OutlawSyndicate/builds/realism-refinement/OutlawSyndicate.exe` with its adjacent PCK file. The original graybox package remains under `builds/windows` and `builds/preserved-11aedc2`. Binaries are local artifacts, not committed downloads.

Choose **New game** for the introduction, or **Continue** for your checkpoint. Enter / controller A skips the introduction. Pause → Controls lists bindings. The separate **Driving course** menu entry opens a handling test scene.

WASD / left stick: move or drive. Mouse / right stick: look. Shift / B: sprint. Space / A: jump or brake. E / Y: interact or enter/exit at low speed. Right mouse / LB: aim. Left mouse / RB: shoot. R / X: reload. Esc / Start: pause. F5/F9: save/load. Mouse aim is required to align shots; combat is fictional and gameplay-tuned.

The Last Address: meet Dante at the ring, enter the orange Sable GT, drive to bonded storage, leave the car and recover the ledger. Fight or escape the two security guards, get outside the warehouse search area until search reaches zero, then return to Dante on foot. Low curbs can be stepped over. The opening is short and its human playtime has not been measured.

## Implemented production increment

Clothed skinned human with AnimationTree locomotion; additional basic keyframed actions; original Blender-modeled sedan and industrial kit; CC0 asphalt/concrete maps; Forward+ nighttime lighting, shadows and fog; Low/Balanced/High presets; responsive HUD and main/pause/settings/controls menus; shoulder/aim/drive cameras; vehicle damage and synthesized engine/tire audio; enemy patrol/perception/engagement/defeat, health/ammo/reload, checkpoint retry and persistent selected consequences.

This remains early production art. Repeated buildings/cast, angular vehicle body, simple action clips, synthetic sounds, lack of voice/facial animation and limited AI are documented in `docs/production-session-report.md`. No photorealism or professional simulation claim. The new pass adds weighted hair/hem springs, visible seated driving, 2K maps, warehouse variants and service props. See docs/realism-reference-report.md for matched before/after captures and explicit gaps.

## Develop and test

Open `project.godot` with Godot **4.6 stable** and press F5, or use `./tools/play.ps1` with the local ignored engine. `./tools/test.ps1` runs original, production, physical mission-route and realism suites against isolated development save data; tests overwrite that test profile. Run `tests/mission_playthrough.gd` with Godot headless for the input-driven mission route. Rendered evidence/performance harness: `tests/production_capture.gd`.

Portable Blender **4.5.3 LTS** is local under ignored tools/blender. Rebuild base meshes using `blender --background --python art/build_assets.py`, then apply the refinement with `blender --background --python art/refine_realism.py`; input human GLB and editable .blend sources are under art/source. After the first Godot import, run `python art/configure_imports.py` and reimport to apply VRAM compression/mipmaps. Rebuild original synthesized WAV files with `python art/build_audio.py`. Asset import settings and licenses are committed. Clone with Git LFS installed (`git lfs pull`) before opening the project. Install Godot and its matching Windows export templates to the custom paths in export_presets.cfg, then use `./tools/build.ps1`. This exports to a separate production folder.

See `docs/production-checklist.md`, `docs/testing-report.md`, `docs/asset-licenses.md`, and `docs/development-progress.md`. No additional districts or later campaign acts have been implemented.
