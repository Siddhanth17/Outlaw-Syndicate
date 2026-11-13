# Vehicle handling

Implemented baseline: one fictional geometric sedan using Godot VehicleBody3D/VehicleWheel3D with four suspended wheels, front steering, rear traction, smoothed steering, engine force and brake. This is not a realistic tire model or advanced driving system. No damage sources currently modify integrity.

Before architecture lock: compare this baseline against raycast-wheel forces under Jolt on skidpad, ramp, curb, slalom and collision courses. Measure stopping distance, rollover frequency, frame-step sensitivity and gamepad steering. Torque curves, automatic/manual gears, traction surfaces, damage stages, handling classes, audio, repairs and customization remain pending. No branded vehicles/assets integrated.
