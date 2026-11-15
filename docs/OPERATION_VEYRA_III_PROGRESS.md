# Operation Veyra III — recovery and acceptance record

Baseline `af6aa75`, main, origin `https://github.com/Siddhanth17/Outlaw-Syndicate.git`. Previous releases preserved. Overall directive **PARTIAL**. No work continues after the active session ends.

## Diagnosis

The published `living-world-foundation-final` executable was opened through its real menu and New Game. Normal camera observations at 18:00 and 18:09 showed some harbor pedestrians walking; this is not a universal update-loop freeze. The foreground Sable is the player's parked car, not an AI vehicle. AI traffic was restricted to two cars north of the spawn, while the experimental eight additional cars remained disabled. Residents begin the 18:00 home schedule and mostly repeat a three-meter segment, making the apparent activity sparse.

The 30-second motion trace at Northline exposed distinct physical/simulation problems:

- Crossing curbs have a vertical step from road to raised plaza. CharacterBody3D does not climb that automatically. Residents stalled near z=144.71.
- Multiple residents share a sidewalk centerline and nearby destinations, causing head-on queues/crowding.
- The old temporary-obstacle ray simply set direction to zero. Recomputed AStar routes excluded only static geometry, so a parked vehicle/prop could block an actor indefinitely.
- Periodic path reset could send a resident back toward the rounded grid start node. Empty paths fell back to a straight line toward the destination, regardless of walls.
- Offscreen travel did not advance route indices after arrival, and reactivation could retain an obsolete physical path.
- Walk animation depended on intended direction, rather than actual displacement, disguising blocked movement.
- Urban shop upper floors had modeled geometry but lacked overhead collision, preventing a physical enclosure query from detecting the interior.

The project uses supported Godot AStarGrid2D pathfinding connected to CharacterBody3D movement. It has no baked NavigationRegion3D/NavMesh or NavigationAgent3D; no missing agent is claimed to be the root cause. Replacing this with a navmesh is not necessary to fix these measured faults and would require new bake/streaming validation.

## Implemented foundation — validation in progress

Collision-swept 24cm curb stepping; local sidewalk passing; temporary vehicle/prop-aware replanning; nearest-cell distance selection; path continuity; real-progress stuck timer; explicit unreachable/blocked/intentional-idle status; actual-velocity animation. Abstract residents advance their route indices, and activation/save restoration clears stale path state. No visible-agent teleport recovery was added.

`--city-debug` enables a separate developer overlay with resident ID/name/state/destination/path status/actual velocity/stuck seconds/schedule and active budget. `--audit-motion` records 31 per-second identity samples and normal gameplay-camera captures. Neither appears in default release HUD.

The new source acceptance route verified 23 nearby residents traveling >5m, Soren reaching work, a resident crossing the raised curb, and checkpoint navigation recovery. A physical parked-car detour test passed. Existing eleven source regression suites passed. The additional older mouse-camera test produced ten failures in headless mode, where Input.mouse_mode is visible; it must be verified in the exported Windows window rather than reported as a pass. Hero and ten-car graph routes also passed. Exact final counts and exported results are recorded below when complete.

## Audio — PARTIAL

Seventeen new original deterministic synthesized PCM assets, reproducible with `art/build_veyra3_audio.py`, hashes/license/peaks in `assets/licenses/veyra3-audio-provenance.json`. No third-party recordings, voice cloning, or regeneration of existing resident/story voices. These are designed synthetic game sounds; no claim of recorded-engine or photoreal acoustic fidelity.

Separate car/bike idle/mid/high/load/coast layers, smooth RPM/pitch/load gains and gear-change one-shots. Engines stop for parked/unoccupied vehicles; car tire rolling remains spatial. Seven real category buses plus Master limiter and independent persisted mix controls. Dialogue/phone, footsteps, vehicle, environment and UI sources are assigned. Four varied spatial fictional sidearm reports; one bounded quieter reflection when a physical overhead surface exists. Existing impact materials/visuals remain. Multiple vehicle-class profiles, richer tire/skid/damage transients, road-surface response, occlusion, five acoustic spaces and refined weapon-class variety are not complete. Human listening review remains required.

## Home and expansion — NOT YET INTEGRATED

`art/build_vale_home.py` authors separate shell, furniture and hinged-door GLBs and editable Blender sources. Furnishings include curved upholstery, cloth-grid quilt, joinery, kitchen, bathroom fixtures, wardrobe, storage and original personal documents. This is new original prototype art, not final visual-quality acceptance. No reference screenshot is redistributed. West/east physical connections, home interactions and New Game integration are the next stage.

## Remaining roadmap

Reliable default traffic integration and incident recovery, representative sustained gameplay profiling, home/connected west/east districts, additional businesses, witnessed crime/dispatch, ownership/factions and playable Mission 02 remain incomplete. Human 20–30 minute route NOT RUN. Keep all original IDs, optional story, prior builds, save compatibility and ragdolls.

## First validated Veyra III increment

Published foundation source regression: original eleven suites357 checks pass; Hero16 checks pass (count from PASS log), new movement/audio24, ten-car opt-in graph10. Mouse-camera headless39/10 environmental failures are retained in the log and not hidden; actual exported Windows camera/physics route **50 passed, zero failed**. Exported movement/audio route **24 passed, zero failed**. Actual game audio WAV is 12.95s, peak0.08768FS, RMS0.00980FS: non-silent, no clipping; tonal/loudness audition remains pending. Build `builds/veyra3-motion-audio/OutlawSyndicate.exe` is separate from all earlier releases. Seven existing texture RID shutdown warnings remain. Normal default fleet remains two cars pending integration; traffic/network code remains uncommitted and excluded from this foundation commit.
