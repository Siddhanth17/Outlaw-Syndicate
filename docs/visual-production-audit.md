# Visual production audit — 14 November 2026

Recommendation: retain Godot 4.6/Jolt and establish a real asset pipeline. Evaluate Forward+ in a separate rendering experiment after engine approval. No engine or renderer migration was performed in this audit. Current delivery is a technical graybox, not realistic, cinematic or finished gameplay art.

## Evidence and preservation

Inspected project.godot, main.tscn, all gameplay scripts, asset inventory and installed-tool locations. Launched the actual source game with Godot 4.6 and captured player, car, district and pause views using tests/visual_audit.gd. Images are under tests/artifacts/audit-*.png, ignored by Git. All four were visually inspected. The pause image directly reproduces HUD text showing through and overlapping the menu.

Existing builds/windows package was not overwritten. Copied EXE, PCK, notices and readme to builds/preserved-11aedc2. SHA256 matches original for both binaries:

- EXE: F9CB815A32A1AE3A73AD8699ED2B068CB76FE01636D7E8538243056FAC05F37B
- PCK: E67661F34D18D570580E75C8D29C0DDBB135C508F64856D7563D0B1C31612E2E

## 1. Temporary visible geometry

Every visible 3D mesh is created from a Godot primitive at runtime:

| Element | Current implementation | Production replacement |
|---|---|---|
| Adrian | Blue CapsuleMesh; separate capsule collision | Skinned human, clothing, hair, hands, UVs and PBR materials |
| Civilians | Eight narrow BoxMeshes | Rigged pedestrians with variation and animation |
| Sedan | Red BoxMesh chassis, untextured box cabin, four CylinderMesh tires | Authored body panels, cabin, windows, interior, lights, rubber tires and rims |
| Warehouses | Sixteen closed boxes with 48 colored facade strips | Modular industrial buildings with roof structure, loading doors, gutters, trim and credible entrances |
| Ground/road | Flat boxes and 20 yellow stripe boxes | UV-mapped road system with kerbs, sidewalk elevation, junctions, drainage and wear |
| Containers | Five smooth boxes | Corrugated containers with corner castings, door locking bars, markings and material variation |
| Training targets | Three boxes | Clearly identified training props or eventual combat encounter assets |
| Objective | Floating amber box | Readable mission marker UI or authored prop indicator |
| Garage sign | Label3D text | Legible sign mesh/material integrated into a detailed garage |

Hidden primitive collision shapes can remain where appropriate; replacing visible art does not require expensive mesh collision everywhere. No imported .glb/.gltf/.fbx/.blend assets exist in the project. No cranes, dock structures, fences, bollards, pallets, streetlamps, cargo equipment, harbor water, buildings with interiors, weapons or finished garage assets exist.

## 2. Animation

No Skeleton3D, skinning, AnimationPlayer, AnimationTree, animation clips, retarget setup or IK. The capsule rotates toward movement. Civilians translate without walking. Vehicle wheels are physics nodes, not a detailed visual/rig pipeline. Entry/exit is instantaneous hide/show and repositioning; interaction is a text/state event. Crouch changes speed only.

Required next assets: idle, walk, run and interaction on one validated human rig; velocity-driven AnimationTree blending; foot contact/no sliding; facing and turn behavior. Separate model-facing transform from physics/camera. Define entry/exit poses and camera behavior before expanding cinematic animation coverage.

## 3. Materials, textures and lighting

No albedo textures, normal maps, roughness maps, AO, HDRI, baked lighting or custom shaders are used. StandardMaterial3D assigns flat albedo colors; environment geometry roughness is 0.65, car body metallic is 0.65, while cabin and tires use default material appearance. Colored facade strips are not emissive lights/windows.

Environment: solid blue-gray background, ambient color (0.45, 0.55, 0.7) with energy 0.7. One warm DirectionalLight3D at (-28, -35, 0) degrees has shadows enabled. Shadows exist, but there are no authored night luminaires, reflection probes, fog, exposure direction or wet-surface detail. Flat normals, missing texture-scale variation, uniform ambient fill and simple silhouettes explain the appearance.

Renderer is explicitly GL Compatibility. For the proposed desktop art milestone, evaluate Forward+ for lighting and atmospheric features while preserving a performance fallback. Godot 4.6 documents Forward+ as its advanced desktop renderer; volumetric fog requires Forward+. Do not assume an effect works in Compatibility just because a newer documentation version lists it. Sources: https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html and https://docs.godotengine.org/en/4.6/classes/class_environment.html .

## 4. HUD layout root cause

main.gd creates one large multiline HUD Label at (28,22); controls, objective, money and search all share it. No width cap, wrap policy, safe-area root or per-region layout. Subtitles are fixed at (160,540), size (960,140); crosshair at (634,348); menu at (430,120), minimum (420,400). Only the pause buttons use a VBoxContainer. canvas_items stretching scales the canvas, but does not provide responsive anchoring or resolve content collisions.

