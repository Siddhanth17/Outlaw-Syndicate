extends Node3D

const SAVE_PATH: String = "user://veyra-save.json"
var memory := CityMemory.new()
var player: ValePlayer
var car: VeyraCar
var ui: GameHUD
var harbor: IronHarbor
var marker: MeshInstance3D
var mission: Dictionary
var targets: Array[StaticBody3D] = []
var guards: Array[HarborGuard] = []
var cooldown: float = 0
var dialogue_time: float = 0
var elapsed: float = 0
var paused: bool = false
var test_mode: bool = false
var ammunition: int = 12
var reserve: int = 72
var reload_time: float = 0
var quality: int = 1
var subtitles_enabled: bool = true
var cinematic_active: bool = false
var cinematic_time: float = 0
var closing: bool = false
var cine_camera: Camera3D
var dante: Node3D
var faction_rep: int = 0
var return_screen: String = "pause"
var ambience: AudioStreamPlayer
var dante_dynamics: HumanDynamics

func _ready() -> void:
	test_mode = OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("--headless")
	_setup_input()
	mission = JSON.parse_string(FileAccess.get_file_as_string("res://data/homecoming.json"))
	harbor = IronHarbor.new()
	add_child(harbor)
	player = ValePlayer.new()
	add_child(player)
	player.position = Vector3(0, 1, 12)
	car = VeyraCar.new()
	add_child(car)
	car.position = Vector3(4, 1.2, 4)
	car.rotation.y = PI
	ui = GameHUD.new()
	add_child(ui)
	ui.command.connect(_menu_action)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.60
	ring.outer_radius = 0.72
	marker.mesh = ring
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.57, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.32, 0.05)
	mat.emission_energy_multiplier = 2
	marker.material_override = mat
	add_child(marker)
	dante = load("res://assets/characters/adrian.glb").instantiate()
	dante.position = Vector3(-1.4, 0.05, -1)
	dante.rotation.y = 0.7
	add_child(dante)
	var dante_skeletons := dante.find_children("*", "Skeleton3D", true, false)
	if not dante_skeletons.is_empty():
		dante_dynamics = HumanDynamics.new()
		dante_dynamics.actor = dante
		dante_skeletons[0].add_child(dante_dynamics)
		dante_dynamics.reset_state()
	var players := dante.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var animation: AnimationPlayer = players[0]
		for name: String in animation.get_animation_list():
			if name.ends_with("Idle"):
				animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
				animation.play(name)
	cine_camera = Camera3D.new()
	add_child(cine_camera)
	cine_camera.fov = 48
	_load_settings()
	ambience = AudioStreamPlayer.new()
	ambience.stream = _loop("harbor")
	ambience.volume_db = -20
	add_child(ambience)
	if DisplayServer.get_name() != "headless": ambience.play()
	if test_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_set_pause(true, "main")
	if OS.get_cmdline_user_args().has("--verify-realism"):
		var verifier := RuntimeVerification.new()
		verifier.game = self
		add_child(verifier)

func _setup_input() -> void:
	GameInputs.install()

