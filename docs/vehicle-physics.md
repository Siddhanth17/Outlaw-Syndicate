# Sable GT handling increment

Original Blender-authored lofted sedan body, real wheel-arch cuts, separate glazing/window frames, cabin seats/dashboard, wheel/tire/rim assemblies, lights, mirrors, handles and grille replace the box car. Vehicle remains angular early-production art. Wheel meshes attach under four VehicleWheel3D nodes; front wheels steer and rear wheels drive. Model local front is +Z; initial vehicle yaw PI points down the harbor road.

VehicleBody3D: mass 1250 kg, lowered center of mass, smoothed throttle and speed-dependent engine force/steering, tuned suspension/damping, handbrake, lower shoulder traction and impact-based integrity. These are gameplay approximations, not a validated real tire/torque/weight-transfer simulation. Positive drive/reverse, steering, braking, settling and saved integrity are engine-tested. Visual alignment is inspected in rendered captures.

Integrity reduces available engine force; low integrity disables headlamps, and zero integrity disables propulsion. The display reports SABLE GT / DAMAGED / ENGINE DAMAGE / DISABLED. No deformable body, glass fracture or physically distinct suspension damage stages. Synthesized looping engine pitch responds to speed/throttle; tire noise responds to speed. These sounds need a proper production sound pass.

Main menu → Driving course opens scenes/driving_course.tscn: textured straight course, alternating cargo slalom and a collision obstacle, R reset and Esc return. It is an engineering test scene, not final environment art. Ramp/skidpad/surface telemetry and extended collision/rollover testing remain pending.
