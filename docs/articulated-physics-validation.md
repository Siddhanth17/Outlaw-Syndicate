# Articulated NPC physics — actual Windows validation

2026-11-14. Godot 4.6 stable/Jolt, Vulkan Forward+, RTX 3050 Laptop 6GB. Continued e6b5317 without resetting local work, regenerating the cast/voices or overwriting the reference-mobility package. This is a validated physics/combat increment; the wider living-city directive and professional visual gate remain incomplete.

## Results

| Validation route | Status | Pass | Fail | Exit |
|---|---|---:|---:|---:|
| Full source regression, eight suites | PASS | 275 | 0 | 0 |
| Final ragdoll source after evidence camera adjustment | PASS | 52 | 0 | 0 |
| Actual final Windows ragdoll/feedback route | PASS | 53 | 0 | 0 |
| Actual Windows city/hero/vehicle-contact route | PASS | 68 | 0 | 0 |
| Actual Windows movement/doors/motorcycle route | PASS | 54 | 0 | 0 |
| Actual Windows physics/acting route | PASS | 50 | 0 | 0 |
| Actual Windows opening mission route | PASS | 14 | 0 | 0 |
| Full human keyboard/gamepad playthrough | NOT RUN | — | — | — |
| Traffic, police driving pursuit, Mission02, streaming | NOT RUN / NOT IMPLEMENTED | — | — | — |

Counts overlap and include repeated regression assertions; do not sum them as unique feature coverage. The final ragdoll export adds the rendered concurrent-body check to its 52 source checks. After the five export routes passed, two verifier camera positions were adjusted because the wall obstructed its own inspection image. The ragdoll source/export was rerun and its final captures inspected. The other four exports used the immediately preceding package with identical gameplay, settings, assets and physics; only the verifier camera framing changed. No failed assertion or script/parse error remains in the accepted final logs.

Source checks use fixed 60 FPS. Exported ragdoll/city/mobility/physics checks use ordinary rendering; the mission uses fixed 60 FPS for deterministic physical input. Mission completion took 50.63 simulated seconds, not a measured human playtime or campaign duration. The short opening mission still rewards exactly once. Existing car dents, independent glass, tires, lamps, bumpers, camera capture/orbit, doors, motorcycle, neural speech/pause/skip, settings and checkpoints pass regression.

## Six physical cases

Every case activates thirteen real physical segments, captures the current animated pose, verifies meaningful world contacts, bounded motion, joint separation/angles, skin-rig pose delivery and settling. Tests explicitly ensure that player defeat has not paused the simulation. An earlier fixture shot from the old city position and attracted armed NPCs; this was diagnosed and corrected by moving the player into the lab, not by weakening the physics assertions.

Additional checks cover actual non-adjacent self-contact reports, distinct front/side resting orientations, sleeping, actual player hitscan waking a physical body, pause without drift, restoration, fixed feedback pools and line-of-sight-limited defeat awareness. The existing exported city route confirms actual low/moderate/severe vehicle-to-NPC contact and surviving recovery.

| Case | Peak joint gap m | Max angular excess degrees | Lowest capsule support y m | Final max speed m/s | Self-contact reports |
|---|---:|---:|---:|---:|---:|
| frontal | 0.0106 | 2.63 | -0.0184 | 0.024 | 592 |
| side | 0.0100 | 6.99 | -0.0223 | 0.001 | 1381 |
| running | 0.0065 | 3.85 | -0.0200 | 0.024 | 1280 |
| wall | 0.0106 | 2.62 | -0.0204 | 0.078 | 1356 |
| stairs | 0.0068 | 9.85 | 0.3157 | 0.004 | 342 |
| slope | 0.0062 | 7.80 | 0.5428 | 0.020 | 116 |

Acceptance bounds: joint-anchor separation below 0.12 m, angular overshoot below 12 degrees over configured hinge/pyramid/twist limits, capsule support above -0.045 m, segment center below 4 m, speed capped at 8 m/s and resting max speed below 0.6 m/s. These are defined gameplay tolerances, not a guarantee of anatomically exact movement or zero transient penetration. Contact reports accumulate across physics ticks and are not counts of unique collisions. Raw results are in evidence/articulated-physics/physics-results.json.

## Rendered inspection and artifacts

