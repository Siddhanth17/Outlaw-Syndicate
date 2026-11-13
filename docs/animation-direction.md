# Animation direction

No character animation assets currently exist. Player is a capsule, vehicle geometric and pedestrians boxes. Movement-facing interpolation is implemented; it is not skeletal animation.

Planned original rig: idle/walk/run/sprint, stop/turn, true crouch, aim/reload, damage, vault/climb, vehicle entry/exit. Use AnimationTree for locomotion blending and AnimationPlayer for authored interactions and camera timelines. Validate foot placement, root/collision synchronization and skip-safe cinematic state before adding IK complexity.
