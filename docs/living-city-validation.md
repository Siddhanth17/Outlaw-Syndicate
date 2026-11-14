# Living city / signature hero — Windows validation

2026-11-14. Godot 4.6 stable, Jolt, Vulkan Forward+, RTX 3050 Laptop 6GB. Continued from 04d1310 without resetting local work or changing engines. This is an incomplete production increment, not a completed game or visual-reference milestone.

## Checks

- Source: **170 PASS, 0 FAIL** across smoke, production, physical mission, realism, acting and living-city suites.
- Actual Windows executable city/hero suite: **68 PASS, 0 FAIL**, exit 0. Includes real component rays, actual player fire dispatch, near miss and real contacts at 3/12/23 m/s, recovery, incident dedup, panic, checkpoint health/injuries, repaired component state and bounded hair/recoil.
- Exported existing physics/acting suite: **50 PASS, 0 FAIL**, exit 0, including actual distinct audio streams for both speakers, amplitude jaw response, pause/skip/cleanup.
- Exported opening mission input-driven route: **14 PASS, 0 FAIL**, exit 0; 50.97 simulated seconds. Uses fixed 60 FPS for deterministic functional testing; not human playtime.

Counts overlap; they are not independent aggregate coverage. The final export reran the 68 city/hero checks after two evidence-camera adjustments. The 50/14 checks ran against the immediately preceding export with identical gameplay; only evidence camera framing changed afterward. Original source tests were rerun after those changes.

## Short populated performance sample

Final actual Windows export, 1920x1080 Balanced, no fixed-FPS flag and no screenshot encoding during measurement. Eight ambient actors plus fixed Dante; combat adds three scripted combatants. Approximately three seconds per phase. Godot's texture/buffer monitor reports about 895–897 MiB, not total process/GPU allocation.

| Phase | Frames | Mean FPS | Mean ms | p95 ms | Worst ms |
|---|---:|---:|---:|---:|---:|
| combat | 538 | 180.0 | 5.56 | 7.91 | 13.13 |
| driving | 548 | 182.6 | 5.48 | 6.94 | 10.30 |
| populated_walk | 492 | 164.1 | 6.09 | 8.81 | 12.62 |

These are short wall-clock frame samples. They do not establish sustained thermal performance, demanding city-scale capacity, precise GPU pass costs or a universal 60 FPS guarantee. Earlier uncapped samples varied (roughly 163–169 FPS). Raw final measurements are in evidence/living-city/performance.json.

## Actual visual evidence and limitations

All images and clips under evidence/living-city come from this Windows executable's viewport. Contact and sprint clips are silent sampled sequences with approximate cadence, not real-time audiovisual or human-input recordings. Dialogue includes both actors but has no embedded sound; the actual WAVs remain in assets/audio/dialogue. The final camera-only capture revision retains the earlier same-gameplay motion sequences. No concept art or supplied reference image is substituted.

Inspected gallery/closeups, Adrian jacket/hair, car glass/tires/panel view, populated harbor and opposed knockdowns. HUD objectives/status are separated and readable in sampled 1080p frames. The gallery is distant and closeups reveal coarse anatomy. Adrian has broad shiny hair clumps, a helmet-like top and a simple jacket; face/hands remain coarse. This does **not** meet the requested silky groom, premium character or photorealistic benchmark. Injury capture is partially obscured by hair; automated material/persistence checks do not prove a polished visible wound pass. Some bullet marks are subtle in the panel view. Knockdowns remain capsule-based posing with potential limb clipping, not joint-stable ragdolls. Full human keyboard/gamepad playthrough, foot IK, anatomical limb collision, door sequencing and Mission 02 are not validated because they are unfinished.

Seven pre-existing Texture RID warnings occur on Vulkan shutdown. Restricted editor settings safe-save warnings remain in development. No new script errors or failed assertions were accepted. See living-city-signature-report.md for COMPLETE/PARTIAL/NOT STARTED scope and the exact continuation.

## Integrity and reproduction

Previous verified PCK remains SHA256 `2c8e0095c38d5caaa19e07928d01edb8ad645ecec3cabfeac7271aa3dd3362a2`. All 104 media/source manifest hashes verified. License notices and neural model/tool provenance are retained; inference weights/venv are not shipped.

Final executable hashes:

- OutlawSyndicate.exe: `f9cb815a32a1ae3a73ad8699ed2b068cb76fe01636d7e8538243056fac05f37b`
- OutlawSyndicate.pck: `0352892e1351505f960b15e6317fd29f22ceecabce6a6e36aca564b3577908ef`

Run tools/test.ps1 then tools/build.ps1. Export verifiers: `OutlawSyndicate.exe -- --verify-city`, `-- --verify-physics`, and `--fixed-fps 60 -- --verify-mission`. Use isolated APPDATA test profiles; these routes overwrite their test checkpoint. For clips add `--record-living` to the city verifier. art/package_living_evidence.py packages actual frames. Local raw logs remain ignored under tools; summarized results/provenance are versioned here.
