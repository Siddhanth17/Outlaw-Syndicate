extends Node3D

const SAVE_PATH: String = "user://veyra-save.json"
var vehicle_transition: VehicleTransition
var character_impacts: CharacterImpacts
var events: CityEvents
var navigation: CityNavigation
var people: Array[CityNPC]=[]
var memory := CityMemory.new()
var player: ValePlayer
var parked_vehicles: Array[VeyraCar]=[]
var bike: HarborMotorcycle
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
var dialogue_volume: float=-6
var movement_volume: float=-5
var subtitles_enabled: bool = true
var cinematic_active: bool = false
var cinematic_time: float = 0
var closing: bool = false
var cine_camera: Camera3D
var dante: Node3D
var faction_rep: int = 0
var return_screen: String = "pause"
var ambience: AudioStreamPlayer
var crash_interest: Vector3
var crash_interest_time: float = 0
var dialogue_director: DialogueDirector
var dante_dynamics: HumanDynamics
var story_active: bool = true # Legacy checkpoints keep their mission progression.
var phone: HarborPhone
var quarter: VeyraQuarter
var traffic: StreetTraffic
var living: LivingWorld
var city_audio: CityAudio

func start_story() -> void:
	if story_active: return
	story_active=true
	marker.show()
	_say("The Last Address","Meet Dante at the garage when you're ready.")

func _ready() -> void:
	test_mode = OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("--headless")
	_setup_input()
	city_audio=CityAudio.new()
	add_child(city_audio)
	mission = JSON.parse_string(FileAccess.get_file_as_string("res://data/homecoming.json"))
	events=CityEvents.new()
	events.game=self
	add_child(events)
	navigation=CityNavigation.new()
	add_child(navigation)
	harbor = IronHarbor.new()
	add_child(harbor)
	character_impacts=CharacterImpacts.new()
	add_child(character_impacts)
	player = ValePlayer.new()
	add_child(player)
	player.position = Vector3(0, 1, 12)
	car = VeyraCar.new()
	car.position = Vector3(4, 1.2, 4)
	car.rotation.y = PI
	add_child(car)
	car.crashed.connect(_on_crash)
	bike=HarborMotorcycle.new()
	bike.game=self
	bike.position=Vector3(-5,0.8,10)
	add_child(bike)
	quarter=VeyraQuarter.new()
	quarter.game=self
	add_child(quarter)
	traffic=StreetTraffic.new()
	traffic.game=self
	add_child(traffic)
	for location: Vector3 in [Vector3(-87,0.9,12),Vector3(86,0.9,-72)]:
		var parked:=VeyraCar.new()
		parked.position=location
		parked.rotation.y=PI/2
		add_child(parked)
		parked_vehicles.append(parked)
	ui = GameHUD.new()
	add_child(ui)
	ui.command.connect(_menu_action)
	phone=HarborPhone.new()
	phone.game=self
	add_child(phone)
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
	var named:=CityNPC.new()
	named.game=self
	named.appearance_id="dante"
	named.npc_id="dante_cross"
	named.story_actor=true
	named.name="DanteCross"
	named.position=Vector3(-1.4,0.05,-1)
	dante=named
	add_child(dante)
	dante_dynamics=named.dynamics
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
	dialogue_director = DialogueDirector.new()
	dialogue_director.game = self
	add_child(dialogue_director)
	vehicle_transition=VehicleTransition.new()
	vehicle_transition.game=self
	add_child(vehicle_transition)
	living=LivingWorld.new()
	living.game=self
	add_child(living)
	if OS.get_cmdline_user_args().has("--city-debug"):
		var debug:=CityDiagnostics.new()
		debug.game=self
		add_child(debug)
	_load_settings()
	call_deferred("_populate_city")
	ambience = AudioStreamPlayer.new()
	ambience.bus="Environment"
	ambience.stream = _loop("harbor")
	ambience.volume_db = -20
	add_child(ambience)
	if DisplayServer.get_name() != "headless": ambience.play()
	if test_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		_set_pause(true, "main")
	if OS.get_cmdline_user_args().has("--verify-ragdoll"):
		var validation:=RagdollValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-metropolis"):
		var validation:=MetropolisValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-urban"):
		var validation:=UrbanValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-living-world"):
		var validation:=LivingWorldValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--audit-motion"):
		var audit:=MotionAudit.new()
		audit.game=self
		add_child(audit)
		audit.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-veyra3"):
		var validation:=Veyra3Validation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-mobility"):
		var validation:=MobilityValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-city"):
		var validation:=LivingValidation.new()
		validation.game=self
		add_child(validation)
		validation.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-mission"):
		var route := MissionRouteValidation.new()
		route.game = self
		add_child(route)
		route.call_deferred("run")
	if OS.get_cmdline_user_args().has("--verify-physics"):
		var verifier := PhysicsValidation.new()
		verifier.game = self
		add_child(verifier)
		verifier.call_deferred("run")
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
	if name=="shot":
		city_audio.fire(at)
		return
	if DisplayServer.get_name() == "headless": return
	var source := AudioStreamPlayer3D.new()
	source.stream = load("res://assets/audio/" + name + ".wav")
	source.position = at
	source.unit_size = 12
	source.volume_db = -9
	source.bus="UI" if name.begins_with("living/") else "Environment"
	add_child(source)
	source.finished.connect(source.queue_free)
	source.play()

