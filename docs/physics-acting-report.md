# Physics, camera and acting increment — 14 November 2026

Recovered the interrupted changes without resetting the project. Godot 4.6/Jolt remains the engine. This is a gameplay increment; the requested full game and visual references remain unmet.

## Confirmed causes and corrections

- The rendered baseline reported fence/cargo collision rays false and mouse yaw delta zero. The corrected probe reported both solids true and yaw delta -0.3 for 120 screen pixels at sensitivity 0.0025.
- Mouse look ran in `_unhandled_input`, after GUI consumption. It now uses `_input`, `screen_relative`, explicit gameplay gating and clamped pitch. Gameplay HUD controls ignore mouse events; modal controls remain interactive. Manual driving orbit delays recentering for 1.5 seconds. Entry/exit preserve orbit; C gives rear view. P supplements Escape for pause, avoiding Computer Use's physical Escape stop control.
- Fences, cargo, lamp posts, dock bumpers/bollards and forklifts lacked appropriate physics coverage. Simplified static or dynamic shapes now follow their model transforms. Sixteen cargo assemblies use 85 kg rigid bodies. Player/NPC movement remains collision-based `move_and_slide`.
- Warehouse main collision already had the correct rotated 16 x 24 footprint. An initial source suspicion about that footprint was not confirmed. Added dock collision covers previously missing protrusions. Roof/crane geometry remains simplified; these are not walkable or destructible interiors.
- The chassis was already force-driven `VehicleBody3D`, not transform-driven normal driving. It retains four vehicle wheels, with explicit solid masks, CCD, compound chassis/cabin shapes, 16 monitored contacts and physics-callback reset requests. A custom suspension rewrite is deferred until measured need justifies it.
- A mission regression exposed an exit handoff bug: a repositioned character was reported as a **71 m/s** collider, falsely crushing the parked car. Character contacts now use intended velocity and a low fictional effective-mass factor. A 0.25-second exit collision handoff lets kinematic motion settle. Capsule-clear grounded exit candidates avoid teleporting into walls. The corrected mission completed with no phantom damage and 100% condition at re-entry.
- Camera harness failures also came from accumulated synthetic events and transition timing. The rendered verifier sends separate events after settlement. Headless mouse-mode behavior is not accepted as desktop camera evidence.

## Layers

| Bit | Role | Behavior |
|---|---|---|
| 1 | Static | Solid against player, vehicles, NPCs, props |
| 2 | Player | All solid roles; suppressed while seated |
| 3 | Vehicles | Static, player, vehicles, NPCs, props |
| 4 | NPCs | All solid roles |
| 5 | Props | All solid roles; cosmetic debris excludes actors/vehicles |
| 6 | Projectile reserve | Weapons currently raycast |
| 7 | Interaction reserve | Existing interactions remain distance-based |
| 8 | Damage-trigger reserve | No new trigger simulation claimed |

## Vehicle damage and repair

Direct-state contacts supply world-space body contact positions, normals, collider and relative closing speed. Positions/normals are converted into chassis coordinates; side normals disambiguate corner contacts. Jolt's estimated impulse is not treated as a measured automotive crash force. Normal-speed threshold: 2.8 m/s; cooldown per collider/zone; strongest event per step. Routine road support is filtered. Character effective mass is a fictional gameplay rule.

Twelve independent regions cover front left/center/right, left/right front/rear sides, rear left/center/right, roof and underbody. Dents rebuild from rest geometry on damage/restore, with at most 12 merged contact records and 0.40 m maximum displacement. Nearby vertices move inward with radial falloff; normals rebuild and procedural scrape marks appear nearby. Physics shapes remain stable. This is constrained mesh deformation, not soft-body metal simulation. Fine panel crumpling remains limited by existing topology.

Six authored glass components independently progress through intact, cracked, heavily cracked and missing/shattered states. Eligible cabin impacts affect nearby panes; projected contact UVs seed the original crack shader. Short-lived fragments and synthesized glass sounds accompany shattering. Bumper impacts do not automatically break every window. No laminated-glass solver or persistent physical shards are claimed.