Pause leaves HUD/subtitles/crosshair visible behind a translucent PanelContainer. Captured pause view shows instructions crossing menu buttons. At default gameplay size the text lines do not visibly collide with one another, but dominate the frame and obscure the scene; other sizes/localized strings remain unverified.

Required redesign: anchored full-screen Control, MarginContainers and bounded objective panel, separate compact status region, bottom subtitle panel with contrast backing, centered crosshair, modal pause backdrop that hides gameplay HUD. Put full controls in a pause-menu Controls page, retaining only contextual interaction prompts in play. Test 1280x720, 1920x1080, ultrawide, window resizing, UI scaling and long objectives.

## 5. Camera audit

Functional baseline, not production-ready. Hierarchy: CharacterBody3D > pivot at local y=1.5 > SpringArm3D length 5.5 > active Camera3D. Yaw/pitch are camera-relative, pitch clamps -0.9 to +0.4 radians; player collider is excluded from spring arm and car is excluded while occupied. Runtime defaults: FOV 75 degrees, near 0.05 m, far 4000 m. Player is centered and takes space under the aiming reticle in captures.

No shoulder offset, authored aim framing, aim zoom, separate driving camera, transition smoothing, look deadzone, explicit spring-arm shape/margin tuning or camera collision regression suite. Driving follows world position above the car, without a dedicated speed/heading response. Far clipping is excessive for this small scene; tune after district visibility planning. Initial -0.18 pitch should be rechecked against an actual human model, not copied into final framing by assumption.

Preserve orbit and collision-avoidance foundations, then frame human head/feet and weapon aim, test wall/corner occlusion, entry/exit, high-speed travel, slopes and controller drift. No claim of correct finished camera configuration.

## 6. Gameplay to preserve

Keep camera-relative CharacterBody3D movement and collision, Jolt setup, vehicle occupancy and wheel handling baseline, mission JSON and five objective transitions, event deduplication, one-time reward, versioned save/backup behavior, input mappings and smoke tests. Preserve APIs while replacing visible child scenes. Do not let artist imports overwrite gameplay scripts or physics node transforms. Target shooting and pedestrian motion remain functional test scaffolding, not advanced combat/AI. Handling needs further testing even if art is replaced successfully.

## 7. Local tools, hardware and legitimate assets

Verified CPU: Intel i5-13450HX, 10 cores / 16 logical processors. Installed physical memory 16,944,848,896 bytes (about 16 GB marketed capacity). GPU: NVIDIA RTX 3050 Laptop, 6144 MiB VRAM, driver 621.01. Free space at audit: C about 13.6 GiB; D about 94.8 GiB. Free space changes over time.

Available: official Godot 4.6 stable editor/console and matching export templates under ignored tools; Git/LFS, Python, NVIDIA diagnostics. Epic Launcher is installed, but LauncherInstalled.dat contains an empty InstallationList. No Unreal Editor or Blender found on PATH or checked standard install roots; no unregistered installation ruled out. Checked Program Files, local Programs, relevant Steam locations, common Blender/Unreal folders and top-level Downloads/Documents. This was a bounded inventory, not an exhaustive disk crawl.

No usable production 3D asset or PBR texture library found in the project or checked download roots. The only project image found is a generated graybox screenshot. Existing commercial game installations do not establish reusable asset rights and are not an art source. No purchased asset entitlement or external asset license was verified. No production audio library found in the project.

## 8. Engine comparison

| Factor | A: retain Godot 4.6 | B: separate UE5 prototype |
|---|---|---|
| Installed readiness | Editor, Jolt, export and running project verified | Launcher present, engine not registered/verified; installation and storage planning needed |
| Hardware | Keep compact authored scene; test Forward+ on 6 GB GPU | 16 GB RAM/6 GB VRAM below Epic recommended 32 GB/8 GB; does not imply UE cannot run |
| Visual tools | PBR/import/animation, authored lights, baked/probe workflow and Forward+ effects; production art still required | Strong cinematic/animation/lighting toolset; high-end features still need hardware and scene budgets |
| Gameplay reuse | Preserve GDScript scenes, behavior and tests | Port controller, mission runtime, save adapter, UI, tests and vehicle tuning; Jolt setup does not carry over to Chaos |
| Assets | Neutral-format licensed assets reusable | UE-only content may not be portable; verify individual licenses and formats |
| Cost/complexity | Add Blender and asset workflow, revise scene composition/UI | Add installation, import/retarget/material conversion and second project/build pipeline alongside Godot |
| Main risk | Mistaking lighting/effects for missing modeling/animation work | Impressive standalone scene that does not preserve playable systems or fit target hardware |