func _menu_action(title: String) -> void:
	for bus: String in CityAudio.BUSES:
		if title==bus+" mix +" or title==bus+" mix -":
			city_audio.adjust(bus,2 if title.ends_with("+") else -2)
			return
	match title:
		"Resume": _set_pause(false)
		"Back": ui.show_screen(return_screen)
		"Save checkpoint": _save()
		"Load checkpoint", "Continue", "Retry checkpoint":
			_load()
			_set_pause(false)
		"New game":
			phone.close()
			story_active=false
			quarter.minutes=1080
			quarter.day=1
			quarter.apply_clock()
			phone.photos.clear()
			phone.reset_social()
			if dialogue_director.active: dialogue_director.stop()
			_end_cinematic()
			character_impacts.reset()
			memory = CityMemory.new()
			events.recent.clear()
			for citizen: CityNPC in people: citizen.restore_outcome(70)
			if dante is CityNPC: dante.restore_outcome(70)
			faction_rep = 0
			reload_time = 0
			cooldown = 0
			_leave_car(true)
			bike.position=Vector3(-5,0.8,10)
			bike.linear_velocity=Vector3.ZERO
			bike.angular_velocity=Vector3.ZERO
			player.position = Vector3(0, 1, 12)
			player.velocity = Vector3.ZERO
			player.health = 100
			player.injuries.restore([])
			ammunition = 12
			reserve = 72
			car.repair()
			car.position = Vector3(4, 1.2, 4)
			car.rotation = Vector3(0, PI, 0)
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
			car.last_velocity = Vector3.ZERO
			car.throttle_smoothed = 0
			car.reset_pose(Transform3D(Basis(Vector3.UP,PI),Vector3(4,1.2,4)))
			_clear_guards()
			harbor.consequence(false)
			marker.show()
			_set_pause(false)
			marker.hide()
			living.restore(null)
			_say("Free roam","Explore Iron Harbor. Open your phone [%s] to choose when to start The Last Address."%phone.key_label())
		"Settings", "Controls", "Credits":
			return_screen = ui.current_screen
			ui.show_screen(title.to_lower())
		"Main menu": _set_pause(true, "main")
		"Driving course":
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/driving_course.tscn")
		"Crash Test Facility":
			get_tree().change_scene_to_file("res://scenes/crash_facility.tscn")
		"Articulated Physics Laboratory":
			get_tree().change_scene_to_file("res://scenes/ragdoll_lab.tscn")
		"Movement Audio Laboratory":
			get_tree().change_scene_to_file("res://scenes/movement_audio_lab.tscn")
		"Living City Laboratory":
			get_tree().change_scene_to_file("res://scenes/living_city_lab.tscn")
		"Human Motion Laboratory":
			get_tree().change_scene_to_file("res://scenes/human_motion_laboratory.tscn")
		"Impact effects: Off": character_impacts.density=0
		"Impact effects: Low": character_impacts.density=0.3
		"Impact effects: Normal": character_impacts.density=0.6
		"Movement volume +": movement_volume=minf(0,movement_volume+2)
		"Movement volume -": movement_volume=maxf(-40,movement_volume-2)
		"Dialogue volume +": dialogue_volume=minf(0,dialogue_volume+2)
		"Dialogue volume -": dialogue_volume=maxf(-30,dialogue_volume-2)
		"Sensitivity +": player.sensitivity = minf(0.01, player.sensitivity + 0.0005)
		"Sensitivity -": player.sensitivity = maxf(0.0005, player.sensitivity - 0.0005)
		"Graphics: Low": quality = 0
		"Graphics: Balanced": quality = 1
		"Graphics: High": quality = 2
		"Subtitles toggle": subtitles_enabled = not subtitles_enabled
		"Reduced shake toggle": player.reduced_shake = not player.reduced_shake
		"Phone key: Tab": phone.bind_key(KEY_TAB)
		"Phone key: O": phone.bind_key(KEY_O)
		"Time: Day": quarter.minutes=720; quarter.apply_clock()
		"Time: Night": quarter.minutes=60; quarter.apply_clock()
		"Exit": get_tree().quit()
	harbor.preset(quality)
	dialogue_director.audio.volume_db=dialogue_volume
	player.movement_audio.volume_db=movement_volume
	_save_settings()

