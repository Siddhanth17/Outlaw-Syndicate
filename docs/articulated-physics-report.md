# Articulated NPC defeat and combat feedback

Continued the existing e6b5317 working tree without resetting Git, regenerating character/voice assets, changing engines or overwriting builds/reference-mobility. This is the ragdoll/combat foundation of the larger directive, not completion of the living-city or campaign milestone.

## Root cause and verified baseline

The supplied screenshot shows a rigid sideways body with fixed limb relationships. The actual enemy.gd implementation confirmed why: defeat paused the animation, shrank one CharacterBody capsule to 0.68 m, and rotated/translated the entire visual node through a shared fall angle. Individual limbs had no rigid bodies, joint limits or independent world contact. Direction selected the whole-mesh axis; it did not make the result articulated. The preserved Windows build was launched with its city verifier and its old knockdown captured under tools/qa-data/ragdoll-before. The before image in evidence is that executable output, not a reconstruction or imported reference photograph. Different cameras/lighting mean it is not a matched pixel comparison.

## Physical implementation — implemented, production quality still partial

NPCs now lazily create a real PhysicalBoneSimulator3D with thirteen PhysicalBone3D segments: pelvis, three torso/chest segments, head, two upper arms, two forearms, two upper legs and two lower legs. Compound foot capsules belong to the lower legs. Hands/toes/helper bones follow the captured pose and hierarchy rather than adding tiny physics bodies. Capsules, realistic-looking mass ratios, friction, damping and CCD give gravity/obstacles actual control of the collapse. Adjacent joint neighbors exclude collision; non-adjacent limbs and torso retain self-collision. Contact counts verify that self-collision actually occurs.

The imported visual skeleton uses centimeter units under 0.01 scale. A separate meter-scale physical skeleton preserves the original assets, bind poses and animations. A SkeletonModifier3D bridge copies simulated local bone poses to the existing skinned mesh. The animation's current pose and velocity are captured before activation; the controller pauses animation and disables the standing character capsule/motor. It no longer rotates the whole visual sideways. Physical limbs drive the actual visible skin.

Cone-twist constraints limit spine/neck/shoulder/hip motion, with oriented hinge constraints at elbows and knees. Joint anchors are rebuilt from the captured animated pose so shoulder/neck helper transforms do not force a rest-pose snap. Godot 4.6 creates its native joint on joint-type changes; final frame setup precedes that creation. Limits are measured against actual body frames, including Jolt's swing-pyramid convention and hinge sign. Initial failed angular checks and subsequent solver/shape corrections were retained in local logs, not removed from the acceptance test.

The API pipeline was checked against [Godot 4.6 ragdoll documentation](https://docs.godotengine.org/en/4.6/tutorials/physics/ragdoll_system.html), [PhysicalBone3D](https://docs.godotengine.org/en/4.6/classes/class_physicalbone3d.html) and the engine's [4.6 physical-bone implementation](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/physics/physical_bone_3d.cpp). No deprecated Skeleton3D ragdoll-control methods or copied commercial assets are used.

## Damage and recovery

Gunfire defeat and severe confirmed car/motorcycle contact enter the same physical controller. It uses actual hit direction/location, current animation and character velocity; the closest body receives a small bounded impulse. Linear speed is capped at 8 m/s and angular speed at 12 rad/s. Light hits retain a short directional spring/flinch instead of enabling the full rig. Vehicle contact cooldown/state guards remain, so sustained contact does not apply damage every frame. Existing glass, tires, dents, bumpers, lamp damage and saves remain.

The ragdoll layer is included in physical collisions and player hitscan. A settled body can be hit through the actual weapon path and wake. Live actors cannot simply walk through its physical shapes. Settling bodies sleep after quiet motion; collision remains active and the body remains visible. Ordinary corpses are retained within the current bounded population, not instantly deleted in view. This is not a streaming/corpse-population manager for hundreds of people.

Pause/cinematic freeze preserves the articulated body and velocities. Nonfatal knockdowns can recover after a delay, low motion, a ground query and a standing-clearance check. Restoration stops the simulator and restores the motor/capsule/animation; old checkpoints remain accepted. Health/absence/injury persistence remains, but exact corpse joint poses are not serialized. Ordinary saved defeated NPCs restore as absent, matching existing world-state policy. Recovery still lacks a properly authored prone/supine get-up blend and can visibly transition too abruptly; it is not a professional animation gate pass.

## Restrained combat presentation

The existing four-mark character injury shader remains damage-driven and persistent. A fixed pool adds twelve short burgundy-fleck particle emitters, twelve small soft floor marks and reused credited impact foley. These are restrained stylized effects, not detailed anatomical wounds or new recorded human impact performances. Density can be set Off/Low/Normal in Settings and persists. New game/load clear transient floor marks and effects; character injury state remains checkpoint-driven. No dismemberment, excessive gore or new external recordings were added.

Nearby civilians/role actors can notice a defeat within 16 m only with an unobstructed static/prop/vehicle sight ray. Existing local gunfire/crash reactions remain. The expanded district flee target no longer clamps side-road NPCs back into the original narrow strip. This is a local awareness improvement, not new police dispatch, driving pursuit, reporting delays or apprehension AI.

## Laboratory and validation

The Articulated Physics Laboratory is available from the main menu. Keys 1–5 reset frontal, side, running, wall and stair cases. Normal movement/look/weapon controls remain. White fixtures are explicitly engineering collision fixtures, not finished district art. The exported automated route additionally tests a slope, actual corpse hitscan, pause/restoration, wall-occluded awareness and concurrent ragdolls. It records real viewport frames; no concept art replaces gameplay evidence.

A test-isolation failure was found during recovery: firing from the player's old city position attracted nearby armed NPCs, eventually caused player defeat and paused the stairs/slope scenarios. The harness now places the player in the physical lab and asserts that every scenario remains unpaused/alive. This corrected the fixture; the falling/settling requirements were not weakened. Full source and actual exported results are in articulated-physics-validation.md.

## Limits and next stage

This fixes the rigid whole-body defeat mechanism. It does not establish GTA V quality or a complete milestone. Coarse character meshes, clothing/body collider approximation, fingers/hands, some skin/garment intersections and sharp recovery transitions remain. Physical constraints are gameplay approximations; defined tolerance tests do not prove every possible collision configuration. Joint solver quality uses 64 velocity and 24 position iterations, so the measured CPU cost and population limits matter. New traffic, broad schedules/navmesh crowd avoidance and large-scale streaming are not delivered by this increment.

This increment adds **zero roads, zero intersections, zero new city blocks and zero completed missions**. The prior road loop/twelve ambient actors/motorcycle/door systems are preserved and regression tested. New four-purpose-block production, a data-driven lane graph, reactive AI traffic, wider pedestrian routines, police vehicle pursuit and Broken Trust runtime remain the next stage. No inaccessible skyline or existing roads are counted as new expansion. Adrian's visual quality, foot IK, exact driver/rider grips and cinematic performances remain incomplete.

Exact continuation: finish rendered/human inspection of the exported body and recovery cases; author proper get-up clips and refine palm/clothing collision. Then validate the actual four-block layout/road widths, build a lane graph tied to physical intersections, add force-driven traffic with obstacle/intersection handling and pedestrian crossings, expand witness/police logic, and implement Broken Trust objectives/dialogue/checkpoints with actual end-to-end playtests. No work is promised after the execution session ends.
