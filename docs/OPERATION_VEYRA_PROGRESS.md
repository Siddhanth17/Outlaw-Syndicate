# Operation Veyra — durable production/resume state

Sprint deadline: **14 December 2026**. Active work began from clean `f49b7e6` on 15 November. This file describes implemented work and the next session, not a promise of execution after this chat ends. Overall sprint: **PARTIAL**.

## Architecture rescue implemented

- Four connected Northline blocks north of Iron Harbor, bounded by x=-70/0/72 and z=58/138/218. **16 detailed building instances from four original GLBs**, not 16 unique buildings. Footprint about 142×160m inside the street center lines. Nine junction positions. Three north-south street extensions and three cross-street runs, of which the southern run reuses the harbor connection: **two new cross streets**, not six entirely new roads. The 12-block/20-intersection target remains unachieved.
- Eight original reusable assets: four frontage buildings, bench, jersey barrier, tree, traffic-signal assembly. Sources in `art/source/urban_*.blend`; reproduction: `tools/blender/blender-4.5.3-windows-x64/blender.exe -b --python art/build_urban_kit.py`. Recessed framed windows, projecting sills/lintels/string courses, modeled open shop vestibules, commercial fascias/signs/canopies, display counters, corner returns, selected balconies, parapets, rain pipes and rooftop mechanical equipment. Shopfronts are **visual/accessibility assets, not working businesses**.
- Meter-based surface UVs, existing licensed concrete albedo/normal maps, runtime facade tint variants, opaque reflective glazing, limited occupied-window emission. Roads reuse the credited asphalt maps/shader; new crossing/center-line paint and connected raised sidewalk blocks. Brick-named material is still a tinted concrete approximation; dedicated brick/stone/wood/metal maps remain needed.
- Original 22 `BoxMesh` skyline instances moved from reachable ground at z≈-219 to background z≈-530. Modeled physical end-of-road barriers at the three harbor termini. These distant boxes are **background-only**, never counted as buildings or accessible blocks. Peripheral terrain edges still need a designed treatment; this is not a seamless six-region world.
- Initial **visual-sector residency** with 155m load/190m unload hysteresis and one sector construction per update. Four cached frontage resources, resident static collision and persistent actors/owned vehicles. This is not threaded asset I/O, full world streaming, occlusion baking or a proven city-scale memory budget. Per-piece visibility ranges were removed after rendered QA revealed isolated floating window surfaces; imported mesh LOD remains enabled.
- Shared advancing 24-hour clock saved with legacy-compatible optional `city_minutes`. Day/night sky, ambient/fog/sun response and streetlight attenuation; Settings → Time: Day/Night. Simplified solar motion and emissive windows remain approximations, not physical sky/weather simulation.
- Selected buildings rotate with matching collision layouts so each block has an outward-facing commercial frontage on all four street edges. Warm entrance lighting supplements streetlights at night. Autonomous braking now drives the actual existing rear brake light. Urban fleeing bounds extend to the new neighborhood rather than incorrectly pulling citizens back toward the old harbor limit.
- Two **force-driven Sable traffic cars** on a bounded perimeter lane circuit, with steering, braking, headlights, wheels and existing damage/collision. Shared NS/EW green/amber/all-red phases at nine junctions, three forward collision-sensing rays per car, obstacle stop/resume. No teleport recovery. This is **PARTIAL traffic**: no general road/lane routing graph, lane changes, safe dynamic spawn/despawn, parking, diverse fleet, police driving, blocked-route recovery or convincing AI driver model yet. Repeated cars and rigid-driver presentation remain prototype quality.
- Four additional named citizens (16 total ordinary population plus Dante), with work/break/home-zone destinations selected from the shared clock. Existing appearance variants and reactions preserved; collision-aware AStar grid extended to the quarter. These are **destination schedules**, not household/interior life simulation. No new general conversation system or NPC relationship expansion.

## Major asset audit

