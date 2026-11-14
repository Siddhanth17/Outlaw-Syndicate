class_name VeyraCar
extends VehicleBody3D

signal crashed(point: Vector3, speed: float)
var damage: VehicleDamage
var pending_contacts: Array[Dictionary] = []
var recent_contacts: Dictionary = {}
var contact_clock: float = 0
var impact_audio: AudioStreamPlayer3D
var requested_pose: Transform3D
var requested_velocity := Vector3.ZERO
var reset_requested: bool = false
var occupied: bool = false
var integrity: float = 100
var wheels: Array[VehicleWheel3D] = []
var engine_audio: AudioStreamPlayer3D
var tire_audio: AudioStreamPlayer3D
var lamps: Array[SpotLight3D] = []
var last_velocity := Vector3.ZERO
var throttle_smoothed: float = 0
var damage_cooldown: float = 0
var steering_visual: Node3D
var brake_light: OmniLight3D

func _ready() -> void:
	collision_layer = CollisionLayers.VEHICLE
	collision_mask = CollisionLayers.SOLIDS
	continuous_cd = true
	var physics := PhysicsMaterial.new()
	physics.friction = 0.55
	physics.bounce = 0.08
	physics_material_override = physics
	mass = 1250
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3, 0)
	contact_monitor = true
	max_contacts_reported = 16
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.82, 0.75, 4.1)
	collision.shape = box
	collision.position.y = -0.13
	add_child(collision)
	var body: Node3D = load("res://assets/vehicles/sable_body.glb").instantiate()
	body.position.y = -0.80
	add_child(body)
	damage = VehicleDamage.new()
	add_child(damage)
	damage.setup(body, self)
	var cabin_collision := CollisionShape3D.new()
	var cabin := BoxShape3D.new()
	cabin.size = Vector3(1.42, 0.5, 1.7)
	cabin_collision.shape = cabin
	cabin_collision.position = Vector3(0, 0.4, -0.14)
	add_child(cabin_collision)
	impact_audio = AudioStreamPlayer3D.new()
	impact_audio.stream = load("res://assets/audio/crash.wav")
	add_child(impact_audio)
	steering_visual = load("res://assets/vehicles/steering.glb").instantiate()
	steering_visual.position = Vector3(-0.39, 0.25, 0.53)
	add_child(steering_visual)
	brake_light = OmniLight3D.new()
	brake_light.position = Vector3(0, -0.1, -2.05)
	brake_light.light_color = Color(1, 0.025, 0.01)
	brake_light.omni_range = 2.6
	add_child(brake_light)
	for x: float in [-0.95, 0.95]:
		for z: float in [-1.30, 1.32]:
			var wheel := VehicleWheel3D.new()
			wheel.position = Vector3(x, -0.2, z)
			wheel.wheel_radius = 0.38
			wheel.wheel_rest_length = 0.3
			wheel.suspension_stiffness = 45
			wheel.suspension_travel = 0.22
			wheel.suspension_max_force = 9000
			wheel.damping_compression = 4.4
			wheel.damping_relaxation = 5.2
			wheel.wheel_friction_slip = 3.2
			wheel.wheel_roll_influence = 0.10
			wheel.use_as_steering = z > 0
			wheel.use_as_traction = z < 0
			add_child(wheel)
			wheel.add_child(load("res://assets/vehicles/sable_wheel.glb").instantiate())
			wheels.append(wheel)
	for x: float in [-0.62, 0.62]:
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(x, -0.13, 2.0)
		lamp.rotation.y = PI
		lamp.light_color = Color(1, 0.88, 0.66)
		lamp.light_energy = 4
		lamp.spot_range = 32
		lamp.spot_angle = 34
		add_child(lamp)
		lamps.append(lamp)
	engine_audio = AudioStreamPlayer3D.new()
	engine_audio.stream = load("res://assets/audio/engine.wav")
	(engine_audio.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	(engine_audio.stream as AudioStreamWAV).loop_end = (engine_audio.stream as AudioStreamWAV).data.size() / 2
	engine_audio.unit_size = 9
	engine_audio.volume_db = -16
	add_child(engine_audio)
	if DisplayServer.get_name() != "headless": engine_audio.play()
	tire_audio = AudioStreamPlayer3D.new()
	tire_audio.stream = load("res://assets/audio/tire.wav")
	(tire_audio.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	(tire_audio.stream as AudioStreamWAV).loop_end = (tire_audio.stream as AudioStreamWAV).data.size() / 2
	tire_audio.volume_db = -30
	tire_audio.unit_size = 5
	add_child(tire_audio)
	if DisplayServer.get_name() != "headless": tire_audio.play()

func _physics_process(delta: float) -> void:
	contact_clock += delta
	for hit: Dictionary in pending_contacts:
		if OS.get_cmdline_user_args().has("--trace-physics"): print("CRASH_EVENT ",hit," at ",position," prior ",last_velocity)
		damage.impact(hit.point, hit.normal, hit.speed)
		integrity = maxf(0, integrity - maxf(0, hit.speed - 2.8) * 1.2)
		if DisplayServer.get_name() != "headless":
			impact_audio.pitch_scale = 0.8 + fmod(hit.speed, 4.0) * 0.1
			impact_audio.volume_db = clampf(-20 + hit.speed, -15, 0)
			impact_audio.play()
		crashed.emit(to_global(hit.point), hit.speed)
	pending_contacts.clear()
	var throttle := Input.get_axis("back", "forward") if occupied and integrity > 0 else 0.0
	throttle_smoothed = move_toward(throttle_smoothed, throttle, delta * 2)
	var forward_speed: float = linear_velocity.dot(global_basis.z)
	var torque_factor: float = clampf(1 - absf(forward_speed) / 48, 0.12, 1)
	engine_force = throttle_smoothed * 2600 * torque_factor * clampf(integrity / 100, 0, 1)
	var target: float = Input.get_axis("right", "left") * (0.42 / (1 + linear_velocity.length() * 0.035)) if occupied else 0.0
	var alignment: float = (float(damage.zones["front_left"]) - float(damage.zones["front_right"])) * 0.0008
	steering = move_toward(steering, target + (alignment if occupied else 0.0), delta * 1.3)
	steering_visual.rotation.z = -steering * 2.2
	brake = 30 if not occupied else (55 if Input.is_action_pressed("handbrake") else 0)
	if occupied and throttle * forward_speed < -1:
		brake = 40
	brake_light.light_energy = 2.0 if brake > 0 and occupied else 0.15
	for wheel: VehicleWheel3D in wheels:
		var wheel_zone: String = ("front_" if wheel.position.z > 0 else "rear_") + ("left" if wheel.position.x < 0 else "right")
		wheel.suspension_stiffness = 45 - float(damage.zones[wheel_zone]) * 0.12
		wheel.wheel_friction_slip = (1.0 - float(damage.zones[wheel_zone]) * 0.004) * (2.0 if absf(position.x) > 8 else (1.8 if Input.is_action_pressed("handbrake") and occupied else 3.2))
	last_velocity = linear_velocity
	engine_audio.pitch_scale = 0.7 + minf(absf(forward_speed) * 0.055 + absf(throttle_smoothed) * 0.3, 1.8)
	engine_audio.volume_db = -16 if occupied else -28
	tire_audio.volume_db = -24 if occupied and linear_velocity.length() > 5 else -60
	for i: int in range(lamps.size()):
		lamps[i].visible = integrity > 20 and float(damage.zones["front_left" if i == 0 else "front_right"]) < 55

func damage_stage() -> String:
	if integrity <= 0: return "DISABLED"
	if integrity < 35: return "ENGINE DAMAGE"
	if integrity < 65: return "DAMAGED"
	return "SABLE GT"

func _exit_tree() -> void:
	if is_instance_valid(engine_audio): engine_audio.stop()
	if is_instance_valid(tire_audio): tire_audio.stop()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if reset_requested:
		state.transform = requested_pose
		state.linear_velocity = requested_velocity
		state.angular_velocity = Vector3.ZERO
		last_velocity = requested_velocity
		reset_requested = false
		return
	var strongest: Dictionary = {}
	var speed: float = 0
	for i: int in range(state.get_contact_count()):
		var normal: Vector3 = state.get_contact_local_normal(i)
		var collider: Object = state.get_contact_collider_object(i)
		var other: Vector3 = state.get_contact_collider_velocity_at_position(i)
		# Kinematic transform changes may report teleport-derived velocities.
		if collider is CharacterBody3D: other = collider.velocity
		var approach: float = maxf(-(last_velocity - other).dot(normal), -(state.get_contact_local_velocity_at_position(i) - other).dot(normal))
		if collider is CharacterBody3D: approach *= 0.1
		var point: Vector3 = state.transform.affine_inverse() * state.get_contact_local_position(i)
		if absf(normal.y) > 0.7 and point.y < -0.35: continue
		var key: String = str(state.get_contact_collider_id(i)) + VehicleDamage.zone_at(point)
		if approach > speed and approach >= 2.8 and contact_clock - float(recent_contacts.get(key, -10)) > 0.45:
			speed = approach
			strongest = {"point": point, "normal": state.transform.basis.inverse() * normal, "speed": approach, "key": key, "collider": str(state.get_contact_collider_object(i))}
	if not strongest.is_empty():
		recent_contacts[strongest.key] = contact_clock
		pending_contacts.append(strongest)

func repair() -> void:
	integrity = 100
	if is_instance_valid(damage): damage.restore({})

func damage_snapshot() -> Dictionary:
	return damage.snapshot()

func restore_damage(data: Dictionary) -> void:
	damage.restore(data)
	pending_contacts.clear()
	recent_contacts.clear()
	last_velocity = Vector3.ZERO

func reset_pose(at: Transform3D, speed: Vector3 = Vector3.ZERO) -> void:
	requested_pose = at
	requested_velocity = speed
	reset_requested = true
	pending_contacts.clear()
	recent_contacts.clear()
	throttle_smoothed = 0
	sleeping = false
