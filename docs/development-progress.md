# Production state — 14 November 2026

Visual correction audit completed: see visual-production-audit.md. All current art remains graybox; no production art milestone completed. Recommendation is retain Godot with a proper Blender/glTF asset pipeline, pending user engine decision. Original build preserved under builds/preserved-11aedc2 with matching hashes. No engine migration or renderer change performed.

Milestone 0: project, engine and Jolt configured; Git/LFS configured. Milestone 1: partial implementation. Milestone 2: NOT COMPLETE. Milestones 3–11: NOT COMPLETE.

Implemented: runtime-generated harbor blockout, capsule character with camera-relative movement/jump/sprint/slow stance, SpringArm camera, four-wheel VehicleBody3D car, hitscan training targets, moving geometric civilians, basic controller bindings, pause/save/load/new-game controls, subtitle dialogue, data-defined five-stage opening mission, event deduplication and one persistent mission consequence. Atomic save replacement has one backup.

Not implemented: finished district, six-region world, streaming, authored character meshes/animation, actual crouch clearance, climbing/vaulting/cover, weapon inventory/reload, enemies, police, navigation, traffic, faction gameplay, day/night/weather, audio/music/voice, cinematics, side activities, garage economy, settings persistence, complete menus/accessibility, remaining campaign or endings. No measured campaign duration. No final game release.

## Next coherent increment

1. Manually play The Last Address with keyboard and controller; record handling/camera issues and actual time. Fix progression or physics problems before adding content.
2. Replace target shooting with health/ammo/reload and a small, navigated enemy encounter, including checkpoint failure/retry tests.
3. Add objective IDs, explicit checkpoint snapshots and mission runtime separated from main.gd; add robust save schema validation and corrupt-save recovery tests.
4. Build actual Dante encounter and skippable opening camera timeline; add original animated player and vehicle art with provenance.
5. Complete and playtest Iron Harbor to vertical-slice quality, then follow release-roadmap.md through all remaining milestones.

Do not call this a polished vertical slice. Automated state transitions do not demonstrate mission fun, animation quality, driving feel or ten hours of authored gameplay.
