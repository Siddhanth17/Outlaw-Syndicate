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

## Integrated home / connected-city increment — current recovery state

The working project now contains eight connected blocks: original four plus two west and two east. Added roads at x=-140 and x=142 connect through the existing three cross streets; west/east outer ends and the north edge have modeled roadworks barriers before the physical world boundary. Central remains future content. Navigation is ground-sampled over the expanded bounds. Original nine road IDs remain stable; new six IDs extend to fifteen junctions and44 directed edges. No engine migration.

New Game now begins at08:00 inside the furnished Vale residence, with morning commuters rather than most residents starting in their evening idle. All36 IDs are retained; seven existing residents use west-side sidewalk schedules and eight east-side schedules. Activation radius160m, ordinary budget28; danger/injury still pinned. New Game resets resident origins and transient route diagnostics. Lena's work schedule anchors her at the cafe counter; break/home destinations remain distinct.

Home implementation: modeled bedroom/living/kitchen/bathroom, hinged collision door, real rest(+8h/health), checkpoint desk, actual jacket material finishes that retain the injury shader, bounded carried-item storage, fictional personal documents/keys/charger/books, owned-home information and live phone map. Optional version1 residence payload validates before live restore and handles legacy saves. Blocked home save positions fall back to the safe bedroom point. Home art remains PARTIAL: original prototype meshes and procedural PBR maps, no photorealism/final character-quality claim, no family-photo assets or final dressing pass.

The full home source route passed15 home checks, physically walked out and to the garage, then completed the opening mission. One first exported continuation ended the mission but failed the guard-defeat assertion; this is recorded as a failed run, not a pass. The combat fixture now checks physical cover, repositions using actual movement, waits for the real process-updated cooldown, logs health changes and still requires real hitscan defeats. A later exported candidate logged70->35->0 on both guards. Final repeated Windows gates are running; do not infer success from the tail's mission-complete message alone.

Traffic now has one graph controller for both retained cars and added cars. Balanced candidate is six actual VehicleBody3D cars; ten-car stress remains a testing mode. Safe two-physics-frame spawning, shared reservations, signals, obstacle sensors and route transitions are retained. Added optional version1 traffic checkpoint state restores transforms, velocities, routes, phase, health and damage; malformed or conflicting ownership is rejected. Earlier apparent movement-test failure was partly an invalid net-displacement metric: one car completed four junction movements and returned near its start. The corrected metric samples cumulative actual physical travel; net displacement remains logged. No transform-playback recovery was added. General incident rerouting/recovery and parked-car management remain PARTIAL.

The ten-car source stress route passed12 checks, including a real blocked-lane stop/resume. One exported candidate passed movement/integrity/on-road gates but failed its three-second stopping assertion. The final fixture uses a bounded eight-second stop with an additional requirement to stop at least3m before the obstacle. Source diagnostic stopped atz102.855 for a barrier at110, speed0.452; actual repeat pending. Final native street-camera captures replace the old overhead-only framing.

Audio now has18 original procedural WAVs, including measured-motion skid and road rolling, actual surface-area metadata sampling, stronger bounded engine/weapon gains, distinct car/bike five-layer RPM/load/coast/gear response, spatial weapon variations and a physical-overhead reflection. No existing story/resident voice regeneration. Original home wood/leather/linen/quilt maps are generated by art/build_home_surfaces.py; provenance in vale-home-provenance.json. Human listening review, richer recordings/vehicle classes, acoustic-space variety, occlusion and broader weapon/impact variants remain PARTIAL.

Published foundation commits:7b0c6a0 andbc93815 pushed normally. The latter corrects a UTF-8 HUD-text issue caught in actual capture. A broad stage/push was rejected by automatic review because it would have included unfinished traffic; the safer explicit foundation stage omitted all traffic/network/home work, and the foundation was validated from an immutable snapshot. Do not rerun tools/stage_veyra3_foundation.py against the expanded project; it was a one-time staging helper.

