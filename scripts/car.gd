class_name VeyraCar
extends VehicleBody3D

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
	mass = 1250
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3, 0)
	contact_monitor = true
	max_contacts_reported = 4
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.82, 0.75, 4.1)
	collision.shape = box
	collision.position.y = -0.13
	add_child(collision)
	var body: Node3D = load("res://assets/vehicles/sable_body.glb").instantiate()
	body.position.y = -0.80
	add_child(body)
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
	damage_cooldown -= delta
	var throttle := Input.get_axis("back", "forward") if occupied and integrity > 0 else 0.0
	throttle_smoothed = move_toward(throttle_smoothed, throttle, delta * 2)
	var forward_speed: float = linear_velocity.dot(global_basis.z)
	var torque_factor: float = clampf(1 - absf(forward_speed) / 48, 0.12, 1)
	engine_force = throttle_smoothed * 2600 * torque_factor * clampf(integrity / 100, 0, 1)
	var target: float = Input.get_axis("right", "left") * (0.42 / (1 + linear_velocity.length() * 0.035)) if occupied else 0.0
	steering = move_toward(steering, target, delta * 1.3)
	steering_visual.rotation.z = -steering * 2.2
	brake = 30 if not occupied else (55 if Input.is_action_pressed("handbrake") else 0)
	if occupied and throttle * forward_speed < -1:
		brake = 40
	brake_light.light_energy = 2.0 if brake > 0 and occupied else 0.15
	for wheel: VehicleWheel3D in wheels:
		wheel.wheel_friction_slip = 2.0 if absf(position.x) > 8 else (1.8 if Input.is_action_pressed("handbrake") and occupied else 3.2)
	var impact: float = (linear_velocity - last_velocity).length()
	if get_contact_count() > 0 and impact > 6 and damage_cooldown <= 0:
		integrity = maxf(0, integrity - impact * 1.2)
		damage_cooldown = 0.5
	last_velocity = linear_velocity
	engine_audio.pitch_scale = 0.7 + minf(absf(forward_speed) * 0.055 + absf(throttle_smoothed) * 0.3, 1.8)
	engine_audio.volume_db = -16 if occupied else -28
	tire_audio.volume_db = -24 if occupied and linear_velocity.length() > 5 else -60
	for lamp: SpotLight3D in lamps:
		lamp.visible = integrity > 20

func damage_stage() -> String:
	if integrity <= 0: return "DISABLED"
	if integrity < 35: return "ENGINE DAMAGE"
	if integrity < 65: return "DAMAGED"
	return "SABLE GT"

func _exit_tree() -> void:
	if is_instance_valid(engine_audio): engine_audio.stop()
	if is_instance_valid(tire_audio): tire_audio.stop()
