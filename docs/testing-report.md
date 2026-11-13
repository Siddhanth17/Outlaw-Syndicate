# Verification — 14 November 2026

Engine: Godot 4.6.stable.official.89cea1439, Windows x64. Physics project setting: Jolt Physics. Rendered launch: OpenGL 3.3, NVIDIA RTX 3050 6GB Laptop GPU.

PASS: editor import and script registration; initial invocation reported sandboxed AppData write errors. Repeated runtime checks use workspace-isolated APPDATA.

PASS: headless scene launch for 180 frames, no runtime errors.

PASS: 19 engine-backed smoke assertions in tests/smoke.gd: first/duplicate event handling, idempotent reward, JSON round-trip, consequence restoration, unknown version rejection, player floor collision, vehicle settling under Jolt, movement input, camera active, car construction, garage objective, vehicle entry, drive objective, ledger/search trigger, escape objective, mission reward, checkpoint reload, and corrupt primary recovery from backup.

PASS: rendered launch and actual viewport screenshot captured at tests/artifacts/harbor.png. Inspected camera, world, vehicle, HUD and opening subtitles. This is geometric blockout art.

NOT RUN: manual end-to-end gameplay, controller playthrough, extended driving stability/feel, combat hit accuracy, full UI navigation, performance benchmarks, interrupted-write/corrupt-backup fault injection, full campaign and branches, Android. Automated tests reposition actors and fast-forward search; they do not measure real playtime.

Build verification is recorded in docs/build-verification.md when an export is produced. No full-game QA claim.
