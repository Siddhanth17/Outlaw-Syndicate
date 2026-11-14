# Metropolis foundation — bounded production increment

The 2026-11-15 directive is **PARTIAL**, not a completed metropolis, photorealistic art pass or full campaign. Recovered clean `main` at `5471131`; no user changes were discarded. Godot 4.6/Jolt and the existing original harbor remain in use. Previous Windows builds are preserved. No engine migration or new third-party asset acquisition occurred.

## Implemented behavior

- New Game enters free roam without the introductory cinematic or active story. It currently starts at the existing harbor, **not an owned apartment**. Phone → Messages → Accept deliberately activates The Last Address. Proximity cannot accept it. Existing version-1 checkpoints without `open_world` retain their active mission; new checkpoints preserve the choice independently of mission stage.
- Original motorcycle handlebars swept back to fit actual limb lengths. Handlebar, grips and mirrors are separately exported and steer together. Wheels now have open rims, spokes, hubs and brake rotors instead of a filled rim disk. Two-wheel vehicle forces, assisted upright chassis and suspension remain. This is an assisted prototype, not a real motorcycle balance simulation.
- Post-animation SkeletonModifier3D aligns the pelvis to the modeled saddle, inclines the torso, solves elbows/knees toward pole targets and tracks hands/ankles to actual grip/peg coordinates without stretching limbs. Boot toe orientation follows the motorcycle. Rider and model share the roll frame. The camera recenters behind the bike after manual orbit times out.
- Bottom-right phone slides in on foot; Tab/O bindings persist through Settings. Movement, camera and action input are captured while open; ambient simulation continues. Gameplay HUD is hidden to avoid overlap. Pause/defeat/load closes the phone and stops call audio. Use on vehicles or airborne is refused.
- Message acceptance, earned Dante contact, a short ringing/voiced call with text and end/busy paths, PNG scene camera, bounded 32-photo gallery with previous/next browsing, and checkpoint persistence are functional. Photos omit the HUD and phone. New Game clears the gallery index without deleting image files. The camera captures the current third-person scene; dedicated aimable camera controls are not implemented.
- Free-roam interaction with Dante offers distinct greeting/work questions and then a number request. A contact permits garage service: player within 4m, stationary Sable within 10m, available mechanic, damage present and $50 cash. Charge and real engine/body/glass/tire/light repair happen synchronously. Healthy vehicles and insufficient funds do not incur charges. Relationship flags, balance and damage restore together. These are small authored interactions, not a general dialogue/social simulation.

## Visual findings and limitations

The supplied bike view correctly identified a fixed-offset rider with no grip/peg constraint. Initial testing found an additional ~30cm reach mismatch; the modeled handlebar sweep and torso articulation address reach rather than scaling arms. Captures are actual game renders. Hands use wrist endpoints and the imported rig has no articulated fingers: finger wrapping, palm orientation and mount/dismount acting still need work. Hair/clothing, lighting and materials remain visibly prototype quality. No photorealism claim is made.

The metropolis reference is useful for road hierarchy, connected blocks, varied footprints, green space and district contrast. It is an aerial city-builder scene, not proof of third-person traversal/traffic performance. This increment does not enlarge the map or copy that layout. A city-scale production scene requires a road/lane graph and streaming budget before additional buildings or population are added.

## Outstanding directive status

| Area | Status | Remaining work |
|---|---|---|
| Rider/camera | PARTIAL | Finger/palm grip, head aim, acting, wider terrain stress tests |
| Free roam | PARTIAL | Optional story works; modeled owned safehouse/storage/sleep absent |
| Smartphone | PARTIAL | Map/GPS, business/property/bank apps, incoming calls, general contacts and dedicated photo controls absent |
| Mechanic/service | PARTIAL | One contact and Sable repair; no schedules, motorcycle repair, earning loop or mini-story |
| Dense metropolis | NOT STARTED in this increment | Six districts, road/lane graph, streaming, varied final architecture, budgets |
| AI traffic/signals | NOT STARTED | Force-driven lane followers, yielding, intersection control, recovery |
| Pedestrian routines | PARTIAL baseline | Routed population/reactivity preserved; occupation/home schedules and broad identity persistence absent |
| Police/justice/factions | PARTIAL baseline | Search/guard reactions preserved; arrest/jail/stations/systemic pursuit and gang progression absent |
| Banking/property/showrooms/jobs | NOT STARTED | No placeholder apps presented as working systems |
| Mission 02/five acts | NOT STARTED as playable content | Preparatory content remains; existing M1 preserved |

The requested home → phone → mechanic → repair → home vertical slice is **not complete**: no owned home, earning job, navigation app or police/arrest branch yet. Next coherent step: an original modest safehouse with entrance/save/storage, then a road/lane graph and one tested signalized traffic loop; retain the interaction loop as regression coverage.

## Validation and delivery

Source/export verification results, build hashes, performance scope and evidence are recorded with the local build. Tests use isolated `tools/qa-data` profiles and do not overwrite the player's normal save. Automated routes exercise actual game input/UI and state; they are not a human mouse/controller playthrough. Existing Vulkan shutdown texture RID warnings remain known.

The original eight source suites passed **275 assertions**; the new source route passed **31**, with no failures. Final exported verification: metropolis **33**, opening mission **14**, mobility **54**, articulated ragdolls **53**, all with **zero failures** and exit 0. Ragdoll regression includes all six scenarios and concurrent bodies. Logs ship locally alongside the evidence. The final phone binding is tested through an actual parsed key event while its GUI has focus, rather than only by calling `close()`.

Final exported render snapshot: **1280×720, Forward+, RTX 3050 Laptop**, stationary mounted rider in the existing harbor. 180 uncapped rendered frames averaged **341.48 FPS**, p95 **4.287ms**, maximum **4.823ms**, texture/buffer monitor **843,665,952 bytes**. This is only about **0.53 seconds** of sampling, not a sustained benchmark, a full VRAM/RAM measurement, a dense city result or a minimum-FPS guarantee. Longer traversal/traffic/population profiling is still required.

Visual inspection covered actual exported front, side, rear and turning views, the phone and gallery. Boot position and upright head orientation improved; fingers remain spread instead of wrapped around grips, hair has visibly stiff/ribbon artifacts, and tire/material lighting still needs art work. These prevent calling the rider's complete visual requirement finished.

Build: `D:/OutlawSyndicate/builds/metropolis-foundation/OutlawSyndicate.exe` with adjacent PCK. Prior `builds/articulated-physics` is preserved. Run opt-in `-- --verify-metropolis` only with a separate APPDATA profile: it deliberately saves/loads and edits a legacy checkpoint fixture. Normal launch does not run QA.

Validated PCK SHA256: `8d177b8e4dd5de82ecc36d2e091ffb0eea2a8c4ade066f7cf264ad9e268d1056`. Preserved prior PCK remains `747ce6ee3f567b1e80f8d6b3277a4c76fec15c5b37c92642198a5f31dd5ef9c8`. No new script errors remain in the final exported route; seven texture RID warnings still appear on Vulkan shutdown. Human/gamepad playthrough: **NOT RUN**.