| Asset family | Classification | Reason / required work |
|---|---|---|
| Original 22 skyline shader boxes | Distant-background-only | Requires mesh replacement for any accessible frontage |
| Legacy `warehouse.glb` | Temporary placeholder | Original graybox retained for history; avoid new placements |
| `warehouse_realism_0..2` | Usable with improvements | Existing detailed industrial kit; repetitive, needs richer doors/interiors and finish variation |
| `urban_frontage_0..3` | Usable with improvements / requires detailed materials | Real architectural parts and entrances; four templates, limited rear detail and approximate material identities |
| Urban benches/barriers | Usable with improvements | Modeled slats/tapered profiles; surface wear and placement variety needed |
| Urban trees | Usable with improvements | Original branch/individual-leaf mesh, no leaf texture/wind/seasonal variation |
| Urban signal | Usable with improvements | Modeled casing/lenses/visors and functional phases; road-facing placement/visibility needs wider coverage |
| Containers/cargo/fences | Usable with improvements | Preserve interaction/collision; add wear, labels, structural variation |
| Crane/forklift | Usable with improvements | Recognizable original modeled props; no detailed machinery simulation |
| Streetlamps/drains/manholes | Usable with improvements | Functional lighting/acoustics; remaining repetition/material polish |
| Roads/sidewalks | Requires detailed materials and edge detailing | Textured asphalt/concrete; crossings work, but curbs, slabs, drains, parking and transitions need a unified kit |
| Base ground planes / outer terrain | Temporary placeholder / requires mesh replacement | Street support remains functional, but perimeter voids and flat district edges need terrain/water/coast containment |
| Sable / Harrier | Usable with improvements | Physics/damage preserved; presentation, tires, drivers, fingers/acting need further work |
| Adrian / population | Usable with improvements | Existing credited rigged variants; hair, hands, skin and acting remain visibly prototype quality |

No major environment family is declared universally production-ready. Existing mission triggers, vehicle physics, articulated ragdolls, audio profiles, phone/social/repair and version-1 saves are preserved.

## Asset/tool decisions

Original Blender geometry is used for this increment; no external model was downloaded. Existing Poly Haven concrete/asphalt maps and notices are reused, including the extracted image copies produced by GLB import. No reference image is shipped.