Launched both the preserved baseline executable and the new exported game. Inspected actual front, side, running, wall and stair/slope output. Final wall/stair views show the body rather than the back of an obstructing fixture. Front/side cases settle in different orientations; arms and legs move independently. The wall blocks the body; stairs support different limbs across treads. Shadows/contact are visible on the textured lab floor. No gross whole-body hover, rigid shared sideways rotation or physics explosion was observed in these sampled cases. Some skin/palm/garment intersection and coarse anatomy remain possible; this is not a final realism sign-off.

MP4/GIF files are silent sampled frames from automated physics scenarios, approximately twelve physics ticks apart. Encoding affects real-time cadence; these are not full human-input or synchronized audiovisual recordings. The before image is the preserved e6b5317 executable's old controlled knockdown, with different framing/lighting; it is not a matched pixel comparison. White fixtures are engineering test geometry, not newly produced city architecture. No concept art, reference photograph or generated illustration replaces gameplay evidence.

Recovery remains a clearance-checked motor/animation restoration and needs authored prone/supine get-up blending. Hands/toes follow their physical parent; compound foot capsules are attached to lower legs. Clothing and fine anatomy use approximations. Exact corpse joint poses are not serialized; ordinary defeated NPCs retain the existing absent-on-load policy. The laboratory is optional; the same controller is used for normal gameplay NPC defeat and severe contact.

## Measured performance

Final actual Windows export, 1920x1080 Balanced. A short three-second uncapped sample contains six newly activated ragdolls (78 segments), three nearby animated workers, the traversing player and the existing global twelve-actor ambient population. Capture encoding is excluded from the timed section. This is not an empty scene, but it is a physics lab, not a large traffic/city or streaming benchmark.

- Frames: 583; mean FPS: **194.3**; 1% low: **69.5 FPS**.
- Mean: 5.15 ms; p95: 9.22 ms; worst: 15.09 ms.
- Engine physics-process monitor mean: **14.18 ms**.
- Engine texture/buffer memory counter: 908.1 MiB; this is not total driver VRAM.

The physics-process counter was 16.72 ms in an earlier otherwise-identical short sample, close to a 60 Hz step budget. The final value does not establish sustained thermal headroom. Solver settings are 64 velocity / 24 position iterations; collision quality improved but CPU cost is material. Larger populations/traffic require profiling, simulation budgets and optimization before expansion. Release static-memory monitoring returned zero, so actual RAM usage is NOT AVAILABLE here. No standalone solver profiler, sustained thermal test, world-streaming stutter measurement or traffic/police cost measurement is claimed.

The current district's separate short samples measured about 142 FPS walking, 155 driving and 171 combat at 1080p Balanced. Those samples do not prove that a larger city will perform equally well. No new road, intersection, block or completed mission is counted in this physics increment.

## Diagnostics, integrity and continuation

Seven previously known Texture RID warnings remain on Vulkan shutdown. The earlier intermittent shutdown resource diagnostic from the prior milestone is not claimed fixed; it did not recur in the accepted current export routes. No suppressions hide failed assertions. Original 158 media/source manifest hashes still match; the reference-mobility PCK remains SHA256 `fefb6f31faf47b1fbc4c946e77ba86408638d8d9685b2031fa468bffde66310f`. No new downloaded asset licenses or voice generation are involved.

Final files:

- OutlawSyndicate.exe: 104578048 bytes, SHA256 `f9cb815a32a1ae3a73ad8699ed2b068cb76fe01636d7e8538243056fac05f37b`
- OutlawSyndicate.pck: 133786056 bytes, SHA256 `747ce6ee3f567b1e80f8d6b3277a4c76fec15c5b37c92642198a5f31dd5ef9c8`

Reproduce with tools/test.ps1 and tools/build.ps1. New export route: `OutlawSyndicate.exe -- --verify-ragdoll --record-ragdoll`; existing routes remain `-- --verify-city`, `-- --verify-mobility`, `-- --verify-physics`, and `--fixed-fps 60 -- --verify-mission`. Use isolated APPDATA because verifier settings/checkpoints are test data. art/package_ragdoll_evidence.py packages actual viewport frames. Raw logs and preserved diagnostic helpers remain under ignored tools/qa-data and tools/*.log.

Next production priority: human controls/recovery inspection, proper get-up clips and palm/garment collision refinement plus solver-cost profiling. Then validate four purposeful connected blocks, a physical lane graph and obstacle-aware traffic, pedestrian schedules/crossings, witness/police vehicle response and Broken Trust objectives/dialogue/checkpoints. These later systems are not finished and no background continuation is promised.
