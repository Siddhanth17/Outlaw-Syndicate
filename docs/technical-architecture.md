# Architecture — production increment

Godot 4.6 stable / typed GDScript / built-in Jolt; Forward+ is now the desktop renderer, verified on RTX 3050 Laptop Vulkan. GL Compatibility graybox export is preserved separately. No Unreal migration.

- main.tscn / main.gd: mission coordinator, save/checkpoint integration, menu commands and skippable presentation. Five stages in data/homecoming.json are retained.
- ValePlayer: collision capsule (hidden), imported human child, AnimationTree state machine, code-driven locomotion, clearance-checked low-step traversal, SpringArm shoulder/aim/drive framing. Imported art is wrapped, not edited at runtime.
- VeyraCar: VehicleBody3D with Jolt-supported wheels; authored body and separate visual wheels; lowered center of mass, speed-dependent force/steering, road/shoulder grip approximation, impact integrity, lights and looping audio.
- IronHarbor: imported modular GLB composition, simplified collision, textured road/sidewalk surfaces, local lights, fog, reflection probe, presets and persistent alert lighting.
- GameHUD: responsive Control containers, bounded objective, compact status/health/ammo, contextual prompt/subtitles and modal main/pause/settings/controls pages. Gameplay HUD is hidden during menus.
- HarborGuard: local CharacterBody3D state machine with raycast LOS, suspicion/investigation/engagement, damage/defeat and persistent consequence IDs. No NavigationServer routing or coordinated cover yet.
- CityMemory: idempotent world-event records and versioned v1 snapshot. Extra optional fields retain vehicle integrity/yaw, health, ammo, faction reputation and driving state. Existing v1 saves remain compatible.
- GameInputs: idempotent keyboard/mouse/gamepad setup shared with driving_course.tscn.

art/build_assets.py -> Blender 4.5.3 -> assets/*.glb -> Godot import -> gameplay-owned scene wrappers. Materials are merged by material in environment exports to reduce draw calls. Art sources are .gdignore-isolated from runtime export. Generated WAV pipeline is separate. Provenance hashes live in assets/asset-manifest.json. No external paid service or runtime generative AI is required.

Saves use atomic replacement and one backup. Position arrays are checked for length/type/finite bounds before restore; settings use ConfigFile. Remaining validation/migration and actual interrupted-write fault testing are still required. Low/Balanced/High presets adjust selected effects; High is not the default tested performance configuration.

Still required before city expansion: extract MissionDirector/SaveService out of main.gd, explicit objective IDs and schema migration, streamed authored district scenes, real navigation, simulation budgets and object pooling. Existing monolithic composition is not a finished open-world architecture.

## Reference refinement modules

HumanDynamics is attached below each nearby supported Skeleton3D and executes after animation, preserving imported bone rest rotations. It uses bounded scale-independent angles rather than native SpringBoneSimulator3D on the existing 0.01-scale rig. Ground traversal remains code-driven without terrain IK. Human Motion Laboratory subclasses the actual main scene; it is not a separate character implementation. RuntimeVerification is an opt-in developer command (-- --verify-realism) that stages/saves inspection views from the exported EXE to user://verification and exits; normal product menu flows do not enable it. The environment uses reusable road/steel/sky/wind shaders, three authored warehouse variants and an instanced distant skyline.
