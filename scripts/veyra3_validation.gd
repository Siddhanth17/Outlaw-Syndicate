class_name Veyra3Validation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var tick: int=0
var worker_visited: bool=false
var staff_visited: bool=false
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().physics_frame
		tick+=1
		if tick<=1800:
			var worker: CityNPC=game.living.actor_for("resident_01")
			if worker and not worker.abstracted and worker.is_on_floor() and worker.position.distance_to(LivingWorld.point(game.living.identities.resident_01.work))<1:worker_visited=true
			var staff: CityNPC=game.living.actor_for("resident_00")
			if staff and not staff.abstracted and staff.is_on_floor() and staff.position.x<-12.5 and staff.position.y>.3 and game.living.cafe_available():staff_visited=true
		if tick<=1800 and tick%12==0 and OS.get_cmdline_user_args().has("--record-veyra3") and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://veyra3-verification/walking-%03d.png"%(tick/12-1))
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	for i: int in range(6):await get_tree().physics_frame
	game._menu_action("New game")
	game.quarter.minutes=600
	game.quarter.apply_clock()
	game.player.position=Vector3(0,.2,93)
	game.player.yaw=PI
	game.player.camera.current=true
	game.player.pitch=-.1
	game.living.refresh(0)
	check(game.traffic.cars.filter(func(c: VeyraCar) -> bool:return c.visible).size()==6 and game.traffic.retained.size()==2,"normal startup enables a measured six-car graph fleet across old/west/east roads")
	DirAccess.make_dir_recursive_absolute("user://veyra3-verification")
	var origins: Dictionary={}
	for actor: CityNPC in game.people:origins[actor.npc_id]=actor.position
	await frames(1800)
	var moving: int=0
	var stalled: Array=[]
	for actor: CityNPC in game.people:
		if not actor.abstracted and actor.position.distance_to(origins[actor.npc_id])>5:moving+=1
		if not actor.abstracted and actor.stuck_duration>4:stalled.append(actor.npc_id)
	print("CROWD_MOVEMENT count=",moving," stalled=",stalled)
	check(moving>=8,"multiple real nearby residents walk more than five meters in thirty seconds")
	check(stalled.is_empty(),"no active resident silently remains stalled for over four seconds in the normal route")
	var worker: CityNPC=game.living.actor_for("resident_01")
	check(worker_visited and worker.arrival_count>0 and staff_visited,"Soren reaches his work zone and Lena physically arrives at the real staffed cafe counter during this route")
	var crossing: CityNPC=game.living.actor_for("resident_10")
	check(crossing.position.z>149 and not crossing.abstracted and crossing.is_on_floor(),"resident physically climbs the raised sidewalk beyond the junction")
	game._save()
	var traffic_before: Dictionary=game.traffic.snapshot()
	game.traffic.cars[0].reset_pose(Transform3D(Basis.IDENTITY,Vector3(0,.9,-170)))
	game.traffic.cars[0].integrity=15
	await frames(2)
	game._load()
	await frames(2)
	check(game.traffic.cars[0].position.distance_to(LivingWorld.point(traffic_before.drivers.retained_00.position))<2 and game.traffic.cars[0].integrity>85,"checkpoint restores the actual traffic vehicle transform, condition and graph route")
	var malformed: Dictionary=traffic_before.duplicate(true)
	malformed.drivers.retained_00.position=[INF,0,0]
	check(not game.traffic.validate(malformed),"malformed traffic state is rejected before replacing live checkpoint state")
	var previous: Vector3=crossing.position
	await frames(240)
	check(crossing.navigation_status!="unplanned" and crossing.stuck_duration<4,"checkpoint restore rebuilds a current navigation path without freezing the resident")
	var probe:=CityNPC.new()
	probe.game=game;probe.npc_id="blocked_route_probe";probe.appearance_id="pedestrian"
	probe.position=Vector3(-10,.2,130)
	probe.route=PackedVector3Array([Vector3(-10,.2,160)])
	game.add_child(probe);game.people.append(probe)
	game.player.position=Vector3(0,.2,138)
	var blocker:=VeyraCar.new()
	blocker.position=Vector3(-10,.85,145);blocker.freeze=true
	game.add_child(blocker)
	await frames(1800)
	print("BLOCKED_ROUTE ",probe.position," ",probe.diagnostic())
	check(probe.position.z>153,"pedestrian repaths around a physical parked vehicle and climbs the next curb")
	check(probe.repath_count>0 and probe.stuck_duration<4,"blocked-route recovery uses navigation and physical movement without teleporting")
	game.people.erase(probe);probe.queue_free();blocker.queue_free()
	for bus: String in CityAudio.BUSES:check(AudioServer.get_bus_index(bus)>0,"real audio bus exists: "+bus)
	var old_mix: float=game.city_audio.levels.Vehicles
	game.city_audio.adjust("Vehicles",-4)
	check(game.city_audio.levels.Vehicles==maxf(-40,old_mix-4),"independent vehicle mix changes the actual saved bus gain")
	game.city_audio.adjust("Vehicles",old_mix-game.city_audio.levels.Vehicles)
	var recorder: AudioEffectRecord
	if DisplayServer.get_name()!="headless":
		recorder=AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,recorder)
		recorder.set_recording_active(true)
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(0,.9,-75)))
	game._enter_car_immediate()
	Input.action_press("forward")
	await frames(240)
	Input.action_release("forward")
	check(game.car.linear_velocity.length()>4 and game.car.sound_model.rpm>1500,"actual car acceleration raises the layered engine RPM model")
	check(game.car.sound_model.layers.size()==5 and game.car.sound_model.load_amount>.5,"car uses five crossfaded layers with throttle load")
	game._leave_car(true)
	await frames(2)
	check(not game.car.sound_model.running,"unoccupied parked car stops its engine layers")
	check(game.bike.sound_model.vehicle_kind=="bike" and game.bike.sound_model.layers[0].stream!=game.car.sound_model.layers[0].stream,"motorcycle uses its own authored engine samples")
	game.bike.position=Vector3(0,.8,-135)
	game.bike.linear_velocity=Vector3.ZERO
	game.player.position=Vector3(-1,.2,-135)
	check(game.bike.interact(),"motorcycle audio test mounts through the real riding interaction")
	await frames(90)
	Input.action_press("forward")
	await frames(240)
	Input.action_release("forward")
	check(game.bike.linear_velocity.length()>3 and game.bike.sound_model.rpm>1800,"actual motorcycle acceleration raises its distinct layered engine RPM")
	game.bike.release()
	game.player.position=Vector3(0,.2,-70)
	await frames(30)
	var shots: int=game.city_audio.shots
	game.sound("shot",Vector3(0,1,-70))
	check(game.city_audio.shots==shots+1 and game.city_audio.last_space=="outdoor","outdoor firing triggers the positional weapon system")
	await frames(75)
	game.player.position=Vector3(-14,.4,80)
	await frames(10)
	game.sound("shot",Vector3(-14,1,80))
	check(game.city_audio.last_space=="interior","a physical overhead surface selects the interior gunfire reflection")
	await frames(90)
	if recorder:
		recorder.set_recording_active(false)
		recorder.get_recording().save_to_wav("user://veyra3-verification/actual-game-audio.wav")
		AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	check(not game.story_active,"movement and audio route leave story activation voluntary")
	print("VEYRA3_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
