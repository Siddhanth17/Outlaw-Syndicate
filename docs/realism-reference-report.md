# Reference-directed realism refinement — 14 November 2026

**Status: substantial implemented increment; the combined realism milestone is incomplete and the supplied reference quality has NOT been achieved.** Earlier 79.2% checklist coverage referred to the previous, smaller production increment; it is not a score for this stricter realism directive.

## References and confirmed baseline

All three user images were studied before changes. They are external visual benchmarks, not current game captures, source textures or redistributable assets. They were not copied into the repository or package.

1. Environment reference: articulated structure, layered foreground/midground/mountains, believable glass/concrete/wood scale, warm interiors against cool atmosphere and rich terrain/vegetation. Apply material/architectural care to industrial spaces; The Heights/Ashwood remain future regions. No exact building/landscape was copied.
2. Human reference: facial anatomy, separate eye/lid/lash/hair detail, subtle skin roughness, convincing fabric and soft close-up light. The current low-detail CC0 human cannot reproduce that fidelity; no attempt was made to recreate the reference person.
3. Vehicle reference: continuously curved panels, precise gaps, detailed wheel/brake/lamp construction, layered paint/glass, believable stance and grounded reflections. Sable remains fictional and unbranded; no BMW model, logo or ripped asset was imported.

Baseline: source game launched and original 72 checks passed. Matched inspection captures and performance were saved to tests/artifacts/reference-before. Previous Windows package remains unchanged at builds/iron-harbor-production and an EXE/PCK copy exists in builds/preserved-840a82d.

## Environment implementation

Three modeled warehouse variants add HVAC/pipe-rack differences, electrical cabinets/conduit, CCTV mounts, warning boards and company fascia. Imported steel surfaces now have age-dependent paint/rust/dirt variation; concrete uses world-scaled PBR maps. Added original modeled manholes, drainage grates and parked forklifts near work areas. Distant city silhouettes use one instanced simplified backdrop; they are not new playable regions.

Road maps were upgraded from 1K to 2K using the same verified CC0 sources. The road shader combines physical tiling with patches, stains, shoulder dirt and localized wetness/roughness. Wet areas are not a universal mirror. Added neutral industrial floodlights alongside existing warm lamps, a restrained sky gradient/radiance source and wind-driven hanging fabric. Existing collision layout and mission sites are preserved. Repetition, flat terrain, empty interiors and limited clutter variety remain visible.

## Human asset, hair and garments

Extended the existing 24-joint skeleton to **32 joints** with four two-bone chains. Reweighted actual surface vertices: 6,788 hair-region vertices and 1,194 rear shirt-hem vertices. Added separate skin/hair roughness regions and smooth shading. Source face geometry/texture is still visibly coarse; it has **zero morph targets**, no separate eyeball/lid controls and no facial acting rig.

HumanDynamics extends SkeletonModifier3D and runs after animation playback. Bounded angular springs use actor acceleration, shared wind and hit impulses, with substeps/damping and teleport/load/occupancy resets. The same mechanism is integrated with Adrian, Dante and guards, with nearby-only Dante updates. Short hair motion is deliberately restrained. Hem motion affects the existing overshirt; it is not a new long jacket or full cloth solver.

Godot's SpringBoneSimulator3D was evaluated. Its documentation warns about scaled skeletons; this imported rig has a 0.01 scale. A scale-aware custom angular modifier was used rather than silently applying an unsupported setup. The implementation preserves imported rest orientations. Sources: https://docs.godotengine.org/en/4.6/classes/class_springbonesimulator3d.html and https://docs.godotengine.org/en/4.6/classes/class_skeletonmodifier3d.html .

Tests observe actual post-modifier hair-bone changes, excitation during movement/wind, settling after stops, angle limits and transient resets. This is lightweight skeletal secondary motion with bounded travel; no full strand/cloth self-collision, scalp collider or comprehensive penetration guarantee is claimed.

## Body, driving, dialogue and combat

Locomotion clip rate now follows actual horizontal speed during acceleration/stopping. A post-animation layer adds restrained lean, lateral response and activity-dependent breathing/recovery. Existing low-curb stepping remains; **terrain foot IK and reliable foot planting are not implemented**.

Adrian is now visible inside the car using an authored looped Drive pose, not hidden while occupied. The car has an actual cockpit cavity, corrected front seat position, separate steering-wheel geometry, steering response and brake-light illumination. The pelvis is tested inside seat-height bounds, and the hand reaches the wheel region. Head/torso respond to steering and longitudinal/lateral acceleration; hair/hem use vehicle acceleration with reduced cabin wind.

This is still approximate seating: open fingers do not grip the rim, hands are not precisely locked throughout steering, lower-body clearance needs artist review, and entry/exit are still instantaneous occupancy transitions. No coherent door-opening sequence is claimed. A looping-pose pelvis drift bug and an initial seat/chest intersection were found and corrected during inspection.

Head orientation supports nearby dialogue partners and driver anticipation. There is no blinking, eye tracking independent of the head, jaw/viseme animation, emotional facial performance or voice synchronization. Combat hit direction now produces bounded torso/secondary response; existing damage/defeat logic remains. No new full-body stagger/ragdoll system.

## Laboratory and actual integration