func _loop(name: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = load("res://assets/audio/" + name + ".wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	return stream

func sound(name: String, at: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	var source := AudioStreamPlayer3D.new()
	source.stream = load("res://assets/audio/" + name + ".wav")
	source.position = at
	source.unit_size = 12
	source.volume_db = -9
	add_child(source)
	source.finished.connect(source.queue_free)
	source.play()

func _menu_action(title: String) -> void:
	match title:
		"Resume": _set_pause(false)
		"Back": ui.show_screen(return_screen)
		"Save checkpoint": _save()
		"Load checkpoint", "Continue", "Retry checkpoint":
			_load()
			_set_pause(false)
		"New game":
			memory = CityMemory.new()
			faction_rep = 0
			reload_time = 0
			cooldown = 0
			_leave_car()
			player.position = Vector3(0, 1, 12)
			player.velocity = Vector3.ZERO
			player.health = 100
			ammunition = 12
			reserve = 72
			car.integrity = 100
			car.position = Vector3(4, 1.2, 4)
			car.rotation = Vector3(0, PI, 0)
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
			car.last_velocity = Vector3.ZERO
			car.throttle_smoothed = 0
			_clear_guards()
			harbor.consequence(false)
			marker.show()
			_set_pause(false)
			_start_cinematic(false)
		"Settings", "Controls", "Credits":
			return_screen = ui.current_screen
			ui.show_screen(title.to_lower())
		"Main menu": _set_pause(true, "main")
		"Driving course":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/driving_course.tscn")
		"Human Motion Laboratory":
			get_tree().change_scene_to_file("res://scenes/human_motion_laboratory.tscn")
		"Sensitivity +": player.sensitivity = minf(0.01, player.sensitivity + 0.0005)
		"Sensitivity -": player.sensitivity = maxf(0.0005, player.sensitivity - 0.0005)
		"Graphics: Low": quality = 0
		"Graphics: Balanced": quality = 1
		"Graphics: High": quality = 2
		"Subtitles toggle": subtitles_enabled = not subtitles_enabled
		"Reduced shake toggle": player.reduced_shake = not player.reduced_shake
		"Exit": get_tree().quit()
	harbor.preset(quality)
	_save_settings()

func _set_pause(value: bool, screen: String = "pause") -> void:
	paused = value
	player.set_physics_process(not paused and not cinematic_active)
	car.set_physics_process(not paused and not cinematic_active)
	car.freeze = paused or cinematic_active
	ui.show_screen(screen if paused else "")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	_set_pause(not paused)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skip") and cinematic_active:
		_end_cinematic()
		return
	if event.is_action_pressed("pause"):
		_pause()
	if paused or cinematic_active:
		return
	if event.is_action_pressed("save"): _save()
	if event.is_action_pressed("load"): _load()
	if event.is_action_pressed("interact"): _interact()
	if event.is_action_pressed("reload"): _reload()
	if event.is_action_pressed("fire"): _fire()

func _reload() -> void:
	if reload_time <= 0 and ammunition < 12 and reserve > 0:
		reload_time = 1.5
		player.perform("Reload", 1.5)
		sound("reload", player.position)

func _fire() -> void:
	if cooldown > 0 or reload_time > 0 or player.driving:
		return
	if ammunition <= 0:
		_reload()
		return
	ammunition -= 1
	cooldown = 0.28
	player.perform("Shoot", 0.25)
	memory.heat = minf(100, memory.heat + 15)
	sound("shot", player.position)
	var camera := player.camera
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 100)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider is HarborGuard:
			hit.collider.take_damage(35)
			faction_rep -= 1
		var flash := OmniLight3D.new()
		flash.position = hit.position
		flash.light_color = Color(1, 0.55, 0.2)
		flash.light_energy = 2
		flash.omni_range = 1.3
		add_child(flash)
		get_tree().create_timer(0.08).timeout.connect(flash.queue_free)
	var muzzle := OmniLight3D.new()
	muzzle.position = player.position + Vector3(0, 1.2, 0)
	muzzle.light_color = Color(1, 0.7, 0.4)
	muzzle.light_energy = 3
	muzzle.omni_range = 2
	add_child(muzzle)
	get_tree().create_timer(0.06).timeout.connect(muzzle.queue_free)
	if not player.reduced_shake:
		player.pitch += 0.015

func damage_player(amount: float, direction: Vector3 = Vector3.ZERO) -> void:
	if paused or cinematic_active:
		return
	if player.driving:
		car.integrity = maxf(0, car.integrity - amount * 0.4)
	else:
		player.health = maxf(0, player.health - amount)
		if player.dynamics: player.dynamics.impact += direction * minf(amount * 0.3, 6)
	if player.health <= 0:
		_set_pause(true, "defeat")

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	if cinematic_active:
		_update_cinematic(delta)
		return
	cooldown -= delta
	dialogue_time -= delta
	ui.subtitle_panel.visible = dialogue_time > 0 and subtitles_enabled
	if reload_time > 0:
		reload_time -= delta
		if reload_time <= 0:
			var amount: int = mini(12 - ammunition, reserve)
			ammunition += amount
			reserve -= amount
	if player.driving:
		player.global_position = car.global_position + Vector3(0, 0.4, 0)
		player.visual.global_transform = car.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.38, -0.8, 0))
	if player.dynamics:
		player.dynamics.wind = harbor.wind_vector
		player.dynamics.has_head_target = not player.driving and player.position.distance_to(dante.position) < 6
		player.dynamics.head_target = dante.position + Vector3.UP * 1.5
	if dante_dynamics:
		dante_dynamics.active = player.position.distance_to(dante.position) < 30
		dante_dynamics.wind = harbor.wind_vector
		dante_dynamics.has_head_target = player.position.distance_to(dante.position) < 6
		dante_dynamics.head_target = player.position + Vector3.UP * 1.5
	var observed: bool = player.position.distance_to(Vector3(12, 0, -95)) < 32
	for guard: HarborGuard in guards:
		if is_instance_valid(guard) and guard.state == HarborGuard.State.ENGAGE:
			observed = true
	if not observed:
		memory.heat = maxf(0, memory.heat - delta * 5)
	if memory.stage < mission.stages.size():
		var stage: Dictionary = mission.stages[memory.stage]
		var at := Vector3(stage.position[0], 0, stage.position[2])
		marker.position = at + Vector3(0, 0.12, 0)
		if stage.kind == "drive" and player.driving and player.position.distance_to(at) < 15:
			_advance()
		elif stage.kind == "escape" and memory.heat <= 0:
			_advance()
		ui.objective.text = "%s\n%d m" % [stage.objective, int(player.position.distance_to(at))]
	else:
		marker.hide()
		ui.objective.text = "Evidence secured.\nThe Last Address complete."
	ui.status.text = "IRON HARBOR\n$%d  /  SEARCH %d%%" % [memory.money, int(memory.heat)]
	ui.health.value = player.health
	ui.ammo.text = ("%03d KM/H  /  %s" % [int(car.linear_velocity.length() * 3.6), car.damage_stage()]) if player.driving else ("RELOADING" if reload_time > 0 else "SIDEARM  %02d / %02d" % [ammunition, reserve])
	ui.prompt.text = ""
	if player.driving:
		ui.prompt.text = "[E] Exit vehicle" if car.linear_velocity.length() < 3 else ""
	elif player.position.distance_to(car.position) < 5:
		ui.prompt.text = "[E] Drive Sable GT"
	elif marker.visible and player.position.distance_to(marker.position) < 5:
		ui.prompt.text = "[E] Interact"
	ui.crosshair.visible = player.aiming and not player.driving

