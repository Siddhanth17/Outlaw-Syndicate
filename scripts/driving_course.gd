extends IronHarbor

var car: VeyraCar
var camera: Camera3D
var readout: Label

func _ready() -> void:
	GameInputs.install()
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.12, 0.17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.7
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.shadow_enabled = true
	add_child(light)
	solid(Vector3(0, -0.5, -60), Vector3(60, 1, 180))
	surface(Vector3(0, 0.01, -60), Vector2(60, 180), "asphalt", Color(0.7, 0.7, 0.7), 3, 0.5)
	for i: int in range(8):
		asset("environment/cargo", Vector3(3 * (1 if i % 2 == 0 else -1), 0, -15 - i * 12))
	asset("environment/container", Vector3(-9, 0, -75), PI / 2)
	solid(Vector3(-9, 1.3, -75), Vector3(6, 2.6, 2.4))
	car = VeyraCar.new()
	car.position = Vector3(0, 1.2, 10)
	car.rotation.y = PI
	add_child(car)
	car.occupied = true
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	ui.add_child(margin)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size", 20)
	margin.add_child(readout)

func _process(delta: float) -> void:
	camera.position = camera.position.lerp(car.position - car.global_basis.z * 7 + Vector3.UP * 3, 1 - exp(-delta * 5))
	camera.look_at(car.position + Vector3.UP * 0.5)
	readout.text = "SABLE / HANDLING COURSE\n%d km/h  •  Integrity %d%%\nWASD drive / Space brake / R reset / Esc main menu\nSlalom pallets, brake on asphalt, compare gravel shoulders in the district.\nThis course is for engineering validation, not final environment art." % [int(car.linear_velocity.length() * 3.6), int(car.integrity)]
	if Input.is_action_just_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	if Input.is_action_just_pressed("reload"):
		car.position = Vector3(0, 1.2, 10)
		car.rotation = Vector3(0, PI, 0)
		car.linear_velocity = Vector3.ZERO
		car.angular_velocity = Vector3.ZERO
		car.integrity = 100
