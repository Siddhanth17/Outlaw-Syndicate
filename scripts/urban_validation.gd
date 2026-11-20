class_name UrbanValidation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var ticks: int=0
var recorded: int=0
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().physics_frame
		ticks+=1
		if OS.get_cmdline_user_args().has("--record-urban") and DisplayServer.get_name()!="headless" and ticks%12==0 and recorded<120:
			var car: VeyraCar=game.traffic.cars[0]
			game.cine_camera.current=true
			game.cine_camera.position=car.position+Vector3(-8,4,10)
			game.cine_camera.look_at(car.position+Vector3.UP*.4)
			await capture("traffic-sequence-%03d"%recorded)
			recorded+=1
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://urban-verification/"+name+".png")
func view(at: Vector3, target: Vector3, name: String) -> void:
	game.cine_camera.current=true
	game.cine_camera.position=at
	game.cine_camera.look_at(target)
	await frames(8)
	await capture(name)
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	game._menu_action("New game")
	game.traffic.set_fleet_enabled(false) # Isolate the two original controller fixtures; the ten-car graph has its own tests.
	DirAccess.make_dir_recursive_absolute("user://urban-verification")
	game.ui.gameplay.hide()
	game.quarter.minutes=720
	game.quarter.apply_clock()
	await frames(15)
	if DisplayServer.get_name()!="headless":
		var actual_size: Vector2i=game.get_viewport().get_texture().get_size()
		check(actual_size==Vector2i(1920,1080),"actual render target is 1920x1080 independent of Windows window clamping")
	var traffic_car: VeyraCar=game.traffic.cars[0]
	var start_at: Vector3=traffic_car.position
	await frames(180)
	check(traffic_car.position.distance_to(start_at)>3 and traffic_car.linear_velocity.length()>1,"AI car moves through actual wheel forces rather than transform playback")
	game.traffic.elapsed=15
	traffic_car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(-67,.9,116)))
	game.traffic.targets[0]=1
	await frames(450)
	print("TRAFFIC_RED ",traffic_car.position," speed=",traffic_car.linear_velocity.length()," reason=",game.traffic.reasons[0])
	check(game.traffic.reasons[0]=="signal" and traffic_car.linear_velocity.length()<1 and traffic_car.position.z<130,"north-south red signal stops approaching physical traffic")
	check(traffic_car.brake_light.light_energy>1,"autonomous braking illuminates the actual rear brake light")
	game.traffic.elapsed=0
	traffic_car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(-67,.9,88)))
	var obstruction: StaticBody3D=game.harbor.solid(Vector3(-67,1,101),Vector3(3,2,1))
	await frames(300)
	print("TRAFFIC_OBSTACLE ",traffic_car.position," speed=",traffic_car.linear_velocity.length()," reason=",game.traffic.reasons[0])
	check(game.traffic.reasons[0]=="obstacle" and traffic_car.position.z<99 and traffic_car.linear_velocity.length()<1,"traffic sensor brakes before an actual blocking collider")
	obstruction.queue_free()
	await frames(180)
	check(traffic_car.linear_velocity.length()>1,"traffic resumes after the physical obstruction is removed")
	game.traffic.elapsed=0
	traffic_car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(-67,.9,201)))
	game.traffic.targets[0]=1
	await frames(450)
	print("TRAFFIC_TURN ",traffic_car.position," yaw=",traffic_car.rotation.y," reason=",game.traffic.reasons[0])
	check(traffic_car.position.x>-60 and traffic_car.position.z<226 and game.traffic.targets[0]==2,"physical traffic negotiates its first junction turn")
	check(game.quarter.centers.size()==8,"eight connected urban blocks retain the original four and add west/east pairs")
	check(game.quarter.kits.size()==4,"four original detailed frontage assets loaded")
	check(game.navigation.path(Vector3(-10,.2,40),Vector3(-10,.2,210)).size()>20,"collision-aware pedestrian navigation connects harbor and new quarter")
	var citizen: CityNPC=game.people.back()
	game.quarter.minutes=600
	citizen.update_schedule()
	check(citizen.schedule_period=="work","named urban citizen selects work destination from shared clock")
	game.quarter.minutes=750
	citizen.update_schedule()
	check(citizen.schedule_period=="break","named urban citizen selects a separate midday break destination")
	game.quarter.minutes=1200
	citizen.update_schedule()
	check(citizen.schedule_period=="home" and not citizen.citizen_name.is_empty(),"named urban citizen returns to home-zone routine in evening")
	var before_flee: float=citizen.position.z
	citizen._on_incident({"kind":"gunshot","position":citizen.position+Vector3(0,0,-2)})
	await frames(12)
	check(citizen.activity=="flee" and citizen.position.z>before_flee,"urban danger reaction flees locally instead of clamping back to the old harbor boundary")
	game.player.position=Vector3(0,.2,138)
	await frames(12)
	game.quarter.refresh(true)
	check(game.quarter.sectors.size()==8,"all eight connected sectors are resident from the central intersection")
	game.ui.gameplay.hide()
	game.quarter.minutes=720
	game.quarter.apply_clock()
	await view(Vector3(10,2,65),Vector3(16,3,82),"day-shopfront")
	await view(Vector3(4,2,125),Vector3(25,6,100),"day-avenue")
	await view(Vector3(95,90,245),Vector3(0,0,138),"day-quarter-wide")
	# Walk through the modeled opening and reach its real shop back-wall collider.
	game.player.position=Vector3(-49,.18,69)
	game.player.yaw=0
	Input.action_press("back")
	await frames(150)
	Input.action_release("back")
	check(game.player.position.z>72 and game.player.position.z<77,"actual input enters the open shop vestibule and stops at its back wall")
	check(game.player.position.y>-.1,"shop entrance has stable ground collision")
	var loads: int=game.quarter.load_count
	game.player.position=Vector3(0,.2,-150)
	game.quarter.refresh(true)
	await frames(2)
	check(game.quarter.sectors.size()==0 and game.quarter.unload_count>=8,"distant decorative sectors unload with hysteresis")
	game.player.position=Vector3(0,.2,138)
	game.quarter.refresh(true)
	check(game.quarter.sectors.size()==8 and game.quarter.load_count>=loads+8,"sector reload restores original and west/east detailed buildings")
	game.quarter.minutes=60
	game.quarter.apply_clock()
	await view(Vector3(5,2,126),Vector3(25,5,100),"night-avenue")
	await view(Vector3(5,1.5,-190),Vector3(0,18,-220),"harbor-background-after")
	game.quarter.minutes=720
	game._save()
	game.quarter.minutes=100
	game._load()
	check(absf(game.quarter.minutes-720)<1,"shared lighting clock survives checkpoint restoration")
	check(not game.story_active,"quarter traversal does not force story acceptance")
	if DisplayServer.get_name()!="headless":
		game.player.position=Vector3(0,.2,138)
		game.quarter.refresh(true)
		game.quarter.apply_clock()
		await view(Vector3(5,2,126),Vector3(25,5,100),"day-matching-night")
		game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(0,.9,76)))
		await frames(4)
		game._enter_car_immediate()
		game.player.camera.current=true
		game.player.yaw=PI
		game.player.pitch=-.12
		var drive_start: Vector3=game.car.position
		Input.action_press("forward",.65)
		var times: Array[float]=[]
		var start:=Time.get_ticks_usec()
		var before:=start
		while Time.get_ticks_usec()-start<10000000:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			times.append((now-before)/1000.0)
			before=now
		var total: float=0
		for t: float in times:total+=t
		times.sort()
		Input.action_release("forward")
		check(game.car.position.distance_to(drive_start)>20,"1080p rendering sample includes actual player-car traversal through the quarter")
		await capture("drive-end")
		var actual_size: Vector2i=game.get_viewport().get_texture().get_size()
		var report: Dictionary={"render_width":actual_size.x,"render_height":actual_size.y,"scope":"10s measured viewport actual forward drive, four urban blocks, two traffic cars and sixteen citizens; not full acceptance route","frames":times.size(),"mean_fps":times.size()*1000/total,"p95_ms":times[int(times.size()*.95)],"p99_ms":times[int(times.size()*.99)],"max_ms":times.back(),"texture_buffer_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		var file:=FileAccess.open("user://urban-verification/performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		print("URBAN_PERFORMANCE ",report)
	print("URBAN_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
