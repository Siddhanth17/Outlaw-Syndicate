# Animation implementation

Imported clothed human has a 24-joint skinned skeleton. Source CC0 Walk and Run clips come from publisher Meshy generation. Blender-authored Idle (gait-average neutral/breathing), Sprint (retimed run), Turn, Jump, Land, Aim, Shoot, Reload, Interact and basic Enter/Exit pose clips are exported with the model.

ValePlayer uses AnimationTree with manual state-machine travel and 0.14-second crossfades, driven by movement/aim/action state. Default full keyboard movement runs, lower analog input walks, Shift/B sprints. Physics movement stays code-driven; animation does not displace the collision body. Real skeleton-pose changes during input are checked by tests. Right-hand attachment holds the original fictional sidearm; aim pose aligns upper/lower arms in Blender.

These are basic action poses, not polished motion capture. Foot sliding, stride matching, contact IK, hand/finger grips, detailed entry/exit and facial/dialogue performance remain incomplete. Entry still instantly hides the player and exit repositions to a ground-checked location; adding Enter/Exit clips does not count as complete vehicle-entry animation. Current additional clips need artist review in motion.

Next: replace procedural action clips with suitable original/licensed performances, tune locomotion speed/stride and grounded feet, then align hands to doors, ledger and weapon. Distinct Dante/security rigs and animation variation are also needed.