Provider checks: [Poly Haven license](https://polyhaven.com/license) and [ambientCG license](https://docs.ambientcg.com/license/) state CC0 and are suitable candidates for material expansion. [Quaternius' current license](https://quaternius.com/license.html) is QAL v1.0, updated 28 August 2026, with standalone asset redistribution restrictions; do not assume its older FAQ makes every new download CC0. No Quaternius download is included here. Any future import must retain its exact acquisition license and source rather than rely on a generic “free assets” claim.

[Godot 4.6 performance guidance](https://docs.godotengine.org/en/4.6/tutorials/performance/optimizing_3d_performance.html) informed cached resources, distance budgeting and imported mesh LOD. Occlusion and threaded streaming remain work to do. [Navigation documentation](https://docs.godotengine.org/en/4.6/tutorials/navigation/navigation_using_navigationmeshes.html) distinguishes navigation from physical collision; this increment preserves and extends the existing collision-sampled AStar grid instead of claiming a navmesh migration. [Coordinate precision guidance](https://docs.godotengine.org/en/4.6/tutorials/physics/large_world_coordinates.html) does not justify rebuilding this sub-kilometer quarter with double precision. No engine migration occurred.

## Current validation/delivery

All **326 source assertions** passed across ten suites. Includes 20 urban checks: traffic wheel-force movement, red stopping, actual brake-light activation, physical obstacle stop/resume, turning, four-sector unload/reload, collision-aware connection to the harbor, shared-clock schedules, local danger response, input-driven shop entry/back-wall collision, clock restoration and optional story preservation. The old fixed population-count test was replaced with an assertion that all four original industrial actor IDs remain present; no gameplay failure was hidden by changing a threshold.

Verified Windows build: `D:/OutlawSyndicate/builds/operation-veyra-architecture/OutlawSyndicate.exe` plus PCK. Prior `builds/metropolis-foundation` and `builds/articulated-physics` remain untouched. Actual exported routes and performance/evidence results follow below. Isolated APPDATA profiles under `tools/qa-data/operation-*` protect normal player saves.

**Final exported results: COMPLETE for these bounded automated routes** — urban **22**, opening mission **14**, mobility **54**, articulated ragdolls **53**, phone/contact/free-roam **33**; all five exited **0**, with zero failed assertions and no new script errors. Seven texture RID warnings remain at Vulkan shutdown. These passes do not complete the sprint or certify all streets/AI cases. M1 is still completable and rewards once; six articulated-ragdoll cases and concurrent bodies remain valid.

**Render-resolution correction:** Initial CLI `--resolution 1920x1080` captures were actually **1875×1055** because Windows clamped the window. The earlier 193.995-FPS result is **not a 1080p benchmark**. Packaging exposed the odd-sized captures. Urban QA now uses a fixed 1920×1080 viewport, asserts texture dimensions and records them in performance.json; baseline before images were recaptured at the same fixed size. All 120 video frames independently verify as 1920×1080. Other functional regression routes still use the OS-clamped window and are not 1080p performance claims.

**Corrected final executable measurement:** actual **1920×1080** Balanced/Forward+, RTX 3050 Laptop, 10-second forward-drive sample: **1,868 frames**, mean **186.778 FPS**, p95 **7.703ms**, p99 **9.929ms**, maximum **13.782ms**, last-frame draw calls **755**, texture/buffer allocation monitor **1,190,881,088 bytes** (not total VRAM). Packaging requires the measured dimensions and every captured frame to match 1920×1080.

**Performance coverage remains PARTIAL.** Four blocks, 16 building instances, two AI cars, 16 ordinary citizens plus Dante; not all are in view or equally active. No screenshot encoding runs inside the timed 10-second driving loop. This is not a sustained session, dense metropolis/night/thermal benchmark, complete RAM/VRAM profile, or minimum-60-FPS guarantee. Fixed-viewport rendering follows [Godot's documented viewport scaling](https://docs.godotengine.org/en/4.6/tutorials/rendering/multiple_resolutions.html).

Final PCK SHA256: `1c155af56bee815e3a309251736542bd791581116feaca5584c81fb16524bb32`, also stamped in `build-manifest.json`. Preserved previous PCKs verified unchanged: metropolis foundation `8d177b8e4dd5de82ecc36d2e091ffb0eea2a8c4ade066f7cf264ad9e268d1056`; articulated physics `747ce6ee3f567b1e80f8d6b3277a4c76fec15c5b37c92642198a5f31dd5ef9c8`.

Actual exported evidence is packaged under `builds/operation-veyra-architecture/evidence`: day/shopfront/wide/night/driving views, matching-camera before images and a 120-frame, 5fps, approximately 24-second silent sampled traffic clip. Its encoded duration/cadence is approximate gameplay sampling, not a real-time full-frame-rate recording. Screenshots show improved architectural relief, frontage orientation, material color, shadows and entrance light spill. Remaining flat glass, approximate masonry, low-detail vegetation, repeated rear walls, empty courtyards and outer terrain prevent claiming photorealism or finished city art. `tools/package_operation.py` validates log completion, stamps the source commit and build hashes, includes licenses/evidence and CRC-checks the ZIP after a clean commit.

Before evidence uses the preserved f49b7e6 PCK rendered by the matching Godot 4.6 executable with an external capture harness; release templates do not execute the external capture script. Matching camera poses are used for the north frontage and harbor backdrop, with night lighting. The new exported executable supplies after captures. No concept art or reference-image compositing is used as gameplay proof.

Human 20–30-minute acceptance route: **NOT RUN**. The [acceptance checklist](operation-veyra-acceptance.md) marks absent features rather than substituting scene-load checks. Recorded gameplay is sampled automated viewport footage, silent, with an explicit test obstruction; it is not a human playthrough or uninterrupted full-frame-rate recording.

## Remaining sprint systems

| Work | Status |
|---|---|
| Four-block architecture/road/streaming foundation | PARTIAL overall art standard; implemented bounded increment |
| 12 blocks / 20 intersections / six districts | NOT STARTED beyond this four-block/harbor footprint |
| Traffic and pedestrian schedules | PARTIAL, as bounded above |
| Phone / Dante contact / repair / M1 | Existing PARTIAL systems preserved |
| Owned starting safehouse | NOT STARTED |
| Banking/ATM, properties, showroom, new shops/transactions | NOT STARTED |
| Expanded police/arrest/station/justice | NOT STARTED; old search/guard reactions preserved |
| Faction progression | NOT STARTED; existing reputation only |
| Mission 02 / additional acts | NOT STARTED as playable missions |
| Hero/vehicle/combat art polish | PARTIAL baseline, no new character asset claim |
| Full 20–30-minute loop and release candidate | NOT STARTED |

## Next resume priorities and commands

1. Inspect `git status` and this file; retain all local work and versioned builds.
2. Finish street-level material identities, rear/side frontage variety, sidewalk/parking/curb transitions and terrain containment. Add road-facing signal coverage and a real lane graph with conflict reservations before increasing traffic density. Profile sectors while traversing rather than mass-placing more buildings.
3. Original modest safehouse and one real café/convenience purchase loop, then a paid earning activity; connect to existing cash, phone and checkpoints. A sign/frontage alone is not a working business.
4. NPC path/schedule persistence and more identities; police witnessed-incident dispatch with a bounded physical patrol; then ATM/property/showroom loops and Mission 02.
5. `tools/test.ps1`; `tools/build.ps1`; actual EXE `--resolution 1920x1080 -- --verify-urban --record-urban` only with isolated APPDATA. Other routes: `--verify-mission`, `--verify-mobility`, `--verify-ragdoll`, `--verify-metropolis`.

Do not claim execution continues outside an active session. No automation or unattended month-long process has been created.

Asset kit commit: `a31b0cc`. Validated integration commit: `78751f6`. Final package provenance is stamped in `build-manifest.json`; packaging-only follow-ups appear in normal Git history. Video encoding retains the original 1920×1080 viewport dimensions. Push only to the verified `main` branch on the authorized Siddhanth17/Outlaw-Syndicate remote; no history rewriting.