Final current export: builds/operation-veyra-iii/OutlawSyndicate.exe. Source hashes captured before export in its source-hashes.json; verify using tools/veyra3_source_manifest.py before committing or packaging. Final source regression logs tools/veyra3-final-*.log: all16 selected suites completed successfully; source gates preceded the final small cover/cooldown fixture, anchored-counter and boundary fixes, which require the repeated Windows gates. The older headless-only mouse-capture failures remain historical/environmental; actual Windows physics/camera route previously passed50 checks.

Active final Windows batch: home, veyra3, network, physics, ragdoll, mobility, metropolis, urban, living-world. Logs tools/veyra3-accepted-<route>.log and -errors.log; exec session82458. All source/headless tasks must be finished before GPU benchmarking. Next: finish actual gates; inspect home/worker/traffic captures; record actual gameplay clips; run expansion route day and night without recording or parallel CPU work for sustained native1080 metrics; verify hashes and licenses; explicitly stage the now-validated integrated increment; normal commit/push; package a new ZIP and detailed status report. No force push, reset, cleanup or prior-build overwrite.


## Final validation recovery — 2026-11-20

The following supersedes historical pending-state notes above. Prior builds and failed-run logs are preserved. Current release candidate: `builds/operation-veyra-iii-release/OutlawSyndicate.exe` with adjacent PCK. It differs from the validated `operation-veyra-iii-final` gameplay only in the expansion QA probe: screenshot readback is now opt-in (`--capture-expansion`), disabled for performance measurements.

Verified completed source navigation regressions: Veyra III 27, living world 32, home 15 plus 2 continuity and 14 opening-mission checks, urban 20, expansion 4; all passed. Actual final Windows checks: home 31, Veyra III 27, living world 32, urban 22. Additional exported core regression evidence: physics/camera 50, ragdoll 53, mobility 54, metropolis 33, network 13; zero failed. Earlier headless mouse-capture failures remain recorded separately and are not counted as passes.

Lena now starts at home and physically crosses the cafe threshold onto the raised service floor. The acceptance check requires active simulation, indoor counter coordinates, floor contact and cafe availability, rather than a nearby outdoor waypoint. Ground rays offset from exact Jolt floor-box edges fix a measured doorway classification error; full-cell occupancy and swept final legs prevent wall shortcuts. Six default physical AI cars and ten-car stress mode use the connected graph. General incident recovery remains incomplete.

The earlier sustained day/night profiles included four synchronous screenshots: 192.2/179.8 average FPS, 57.3/50.3 FPS 1% lows and 579.6/718.0 ms maximum frames. These are preserved as capture-contaminated measurements, not evidence of stable 60 FPS. Clean measurements use no recording or image readback. Day: 246.78 s, 764.15 m, eleven junctions, six AI cars, 1920x1080, 175.77 average FPS, 64.10 FPS 1% low; frame p95 9.610 ms, p99 13.277 ms, max 31.561 ms. NPC mean 774.90 us/physics step; traffic mean 283.79 us/step. Texture/buffer allocation peak 1,326,343,888 bytes is not total GPU memory. Release static allocation monitor reports zero/unavailable. Audio DSP CPU is NOT MEASURED. Night: 246.76 s, 764.15 m, eleven junctions, six AI cars, 180.63 average FPS, 70.47 FPS 1% low; frame p95 9.078 ms, p99 11.991 ms, max 27.364 ms. NPC mean 759.61 us/step; traffic mean 277.46 us/step. Both clean exported routes passed all five checks. These samples do not imply every frame meets 16.67 ms or a human campaign playtest.

Asset audit: SHA256 verified all 18 original synthesized WAVs and 8 original residence texture maps against the CC0 manifests. Existing licensed assets and voices remain unchanged except documented new synthesized sidearm variants; no private reference photos are shipped. Actual captured audio is non-silent and unclipped, but subjective listening quality is NOT RUN. Human extended playtest is NOT RUN. Original modeled residence/sign and gameplay screenshots were inspected; visual quality remains prototype, not photorealistic. Seven existing texture RID shutdown warnings remain.