func _set_pause(value: bool, screen: String = "pause") -> void:
	paused = value
	if is_instance_valid(phone) and phone.opened: phone.close()
	player.camera_input_enabled = not paused and not cinematic_active
	harbor.pause_props(paused or cinematic_active)
	player.set_physics_process(not paused and not cinematic_active)
	car.set_physics_process(not paused and not cinematic_active)
	car.freeze = paused or cinematic_active or (is_instance_valid(vehicle_transition) and vehicle_transition.active)
	for parked: VeyraCar in parked_vehicles:
		parked.freeze=paused or cinematic_active
		parked.set_physics_process(not paused and not cinematic_active)
	bike.freeze=paused or cinematic_active or bike.mounting
	bike.set_physics_process(not paused and not cinematic_active)
	ui.show_screen(screen if paused else "")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	_set_pause(not paused)

func _input(event: InputEvent) -> void:
	# Handle the binding before GUI focus consumes Tab as focus-next.
	if event.is_action_pressed("phone") and not event.is_echo() and not paused and not cinematic_active:
		phone.toggle()
		get_viewport().set_input_as_handled()
	elif phone.opened and event.is_action_pressed("pause"):
		_pause()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if phone.opened and not event.is_action_pressed("pause"): return
	if event.is_action_pressed("skip") and cinematic_active:
		if dialogue_director.active: dialogue_director.stop()
		else: _end_cinematic()
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
	if player.riding_bike or bike.mounting:return
	if is_instance_valid(vehicle_transition) and vehicle_transition.active:return
	if cooldown > 0 or reload_time > 0 or player.driving:
		return
	if ammunition <= 0:
		_reload()
		return
	ammunition -= 1
	cooldown = 0.28
	player.perform("Shoot", 0.25)
	player.apply_recoil()
	memory.heat = minf(100, memory.heat + 15)
	sound("shot", player.position)
	events.publish("gunshot",player.position,35,"player")
	var camera := player.camera
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 100)
	query.exclude = [player.get_rid()]
	query.collision_mask=CollisionLayers.STATIC|CollisionLayers.NPC|CollisionLayers.PROP|CollisionLayers.PROJECTILE|CollisionLayers.RAGDOLL
	query.collide_with_areas=true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider is HarborPhysicalBone:
			hit.collider.driver.nudge(hit.collider,-camera.global_basis.z*2.0)
		elif hit.collider is HarborGuard:
			hit.collider.take_damage(35, -camera.global_basis.z, hit.position)
			if hit.collider.get_meta("civilian",false): memory.heat=minf(100,memory.heat+8)
			else: faction_rep -= 1
		elif hit.collider is VehicleHitRegion:
			hit.collider.receive_hit(hit.position,-camera.global_basis.z,35)
		elif hit.collider is VeyraCar:
			hit.collider.receive_bullet(hit.position, -camera.global_basis.z, 35)
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
		if player.injuries: player.injuries.hit(player.global_position+Vector3.UP*1.3,amount)
		if player.dynamics: player.dynamics.impact += direction * minf(amount * 0.3, 6)
	if player.health <= 0:
		_set_pause(true, "defeat")

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	crash_interest_time = maxf(0, crash_interest_time-delta)
	if cinematic_active:
		if dialogue_director.active: return
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
	if player.driving and not vehicle_transition.active:
		player.global_position = car.global_position + Vector3(0, 0.4, 0)
		player.visual.global_transform = car.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.38, -0.8, 0))
	if player.dynamics:
		player.dynamics.wind = harbor.wind_vector
		player.dynamics.has_head_target = not player.driving and not player.riding_bike and player.position.distance_to(dante.position) < 6
		player.dynamics.head_target = dante.position + Vector3.UP * 1.5
	if dante_dynamics:
		dante_dynamics.active = player.position.distance_to(dante.position) < 30
		dante_dynamics.wind = harbor.wind_vector
		dante_dynamics.has_head_target = crash_interest_time>0 or player.position.distance_to(dante.position) < 6
		dante_dynamics.head_target = crash_interest if crash_interest_time>0 else player.position + Vector3.UP * 1.5
	var observed: bool = player.position.distance_to(Vector3(12, 0, -95)) < 32
	for guard: HarborGuard in guards:
		if is_instance_valid(guard) and guard.state == HarborGuard.State.ENGAGE:
			observed = true
	if not observed:
		memory.heat = maxf(0, memory.heat - delta * 5)
	var district: String="NORTHLINE" if player.position.z>65 else "IRON HARBOR"
	if not story_active:
		marker.hide()
		ui.objective_title.text=district+" / FREE ROAM"
		ui.objective.text="Explore at your own pace.\n[%s] Phone • choose your story"%phone.key_label()
	elif memory.stage < mission.stages.size():
		ui.objective_title.text="THE LAST ADDRESS"
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
	ui.status.text = "%s / %02d:%02d\n$%d  /  SEARCH %d%%" % [district,int(quarter.minutes)/60,int(quarter.minutes)%60,memory.money, int(memory.heat)]
	ui.health.value = player.health
	ui.ammo.text = ("%03d KM/H  /  %s" % [int(car.linear_velocity.length() * 3.6), car.damage_stage()]) if player.driving else ("RELOADING" if reload_time > 0 else "SIDEARM  %02d / %02d" % [ammunition, reserve])
	ui.prompt.text = ""
	if player.driving:
		ui.prompt.text = "[E] Exit vehicle" if car.linear_velocity.length() < 3 else ""
	elif player.position.distance_to(car.position) < 5:
		ui.prompt.text = "[E] Drive Sable GT"
	elif marker.visible and player.position.distance_to(marker.position) < 5:
		ui.prompt.text = "[E] Interact"
	elif not story_active and player.position.distance_to(dante.position)<4:
		ui.prompt.text="[E] Talk to Dante Cross • mechanic"
	elif living.roster_ready:
		var resident: CityNPC=living.interaction_target()
		if resident:ui.prompt.text="[E] Speak to "+living.identities[resident.npc_id].name
	if vehicle_transition.active: ui.prompt.text="Vehicle interaction: "+vehicle_transition.phase
	if player.riding_bike:
		ui.ammo.text="HARRIER / %03d KM/H"%int(bike.linear_velocity.length()*3.6)
		ui.prompt.text="[E] Dismount Harrier" if bike.linear_velocity.length()<2 else ""
	elif not player.driving and player.position.distance_to(bike.position)<3:
		ui.prompt.text="[E] Ride Harrier motorcycle"
	ui.crosshair.visible = player.aiming and not player.driving and not player.riding_bike

