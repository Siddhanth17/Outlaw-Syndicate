# Operation Veyra II — durable recovery record

Baseline: clean `6fe8225`, Godot 4.6/Jolt. Existing architecture, source assets and prior Windows releases preserved. Current sprint remains **PARTIAL**. No execution is promised between active sessions.

## P0/P1 foundation

- 36 ordinary citizens plus Dante: retained the original 16 and added 20 stable records in `data/living_roster.json`. Eight new recurring identities join the four established named Northline citizens. Nine existing geometric character variants are reused; no new character-mesh realism claim.
- `LivingWorld` owns resident identity/relationship state, bounded inventory/receipts/bank-account foundation and population activation. `CityMemory.money` remains the only cash authority; existing `CityEvents`, `CityNavigation`, `VeyraQuarter` clock and actor controllers are reused. Dante's existing contact state remains in the backwards-compatible phone payload.
- Normal nearby population budget 28, 115m activation radius. Actual exported samples activated 22–23 citizens, with 13–14 abstracted. Injury, ragdoll, danger and conversation actors remain simulated even if they exceed the normal budget. Offscreen actors follow collision-sampled paths with animation/physical navigation disabled; this is not spawning/deleting identities.
- Component-version-1 `living_world` payload extends existing root-version-1 saves. Legacy saves use defaults; unsupported component versions and invalid coordinates are rejected before replacing live state. Identity positions, distinct conversation topics, consented contacts, bank balance, inventory, receipts and transaction sequence restore. Root atomic checkpoint/backup policy remains.
- Per-person schedule hours and break windows. Lena Ortiz works at the Lantern counter 08:00–19:00, breaks 12:30–13:00. Physical availability requires her to reach the counter, remain healthy and not be fleeing. Working, break and home-zone destinations are implemented; these are not fully furnished homes or independent personal quests.
- Nearby line-of-sight resident interaction: name, work and neighborhood topics; repeated greetings cannot farm familiarity. Two distinct interactions permit a number request. Contact records use the actual identity; conversations stop actor movement and restore it on close, with danger still interrupting them.
- Twenty original resident phone replies generated offline with the installed Kokoro toolchain and existing stock presets. `data/living_voices.json` maps each ID to its authored line/WAV. Existing story recordings untouched. Ring/connect/busy/end paths use actual audio and text. New calls do not yet have a persisted call-history app or viseme lip sync.
- Lantern counter: coffee $4, sandwich $8; actual cash charge, bounded carried item, receipt and checkout sound. Phone carried-items consumption restores 5/25 health and removes the item; full health refuses consumption. Staff break/closing and insufficient funds reject sales. Existing paid Sable repair now records the authoritative cash transaction.
- Scrollable phone content: resident contacts/cards, conversation, café menu, carried items, wallet/receipts. Wallet banking data is real persisted state, but physical ATM/bank interaction is **NOT IMPLEMENTED**; transfer methods are foundation/test APIs, not a delivered bank location.

## Provenance

No new external models/textures or downloads. `art/build_living_voices.py` uses locally installed Kokoro-82M int8 (Apache-2.0) / kokoro-onnx (MIT) with existing licensed generic presets. No cloning/impersonation. Original texts and synthesized ring/checkout tones; model/voice hashes and per-WAV hashes retained in `assets/licenses/living-voices-provenance.json`. Earlier license notices remain included. Multiple citizens share voice presets and existing appearance variants; twenty replies do not imply twenty bespoke human performances.

## Validation recovered before the resume request

- Initial full source regression completed with no failures, including the new 27-check living-world route. Final source rerun is required for the exact published snapshot.
- `builds/living-world-foundation/OutlawSyndicate.exe` launched with isolated APPDATA under `tools/qa-data/living2-foundation`; **28 exported checks passed**. Contact consent, actual WAV playback selection, café cash/item/receipt, consumption, closed counter, bank foundation, save/load, invalid component version, abstract travel and optional story were checked.
- True 1920×1080 populated profiling: day walk 12s, average 139.23 FPS, 1% low 74.58, p95 10.805ms; night crowd 10s, average 135.80 FPS, 1% low 65.42, p95 10.368ms; open phone 5s, average 139.45 FPS, 1% low 66.20, p95 9.902ms. Two traffic cars, 22–23 active citizens. Texture/buffer monitor ~1.20GB, not total VRAM. These are short scenarios, not sustained whole-city performance.
- Actual captures in the isolated profile show the neighborhood, resident UI/call and transaction. The original transaction capture camera still faced the intersection; validation framing was corrected to show the actual café counter for the final run.
- Seven texture RID shutdown warnings remain. Human 20–30-minute route: **NOT RUN**.

## P2 experiment — preserve, do not ship as complete

Uncommitted `road_network.gd`, `network_validation.gd`, `tests/network.gd` and traffic-controller changes define nine junction IDs, 24 directed lanes, closure-aware BFS routing, curved movements and reservation ownership. The additional fleet is **opt-in and disabled by default** until validated.

First 60-second headless gate: graph/routing/reservation unit checks passed, but only **six total cars** spawned instead of ten. All six finished with integrity 100 and on-road positions; target-count-dependent checks failed. Do not loosen the spawn-clearance test. Exact next diagnostic: inspect `SPAWN_BLOCKED` output in `tools/living2-network-source.log` to identify the four rejected positions/colliders, then rerun the minute-long route. No traffic variation, police vehicles, parking, generalized recovery or finished pedestrian crossing signal system is claimed.

The resume directive requires publishing stable P0/P1 before continuing P2. Preserve the experiment in the working tree. Stage the foundation separately; an isolated source snapshot of its commit can be built without reverting or overwriting the P2 working files. Do not include the `--verify-network` hook in that foundation snapshot unless its referenced experiment is also included.

## Still unfinished

P2 general populated traffic remains under test. P3 witness crime registry/dispatch/pursuit not implemented beyond legacy guard/search reactions. Starting home, ATM/bank location, property/vehicle purchases/showroom, additional businesses, faction progression and playable Mission 02 remain **NOT STARTED** in this increment. Existing M1/phone/repairs/13-segment ragdolls must remain regression gates.

## Exact continuation

1. Preserve status/diff and generated audio; do not regenerate it.
2. Publish a coherent P0/P1 source snapshot after full source and exported validation; update this file with actual commit/build/hash/push results.
3. Resume the gated P2 spawn-clearance diagnostic, then validate ten-car movement/turns/reservations/obstacles and native-1080p populated performance before enabling it in normal gameplay.
4. Then implement witnessed crime reporting and physical dispatch using existing events/actors, followed by a useful safehouse and persistent commercial ownership loops.
