Latest increment: Operation Veyra architecture rescue: four Northline blocks, detailed original frontages, signal-controlled two-car traffic prototype, shared lighting clock, four named scheduled citizens and initial visual-sector streaming. Full sprint status and resume instructions: docs/OPERATION_VEYRA_PROGRESS.md. The 12-block metropolis and wider campaign remain incomplete.

# OUTLAW SYNDICATE

Godot 4.6 / Jolt, Windows-first third-person crime game in active production.

**Current build: Operation Veyra architecture increment. Existing harbor plus four urban blocks and one optional opening mission; not the completed metropolis.**

## Play the new build

On this development machine run `D:/OutlawSyndicate/builds/operation-veyra-architecture/OutlawSyndicate.exe` with its adjacent PCK. Previous builds remain in `builds/metropolis-foundation` and `builds/articulated-physics`. From the harbor, turn north and continue past the northern junction into Northline. Settings > Time: Day / Night controls the shared world clock. New shopfronts have walkable vestibules but do not yet sell items. Binaries are local artifacts, not committed downloads.

Choose **New game** for harbor free roam. On foot, Tab > Messages > Accept intentionally starts The Last Address. E near Dante in free roam opens conversation: greet, ask about work, then request his number. Contacts supports a short voiced call. A damaged stationary Sable near the garage can be repaired for $50. Camera captures a scene PNG without HUD; Gallery browses saved captures. F5 saves the gallery index and relationship. Settings offers Tab or O for the phone. Continue restores your checkpoint.

WASD / left stick: move or drive. Mouse / right stick: look. Shift / B: sprint. Space / A: jump or brake. E / Y: interact or enter/exit at low speed. Right mouse / LB: aim. Left mouse / RB: shoot. R / X: reload. Esc / Start: pause. F5/F9: save/load. Mouse aim is required to align shots; combat is fictional and gameplay-tuned.

The Last Address: meet Dante at the ring, enter the orange Sable GT, drive to bonded storage, leave the car and recover the ledger. Fight or escape the two security guards, get outside the warehouse search area until search reaches zero, then return to Dante on foot. Low curbs can be stepped over. The opening is short and its human playtime has not been measured.

## Implemented production increment

Clothed skinned human with AnimationTree locomotion; additional basic keyframed actions; original Blender-modeled sedan and industrial kit; CC0 asphalt/concrete maps; Forward+ nighttime lighting, shadows and fog; Low/Balanced/High presets; responsive HUD and main/pause/settings/controls menus; shoulder/aim/drive cameras; vehicle damage and synthesized engine/tire audio; enemy patrol/perception/engagement/defeat, health/ammo/reload, checkpoint retry and persistent selected consequences.

This remains early production art. Repeated buildings/cast, angular vehicle body, simple action clips, synthetic sounds, limited facial animation and limited AI are documented in `docs/production-session-report.md`. No photorealism or professional simulation claim. The new pass adds weighted hair/hem springs, visible seated driving, 2K maps, warehouse variants and service props. See docs/realism-reference-report.md for matched before/after captures and explicit gaps.

## Develop and test

Open `project.godot` with Godot **4.6 stable** and press F5, or use `./tools/play.ps1` with the local ignored engine. `./tools/test.ps1` runs original, production, physical mission-route, realism, acting and living-city suites against isolated development save data; tests overwrite that test profile. Run `tests/mission_playthrough.gd` with Godot headless for the input-driven mission route. Rendered evidence/performance harness: `tests/production_capture.gd`.

Portable Blender **4.5.3 LTS** is local under ignored tools/blender. Rebuild base meshes using `blender --background --python art/build_assets.py`, then apply the refinement with `blender --background --python art/refine_realism.py`; input human GLB and editable .blend sources are under art/source. After the first Godot import, run `python art/configure_imports.py` and reimport to apply VRAM compression/mipmaps. Rebuild original synthesized non-dialogue WAV files with `python art/build_audio.py`. Current neural dialogue is preserved by default by `art/build_neural_dialogue.py`; exact tool/model provenance is in assets/licenses/neural-voice-provenance.json. Asset import settings and licenses are committed. Clone with Git LFS installed (`git lfs pull`) before opening the project. Install Godot and its matching Windows export templates to the custom paths in export_presets.cfg, then use `./tools/build.ps1`. This exports to a separate production folder.

See `docs/production-checklist.md`, `docs/testing-report.md`, `docs/asset-licenses.md`, and `docs/development-progress.md`. No additional districts or later campaign acts have been implemented.

Living City Laboratory shows the nine role assets and real vehicle/person experiments. F6 cycles voice samples; F7 starts the Adrian/Dante conversation. Press P to pause as an alternative to Esc. Actual district NPCs use the same models and behaviors.

The Harrier motorcycle is parked near (-5, 10) in the starting area: approach and press E/Y, then use normal drive/brake/look controls. Stop before dismounting. Car doors animate during normal gameplay. Movement Audio Laboratory provides nine labeled acoustic pads; number keys 1–9 select a pad. Pause > Settings offers separate movement volume. Side roads at x=-70 and x=72 connect through streets at z=58 and z=-176. Bike traversal currently supports free roam; the opening mission still requires the Sable.

Articulated Physics Laboratory: keys 1–5 reset frontal, side, running, wall and stair cases. Normal movement/look/shoot controls apply. Pause > Settings offers impact-effect density. The automated exported ragdoll route additionally checks a slope and concurrent bodies; its debug fixtures are not final environment art.
