# Reference-directed mobility — actual Windows validation

2026-11-14. Continued ff5e16e, Godot 4.6 stable/Jolt, Vulkan Forward+, RTX 3050 Laptop 6GB. The visual reference and full campaign gates remain incomplete. See reference-mobility-report.md for implementation and exact continuation.

## Functional checks

| Route | Pass | Fail | Exit |
|---|---:|---:|---:|
| Source regression, seven suites | 223 | 0 | 0 |
| Actual Windows mobility/audio/door/bike/world | 54 | 0 | 0 |
| Actual Windows city/hero | 68 | 0 | 0 |
| Actual Windows physics/acting | 50 | 0 | 0 |
| Actual Windows opening mission | 14 | 0 | 0 |

Counts overlap; do not add them as independent coverage. Source mobility contributes 53 checks; rendered mobility adds an actual engine output-mix recording check. Source uses fixed FPS for deterministic functional checks. Exported mobility/city/physics use ordinary real rendering. The mission uses fixed 60 FPS and physical movement/vehicle input; 50.63 simulated seconds is not human playtime.

An earlier exported physics camera assertion failed because it expected immediate occupancy after interact. The verifier now waits for animated entry/exit, then checks real mouse orbit. The final exported 50-check route passes without replacing normal gameplay animation with test fallback. Mobility explicitly forces animated door paths even when its other test setup uses test_mode. It checks blocked door rejection, pause, close/settle and cancellation. Legacy headless and mission logic routes retain their documented immediate fallback; these do not establish visual animation quality.

Mobility checks nine ground-material ray selections and actual walking emissions, nonrepeating samples, grounded cadence, sprint/stop/land, stationary/pause behavior, independent settings persistence, real manhole/cargo tags, two-wheel mount/ride/steer/brake/dismount, real chassis/world contact, bike checkpoint recovery, new population and connected navigation routes. Human keyboard/gamepad acceptance and professional audio/art acceptance have not been performed.

## Short actual rendering samples

Final executable, 1920x1080 Balanced, uncapped, no screenshot/movie encoding during each timed measurement. Twelve ambient actors plus fixed Dante exist; central combat adds three scripted combatants. Side-road actors are routed in the expanded map; visibility/workload differs by camera. Each sample is about three seconds, not sustained profiling.

| View | Frames | Mean FPS | Mean ms | p95 ms | Worst ms |
|---|---:|---:|---:|---:|---:|
| Central combat | 516 | 172.2 | 5.81 | 8.54 | 14.57 |
| Central driving | 465 | 155.0 | 6.45 | 8.24 | 11.57 |
| Central populated_walk | 473 | 157.5 | 6.35 | 8.27 | 11.43 |
| West freight walking | 725 | 241.6 | 4.14 | 6.10 | 8.41 |

Godot's reported texture/buffer memory is roughly 915–922 MiB; it is not total process allocation or total driver VRAM. The west view is less demanding than the central harbor. These samples do not guarantee a uniform frame rate, thermal stability, large traffic/crowd scalability or completed optimization. Raw JSON is in evidence/reference-mobility.

## Evidence and visual findings

The screenshots, silent MP4/GIF sequences and 16.32-second stereo 48 kHz engine audio mix are actual final executable output. Clips are sampled automated scenarios with approximate cadence, not full human-input or synchronized audiovisual recordings. The audio contains movement plus quiet scene vehicle background; its perceptual quality/mix still needs human listening review. Material foley is credited Kenney CC0 with exact processing provenance, not nine new boot recording sessions.

Inspected hero front/rear, running frames, door opening, motorcycle rider, expanded district and acoustic pads. The initial motorcycle car pose was replaced with a separate straddled Ride action after rendered inspection. Hands and feet still do not reliably contact bars/pegs. Door hands/legs/root paths remain approximate and can slide/clip. The hero's cap can look helmet-like and the tail remains coarse/streaky; face/skin/beard/hands and jacket are below the supplied reference. No photorealism, premium animation or completed visual milestone claim. The acoustic pads are labeled engineering fixtures, not completed material environments. HUD blocks are separated/readable in the sampled frames; manual gamepad, alternate resolutions and full exploration remain unverified.

## Diagnostics and limits

Seven pre-existing Texture RID warnings remain on Vulkan shutdown. One final mission run additionally reported ObjectDB/three resources still in use at shutdown, despite passing all gameplay assertions and exiting 0. An immediate verbose diagnostic replay passed all 14 checks and did not reproduce that resource error, but reported an unclaimed Master string name. This intermittent shutdown diagnostic is unresolved and is not hidden. Restricted editor settings safe-save warnings also remain. No failed assertion or script/parse error is accepted in the final test logs.

Full articulated ragdolls, foot IK, precise grips, advanced bike balance/damage, tank-top outfit and Mission02/full campaign remain unfinished. Bike saves deliberately restore the parked bike and player on foot. The opening mission still uses the Sable.

## Integrity and reproduction

158 media/source manifest entries verified against SHA256. Current reference image is ignored/local and excluded from the repository/package. Existing NPC and dialogue assets are retained. Previous living-city-signature PCK remains `0352892e1351505f960b15e6317fd29f22ceecabce6a6e36aca564b3577908ef`; older physics PCK remains `2c8e0095c38d5caaa19e07928d01edb8ad645ecec3cabfeac7271aa3dd3362a2`.

Final files:

- OutlawSyndicate.exe: 104578048 bytes, SHA256 `f9cb815a32a1ae3a73ad8699ed2b068cb76fe01636d7e8538243056fac05f37b`
- OutlawSyndicate.pck: 133751616 bytes, SHA256 `fefb6f31faf47b1fbc4c946e77ba86408638d8d9685b2031fa468bffde66310f`

Run tools/test.ps1, then tools/build.ps1. Actual export flags: `-- --verify-mobility --record-mobility`, `-- --verify-city --record-living`, `-- --verify-physics`, `--fixed-fps 60 -- --verify-mission`. Use isolated APPDATA directories because verifier checkpoints/settings are overwritten. art/package_reference_evidence.py packages actual captures; raw logs/profiles stay ignored under tools. Do not regenerate preserved voices needlessly.