func _interact() -> void:
	if vehicle_transition.active or bike.mounting:return
	if not story_active and not player.driving and not player.riding_bike and player.position.distance_to(dante.position)<4:
		phone.talk_to_dante()
		return
	if bike.rider!=null:
		bike.interact()
		return
	if story_active and memory.stage < mission.stages.size():
		var stage: Dictionary = mission.stages[memory.stage]
		var at := Vector3(stage.position[0], player.position.y, stage.position[2])
		if stage.kind == "interact" and player.position.distance_to(at) < 5 and not player.driving:
			if stage.speaker=="Dante" and dante is HarborGuard and dante.state in [HarborGuard.State.STAGGER,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER]:
				_say("Adrian","Give him a moment to recover.")
				return
			player.perform("Interact", 0.9)
			var greeting: bool = memory.stage == 0
			_advance()
			if greeting and not test_mode: dialogue_director.start(false)
			return
	if not player.driving and player.position.distance_to(bike.position)<3 and player.position.distance_to(bike.position)<player.position.distance_to(car.position):
		bike.interact()
		return
	if player.driving:
		if car.linear_velocity.length() < 3:
			_leave_car()
	elif player.position.distance_to(car.position) < 5:
		if not test_mode or vehicle_transition.force_animation:
			vehicle_transition.begin(true)
		else: _enter_car_immediate()
	elif living.roster_ready:
		var resident: CityNPC=living.interaction_target()
		if resident:phone.talk_to_resident(resident.npc_id)