Front/rear bumpers deform and can detach after severe accumulated corresponding damage. Detached parts use simplified 8 kg bodies, bounded initial velocity, an eight-part cap and 12-second cleanup. Repair/load clears transient debris. Emitters are bounded and short-lived, not a preallocated debris pool. Local lamp failure, wheel-zone traction/stiffness degradation, slight front misalignment and overall condition-dependent propulsion provide gameplay consequences. Zones, dents, panes and crack origins persist in checkpoints; old saves without the new dictionary remain supported. Dante's return repair restores supported components.

Crash/glass audio is original deterministic synthesis. Material-specific production recordings, persistent scrape loops, advanced suspension breakage and realistic fragment geometry remain incomplete.

## Dialogue fallback

The Adrian–Dante greeting and closing conversation use six original lines synthesized offline with **eSpeak NG 1.52.0 formant voices**. No identifiable real voice is cloned. The GPL build tool is not distributed; its upstream license, source URL and MSI hash are recorded under `assets/licenses`. These are conspicuously synthetic draft voices, not production dramatic performances. Other mission/radio subtitles and the arrival monologue remain text-only.

Four conservative morphs were authored on the existing CC0 mesh: JawOpen (129 vertices), BlinkLeft (52), BlinkRight (54), BrowConcern (58). A 50 Hz RMS envelope follows actual voice playback position. This is **amplitude-driven jaw/chin motion**, not phoneme/viseme lip synchronization. There is no oral cavity, independent eyeball rig, robust lip closure or production facial topology. Head targeting supplies bounded gaze direction; blinking compresses lid-region geometry. The same human still represents both characters.

A reusable director coordinates audio, subtitles, facial overlays, contextual upper-body gestures, listener/head reactions and establishing/speaker/reaction shots. Camera positions stay on one side of the conversation axis and interpolate. The limited concern/point/open/warning/nod/listen overlays are not a complete gesture library. Pause freezes audio, mouth and timeline. Skip clears overlays and restores control while retaining already-awarded mission progress. Precise hand acting, eye darts, full posture choreography and collision-aware cinematic camera paths remain incomplete.

## Interaction and facility

Main menu → Crash Test Facility contains a concrete wall, steel barrier, parked/movable cars, poles, slope and dynamic cargo. Simple fixtures are engineering geometry, not a finished environment art pass. E enters; 1/2/3 initialize front/corner/high-speed tests; 4 repairs; 5 resets pose. Normal driving, mouse, C and P controls remain available. Controlled initial velocities are repeatable experiments, not a human driver's input recording. The automated route also checks side, rear, elevated glass, minor-contact and 32 m/s thin-barrier crashes.

Nearby guards hear confirmed crashes and investigate; Dante briefly looks toward nearby impact sounds. Existing patrol/combat remains. Cargo responds to player impulses and vehicle momentum. Ragdolls, hinged doors, authored wooden-fence destruction, broad civilian routines and drivable forklifts are not implemented.

## Validation and limitations

Final counts, exported routes, evidence and performance are recorded in the accompanying validation summary. Automated physics crashes, direct visualization-state tests and manual UI checks are distinguished. An assertion count is not a human playthrough or visual-quality gate.

Existing seven Texture RID warnings on Vulkan shutdown and restricted editor-settings safe-save warnings remain. A transient freed-debris lambda warning found during testing was fixed with a weak reference. Sustained thermal stability, leak-free rendering and engineering-grade physical accuracy have not been established.

## Exact continuation

Extend keyboard/gamepad collision-recovery playtests, focus transitions and rollover/blocked-exit coverage. Improve panel topology, window remnants, impact-load distribution, material-specific audio and pooled debris. Replace or substantially author unique hero/Dante faces with mouths, eyes, lids, visemes and expressive controls; secure production voice performances and authored gesture, entry/exit, grip and foot-IK clips.

The five-act, approximately ten-hour campaign remains unbuilt beyond the short opening mission. Other districts, interiors, missions, side activities, distinct cast, story branches and endings remain roadmap work. The photographic references remain unmet. No asynchronous development is promised.

Technical sources: [Godot 4.6 mouse coordinates](https://docs.godotengine.org/en/4.6/tutorials/inputs/mouse_and_input_coordinates.html), [body contact coordinates](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectbodystate3d.html), [Jolt impulse limitations](https://docs.godotengine.org/en/4.6/tutorials/physics/using_jolt_physics.html), [eSpeak NG](https://github.com/espeak-ng/espeak-ng), [upstream GPL](https://github.com/espeak-ng/espeak-ng/blob/1.52.0/COPYING).
