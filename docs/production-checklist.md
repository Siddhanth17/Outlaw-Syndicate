# Iron Harbor production milestone

Approved 14 November 2026: Godot 4.6/Jolt; Blender → GLB pipeline. Previous package preserved in builds/preserved-11aedc2. This is the fixed checklist used for session reporting; completion requires implementation plus applicable verification, not source files alone. Each of 24 items has equal weight. Partial work does not count as completed.

| # | Acceptance item | State |
|---|---|---|
| 1 | Portable Blender and reproducible GLB production | PASS |
| 2 | Licensed clothed, rigged human replaces capsule | PASS |
| 3 | Integrated idle/walk/run/sprint animation state machine | PASS |
| 4 | Integrated jump/land/aim/shoot/reload/interaction clips | FAIL (partial) |
| 5 | Detailed car body, separate wheels/glass/lights/materials | PASS |
| 6 | Modeled modular warehouses with industrial detail | PASS |
| 7 | Textured road, kerbs and sidewalks | PASS |
| 8 | Containers, port props, fences, signs and cargo equipment | PASS |
| 9 | Night lighting, shadows and atmospheric depth | PASS |
| 10 | Wet surface/reflection workflow and graphics presets | PASS |
| 11 | Responsive objective/status/subtitle HUD, no pause overlap | PASS |
| 12 | Main menu, pause controls page and settings | PASS |
| 13 | Shoulder/aim/drive camera with collision and transitions | FAIL (partial) |
| 14 | Improved vehicle control, wheel alignment and dedicated test course | PASS |
| 15 | Vehicle damage, persistent integrity and engine/tire audio | PASS |
| 16 | Enemy perception/patrol/investigation/engagement/defeat | FAIL (partial) |
| 17 | Playable mission encounter, ammo/reload/hit/audio feedback | PASS |
| 18 | Skippable opening/closing presentation and dialogue | FAIL (partial) |
| 19 | Five objective stages, checkpoint/failure/retry integration | PASS |
| 20 | Gameplay-linked faction/district/NPC consequences | FAIL (partial) |
| 21 | Regression and expanded gameplay/asset integration tests | PASS |
| 22 | Actual screenshots and animation/vehicle visual inspection | PASS |
| 23 | Representative rendered performance/resource measurement | PASS |
| 24 | Separate Windows export, launch test, licenses and Git preservation | PASS |

Target: at least 18/24 verified items (75%). This is a production milestone target, not a percentage of the full game. The full quality gate still requires every applicable requirement; 75% does not mean finished.

Verified scope: **19/24 = 79.2%**. Five partial acceptance items remain failed, so the complete production milestone is NOT finished. Equal checklist weights describe acceptance coverage, not elapsed effort, visual quality score or full-game completion.

Partial details: #4 basic clips exist but require performance/contact polish; #13 shoulder/aim/wall tests pass but entry/exit still cut position and need smooth spatial staging; #16 combat AI works locally but lacks navigation/cover; #18 simple skippable camera move lacks distinct cinematic acting/shots; #20 selected consequences work but the broader NPC/faction/district system remains limited.