func _enter_car_immediate() -> void:
	player.driving = true
	player.vehicle = car
	player.visual.show()
	player.perform("Drive", 99999)
	if player.dynamics: player.dynamics.reset_state()
	player.collision_layer = 0
	player.collision_mask = 0
	player.arm.add_excluded_object(car.get_rid())
	car.occupied = true
	player.camera_manual_time = 1.5

func _leave_car(force: bool = false) -> void:
	if force and is_instance_valid(bike) and bike.rider!=null:bike.release()
	if is_instance_valid(vehicle_transition):
		if force: vehicle_transition.cancel()
		elif vehicle_transition.active:return
		elif player.driving and (not test_mode or vehicle_transition.force_animation):
			vehicle_transition.begin(false)
			return
	if player.driving and not force:
		var found: bool = false
		for side: float in [2.0, -2.0, 2.8, -2.8]:
			var candidate: Vector3 = car.position + car.global_basis.x * side + Vector3.UP * 0.2
			var ray := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 2, candidate - Vector3.UP * 4)
			ray.exclude = [car.get_rid(), player.get_rid()]
			var ground := get_world_3d().direct_space_state.intersect_ray(ray)
			if ground.is_empty() or ground.normal.y < 0.7: continue
			candidate.y = ground.position.y + 0.06
			var shape := PhysicsShapeQueryParameters3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.31
			capsule.height = 1.8
			shape.shape = capsule
			shape.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 0.9)
			shape.collision_mask = CollisionLayers.SOLIDS
			shape.exclude = [car.get_rid(), player.get_rid()]
			if get_world_3d().direct_space_state.intersect_shape(shape).is_empty():
				player.position = candidate
				found = true
				break
		if not found:
			_say("Adrian", "The door is blocked. Move the car to a clear space.")
			return
	elif player.driving:
		player.position = car.position + car.global_basis.x * 2 + Vector3.UP * 0.2
		var query := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * 2, player.position - Vector3.UP * 4)
		query.exclude = [car.get_rid(), player.get_rid()]
		var ground := get_world_3d().direct_space_state.intersect_ray(query)
		if not ground.is_empty(): player.position.y = ground.position.y + 0.05
	if player.driving:
		car.add_collision_exception_with(player)
		player.add_collision_exception_with(car)
		get_tree().create_timer(0.25).timeout.connect(func() -> void:
			if is_instance_valid(player) and is_instance_valid(car) and not player.driving:
				car.remove_collision_exception_with(player)
				player.remove_collision_exception_with(car))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.driving = false
	player.camera_manual_time = 1.5
	player.visual.transform = Transform3D.IDENTITY
	if player.dynamics: player.dynamics.reset_state()
	player.visual.show()
	player.collision_layer = CollisionLayers.PLAYER
	player.collision_mask = CollisionLayers.SOLIDS
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
		guard.appearance_id="security" if i==0 else "faction"
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
			car.repair()
		if not test_mode: dialogue_director.start(true)
	_save()

