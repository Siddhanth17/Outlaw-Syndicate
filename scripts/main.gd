extends Node3D

const SAVE_PATH: String = "user://veyra-save.json"
var memory := CityMemory.new()
var player: ValePlayer
var car: VeyraCar
var hud: Label
var dialogue: Label
var marker: MeshInstance3D
var mission: Dictionary
var targets: Array[StaticBody3D] = []
var civilians: Array[Node3D] = []
var cooldown: float = 0
var dialogue_time: float = 0
var elapsed: float = 0
var paused: bool = false
var menu: PanelContainer

func _ready() -> void:
	_setup_input()
	mission = JSON.parse_string(FileAccess.get_file_as_string("res://data/homecoming.json"))
	_build_world()
	player = ValePlayer.new()
	add_child(player)
	player.position = Vector3(0, 1, 12)
	car = VeyraCar.new()
	add_child(car)
	car.position = Vector3(4, 1.2, 4)
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_say("Adrian Vale", "Three years away. One message from Mara. Then nothing. Dante's garage is my last address.")

func _setup_input() -> void:
	var keys: Dictionary = {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE, "interact": KEY_E, "handbrake": KEY_SPACE, "save": KEY_F5, "load": KEY_F9, "pause": KEY_ESCAPE, "fire": KEY_F}
	for action: String in keys:
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for spec: Array in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["forward", JOY_AXIS_LEFT_Y, -1.0], ["back", JOY_AXIS_LEFT_Y, 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = spec[1]
		axis.axis_value = spec[2]
		InputMap.action_add_event(spec[0], axis)
	for spec: Array in [["jump", JOY_BUTTON_A], ["interact", JOY_BUTTON_Y], ["fire", JOY_BUTTON_RIGHT_SHOULDER], ["pause", JOY_BUTTON_START]]:
		var button := InputEventJoypadButton.new()
		button.button_index = spec[1]
		InputMap.action_add_event(spec[0], button)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", mouse)

func _box(at: Vector3, size: Vector3, color: Color, solid: bool = true) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	mesh.material_override = material
	if solid:
		var body := StaticBody3D.new()
		add_child(body)
		body.position = at
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		body.add_child(mesh)
	else:
		add_child(mesh)
		mesh.position = at
	return mesh

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.08, 0.12, 0.18)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.45, 0.55, 0.7)
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, -35, 0)
	sun.light_color = Color(1, 0.71, 0.46)
	sun.shadow_enabled = true
	add_child(sun)
	_box(Vector3(0, -0.5, -60), Vector3(180, 1, 240), Color(0.15, 0.18, 0.19))
	_box(Vector3(0, 0.02, -60), Vector3(16, 0.04, 220), Color(0.055, 0.065, 0.075))
	for i: int in range(20):
		_box(Vector3(0, 0.06, 35 - i * 10), Vector3(0.15, 0.03, 4), Color(0.9, 0.7, 0.3), false)
	for side: int in [-1, 1]:
		for i: int in range(8):
			var height: float = 6 + (i % 3) * 4
			_box(Vector3(side * 34, height / 2, 20 - i * 24), Vector3(26, height, 18), Color(0.22 + i * 0.012, 0.25, 0.28))
			for row: int in range(3):
				_box(Vector3(side * 20.9, 2 + row * 1.5, 20 - i * 24), Vector3(0.1, 0.7, 12), Color(0.6, 0.43, 0.19), false)
	for i: int in range(5):
		_box(Vector3(55, 1.5 + (i % 2) * 3, -60 - i * 9), Vector3(10, 3, 6), Color(0.2, 0.32, 0.38))
	for i: int in range(3):
		var target := _box(Vector3(-12, 1, -40 - i * 8), Vector3(1, 2, 1), Color(0.7, 0.2, 0.1))
		targets.append(target.get_parent())
	for i: int in range(8):
		var civilian := _box(Vector3(11 + i % 2 * 3, 0.9, -i * 15), Vector3(0.6, 1.8, 0.6), Color(0.25, 0.4, 0.4), false)
		civilians.append(civilian)
	marker = _box(Vector3.ZERO, Vector3(1, 3, 1), Color(1, 0.65, 0.12), false)
	var garage := Label3D.new()
	garage.text = "CROSS MOTOR WORKS\nIRON HARBOR"
	garage.position = Vector3(0, 5, -3)
	garage.font_size = 64
	add_child(garage)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(28, 22)
	hud.add_theme_font_size_override("font_size", 21)
	layer.add_child(hud)
	dialogue = Label.new()
	dialogue.position = Vector2(160, 540)
	dialogue.size = Vector2(960, 140)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_font_size_override("font_size", 24)
	layer.add_child(dialogue)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(634, 348)
	layer.add_child(crosshair)
	menu = PanelContainer.new()
	menu.position = Vector2(430, 120)
	menu.custom_minimum_size = Vector2(420, 400)
	layer.add_child(menu)
	var column := VBoxContainer.new()
	menu.add_child(column)
	for title: String in ["Resume", "Save checkpoint", "Load checkpoint", "New game", "Sensitivity +", "Sensitivity -", "Exit"]:
		var button := Button.new()
		button.text = title
		button.custom_minimum_size.y = 48
		column.add_child(button)
		button.pressed.connect(_menu_action.bind(title))
	menu.hide()

