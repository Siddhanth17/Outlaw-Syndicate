class_name HumanDynamics
extends SkeletonModifier3D

# Scale-aware angular springs. Runs after AnimationMixer via SkeletonModifier3D.
# Hair/hem bones deform the actual weighted surface; no detached proxy meshes.
var actor: Node3D
var wind := Vector3(0.8, 0, 0.3)
var hair_angle := Vector2.ZERO
var hem_angle := Vector2.ZERO
var hair_velocity := Vector2.ZERO
var hem_velocity := Vector2.ZERO
var previous_velocity := Vector3.ZERO
var previous_position := Vector3.ZERO
var acceleration := Vector3.ZERO
var clock: float = 0
var exertion: float = 0
var head_target := Vector3.ZERO
var has_head_target: bool = false
var reset_count: int = 0
var impact := Vector3.ZERO

func reset_state() -> void:
	hair_angle = Vector2.ZERO
	hem_angle = Vector2.ZERO
	hair_velocity = Vector2.ZERO
	hem_velocity = Vector2.ZERO
	previous_velocity = Vector3.ZERO
	acceleration = Vector3.ZERO
	impact = Vector3.ZERO
	if is_instance_valid(actor): previous_position = actor.global_position
	reset_count += 1

func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if not skeleton or not is_instance_valid(actor): return
	var speed := Vector3.ZERO
	var driver: ValePlayer = actor as ValePlayer
	var driving: bool = driver != null and driver.driving
	var visual_root: Node3D = driver.visual if driver else (actor.visual if actor is HarborGuard else actor)
	if driving and is_instance_valid(driver.vehicle):
		speed = driver.vehicle.linear_velocity
	elif actor is CharacterBody3D:
		speed = actor.velocity
	if actor.global_position.distance_to(previous_position) > 3:
		reset_state()
	previous_position = actor.global_position
	var dt: float = clampf(delta, 0.001, 0.05)
	acceleration = ((speed - previous_velocity) / dt).limit_length(32)
	previous_velocity = speed
	clock += dt
	exertion = move_toward(exertion, clampf(speed.length() / 6.5, 0, 1), dt * (0.9 if speed.length() > 1 else 0.18))
	impact = impact.move_toward(Vector3.ZERO, dt * 12)
	var local_force: Vector3 = visual_root.global_basis.orthonormalized().inverse() * (-acceleration + wind * (0.15 if driving else 1) + impact)
	var target := Vector2(local_force.z, -local_force.x) * 0.009
	var hair_target := target.limit_length(0.14)
	var hem_target := (target * 1.7).limit_length(0.23)
	# Substep prevents variable-render-rate instability; damping settles stops.
	var steps: int = maxi(1, int(ceil(dt / 0.008)))
	var h: float = dt / steps
	for i: int in range(steps):
		hair_velocity += ((hair_target - hair_angle) * 145 - hair_velocity * 22) * h
		hair_angle = (hair_angle + hair_velocity * h).limit_length(0.16)
		hem_velocity += ((hem_target - hem_angle) * 70 - hem_velocity * 15) * h
		hem_angle = (hem_angle + hem_velocity * h).limit_length(0.25)
	for name: String in ["HairCrown", "HairFringe", "HairCrownTip", "HairFringeTip"]:
		_set_secondary(skeleton, name, hair_angle * (0.7 if name.ends_with("Tip") else 1.0))
	for name: String in ["HemLeft", "HemRight", "HemLeftTip", "HemRightTip"]:
		_set_secondary(skeleton, name, hem_angle * (0.6 if name.ends_with("Tip") else 1.0))
	var spine: int = skeleton.find_bone("Spine")
	if spine >= 0:
		var lean: float = -clampf(speed.length() * 0.009, 0, 0.065) + clampf(local_force.z * 0.001, -0.035, 0.035)
		if driving:
			lean = clampf(local_force.z * 0.003, -0.06, 0.06)
		var breath: float = sin(clock * (1.5 + exertion * 2.5)) * (0.003 + exertion * 0.007)
		var lateral: float = clampf(local_force.x * 0.002, -0.05, 0.05)
		skeleton.set_bone_pose_rotation(spine, skeleton.get_bone_pose_rotation(spine) * Quaternion(Vector3.RIGHT, lean + breath) * Quaternion(Vector3.FORWARD, lateral))
	var head: int = skeleton.find_bone("Head")
	if head >= 0 and has_head_target:
		var offset: Vector3 = visual_root.global_basis.orthonormalized().inverse() * (head_target - actor.global_position)
		var turn: float = clampf(atan2(offset.x, offset.z), -0.35, 0.35)
		skeleton.set_bone_pose_rotation(head, skeleton.get_bone_pose_rotation(head) * Quaternion(Vector3.UP, turn))
	elif head >= 0 and driving and is_instance_valid(driver.vehicle):
		skeleton.set_bone_pose_rotation(head, skeleton.get_bone_pose_rotation(head) * Quaternion(Vector3.UP, driver.vehicle.steering * 0.18))

func _set_secondary(skeleton: Skeleton3D, name: String, angle: Vector2) -> void:
	var index: int = skeleton.find_bone(name)
	if index >= 0:
		var rest: Quaternion = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index, rest * Quaternion(Vector3.RIGHT, angle.x) * Quaternion(Vector3.FORWARD, angle.y))