func _say(speaker: String, line: String) -> void:
	ui.subtitles.text = "%s — %s" % [speaker, line]
	dialogue_time = 9
	ui.subtitle_panel.visible = subtitles_enabled

func _start_cinematic(is_closing: bool) -> void:
	closing = is_closing
	cinematic_active = true
	player.camera_input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
	if is_instance_valid(dialogue_director) and dialogue_director.active:
		dialogue_director.stop()
		return
	cinematic_active = false
	player.camera_input_enabled = not paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	player.camera.current = true
	player.set_physics_process(not paused)
	car.set_physics_process(not paused)
	car.freeze = paused
	ui.health.show()

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("effects","impact_density",character_impacts.density)
	config.set_value("audio","movement_db",movement_volume)
	config.set_value("audio","dialogue_db",dialogue_volume)
	config.set_value("graphics", "preset", quality)
	config.set_value("controls", "sensitivity", player.sensitivity)
	config.set_value("controls", "phone_key", phone.key_code)
	config.set_value("accessibility", "subtitles", subtitles_enabled)
	config.set_value("accessibility", "reduced_shake", player.reduced_shake)
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		phone.bind_key(int(config.get_value("controls","phone_key",KEY_TAB)))
		character_impacts.density=clampf(float(config.get_value("effects","impact_density",0.6)),0,1)
		movement_volume=clampf(float(config.get_value("audio","movement_db",-5)),-40,0)
		dialogue_volume=clampf(float(config.get_value("audio","dialogue_db",-6)),-30,0)
		quality = clampi(int(config.get_value("graphics", "preset", 1)), 0, 2)
		player.sensitivity = clampf(float(config.get_value("controls", "sensitivity", 0.0025)), 0.0005, 0.01)
		subtitles_enabled = bool(config.get_value("accessibility", "subtitles", true))
		player.reduced_shake = bool(config.get_value("accessibility", "reduced_shake", true))
	harbor.preset(quality)
	dialogue_director.audio.volume_db=dialogue_volume
	player.movement_audio.volume_db=movement_volume

