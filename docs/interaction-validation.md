# Interaction validation — 14 November 2026

- Source regression: **100 PASS**, zero assertion/script errors (92 existing checks and 8 new headless acting checks). Headless audio output explicitly NOT RUN.
- Final exported Windows interaction route: **48 PASS**, zero failures, process exit **0**. Includes rendered mouse events through HUD, yaw/pitch/sensitivity, aiming, pause/resume, occupancy/load/skip transitions, warehouse/fence blocking, physical front/corner/side/rear/rotated impacts, minor contact, 32 m/s CCD, bounded dents, localized physical glass damage, repair/persistence, bumper detachment, wheel-condition handling, vehicle momentum transfer, movable cargo, NPC crash response and real audio-stream/facial/gesture playback.
- Damage-stage accumulation, selected crack stage and bumper threshold checks also call the same damage-event entry point directly to isolate visualization state. They are distinguished from contact-driven crash experiments in scripts/physics_validation.gd.
- Final exported mission route: **14 PASS**, zero failures, process exit **0**, 50.6833 simulated physics seconds. The actual packaged game traverses the route with movement/vehicle inputs and scripted combat aim. This is an automated short route, not human playtime or campaign duration.
- Computer Use: launched executable, inspected menu and opened facility. Concurrent physical user input made controlled key-by-key checks inconclusive. No agent-controlled full manual playthrough or gamepad PASS is claimed. No Escape input was sent by the agent.

## Rendering sample

Final exported executable, 1920 x 1080, Balanced, RTX 3050 Laptop, Forward+, short crash-fixture inspection after warmup, **672 rendered wall-frame intervals**: average **134.38 FPS**, mean **7.442 ms**, p95 **8.795 ms**, engine video-memory estimate **816.60 MiB**. Another playable build was available for concurrent user testing during this final sample; it is not an isolated GPU benchmark or comparable to the previous district-view measurement. An earlier run measured 278.20 FPS / 3.595 ms before that concurrent session. Capture encoding is outside the timed interval. Long-run thermal behavior, worst-case stutter and full-district profiling remain NOT RUN.

## Evidence

JPEGs and dialogue GIF/MP4 come from final exported viewport frames. The silent physical-crash GIF/MP4 uses the first exported interaction package's actual crash frame sequence; its gameplay code matches the final package, whose later changes concern facility readout layout and an inspection camera. These are scripted repeatable experiments, not human-driving recordings. Frame sampling/encoding changes playback cadence; no claim of frame-perfect real-time video capture is made. Dialogue clips are silent viewport sequences; actual audio playback is asserted separately. No rendered reconstruction or user reference image is substituted.

The front-left post-impact inspection hides the pole's visible mesh to expose the damaged side; the collision shape and confirmed contact remain. Other screenshots preserve the test fixture. The regular procedural glass pattern, angular car and coarse face remain below the requested visual target.

Known diagnostics: seven Texture RID warnings on Vulkan shutdown; editor-settings safe-save warning under restricted permissions. No final gameplay assertion failure or runtime script error is accepted. Full production-quality acting, independently animated eyes/oral cavity/visemes, detailed crumple/fracture, pooled debris, ragdolls/doors and the full campaign remain incomplete. See physics-acting-report.md.
