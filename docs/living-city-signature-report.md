# Living city and signature hero — partial production increment

Continued the existing working tree from `04d1310`. No reset, engine migration, discarded local work or replacement of the last verified Windows package occurred. The previous `builds/physics-acting-validated/OutlawSyndicate.pck` remains SHA256 `2c8e0095c38d5caaa19e07928d01edb8ad645ecec3cabfeac7271aa3dd3362a2`.

This is a playable systems increment, **not completion of the requested visual milestone or five-act campaign**. Final executable validation and measurements are in `living-city-validation.md` and `docs/evidence/living-city`.

## Recovered assets and NPC identities

Nine CC0-derived male character assets are authored by `art/build_population.py`: worker, supervisor, security, pedestrian, delivery, Dante/mechanic, police, faction and shopkeeper. Ten data-driven archetype definitions reference them. Changes include conservative face-width/nose sculpts, shorter/gray hair variations, shaped headwear, rigged vest/bib/apron/belt/satchel/glasses geometry and differentiated materials. These are curated derivatives of the existing human, not nine independently scanned faces. Body anatomy is not randomly stretched.

The live district contains eight ambient actors plus fixed Dante, with actual routes or work/inspection stops. The ambient roster no longer duplicates Dante's model. The opening mission's two guards use different security/faction appearances. Named story identity is fixed rather than randomly generated. The remaining major cast has voice profiles and written direction, not completed visual assets. Clothing, faces and accessories remain visibly coarse; full art-reference parity is **not achieved**.

Walking profiles vary cadence, posture and phase using the existing compatible clips. They are not nine independently authored gait libraries. Work/inspection gestures do not constitute actual cargo-carrying or job simulation. The laboratory shows the same assets and behavior used in the district; it does not replace integration.

## Offline neural voices and acting

Existing generated audio was retained and integrated. Adrian/Dante's six current conversation WAVs now use local **Kokoro-82M v1.0 int8** inference rather than earlier eSpeak formant speech. Eight fixed profiles have generated samples: Adrian, Dante, Mara, Elena, Victor, Nadia, Elias and Marcus. All use different generic model voice presets and authored original text; no identifiable actor/celebrity impersonation was requested.

The upstream model is Apache-2.0 and `kokoro-onnx` is MIT. Official release model/voice-vector hashes were verified. Exact versions, upstream model card, license texts, provenance and reproducible generation scripts are retained. Only 24 kHz PCM WAV output ships; no model, inference runtime or paid API is required in gameplay. Generation preserves existing WAVs by default; `--regenerate` is explicit. Audio is normalized with a 0.89 peak ceiling and a controlled RMS target. Dialogue volume is adjustable and saved in Settings. These are improved stock neural voices, not human dramatic performances or a full emotional voice-production pass.

Playback still drives a 50 Hz amplitude envelope and four conservative facial morphs. Both actors select different actual audio streams and animate while speaking; pause freezes audio/timeline/jaw, and skip stops audio and clears overlays. The lab stops sample playback before a conversation. Jaw/chin movement is **not viseme or phoneme lip synchronization**. There is no modeled oral cavity, individual eyeball rig, detailed lip closure or full facial expression library. Existing contextual gesture, bounded head targeting and shot/reaction direction remain; full professional acting is **PARTIAL**.

Five additional Broken Trust lines were generated incrementally and preserved. They are preparatory audio, **not a playable second mission**.

## Vehicle contacts, NPC reactions and city events

The chassis's Jolt direct-state contacts now notify the contacted character. Contact position, relative normal speed and direction come from confirmed physics contact; merely being nearby does not injure an NPC. The existing character-teleport velocity correction remains. Vehicle damage uses a low fictional character effective-mass factor, while a separate unscaled character-contact event controls injury.

Low-speed contact causes a bounded nonfatal stagger. Moderate/severe contact produces a controlled knockdown, bounded horizontal response (maximum 6 m/s), gravity/ground collision, a lowered capsule and clearance-checked recovery. A 0.9-second cooldown and state guards prevent per-frame repeated damage. Important Dante cannot be permanently killed; dialogue waits while he recovers. Defined 3, 12 and 23 m/s scenarios and a near miss are tested.

Knockdown axes derive from hit direction and actor orientation, rather than always falling to one side. Combat damage has explicit stagger/recovery/defeat state and bounded directional response. This is **kinematic knockdown posing**, not an articulated Jolt ragdoll. Limb self-collision, joint constraints and guaranteed terrain clearance for every limb are **NOT STARTED**. Simplified capsule posing can still clip on complex surfaces.

`CityEvents` shares crashes, gunshots, glass breakage and vehicle/person incidents. Civilians flee and later resume routes; security/police/faction actors investigate or engage according to the current simple role rules. Guards' return fire also alerts nearby people. Event dedup and per-NPC danger timers prevent repetitive panic restarts; transient dedup storage is capped. `CityNavigation` uses a collision-sampled AStarGrid2D with sidewalk preference and simple dynamic-obstacle checks. This is a small flat district route system, not full navmesh/crowd avoidance.