func _save() -> void:
	if vehicle_transition.active or bike.mounting:
		_say("Checkpoint","Finish the vehicle interaction before saving.")
		return
	var data := memory.snapshot()
	data["open_world"]={"story_active":story_active,"photos":phone.photos,"dante_social":phone.social_snapshot()}
	data["city_minutes"]=quarter.minutes
	data["city_day"]=quarter.day
	data["living_world"]=living.snapshot()
	var outcomes: Dictionary={}
	for citizen: CityNPC in people: outcomes[citizen.npc_id]={"health":citizen.health,"injuries":citizen.injuries.snapshot()}
	if dante is CityNPC: outcomes[dante.npc_id]={"health":dante.health,"injuries":dante.injuries.snapshot()}
	data["npc_outcomes"]=outcomes
	data["player"] = [player.position.x, player.position.y, player.position.z]
	data["bike"]=[bike.position.x,bike.position.y,bike.position.z]
	data["bike_yaw"]=bike.rotation.y
	if player.riding_bike:
		var safe: Variant=bike.outside_point()
		var point: Vector3=safe if safe!=null else bike.position+Vector3.LEFT*2
		data["player"]=[point.x,point.y,point.z]
	data["car"] = [car.position.x, car.position.y, car.position.z]
	data["car_yaw"] = car.rotation.y
	data["integrity"] = car.integrity
	data["vehicle_damage"] = car.damage_snapshot()
	data["health"] = player.health
	data["player_injuries"]=player.injuries.snapshot()
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
	character_impacts.reset()
	if dialogue_director.active: dialogue_director.stop()
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
		if not valid or not living.validate(data.get("living_world")) or not memory.restore(data): continue
		phone.close()
		var world: Dictionary=data.get("open_world",{}) if data.get("open_world",{}) is Dictionary else {}
		story_active=bool(world.get("story_active",true))
		phone.restore(world.get("photos",[]))
		phone.restore_social(world.get("dante_social",{}))
		var saved_minutes: float=float(data.get("city_minutes",1080))
		quarter.minutes=fposmod(saved_minutes,1440) if is_finite(saved_minutes) else 1080
		quarter.day=clampi(int(data.get("city_day",1)),1,100000)
		quarter.apply_clock()
		_leave_car(true)
		var bike_at: Variant=data.get("bike")
		if bike_at is Array and bike_at.size()==3 and bike_at.all(func(v: Variant) -> bool: return (v is float or v is int) and is_finite(float(v)) and absf(float(v))<10000):
			bike.position=Vector3(bike_at[0],bike_at[1]+0.05,bike_at[2])
			var saved_yaw: float=float(data.get("bike_yaw",0))
			bike.rotation.y=saved_yaw if is_finite(saved_yaw) else 0
			bike.linear_velocity=Vector3.ZERO
			bike.angular_velocity=Vector3.ZERO
		var p: Array = data.player
		var c: Array = data.car
		car.position = Vector3(float(c[0]), float(c[1]) + 0.15, float(c[2]))
		car.rotation.y = float(data.get("car_yaw", PI))
		player.position = Vector3(float(p[0]), float(p[1]) + 0.15, float(p[2]))
		if data.get("driving", false): player.position = car.position + car.global_basis.x * 2 + Vector3.UP
		car.linear_velocity = Vector3.ZERO
		car.angular_velocity = Vector3.ZERO
		car.reset_pose(Transform3D(Basis(Vector3.UP,car.rotation.y),car.position))
		player.velocity = Vector3.ZERO
		if player.dynamics: player.dynamics.reset_state()
		car.restore_damage(data.get("vehicle_damage", {}) if data.get("vehicle_damage", {}) is Dictionary else {})
		car.integrity = clampf(float(data.get("integrity", 100)), 0, 100)
		player.health = clampf(float(data.get("health", 100)), 1, 100)
		player.injuries.restore(data.get("player_injuries",[]) if data.get("player_injuries",[]) is Array else [])
		ammunition = clampi(int(data.get("ammunition", 12)), 0, 12)
		reserve = maxi(0, int(data.get("reserve", 72)))
		faction_rep = int(data.get("faction_rep", 0))
		var outcomes: Dictionary=data.get("npc_outcomes",{}) if data.get("npc_outcomes",{}) is Dictionary else {}
		for citizen: CityNPC in people:
			var value: Variant=outcomes.get(citizen.npc_id,70)
			citizen.restore_outcome(float(value.get("health",70)) if value is Dictionary else float(value))
			if value is Dictionary: citizen.injuries.restore(value.get("injuries",[]) if value.get("injuries",[]) is Array else [])
		if dante is CityNPC:
			var value: Variant=outcomes.get(dante.npc_id,70)
			dante.restore_outcome(float(value.get("health",70)) if value is Dictionary else float(value))
			if value is Dictionary: dante.injuries.restore(value.get("injuries",[]) if value.get("injuries",[]) is Array else [])
		reload_time = 0
		harbor.consequence(memory.stage >= 3)
		_clear_guards()
		if memory.stage == 3: _spawn_guards()
		marker.show()
		_say("Checkpoint", "Restored. The city remembers.")
		living.restore(data.get("living_world"))
		return
	_say("Checkpoint", "No valid save or backup found.")

