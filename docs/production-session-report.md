# Iron Harbor production session — 14 November 2026

Historical first-production increment. The later, stricter reference-directed pass is documented in realism-reference-report.md; the 79.2% checklist below is not a reference-quality realism score.

Delivered a substantial playable production increment in the existing **Godot 4.6/Jolt** project. **19/24 checklist items verified (79.2% acceptance coverage)**. Five partial items are not counted; the polished visual milestone and full game remain incomplete. This measures the fixed checklist, not production effort or full-game completion.

## Implemented changes

The capsule is replaced by a clothed skinned human with AnimationTree locomotion. The box car is replaced by an original modeled Sable GT with wheel arches, separate visual wheels/rims, glazing, lights, cabin, mirrors, handles and grille. Modeled warehouses, containers, streetlights, fencing, cargo assemblies and lattice cranes replace the old visible blockout. Asphalt/concrete maps, raised sidewalks, clearance-checked curb stepping, nighttime Forward+ lights/shadows/fog/reflections and three graphics presets are integrated.

The responsive HUD separates objectives, status, health, context prompts, ammo/speed and subtitles. Main/pause/settings/controls/credits/retry screens hide gameplay UI. Camera has shoulder framing, aiming FOV/distance, a collision sweep and driving heading follow. Vehicle occupancy still repositions instantly and needs spatial/animation polish.

The five-stage opening now includes two security actors, actual health/damage, ammo/reload, enemy defeat, checkpoint retry and selected persistent consequences. Poor faction reputation affects detection; the ledger changes alert lighting; defeated guards stay defeated after reload; Dante's mission reward repairs 25 integrity once. A separate handling course is accessible from the main menu. Opening/closing camera moves are skippable and use timed text subtitles.

## Assets and licenses

Portable Blender 4.5.3 LTS ran successfully; its archive SHA256 matches the publisher checksum. Reproducible Blender scripts and editable sources establish Blender → GLB → Godot.

- Human and source Walk/Run clips: publisher-declared CC0 on vibeassets; explicitly Meshy-generated. Basic additional action clips are project-keyframed, not motion capture.
- Asphalt 02 and Concrete Layers 02: CC0, Rob Tuytel / Poly Haven.
- Sedan, sidearm and industrial kit: original modeled project assets.
- Engine, tire, harbor, footstep, shot and reload WAVs: original synthesized audio, no external samples.

Exact sources, license text, metadata and hashes: [asset provenance](asset-licenses.md) and `assets/asset-manifest.json`. No unauthorized branded models, commercial music or proprietary Mixamo raw downloads were used.

## Actual visual evidence

![Actual Iron Harbor gameplay](evidence/1080p.jpg)

![Actual modeled vehicle](evidence/car.jpg)

![Actual pause interface](evidence/pause.jpg)

These are compressed actual viewport captures, not generated promotional art. More views are in `docs/evidence`; full PNGs, 16 motion frames and a GIF remain under `tests/artifacts`. Skeleton-pose changes during movement are tested.

The improvement is substantial, but this remains early production art: angular sedan, repeated buildings/cargo, shared Adrian/Dante/security model, basic action clips and hand/foot contacts, synthetic sounds, no voice/facial acting, no unique investigation interiors or waterfront. No photorealism claim.

## Verification

**72 source-game assertions PASS:** 19 original regression checks, 39 production checks and 14 input-driven mission checkpoints. The latter uses walking and actual vehicle physics, scripted weapon aiming, security defeat, escape and garage return without objective-position teleporting. It reports **50.6167 simulated physics seconds**, not human campaign playtime. Human keyboard/gamepad playthrough remains NOT RUN.

The separate Windows release exports and launches on the RTX 3050 under Vulkan/Forward+, **exit 0**. Its startup menu was launch-tested; the full automated route was tested in the source game. An optional external test-script attempt against the export did not yield a completed result and was stopped: BLOCKED, no packaged-suite PASS claimed.

Known diagnostics: editor-settings safe-save warning during restricted export, and seven Texture RID warnings on rendered shutdown. Investigate before a release-quality claim. Headless tests mute audio playback to avoid dummy-backend teardown leaks; rendered playback stays enabled. Final headless suites have no warning/error output. See [testing report](testing-report.md).

## Measured rendering performance

Machine: i5-13450HX, approximately 16 GB RAM, RTX 3050 Laptop 6 GB, driver 621.01. Godot 4.6 Vulkan/Forward+. Each sample: 120 warmup frames, then 600 rendered intervals.

| Scenario | Average FPS | Mean ms | p95 ms |
|---|---:|---:|---:|
| 1080p district, Low | 199.48 | 5.013 | 6.060 |
| 1080p district, Balanced | 143.03 | 6.992 | 8.138 |
| 1080p district, High | 121.72 | 8.216 | 9.341 |
| 720p accelerating vehicle, Balanced | 232.52 | 4.301 | 5.320 |

Engine video-memory estimates: about 761 MiB in the 1080p Balanced view, 807 MiB High and 656 MiB driving. Engine static-memory counter: about 100 MiB, not OS working set. District view reported 305 draw calls; driving 576. Raw data is copied to `docs/evidence/performance.json`.

These short wall-clock samples include scheduling/presentation. They are not isolated GPU timing, thermal/sustained tests or full-city guarantees. High-only SSR/volumetrics and cached buffers affect memory estimates.

## Windows package and Git

New package: `D:/OutlawSyndicate/builds/iron-harbor-production/OutlawSyndicate.exe`, with adjacent PCK, notices and licenses. Choose New game; Enter/A skips; Esc → Controls lists bindings. No installer, signature or nonexistent download URL is claimed.

EXE SHA256: `F9CB815A32A1AE3A73AD8699ED2B068CB76FE01636D7E8538243056FAC05F37B` — unchanged official export template; actual game content is the PCK.

PCK SHA256: `2BD025A7D144F2708F40CC2D69BF05F4BE7835A8A0C977679D96C89B787CD4F2`.

Previous packages remain unchanged in `builds/windows` and `builds/preserved-11aedc2`; old PCK SHA256 `E67661F34D18D570580E75C8D29C0DDBB135C508F64856D7563D0B1C31612E2E`.

Authorized main/origin retained. Asset/source commit `f689e81` was pushed, including LFS. Gameplay integration, evidence and this report form the next coherent commit; the final chat response records its hash and push result. No force-push or history rewriting.

## Remaining work and continuation

Partial checklist items: action animation/contact polish; spatial camera/entry/exit transitions; navigation/cover AI; distinct cinematic acting/shots; broader NPC/faction/district consequences. Exact acceptance states are in [production checklist](production-checklist.md).

**Next action:** manually play the new package end to end and record human duration and control/aim/handling issues. Then replace basic action and vehicle-entry clips with grounded authored performances, provide distinct cast art, and finish unique investigation spaces. Fix the shutdown diagnostics and run sustained performance testing before expanding the district.

Streaming, traffic/police/civilian simulation, remaining districts, later acts/endings and the ten-hour campaign are unimplemented. No background work is promised after this session ends.