Significant incidents, health/absence and injury marks persist through checkpoints; distant minor movement does not. Civilian injury is recorded as a public incident rather than an enemy-faction alert. Cover selection, coordinated retreat/reinforcements, nuanced wanted-law escalation, traffic and broad civilian simulation remain **PARTIAL/NOT STARTED**.

## Localized gunfire damage

The actual player hitscan path now queries ray-only vehicle mesh regions on collision bit 6 (value 32), separate from stable physical chassis proxies. Body/window/lamp regions use original rest mesh triangles; tires use bounded spheres. Missing glass/lamps disable their ray receiver. Deformed physical collision remains stable; bullet receiver geometry is an approximation of the undeformed component.

Validated hits select body, individual panes, tires or lamps. Glass progresses locally through crack/shatter states; unrelated panes are unaffected. Tires accumulate damage, visibly reduce radius, and lower grip. Individual headlamp meshes/spotlights fail. Body hits accumulate local condition and a preallocated maximum 24-decal impact pool. Bullet impacts do not rebuild the body mesh every frame. Existing contact dents, component detachment and crash handling remain.

Glass, four tires, four lamps, local bullet marks and existing zones/dents persist in the version-1 checkpoint extension; old saves missing these fields default safely. Repair resets supported condition and marks. The values are fictional gameplay tuning, not ballistic or automotive engineering. Detailed tire carcasses, physical fragments, material-specific production impact audio and advanced panel fracture remain **PARTIAL**.

## Adrian's signature derivative

The original human asset and NPC derivatives remain intact. A separate `adrian_signature.glb`/editable Blender source adds a conservative torso sculpt (maximum 5.5% width change), an actual fitted jacket mesh with thickness, lapels, pocket/seam/zipper geometry, original procedural leather color/roughness maps and a dark underlayer.

Shoulder-length dark hair combines a smooth under-volume with 36 skinned layered ribbons. Four new two-joint chains extend the existing rig; both the long hair and existing jacket hem weights receive bounded post-animation springs. Same-material rig attachments are joined to control draw meshes. Running, stopping, wind and occupant acceleration feed the modifier. This is **PARTIAL early-production character art**: broad shiny hair clumps/cards and a helmet-like top silhouette, imperfect fit, simple hardware, original face/hand topology and approximate cloth collision remain. It is not premium scanned leather, strand-level hair, a detailed new face or collision-complete garment simulation.

Locomotion retains source walk/run/sprint clips with speed scaling, body lean, acceleration/deceleration and spring settling. A filtered AimWalk blend preserves moving legs under upper-body aiming, addressing fixed aim-leg sliding. Actual firing adds bounded camera/body recoil that returns without drift and respects reduced-shake mode. Exact two-handed grip, multiple weapon categories, cover aiming, authored stop/turn plants and terrain foot IK are **NOT STARTED/PARTIAL**.

Driving retains the Jolt VehicleBody/wheel architecture and visible seated pose. Damage-related handling remains. New hair/jacket react through occupant acceleration. Hand-to-wheel IK, independently animated doors and a coherent handle/open/enter/sit/close sequence are **NOT STARTED**.

## Restrained injury appearance

A shared material framework applies up to four localized subdued bruise/stain marks per actor, driven by actual hit position/severity. Textured skin/jacket surfaces receive the effect; untextured accessories are excluded. Health and marks survive save/load; new game/defined restoration clears them. No dismemberment or excessive gore is added. The masks are an approximation in mesh/rest coordinates, not anatomically resolved wounds or a full healing system. This feature is **PARTIAL**.

## Campaign status and continuation

The short opening mission remains playable and is regression tested. The five acts and approximately ten-hour ambition are preserved as roadmap targets. Broken Trust has five prepared voice lines but **no completed runtime objectives, checkpoints, encounter route or end-to-end playtest**; its gameplay is **NOT STARTED** and is not counted as delivered story content.

Next: inspect the exported evidence and extend physical keyboard/gamepad/blocked-recovery tests; improve the actual hero groom/jacket/face/hand assets; implement terrain foot IK and authored transitions; build/validate a genuine PhysicalBone ragdoll with bounded joints; author driver grip and hinged door interaction. Then bind the dialogue director to arbitrary NPC partners and implement Broken Trust's supervisor/driver investigation, evidence, conflict, vehicle-component objective, checkpoints and return sequence. Do not count prepared dialogue as a mission. No asynchronous work is promised.

Known diagnostics remain: seven Texture RID warnings on Vulkan shutdown and restricted editor-settings safe-save warnings. Sustained thermal profiling and a full human end-to-end/gamepad playthrough are not claimed. The full game and reference-quality visual gate remain **incomplete**.