Main menu → Human Motion Laboratory opens the actual Iron Harbor scene with the real character/vehicle systems. Keys 1/2/3 select walk/run/sprint input, 4 stops, 5 jumps, 6 seats/exits, 7 changes shared wind, F2 inspects the face. Lab controls are developer conveniences, not a separate unintegrated technology demo. All implemented effects also run during normal exploration/mission/combat/driving.

## Actual before/after evidence

Own captures only; supplied reference images are excluded. Matched character/car/road/wide inspection cameras are in docs/evidence/realism/before-*.jpg and after-*.jpg. Additional **Windows-export captures** are windows-character.jpg, windows-vehicle.jpg, windows-harbor.jpg, windows-driver.jpg, windows-running.jpg and windows-dialogue.jpg. Secondary-motion GIF is assembled from 20 unretouched gameplay frames, reduced in size for viewing.

![Actual Windows harbor capture](evidence/realism/windows-harbor.jpg)

![Actual Windows seated driver](evidence/realism/windows-driver.jpg)

| Comparison dimension | Change and remaining gap |
|---|---|
| Geometry | More warehouse service detail, curved sedan profiles and usable cabin; still far below the architectural/vehicle references |
| Materials | 2K road/concrete, varied wetness/weathering, separate roughness/clearcoat/glass; coarse character texture and simplistic trim persist |
| Lighting | Mixed practical/flood lighting, sky radiance and depth; no calibrated/baked high-end lighting solution |
| Texture fidelity | Better street-scale maps; face/eyes/hair remain unsuitable for reference-level close-ups |
| Coherence | Logical industrial details and consistent world wind; repeated cast/building motifs remain |
| Physical animation | Real weighted hair/hem deformation and visible seating; no full IK, precise grips, cloth collision or facial performance |
| Overall realism | Noticeable functional refinement, not photorealism or reference parity |

## Validation and performance

PASS: 92 automated assertions (72 existing + 20 new realism checks). Existing physical-input opening-mission route still completes. PASS: Motion Laboratory headless launch. PASS: Windows export launches and exits 0; opt-in developer verification captured all six views from the **exported EXE**, each PNG save returned OK. Inspection routes reposition cameras/actors and are not a human playthrough. Physical gamepad and extended manual QA: NOT RUN.

Fresh matched 1080p Balanced source-game samples, 120-frame warmup and 600 rendered intervals:

| | Before | After |
|---|---:|---:|
| Average FPS | 155.84 | 204.61 |
| Mean frame time | 6.417 ms | 4.887 ms |
| p95 frame time | 7.288 ms | 5.660 ms |
| 1% low FPS | 125.46 | 157.68 |
| Engine video-memory estimate | 761.45 MiB | 807.80 MiB |

1% low is the reciprocal average of the slowest 1% of sampled intervals. These are short wall-clock inspection-view measurements on i5-13450HX / approximately 16 GB RAM / RTX 3050 Laptop 6 GB, not sustained gameplay or isolated GPU timing. Raw reports are alongside evidence. The final pass explicitly enables S3TC/BPTC VRAM compression and mipmaps on all fourteen imported asset textures; character albedo uses higher-quality compression. An intermediate unoptimized 2K pass measured about 122 FPS; that is superseded by the final row. Imported automatic LOD and limited secondary chains remain enabled.

Known diagnostics: restricted editor-settings safe-save warning during import/export; seven Texture RID warnings on Vulkan shutdown remain. No completed quality gate or long-run leak-free claim. The full realism gate fails where facial animation, foot IK, garment collision and door transitions are missing.

| Acceptance area | Result |
|---|---|
| Tested hair/hem excitation, settling, wind and reset behavior | PASS for the implemented short chains |
| Visible seated driver and responsive wheel/brake light | PASS for basic integration; precise grips remain incomplete |
| Full terrain foot IK and authored door entry/exit | FAIL — not implemented |
| Collision-complete hair/garment simulation | FAIL — bounded skeletal motion only |
| Facial blinking, eye/jaw controls and acting | BLOCKED by current asset topology/rig; replacement or major authoring required |
| Supplied photographic/reference quality parity | FAIL — visibly not achieved |
| Physical gamepad, extended human playtest, rain and sustained profiling | NOT RUN |

## Assets, build and continuation

Original additions: art/refine_realism.py, art/build_assets.py, shaders/* and scripts/human_dynamics.gd. Existing CC0 human/animation provenance is unchanged; same Poly Haven map sources were upgraded to 2K. Metadata, license text, file hashes, editable Blender sources and changes are tracked in assets/asset-manifest.json and docs/asset-licenses.md. No copyrighted reference image is redistributed.

New Windows package: **D:/OutlawSyndicate/builds/realism-refinement/OutlawSyndicate.exe**, with adjacent PCK/notices/licenses. Previous package is intact. Source and artifacts are preserved; final chat records the commit/push result.

Next priorities: obtain/author a production-quality original hero rig with separate eyes/lids/facial controls and better hand topology; implement and validate terrain foot IK; authored gripping, door entry/exit and lower-body seating; collision-aware garment/hair limits; distinct cast and dialogue acting; unique investigation interiors and improved vehicle panel/lamp detail. Rain/wet-character response, drivable industrial vehicles, broad NPC simulation and future districts remain unimplemented. No asynchronous work is promised.