func _interact() -> void:
	if memory.stage < mission.stages.size():
		var stage: Dictionary = mission.stages[memory.stage]
		var at := Vector3(stage.position[0], player.position.y, stage.position[2])
		if stage.kind == "interact" and player.position.distance_to(at) < 5 and not player.driving:
			player.perform("Interact", 0.9)
			_advance()
			return
	if player.driving:
		if car.linear_velocity.length() < 3:
			_leave_car()
	elif player.position.distance_to(car.position) < 5:
		player.driving = true
		player.vehicle = car
		player.visual.show()
		player.perform("Drive", 99999)
		if player.dynamics: player.dynamics.reset_state()
		player.collision_layer = 0
		player.collision_mask = 0
		player.arm.add_excluded_object(car.get_rid())
		car.occupied = true
		player.yaw = car.rotation.y + PI
		player.pitch = -0.16

func _leave_car() -> void:
	if player.driving:
		player.position = car.position + car.global_basis.x * 2 + Vector3.UP * 0.2
		var query := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * 2, player.position - Vector3.UP * 4)
		query.exclude = [car.get_rid(), player.get_rid()]
		var ground := get_world_3d().direct_space_state.intersect_ray(query)
		if not ground.is_empty(): player.position.y = ground.position.y + 0.05
	player.driving = false
	player.visual.transform = Transform3D.IDENTITY
	if player.dynamics: player.dynamics.reset_state()
	player.visual.show()
	player.collision_layer = 1
	player.collision_mask = 1
	car.occupied = false
	player.arm.remove_excluded_object(car.get_rid())
	player.perform("Exit", 0.6)

func _clear_guards() -> void:
	for guard: HarborGuard in guards:
		guard.queue_free()
	guards.clear()

func _spawn_guards() -> void:
	_clear_guards()
	for i: int in range(2):
		var id: String = "HarborGuard%d" % i
		if memory.events.has("guard_defeated_" + id): continue
		var guard := HarborGuard.new()
		guard.name = id
		guard.game = self
		guard.position = Vector3(9 + i * 4, 0.3, -105 - i * 5)
		add_child(guard)
		guards.append(guard)

func _advance() -> void:
	var stage: Dictionary = mission.stages[memory.stage]
	_say(stage.speaker, stage.line)
	memory.remember("ACT1_01_stage_%d" % memory.stage, {"district": "iron_harbor"})
	memory.stage += 1
	if memory.stage == 3:
		memory.heat = 100
		memory.remember("ledger_security_alert", {"district": "iron_harbor", "faction": "rell_security", "reputation": -2})
		harbor.consequence(true)
		_spawn_guards()
	if memory.stage == 5:
		memory.remember("mara_ledger_preserved", {"reward": int(mission.reward), "relationship_dante": 1})
		if memory.remember("dante_garage_repair", {"relationship": "dante", "repair": 25}):
			car.integrity = minf(100, car.integrity + 25)
		if not test_mode: _start_cinematic(true)
	_save()