Completion remains PARTIAL: ownership/economy, police expansion, factions, Mission 02 and the five-act campaign are unfinished. Final motion evidence, clean night result, source review/publication and packaging are tracked below as completed, rather than assumed from an interrupted process.

Continuous evidence: exported MovieWriter captures at 30 FPS / 1280x720 with engine audio, explicitly offline simulation, separate from 1080p benchmarks. `evidence/motion/pedestrians.mp4` covers 30 seconds and `cafe.mp4` 12 seconds. Inspected frames show displaced pedestrians and Lena crossing into the cafe. Her trace goes from (-10,.2,76) to (-13.7245,.34094,79.8974), intentional idle inside. Movies and per-second identity traces are shipped locally, not temporary source assets.

Traffic movie completed with all 13 network checks passing, including physical obstruction stop/resume. Its normal player camera is partly pitched down early, so the movie provides limited traffic framing rather than a comprehensive vehicle visual review. MovieWriter exit additionally reports ObjectDB/resource-in-use cleanup diagnostics; non-recorded benchmark exits only report the existing seven texture RIDs. These shutdown issues remain open. Release source hash verification passed for all 766 files after all captures. No secret-pattern matches were found in reviewed code.


## Police witness foundation — next milestone begun, 2026-11-20

The core was committed and pushed as `96e07a9e44f3dbb39e2870a01a0094279f8d9b57`. Its Windows ZIP is `builds/OutlawSyndicate-Operation-Veyra-III-Windows-x64.zip` (313,473,780 bytes, CRC checked). EXE/PCK SHA256, source commit, tests and clean profiles are in `builds/operation-veyra-iii-release/build-manifest.json`. This frozen core package remains separate from subsequent police changes.

Implemented `CityLaw`: active healthy residents within28m must have an unobstructed static/prop/vehicle ray to observe a player-attributed incident. Calls take two simulation seconds and pause with the game. A sole incapacitated witness cannot finish calling. Confirmed reports and pending call timers survive the actual checkpoint path. History is bounded64 with monotonic IDs, New Game clears it, malformed/unknown witness state is rejected before live restoration, and legacy checkpoints without the optional component remain accepted. Phone > Crime reports displays confirmed entries. Current production attribution is player gunfire; existing defeat/vehicle events carry victim/source IDs and are deliberately not guessed to be player crimes.

Source law route:18 checks passed. Exported law route:19 checks passed, including actual opened phone UI; `tools/qa-data/law-native-law/Godot/app_userdata/OUTLAW SYNDICATE/law-verification/reported-case.png` visually inspected at1080p. First law fixture16/1 is preserved: loading reactivated other witnesses, so the sole-caller scenario was corrected to re-isolate the crowd and explicitly assert one observed witness. No gameplay threshold was weakened.

This is a witness/crime-history foundation, not completed police AI. Existing combat/search remains independent. Reports do not yet dispatch officers, set new wanted levels, impose fines, clear cases, create a station or spawn pursuit vehicles. No new art/audio assets were added. The police candidate is `builds/veyra3-law-witness-candidate/OutlawSyndicate.exe` plus matching PCK, with772 verified gameplay source hashes. Core day/night numbers above belong to commit96e07a9, not a new police-candidate benchmark.

Exact continuation: connect confirmed reports to a bounded dispatch queue using existing officer identities and physically navigable last-observed locations; distinguish hearing gunfire from identifying its shooter; add investigation expiry/abandonment, witnessed reacquisition and persistent case resolution. Then validate wanted/pursuit/station consequences before economy/ownership, richer schedules, factions and Mission02. Do not rerun asset generators or replace the published core. Preserve `tools/stage_veyra3_foundation.py` as an obsolete untracked helper; do not execute it against the integrated project.


