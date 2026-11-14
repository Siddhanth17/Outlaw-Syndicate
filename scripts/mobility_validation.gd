class_name MobilityValidation
extends Node

var game: Node3D
var passes: int = 0
var failures: int = 0
var recorder: AudioEffectRecord
var capture_tick: int=0
var door_frames: int=0
var bike_frames: int=0

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if ok: passes += 1
	else: failures += 1

func frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().physics_frame
		capture_tick+=1
		if OS.get_cmdline_user_args().has("--record-mobility") and DisplayServer.get_name()!="headless" and capture_tick%12==0:
			if is_instance_valid(game.vehicle_transition) and game.vehicle_transition.active and door_frames<40:
				game.cine_camera.current=true
				game.cine_camera.position=game.car.position+Vector3(-4,2,4)
				game.cine_camera.look_at(game.car.position+Vector3.UP*0.3)
				await capture("door-sequence-%03d"%door_frames)
				door_frames+=1
			elif game.player.riding_bike and bike_frames<36:
				game.cine_camera.current=true
				game.cine_camera.position=game.bike.position+Vector3(-3,1.5,3)
				game.cine_camera.look_at(game.bike.position+Vector3.UP*0.4)
				await capture("bike-sequence-%03d"%bike_frames)
				bike_frames+=1

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://mobility-verification/"+name+".png")

