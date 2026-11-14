# Verification — production history, 14 November 2026

Latest realism increment: 92 PASS assertions (existing 72 + 20 new). New tests cover secondary chains, observed post-animation bone motion, settling, wind, bounds, teleport reset, visible seating, pelvis bounds, steering reach/rotation and exit restoration. Human Motion Laboratory launches. The exported realism-refinement EXE now has a successful opt-in capture route: six actual PNG captures returned OK and the process exited 0. The earlier external --script attempt below belongs to the previous increment. See realism-reference-report.md for current evidence/performance and unmet acceptance criteria.

Engine: Godot 4.6.stable.official.89cea1439, Windows x64, Jolt Physics. Rendered source and exported package use Vulkan 1.4.357 / Forward+ on NVIDIA RTX 3050 6GB Laptop GPU. CPU i5-13450HX, approximately 16 GB RAM.

| Check | Result | Evidence / limits |
|---|---|---|
| Portable Blender and archive integrity | PASS | Blender 4.5.3 LTS executed; SHA256 matches official publisher checksum |
| Blender → GLB → Godot import | PASS | Human, sedan/wheels/sidearm and harbor kit generated/imported; editable sources and provenance retained |
| Original regression suite | PASS | 19 assertions in tests/smoke.gd, unchanged |
| Expanded production suite | PASS | 39 assertions in tests/production.gd: rig/state machine, clips, real pose changes, aim/collision camera, curb traversal, UI, cinematic skip, driving/steering/braking, saved damage, perception/health/hits/ammo/defeat/retry and presets |
| Input-driven opening mission | PASS | 14 checkpoints in tests/mission_playthrough.gd; movement and actual vehicle physics used, scripted camera aim for shots; no objective-position teleports |
| Rendered captures | PASS | Player, car, district, aim, interaction, driving, cinematic, main/pause/controls; motion frame sequence and GIF |
| UI at multiple sizes | PASS | Captures at 1280x720, 1920x1080 and 2560x1080; no gameplay HUD behind modal menus |
| Dedicated handling scene | PASS with warning | Headless 180-frame scene launch; force-exit dummy-audio shutdown emitted resource warnings; control/braking tests passed separately |
| Windows export and renderer launch | PASS | Separate release EXE/PCK, rendered launch exit 0; see production-session-report.md |
| External test harness against exported EXE | BLOCKED | Optional absolute-path --script attempt produced no completed result and was stopped; no packaged suite PASS claimed |
| Manual keyboard/gamepad playthrough | NOT RUN | Required next; automated input does not measure human playtime or feel |
| Long-running thermal/GPU/frame profiling | NOT RUN | Only short rendered wall-frame samples and engine memory counters available |
| Full campaign/branches/Android | NOT RUN | Not implemented |

Total source-game checks: 72 PASS (19 + 39 + 14), zero assertion failures on final suites. An earlier physical route exposed inability to climb a low curb; clearance-checked step handling and a regression assertion fixed it. Car approach test radius was also corrected to respect collision extents. These earlier failures are not hidden or counted as final results.

Input-driven route reported 50.6167 simulated physics seconds on the final run. This is a scripted short mission route, not measured human playtime or campaign duration. Full temporal/cinematic branching QA is not complete.

Known diagnostics: editor export reports an editor-settings safe-save warning under restricted permissions but finishes and launches. Rendered shutdown consistently reports seven Texture RIDs leaked; investigate before a release-quality claim. No runtime script errors in successful render runs. Headless audio playback is muted to avoid dummy-backend teardown leaks; rendered playback remains enabled. The earlier forced immediate dummy-audio course exit warned before this headless-only change. Final headless suites contain no warning/error output.

Raw test/build/render logs remain under ignored tools/*.log and builds/iron-harbor-production/*.log. Source test profiles use ignored tools/runtime-data; do not run suites against personal save data.