func _say(speaker: String, line: String) -> void:
	ui.subtitles.text = "%s — %s" % [speaker, line]
	dialogue_time = 9
	ui.subtitle_panel.visible = subtitles_enabled

func _start_cinematic(is_closing: bool) -> void:
	closing = is_closing
	cinematic_active = true
	cinematic_time = 0
	player.set_physics_process(false)
	car.set_physics_process(false)
	car.freeze = true
	cine_camera.current = true
	if not closing:
		player.position = Vector3(0, 0.05, 12)
	ui.prompt.text = ""
	ui.ammo.text = ""
	ui.status.text = ""
	ui.crosshair.hide()
	ui.health.hide()
	ui.objective.text = "THE LAST ADDRESS\n[Enter / A] Skip"
	_say("Dante" if closing else "Adrian", "I'll hide the car. You find Elena. Whatever Mara found, we finish it together." if closing else "Three years away. One message from Mara. Then nothing. Dante's garage is my last address.")

func _update_cinematic(delta: float) -> void:
	cinematic_time += delta
	var t: float = clampf(cinematic_time / 8, 0, 1)
	cine_camera.position = Vector3(7, 3.2, 13).lerp(Vector3(3, 1.8, 3.8), t)
	cine_camera.look_at(Vector3(-0.4, 1.2, -0.5))
	if cinematic_time > 8: _end_cinematic()

func _end_cinematic() -> void:
	cinematic_active = false
	player.camera.current = true
	player.set_physics_process(not paused)
	car.set_physics_process(not paused)
	car.freeze = paused
	ui.health.show()

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "preset", quality)
	config.set_value("controls", "sensitivity", player.sensitivity)
	config.set_value("accessibility", "subtitles", subtitles_enabled)
	config.set_value("accessibility", "reduced_shake", player.reduced_shake)
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		quality = clampi(int(config.get_value("graphics", "preset", 1)), 0, 2)
		player.sensitivity = clampf(float(config.get_value("controls", "sensitivity", 0.0025)), 0.0005, 0.01)
		subtitles_enabled = bool(config.get_value("accessibility", "subtitles", true))
		player.reduced_shake = bool(config.get_value("accessibility", "reduced_shake", true))
	harbor.preset(quality)

func _save() -> void:
	var data := memory.snapshot()
	data["player"] = [player.position.x, player.position.y, player.position.z]
	data["car"] = [car.position.x, car.position.y, car.position.z]
	data["car_yaw"] = car.rotation.y
	data["integrity"] = car.integrity
	data["health"] = player.health
	data["ammunition"] = ammunition
	data["reserve"] = reserve
	data["faction_rep"] = faction_rep
	data["driving"] = player.driving
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_say("Save", "Unable to write checkpoint.")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	if DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) != OK:
		_say("Save", "Checkpoint replacement failed; previous save retained.")

func _load() -> void:
	for path: String in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK: continue
		var data: Variant = parser.data
		if not data is Dictionary: continue
		var valid: bool = true
		for key: String in ["player", "car"]:
			var value: Variant = data.get(key)
			if not value is Array or value.size() != 3:
				valid = false
				break
			for component: Variant in value:
				if not (component is float or component is int) or not is_finite(float(component)) or absf(float(component)) > 10000:
					valid = false
		if not valid or not memory.restore(data): continue
		_leave_car()
		var p: Array = data.player
		var c: Array = data.car
		car.position = Vector3(float(c[0]), float(c[1]) + 0.15, float(c[2]))
		car.rotation.y = float(data.get("car_yaw", PI))
		player.position = Vector3(float(p[0]), float(p[1]) + 0.15, float(p[2]))
		if data.get("driving", false): player.position = car.position + car.global_basis.x * 2 + Vector3.UP
		car.linear_velocity = Vector3.ZERO
		car.angular_velocity = Vector3.ZERO
		player.velocity = Vector3.ZERO
		if player.dynamics: player.dynamics.reset_state()
		car.integrity = clampf(float(data.get("integrity", 100)), 0, 100)
		player.health = clampf(float(data.get("health", 100)), 1, 100)
		ammunition = clampi(int(data.get("ammunition", 12)), 0, 12)
		reserve = maxi(0, int(data.get("reserve", 72)))
		faction_rep = int(data.get("faction_rep", 0))
		reload_time = 0
		harbor.consequence(memory.stage >= 3)
		_clear_guards()
		if memory.stage == 3: _spawn_guards()
		marker.show()
		_say("Checkpoint", "Restored. The city remembers.")
		return
	_say("Checkpoint", "No valid save or backup found.")

func _exit_tree() -> void:
	if is_instance_valid(ambience): ambience.stop()