func run() -> void:
	game.test_mode = true
	game._set_pause(false)
	game._end_cinematic()
	await frames(5)
	DirAccess.make_dir_recursive_absolute("user://mobility-verification")
	load("res://scripts/movement_lab.gd").build_pads(game)
	await frames(3)
	var audio: MovementAudio = game.player.movement_audio
	check(audio.profiles.size() == 10, "nine material profiles plus a separate quiet cloth layer")
	check(audio.samples.size() == 40, "forty preloaded credited foley variations")
	game.ambience.stop()
	game.car.engine_audio.stop()
	game.car.tire_audio.stop()
	if DisplayServer.get_name() != "headless":
		recorder = AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,recorder)
		recorder.set_recording_active(true)
	var materials: Array[String] = ["asphalt","concrete","warehouse","metal","dirt","grass","wood","interior","stairs"]
	for i: int in range(materials.size()):
		game.player.position = Vector3(200+i*5,0.08,18)
		game.player.velocity = Vector3.ZERO
		game.player.yaw = 0
		audio.reset_motion()
		await frames(8)
		check(audio.surface_at(game.player.position) == materials[i], "ground ray selects tagged surface: "+materials[i])
		var steps_before: int = audio.steps
		Input.action_press("forward")
		Input.action_press("crouch")
		await frames(60)
		Input.action_release("forward")
		Input.action_release("crouch")
		await frames(12)
		check(audio.steps > steps_before and audio.events.any(func(e: Dictionary) -> bool: return e.surface==materials[i] and e.kind=="step"), "actual grounded walking emits surface steps: "+materials[i])
		if i in [0,3,4,5]:
			game.cine_camera.current = true
			game.cine_camera.position = game.player.position+Vector3(2,2,-3)
			game.cine_camera.look_at(game.player.position+Vector3.UP)
			await capture("walking-"+materials[i])
	var count: int = audio.steps
	await frames(80)
	check(audio.steps == count, "standing still does not repeat footsteps")
	game.player.position = Vector3(200,0.1,18)
	game.player.velocity = Vector3.ZERO
	audio.reset_motion()
	await frames(6)
	Input.action_press("forward")
	Input.action_press("sprint")
	await frames(65)
	Input.action_release("forward")
	Input.action_release("sprint")
	await frames(25)
	check(audio.events.any(func(e: Dictionary) -> bool: return e.kind=="step" and e.speed>5), "sprinting emits heavier speed-driven footfalls")
	check(audio.events.any(func(e: Dictionary) -> bool: return e.kind=="stop"), "decelerating to rest emits a restrained stop contact")
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await frames(90)
	check(audio.events.any(func(e: Dictionary) -> bool: return e.kind=="land"), "real jump landing emits impact once grounded")
	if recorder:
		recorder.set_recording_active(false)
		var recording:=recorder.get_recording()
		check(recording != null and recording.get_length()>1,"actual engine audio mix captured for listening review")
		if recording: recording.save_to_wav("user://mobility-verification/actual-movement-mix.wav")
		AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var repeated: bool = false
	var last: String = ""
	for i: int in range(40):
		audio.emit_contact("step",3.4,"concrete")
		var selected: String = audio.events[-1].sample
		if selected == last: repeated = true
		last = selected
	check(not repeated and audio.events.size()==32, "sample selection prevents immediate repeats and caps diagnostic history")
	game.movement_volume = -13
	game._save_settings()
	game.movement_volume = 0
	game._load_settings()
	check(game.movement_volume == -13 and audio.volume_db == -13, "independent movement volume survives settings reload")
	count = audio.steps
	game._set_pause(true)
	await frames(20)
	check(audio.steps == count, "paused player produces no extra footsteps")
	game._set_pause(false)
	game.car.repair()
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(0,0.8,30)))
	await frames(45)
	game.player.position=game.car.to_global(Vector3(-2.3,-0.72,0.35))
	game.player.velocity=Vector3.ZERO
	game.vehicle_transition.force_animation=true
	check(is_instance_valid(game.car.driver_door),"separate authored driver door hinge is integrated")
	game._interact()
	check(game.vehicle_transition.active and game.player.transitioning and not game.car.occupied,"entry begins a timed transition rather than instant driving")
	var ammo_before: int=game.ammunition
	game._fire()
	check(game.ammunition==ammo_before,"entry blocks shooting until interaction finishes")
	await frames(65)
	check(game.car.driver_door.rotation.y>0.6,"driver door opens visibly during entry")
	var transition_clock: float=game.vehicle_transition.clock
	game._set_pause(true)
	await frames(30)
	check(is_equal_approx(game.vehicle_transition.clock,transition_clock),"pause freezes door interaction timeline")
	game._set_pause(false)
	game.cine_camera.current=true
	game.cine_camera.position=game.car.position+Vector3(-4,2,4)
	game.cine_camera.look_at(game.car.position+Vector3.UP*0.3)
	await capture("door-entry-open")
	await frames(130)
	check(not game.vehicle_transition.active and game.player.driving and game.car.occupied and is_zero_approx(game.car.driver_door.rotation.y),"entry settles into driving with a closed door")
	game._leave_car()
	check(game.vehicle_transition.active and game.player.transitioning,"exit begins a timed door transition")
	await frames(80)
	await capture("door-exit-open")
	await frames(120)
	check(not game.player.driving and game.player.collision_layer==CollisionLayers.PLAYER and game.player.collision_mask==CollisionLayers.SOLIDS,"exit restores on-foot collision and control")
	var obstruction: StaticBody3D=game.harbor.solid(game.car.to_global(Vector3(-1.65,0.2,0.35)),Vector3(0.8,2.0,1.2))
	await frames(3)
	check(not game.vehicle_transition.begin(true) and not game.vehicle_transition.active,"blocked driver-door sweep rejects unsafe entry")
	obstruction.queue_free()
	await frames(3)
	game.vehicle_transition.begin(true)
	await frames(10)
	game._leave_car(true)
	check(not game.vehicle_transition.active and not game.player.transitioning and is_zero_approx(game.car.driver_door.rotation.y),"forced checkpoint reset cancels transient interaction cleanly")
	game.vehicle_transition.force_animation=false
	game.dialogue_time=0
	game.bike.position=Vector3(-70,0.8,15)
	game.bike.rotation=Vector3.ZERO
	game.bike.linear_velocity=Vector3.ZERO
	await frames(70)
	check(game.bike.wheels.size()==2,"motorcycle has two independent physics wheels")
	game.player.position=game.bike.position+Vector3(-1.1,-0.4,0)
	game.player.velocity=Vector3.ZERO
	game._interact()
	check(game.bike.mounting and not game.player.riding_bike,"motorcycle starts a timed mount")
	await frames(70)
	check(game.player.riding_bike and not game.bike.mounting and game.player.collision_layer==0,"mount settles into a visible seated rider state")
	check(game.player.action_name=="Ride","motorcycle selects its separate straddled rider animation")
	var bike_start: Vector3=game.bike.position
	Input.action_press("forward")
	await frames(160)
	Input.action_press("left")
	await frames(35)
	Input.action_release("left")
	Input.action_release("forward")
	check(game.bike.position.distance_to(bike_start)>3 and game.bike.linear_velocity.length()>2,"actual motorcycle wheel forces accelerate and traverse the district")
	check(absf(game.bike.lean)>0.015 and absf(game.bike.global_rotation.z)<0.1,"assisted motorcycle turns with bounded visual lean and upright chassis")
	game.cine_camera.current=true
	game.cine_camera.position=game.bike.position+Vector3(-3,1.5,3)
	game.cine_camera.look_at(game.bike.position+Vector3.UP*0.4)
	await capture("motorcycle-riding")
	Input.action_press("handbrake")
	await frames(140)
	Input.action_release("handbrake")
	check(game.bike.linear_velocity.length()<2,"motorcycle braking reaches safe dismount speed")
	game._interact()
	await frames(70)
	check(not game.player.riding_bike and game.bike.rider==null and game.player.collision_layer==CollisionLayers.PLAYER,"timed motorcycle dismount restores on-foot state")
	game.bike.position=Vector3(-70,0.8,36.5)
	game.bike.rotation=Vector3.ZERO
	game.bike.linear_velocity=Vector3(0,0,12)
	var wall: StaticBody3D=game.harbor.solid(Vector3(-70,1,39),Vector3(6,2,0.4))
	var contacts_before: int=game.bike.world_contacts
	await frames(70)
	check(game.bike.world_contacts>contacts_before and game.bike.position.z<39.2 and game.bike.linear_velocity.length()<20,"motorcycle has real bounded collision with the world")
	wall.queue_free()
	await frames(5)
	game.bike.linear_velocity=Vector3.ZERO
	game.bike.position=Vector3(-70,0.8,15)
	await frames(60)
	game.player.position=game.bike.position+Vector3(-1.1,-0.4,0)
	game._interact()
	await frames(70)
	game._save()
	var saved_bike: Vector3=game.bike.position
	game._load()
	check(not game.player.riding_bike and game.bike.rider==null and game.bike.position.distance_to(saved_bike)<0.2,"bike checkpoint restores parked position and safely returns rider on foot")
	game.player.position=Vector3(-70,0.2,54)
	game.player.velocity=Vector3.ZERO
	await frames(8)
	check(audio.surface_at(game.player.position)=="asphalt","expanded north/west intersection has asphalt acoustics")
	for endpoint: Vector3 in [Vector3(-80,0,-140),Vector3(82,0,-130)]:
		var path: PackedVector3Array=game.navigation.path(Vector3(-10,0,38),endpoint)
		check(path.size()>20,"expanded road network has a connected pedestrian route to "+str(endpoint))
	check(audio.surface_at(Vector3(2,0.06,-20))=="metal","actual district manhole overrides road acoustics")
	check(game.harbor.physical_props[0].get_meta("foot_surface","")=="wood","movable wooden cargo carries its own acoustic material")
	var industrial_ids: Array[String]=[]
	for citizen: CityNPC in game.people: industrial_ids.append(citizen.npc_id)
	check(["west_worker_01","west_supervisor_01","quay_delivery_01","quay_worker_01"].all(func(id: String) -> bool:return industrial_ids.has(id)),"expanded district retains all four routed industrial actors")
	game.cine_camera.current=true
	game.cine_camera.position=Vector3(-45,42,86)
	game.cine_camera.fov=65
	game.cine_camera.look_at(Vector3(-30,0,-45))
	await capture("expanded-district")
	if DisplayServer.get_name()!="headless": await benchmark_expansion()
	print("MOBILITY_VALIDATION ",passes," passed ",failures," failed")
	get_tree().quit(1 if failures else 0)

func benchmark_expansion() -> void:
	game.quality=1
	game.harbor.preset(1)
	get_viewport().size=Vector2i(1920,1080)
	game.player.position=Vector3(-80,0.2,-45)
	game.player.velocity=Vector3.ZERO
	game.player.yaw=0
	game.player.camera.current=true
	await frames(30)
	Input.action_press("forward")
	var samples: Array[float]=[]
	var start_time: int=Time.get_ticks_usec()
	var previous: int=start_time
	while Time.get_ticks_usec()-start_time<3000000:
		await get_tree().process_frame
		var now: int=Time.get_ticks_usec()
		samples.append((now-previous)/1000.0)
		previous=now
	Input.action_release("forward")
	samples.sort()
	var total: float=0
	for value: float in samples:total+=value
	var report: Dictionary={"phase":"west freight sidewalk traversal","resolution":"1920x1080","quality":"Balanced","frames":samples.size(),"average_fps":1000/(total/samples.size()),"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*0.95)],"max_ms":samples[-1],"global_ambient_population":game.people.size(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"scope":"Uncapped short 3-second sample in expanded west district, no capture encoding during measurement; not sustained thermal profiling"}
	var file:=FileAccess.open("user://mobility-verification/expanded-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
