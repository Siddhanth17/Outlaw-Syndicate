Reference/mobility increment adds timed hinged car-door root transitions and a separate Ride pose. Exact handle/wheel/peg contact, leg-over and leg-withdrawal clips remain incomplete.

# Animation implementation

Imported clothed human has a 32-joint skinned skeleton (24 original + eight secondary bones). Source CC0 Walk and Run clips come from publisher Meshy generation. Blender-authored Idle (gait-average neutral/breathing), Sprint (retimed run), Turn, Jump, Land, Aim, Shoot, Reload, Interact and basic Enter/Exit pose clips are exported with the model.

ValePlayer uses AnimationTree with manual state-machine travel and 0.14-second crossfades, driven by movement/aim/action state. Default full keyboard movement runs, lower analog input walks, Shift/B sprints. Physics movement stays code-driven; animation does not displace the collision body. Real skeleton-pose changes during input are checked by tests. Right-hand attachment holds the original fictional sidearm; aim pose aligns upper/lower arms in Blender.

These are basic action poses, not polished motion capture. Foot sliding, stride matching, contact IK, hand/finger grips, detailed entry/exit and facial/dialogue performance remain incomplete. Driving now uses a visible authored Drive pose; entry is still instantaneous and exit repositions to a ground-checked location; adding Enter/Exit clips does not count as complete vehicle-entry animation. Current additional clips need artist review in motion.

Next: replace procedural action clips with suitable original/licensed performances, tune locomotion speed/stride and grounded feet, then align hands to doors, ledger and weapon. Distinct Dante/security rigs and animation variation are also needed.

## Secondary-motion integration

HumanDynamics is a scale-aware SkeletonModifier3D, evaluated after AnimationMixer. Actual hair and rear shirt hem weights use four two-joint chains, bounded damped angular motion, shared district wind and actor/vehicle acceleration. It layers restrained torso lean, breathing, gaze and hit response; transient states reset after teleports/load/occupancy. AnimationTree locomotion includes TimeScale nodes driven by actual horizontal velocity. There is no full strand/cloth collision, terrain foot IK, precision hand grip, facial morphs or true door-entry sequence. Main menu offers the integrated Human Motion Laboratory; controls are displayed there.