Epic hardware source: https://dev.epicgames.com/documentation/en-us/unreal-engine/hardware-and-software-specifications-for-unreal-engine . Engine licensing differs: Godot uses MIT (https://godotengine.org/license/); Unreal has its own commercial terms (https://www.unrealengine.com/license). Asset rights must be reviewed separately from engine rights.

Recommendation is a production judgment, not an engine benchmark: choose A on this machine. The immediate bottleneck is absent art/animation and scene/UI composition, not demonstrated Godot rendering incapacity. UE would offer valuable production tools but would add a rebuild before fixing that bottleneck. No UE or Forward+ performance measurements were made. Reconsider a separate UE scene only if a representative, properly authored Godot scene fails the agreed visual/performance gate.

If B is approved later: create a separate project/directory and branch, leave Godot/build intact, use the same legally portable hero/car/warehouse assets, compare matched camera and resolution, measure editor and packaged performance, and explicitly document what gameplay was ported. Do not represent a UE still render as a playable migration. Android would require a new renderer/content budget in either engine.

## Proposed asset pipeline after engine approval

1. Obtain a verified Blender installation. Keep editable source meshes, rig and authored animations separate from exported game assets. Use original or individually licensed assets; record author, URL, license text, purchase/entitlement where relevant, modifications, redistribution rules and file hashes before importing or committing. Do not commit restricted raw assets to a public repository.
2. Human: acquire/author a credible clothed adult male, one compatible rig and idle/walk/run/interact clips. Confirm weights, hands/face, silhouette and close-camera quality. No capsule silhouette substitute. Unknown character/animation sourcing is the main unresolved asset dependency.
3. Vehicle: fictional unbranded sedan with separate wheel pivots, rims/tires, window glass, visible cabin, body, lights and underside sufficient for gameplay. Retain physics root and attach art below it; match axle/wheel radius and orientation to authored mesh.
4. Environment: modeled warehouse kit and detailed container/port props, roads with UV scale and proper kerbs/sidewalks. Use reusable modules and trim sheets without presenting raw box assemblies as final art. Bake normal/AO details and supply metal/rough PBR materials.
5. Export GLB/glTF 2.0 with meter scale, applied transforms, consistent pivots, named skeleton/clips and documented facing orientation. Keep imported scenes immutable; wrap them in gameplay-owned scenes. Godot recommends glTF: https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html .
6. Texture/environment candidate: Poly Haven assets are CC0 per https://polyhaven.com/license . They are not currently downloaded or integrated. Select actual road/concrete/metal/environment assets and record provenance; this source does not resolve the missing protagonist/car/animation requirements.
7. Initial budgets, subject to measurement: 2K hero textures, 1K/2K tileable world textures, compressed mipmaps, shared material sets, mesh LODs, simple collision and limited shadow-casting lights. These are starting constraints, not proven final budgets.
8. Night direction: local warm industrial fixtures, cool ambient separation, readable face/car silhouettes, restrained fog and wetness. Test Forward+; prefer baked lighting/probes for static warehouse surfaces, limited local shadows, bounded reflection probes and roughness variation. Use SSR/volumetrics selectively after profiling rather than full-scene mirror roads or expensive unlimited lights.

## Baseline validation and next milestone gate

PASS: current game launched; four actual screenshots inspected; 19 gameplay regression assertions passed; preserved package hashes match. Animation inspection: FAIL against requested milestone because no human skeleton or clips exist. Asset completion: FAIL. HUD: FAIL in pause capture. No visual milestone completion claim.

Measured baseline only: 1280x720 Compatibility, stationary graybox district camera, 600 process-frame intervals. Mean 1.037 ms, p95 1.923 ms, reciprocal average 964.25 frames/s, last-frame reported draw calls 302. This short scheduling-based measurement is not GPU frame timing, a traversal benchmark, target-art performance, or a sustained frame-rate promise. Do not infer production capacity from these empty-scene figures. Raw report: tests/artifacts/audit-baseline.json. It did not test animation or vehicle handling while driving.

Before next visual milestone is accepted: launch an exported playable build, capture human/car/district and pause UI, verify all four requested character animations in motion, test steering/braking and visual wheel alignment, test camera collision and driving transitions, inspect objectives/subtitles/control page at multiple resolutions, rerun regressions, and record repeatable driving/on-foot CPU/GPU frame timings and memory after warmup. Proposed target: 1080p/60 fps (16.67 ms), fallback settings if needed; unverified until representative assets and lighting are present. Record missing assets and deviations explicitly. Preserve this graybox build and export the new milestone to a different folder.

Decision pending: approve A (recommended) or B before implementation of an engine-specific visual production milestone. This audit did not acquire assets, install tools, modify gameplay or change the renderer.