func _exit_tree() -> void:
	if is_instance_valid(ambience): ambience.stop()

func _notification(what: int) -> void:
	if not is_instance_valid(player): return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not test_mode and not OS.get_cmdline_user_args().has("--verify-physics") and not OS.get_cmdline_user_args().has("--verify-mission") and not OS.get_cmdline_user_args().has("--verify-city") and not OS.get_cmdline_user_args().has("--verify-mobility") and not OS.get_cmdline_user_args().has("--verify-ragdoll"):
		if not paused: _set_pause(true)

func _on_crash(point: Vector3, speed: float) -> void:
	if is_instance_valid(events): events.publish("crash",point,speed,str(car.get_instance_id()))
	if point.distance_to(dante.position)<24:
		crash_interest=point+Vector3.UP
		crash_interest_time=2.5
	if player.driving and player.dynamics:
		player.dynamics.impact += (car.linear_velocity-car.last_velocity).limit_length(5)

func _populate_city() -> void:
	await get_tree().physics_frame
	navigation.rebuild()
	var definitions: Array=[
		["worker_01","industrial_worker",Vector3(18,0.1,-16),Vector3(18,0.1,-35)],
		["foreman_01","dock_supervisor",Vector3(13,0.1,-40),Vector3(20,0.1,-40)],
		["walker_01","pedestrian",Vector3(-10,0.2,20),Vector3(-10,0.2,-18)],
		["driver_01","delivery_driver",Vector3(10,0.2,4),Vector3(10,0.2,-14)],
		["quay_security_01","security",Vector3(-18,0.1,-40),Vector3(-18,0.1,-55)],
		["officer_01","police",Vector3(-10,0.2,24),Vector3(-10,0.2,38)],
		["faction_01","faction",Vector3(-18,0.1,-125),Vector3(-18,0.1,-144)],
		["vendor_01","shopkeeper",Vector3(-10,0.2,-34),Vector3(-10,0.2,-36)],
		["west_worker_01","industrial_worker",Vector3(-80,0.2,30),Vector3(-80,0.2,6)],
		["west_supervisor_01","dock_supervisor",Vector3(-83,0.2,-50),Vector3(-83,0.2,-68)],
		["quay_delivery_01","delivery_driver",Vector3(82,0.2,-75),Vector3(82,0.2,-100)],
		["quay_worker_01","industrial_worker",Vector3(85,0.2,-128),Vector3(85,0.2,-145)]]
	for spec: Array in definitions:
		var actor:=CityNPC.new()
		actor.game=self
		actor.npc_id=spec[0]
		actor.name=spec[0]
		actor.appearance_id=spec[1]
		actor.position=spec[2]
		actor.route=PackedVector3Array([spec[2],spec[3]])
		add_child(actor)
		people.append(actor)
	for i: int in range(4):
		var actor:=CityNPC.new()
		actor.game=self
		actor.npc_id="northline_citizen_%d"%i
		actor.citizen_name=["Iris Morrow","Jonah Lin","Nadia Voss","Theo Mercer"][i]
		actor.appearance_id=["shopkeeper","delivery_driver","pedestrian","dock_supervisor"][i]
		var x: float=-10 if i%2==0 else 10
		var z: float=83 if i<2 else 163
		actor.position=Vector3(x,.2,z)
		actor.daily_destinations={"home":Vector3(x,.2,z),"work":Vector3(x,.2,z+30),"break":Vector3(x,.2,z+15)}
		actor.route=PackedVector3Array([actor.position,actor.position+Vector3(0,0,3)])
		add_child(actor)
		people.append(actor)
	living.populate()

func publish_city_event(kind: String, point: Vector3, severity: float, source: String) -> void:
	if is_instance_valid(events): events.publish(kind,point,severity,source)