func _menu_action(title: String) -> void:
	match title:
		"Resume": _pause()
		"Save checkpoint": _save()
		"Load checkpoint": _load()
		"New game":
			memory = CityMemory.new()
			_leave_car()
			player.position = Vector3(0, 2, 12)
			player.velocity = Vector3.ZERO
			car.position = Vector3(4, 1.2, 4)
			car.rotation = Vector3.ZERO
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
			marker.show()
			_pause()
		"Sensitivity +": player.sensitivity = minf(0.01, player.sensitivity + 0.0005)
		"Sensitivity -": player.sensitivity = maxf(0.0005, player.sensitivity - 0.0005)
		"Exit": get_tree().quit()

func _pause() -> void:
	paused = not paused
	menu.visible = paused
	player.set_physics_process(not paused)
	car.set_physics_process(not paused)
	car.freeze = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_pause()
	if paused:
		return
	if event.is_action_pressed("save"):
		_save()
	if event.is_action_pressed("load"):
		_load()
	if event.is_action_pressed("interact"):
		_interact()
	if event.is_action_pressed("fire") and cooldown <= 0 and not player.driving:
		cooldown = 0.3
		memory.heat = minf(100, memory.heat + 15)
		var camera := player.camera
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 120)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider in targets:
			targets.erase(hit.collider)
			hit.collider.queue_free()
			_say("Training", "Target hit. Gunfire attracts attention.")

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	cooldown -= delta
	dialogue_time -= delta
	dialogue.visible = dialogue_time > 0
	if player.driving:
		player.global_position = car.global_position + Vector3(0, 1.5, 0)
	var observed: bool = player.position.distance_to(Vector3(12, 0, -95)) < 32
	if not observed:
		memory.heat = maxf(0, memory.heat - delta * 5)
	for i: int in range(civilians.size()):
		var civilian: Node3D = civilians[i]
		civilian.position.z += delta * (4 if memory.heat > 0 else 0.8) * (1 if i % 2 == 0 else -1)
		if absf(civilian.position.z + 60) > 110:
			civilian.position.z = -60
	if memory.stage < mission.stages.size():
		var stage: Dictionary = mission.stages[memory.stage]
		var at := Vector3(stage.position[0], 0, stage.position[2])
		marker.position = at + Vector3(0, 2 + sin(elapsed * 2) * 0.3, 0)
		if stage.kind == "drive" and player.driving and player.position.distance_to(at) < 15:
			_advance()
		elif stage.kind == "escape" and memory.heat <= 0:
			_advance()
		var distance: int = int(player.position.distance_to(at))
		hud.text = "OUTLAW SYNDICATE  /  IRON HARBOR\nThe Last Address\n%s  [%dm]\n$%d  |  SEARCH %d%%\nWASD move / drive · Mouse look · Shift sprint · Space jump / brake\nE interact / car · Click fire · F5 save · F9 load · Esc pause" % [stage.objective, distance, memory.money, int(memory.heat)]
	else:
		marker.hide()
		hud.text = "THE LAST ADDRESS — COMPLETE\n$%d · Mara's evidence preserved\nFirst mission blockout complete. Remaining campaign is not implemented.\nExplore Iron Harbor · F5 save · Esc menu" % memory.money

func _interact() -> void:
	if memory.stage < mission.stages.size():
		var stage: Dictionary = mission.stages[memory.stage]
		var at := Vector3(stage.position[0], player.position.y, stage.position[2])
		if stage.kind == "interact" and player.position.distance_to(at) < 5 and not player.driving:
			_advance()
			return
	if player.driving:
		if car.linear_velocity.length() < 3:
			_leave_car()
	elif player.position.distance_to(car.position) < 5:
		player.driving = true
		player.visual.hide()
		player.collision_layer = 0
		player.collision_mask = 0
		(player.pivot.get_child(0) as SpringArm3D).add_excluded_object(car.get_rid())
		car.occupied = true

func _leave_car() -> void:
	if player.driving:
		player.position = car.position + car.global_basis.x * 3 + Vector3.UP
	player.driving = false
	player.visual.show()
	player.collision_layer = 1
	player.collision_mask = 1
	car.occupied = false
	(player.pivot.get_child(0) as SpringArm3D).remove_excluded_object(car.get_rid())

func _advance() -> void:
	var stage: Dictionary = mission.stages[memory.stage]
	_say(stage.speaker, stage.line)
	memory.remember("ACT1_01_stage_%d" % memory.stage, {"district": "iron_harbor"})
	memory.stage += 1
	if memory.stage == 3:
		memory.heat = 100
	if memory.stage == 5:
		memory.remember("mara_ledger_preserved", {"reward": int(mission.reward), "relationship_dante": 1})
	_save()

func _say(speaker: String, line: String) -> void:
	dialogue.text = "%s: %s" % [speaker, line]
	dialogue_time = 9

func _save() -> void:
	var data := memory.snapshot()
	data["player"] = [player.position.x, player.position.y, player.position.z]
	data["car"] = [car.position.x, car.position.y, car.position.z]
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_say("Save", "Unable to write checkpoint.")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var error := DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)
	if error != OK:
		_say("Save", "Checkpoint replacement failed; previous save retained.")

func _load() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var data: Variant = parser.data
		if not data is Dictionary or not memory.restore(data):
			continue
		_leave_car()
		var p: Array = data.get("player", [0, 2, 12])
		if p.size() == 3:
			player.position = Vector3(float(p[0]), float(p[1]) + 0.3, float(p[2]))
		var c: Array = data.get("car", [4, 2, 4])
		if c.size() == 3:
			car.position = Vector3(float(c[0]), float(c[1]) + 0.3, float(c[2]))
		car.linear_velocity = Vector3.ZERO
		car.angular_velocity = Vector3.ZERO
		marker.show()
		_say("Checkpoint", "Restored. The city remembers.")
		return
	_say("Checkpoint", "No valid save or backup found.")