## Acceptance report index — current session

| Requested item | Status | Actual result |
|---|---|---|
|1 Recovered work / Git|COMPLETE|Uncommitted home, city, traffic and assets recovered; no reset, clean, history rewrite or previous-build replacement. Core96e07a9 pushed. Obsolete helper intentionally preserved untracked.|
|2 Navigation tests|COMPLETE|Five completed source navigation suites passed; exact counts above, including physical doorway/counter arrival.|
|3 Windows tests|COMPLETE for core|Final home31, VeyraIII27, living-world32, urban22; retained exported physics50/ragdoll53/mobility54/metropolis33/network13. Police-candidate results recorded separately.|
|4 Sustained day/night|COMPLETE for core|Two unrecorded247-second1080p circuits,11 junctions/764m each; day175.77/64.10 and night180.63/70.47 average/1%low FPS. Full distributions and simulation costs in JSON.|
|5 Cafe owner navigation|COMPLETE within tested route|Lena physically enters raised counter space, floor contact and business availability verified;12-second movie and trace retained.|
|6 Crowd and traffic|PARTIAL|Physical walking, curb/obstacle recovery, six-car default, ten-car stop/resume and save/load tested. General traffic incident recovery and richer routines unfinished.|
|7 Home|PARTIAL|Rest, wardrobe/material, storage, desk/checkpoint, safe restore and physical exit work. Original modeled furnishings remain prototype art.|
|8 Audio|PARTIAL / listening NOT RUN|18 original procedural assets, load/speed/lateral-slip layers, independent mix buses, physical indoor reflection. Actual engine mix recorded, non-silent and unclipped; no subjective quality claim.|
|9 City expansion|COMPLETE within defined scope|Eight connected blocks, original four plus two west/two east;15 junctions44 directed edges; explicit roadworks boundaries. City-wide metropolis unfinished.|
|10 Gameplay evidence|COMPLETE with framing limits|1080p screenshots, synchronized720p30FPS offline pedestrian/cafe/traffic movies and identity traces. Traffic camera partly looks down early. No capture timing used as benchmark.|
|11 EXE and PCK|COMPLETE|Stable core: `builds/operation-veyra-iii-release/OutlawSyndicate.exe` and `.pck`; police witness candidate separate in `builds/veyra3-law-witness-candidate/`. Run beside matching PCK, choose New game; Tab phone, Esc controls.|
|12 Source consistency|COMPLETE|Core766 hashes verified before packaging; police772 verified after export. Build manifests distinguish revisions.|
|13 Commits|COMPLETE for core|96e07a9 integrated city/home/traffic; preceding7b0c6a0 andbc93815 foundation retained. Police publication recorded below after validation.|
|14 GitHub push|COMPLETE for core|Normal push confirmedbc93815..96e07a9 to origin/main. No force push.|
|15 Missing features|PARTIAL|Dispatch/wanted/pursuit/station, ownership/economy expansion, advanced NPC life, factions, Mission02 and five-act campaign unfinished. Texture RID cleanup open; MovieWriter also emits resource cleanup diagnostics. Human extended playtest NOT RUN.|
|16 Next milestone begun|PARTIAL|Implemented physically witnessed delayed crime reports, persistent bounded registry and phone history; source18/native19 checks passed. Existing combat/search remains independent.|
|17 Continuation|PARTIAL|Next connect confirmed reports to physical officer investigation, then wanted/pursuit and persistent case resolution. Exact handoff above. Work does not continue after the session ends.|

Police-candidate final regression results: source production39, home/continuity/Mission01 total31, VeyraIII27, living-world32, witness registry18; all passed, processes exited0. Native candidate witness19, home/continuity/Mission01 total31, VeyraIII27; all passed, processes exited0.772 gameplay hashes verified again after the runs. Native exits retain seven texture RID warnings. No additional police-candidate sustained benchmark or human listening/extended playtest was run.
