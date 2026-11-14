# Latest continuation — articulated NPC physics

Recovered and preserved uncommitted work from e6b5317. Replaced whole-mesh defeat rotation with thirteen real physical segments, oriented constraints, captured animation pose/momentum, non-adjacent self-collision, floor/wall/stair/slope contact, sleeping/waking, pause/restoration and restrained pooled feedback. Added local occluded defeat awareness and corrected expanded-district flee bounds. See articulated-physics-report.md and articulated-physics-validation.md for real source/export evidence and remaining limitations.

The test fixture initially attracted city police by firing from the old player location, causing player defeat and pausing two scenarios; moving the player into the isolated lab and checking external interruption restored valid tests. No physics acceptance check was suppressed. Earlier angular-limit/shape/solver failures were investigated and corrected rather than reported as passes.

This is a physics/combat foundation, not a completed GTA-scale milestone. New roads/blocks/traffic/mission content: zero in this increment. Priority continuation: inspect human controls/recovery and refine palms/cloth/get-up blending; then validate four purposeful connected blocks, implement a physical lane graph and obstacle-aware traffic, expand pedestrian schedules/crossings and police vehicle response, and implement Broken Trust gameplay/checkpoints. Existing fixed population/roads/vehicles/voices and opening mission remain. No work continues after this session ends.

Earlier entries are historical and may contain superseded limitations.

# Latest continuation — reference-directed mobility

Continued ff5e16e without restarting. Preserved old hero/NPC/voice assets and the previous Windows package. New separate half-tied hero derivative, nine-profile movement audio, real hinged driver door/timed transitions, an original assisted two-wheel motorcycle and a multi-road district expansion are implemented. See reference-mobility-report.md and reference-mobility-validation.md for actual evidence and scope. All remain partial production quality; no photorealism claim.

COMPLETE for the scoped systems increment: surface lookup/cadence/sample variation/volume; door timeline/pause/block/cancel; core bike mount/ride/brake/dismount; connected expanded road paths. PARTIAL: reference face/hair/physique/clothing fidelity, nine-surface world art coverage, contact-quality door/rider animation, bike balance/visuals/damage and district density. NOT STARTED runtime: Mission02, remaining campaign, terrain foot IK and full articulated ragdolls. Next: manually listen/play; refine groom/skin/hand/outfit assets, door grips/legs and rider pegs/bars; improve dynamic transition clearance/balance; implement Broken Trust objectives/checkpoints/dialogue partners in the new road loop. No work continues in the background after this session.

Earlier entries below are historical and may contain superseded limitations.

# Latest continuation — living city and signature hero

Preserved the interrupted local assets and original Windows build. Implemented nine role variants, eight stock neural voice profiles and current dialogue, shared incidents/navigation, actual vehicle/person contacts, component gunfire damage/persistence, separate partial Adrian jacket/hair, moving-leg aiming, bounded recoil, directional knockdown and injury masks. See living-city-signature-report.md and living-city-validation.md for scope/evidence.

COMPLETE for this systems increment: live integration, actual contact/ray dispatch, bounded history and save/load. PARTIAL: visual quality, gait/acting, hair/garment collision, driver motion and injuries. NOT STARTED: articulated ragdolls, terrain foot IK, authored door sequence, Mission 02 runtime and full campaign. No background work continues after the session. Exact next work: genuine bounded PhysicalBone joints and ground tests; terrain feet/driver hands and hinged doors; improved groom/face/hands/jacket; arbitrary dialogue partner binding and Broken Trust objectives/checkpoints.

The following sections describe earlier historical milestones and may contain superseded limitations.

# Current physics / acting continuation

Recovered interrupted work and fixed the kinematic exit-velocity damage regression. The short opening mission completes again. Contact-local dents, independent glass, bumper detachment, physical cargo and a draft amplitude-driven facial/gesture conversation are implemented. Full production acting, detailed destruction and the campaign remain incomplete; see physics-acting-report.md and interaction-validation.md for exact scope and results.

# Production state â€” 14 November 2026

Latest increment: reference-directed realism refinement, documented in realism-reference-report.md. New package: builds/realism-refinement. Added 32-joint weighted hair/hem motion, post-animation body/breathing/gaze layers, visible seated Drive pose, rotating steering wheel/brake light, cockpit/seat correction, warehouse service variants, 2K road/concrete maps, original surface/weathering shaders, drains/manholes/forklifts, distant instanced skyline and Human Motion Laboratory. Previous builds remain preserved. Reference-quality realism is NOT achieved; full milestone incomplete.

Current continuation priorities: hero face/eye/hand rig replacement, terrain foot IK, collision-aware secondary motion, precise wheel grips, authored door entry/exit and distinct cast/dialogue performances. Entry/exit still reposition instantly; seated hands only reach the wheel region. Facial morph targets are absent.

Option A was approved. Godot 4.6/Jolt retained; no Unreal migration. The original graybox package remains unchanged in builds/windows and copied to builds/preserved-11aedc2. The new package is builds/iron-harbor-production. See production-session-report.md and production-checklist.md for evidence and scoped progress.

Implemented this session: verified portable Blender/GLB pipeline; licensed clothed rigged human and locomotion; original modeled Sable sedan/wheels and modular industrial kit; CC0 textured roads/sidewalks; nighttime Forward+ lights/shadows/fog/reflections; graphics presets; responsive main/pause/settings/controls/HUD; shoulder/aim/drive cameras; low-curb stepping; engine/tire/footstep/harbor/combat synthesized audio; basic damage/ammo/reload; two-guard encounter; checkpoint defeat/retry; selected persistent guard/faction/district/garage consequences; dedicated handling scene. The original five mission stages and existing tests are preserved.

Milestone 0: foundation delivered, CI still pending. Milestone 1: substantially expanded, advanced controller/combat/navigation remain incomplete. Milestone 2: production increment delivered, polished vertical slice still NOT COMPLETE. Milestones 3â€“11 remain incomplete. One short opening mission exists; no later acts or additional districts, no measured ten-hour campaign.

## Exact continuation point

1. Manually play the new Windows package from New game through mission completion, with keyboard and physical gamepad. Record actual human playtime, aiming/handling problems and readability. Current end-to-end evidence is an automated physical-input route, not a human playtest.
2. Replace basic action clips and instantaneous vehicle occupancy with authored grounded entry/exit, reload/interact/aim/shoot performances; tune stride and add foot/hand contact. Give Adrian, Dante and security distinct art; current shared CC0 Meshy-origin human remains a production stand-in, not final cast identity.
3. Add navigation/cover and robust perception routes to the encounter. Current guards use direct steering/LOS and can snag on complex obstacles. Improve impact/muzzle feedback, dialogue timing and encounter balance.
4. Stage genuinely distinct opening/closing cinematic shots and actor performances. Current skippable camera move and timed subtitles are functional presentation only; no voice, lip sync or facial animation.
5. Finish unique garage/warehouse investigation spaces, water/shoreline and district set dressing. Current modeled kit repeats; roads and sedan still need artist polish. Investigate seven Vulkan Texture RID shutdown warnings; no long-run leak/performance claim.
6. Extract mission/save services, add full save-field validation/migrations and interrupted-write tests, then expand authored Iron Harbor content. Do not scale to empty placeholder districts.

Not implemented: finished six-region streaming world; professional final art/animation/audio; broad weapons/vehicles; coordinated combat/navigation; police actors/traffic/civilian schedules; dynamic day/night/weather; complex faction economy; branching later missions/endings; full accessibility/remapping; Android; full campaign QA/release. No asynchronous continuation is promised.
