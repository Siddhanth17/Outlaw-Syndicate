class_name LivingValidation
extends Node

var game: Node3D
var passes: int=0
var failures: int=0
var timing: Array[float]=[]
var measuring: bool=false
var last_tick: int=0
var benchmarks: Dictionary={}
var targets: Array[CityNPC]=[]

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok: passes+=1
	else: failures+=1

func frames(count: int) -> void:
	for i: int in range(count): await get_tree().physics_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://living-verification/"+name+".png")

func view(at: Vector3, target: Vector3) -> void:
	game.cine_camera.current=true
	game.cine_camera.position=at
	game.cine_camera.look_at(target)
	game.cine_camera.fov=52

func subject(at: Vector3, identity: String="pedestrian") -> CityNPC:
	var npc:=CityNPC.new()
	npc.game=game
	npc.npc_id="TestSubject_%d"%targets.size()
	npc.name=npc.npc_id
	npc.appearance_id=identity
	npc.position=at
	npc.route=PackedVector3Array([at])
	game.add_child(npc)
	targets.append(npc)
	return npc

func shoot_region(at: Vector3, from: Vector3, expected: String) -> Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(from,at+(at-from).normalized()*0.2,CollisionLayers.PROJECTILE)
	ray.collide_with_areas=true
	var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider is VehicleHitRegion and hit.collider.kind==expected,"validated hitscan reaches "+expected+" component")
	if not hit.is_empty() and hit.collider is VehicleHitRegion: hit.collider.receive_hit(hit.position,(at-from).normalized(),35)
	return hit

func contact_trial(speed: float, side_offset: float=0) -> CityNPC:
	game.car.repair()
	var npc: CityNPC=subject(Vector3(200+side_offset,0.05,0))
	game.car.occupied=true
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,-3.5)),Vector3(0,0,speed))
	if OS.get_cmdline_user_args().has("--record-living"):
		view(Vector3(204,2,-3),Vector3(200,0.8,0))
		for frame: int in range(65):
			await frames(1)
			if frame%3==0: await capture("contact-%02d-%03d"%[int(speed),frame])
	else: await frames(65)
	print("NPC_CONTACT speed=",speed," count=",npc.vehicle_hit_count," health=",npc.health," state=",npc.state," position=",npc.position," knock_velocity=",npc.knock_velocity)
	return npc

func run() -> void:
	DirAccess.make_dir_recursive_absolute("user://living-verification")
	game._set_pause(false)
	game.quality=1
	game.harbor.preset(1)
	game.get_window().size=Vector2i(1920,1080)
	await frames(60)
	var definitions: Dictionary=NPCCatalog.profile("dante")
	check(NPCCatalog.definitions.size()>=10,"ten archetype definitions available")
	var signatures: Dictionary={}
	for id: String in ["industrial_worker","dock_supervisor","security","pedestrian","delivery_driver","mechanic","police","faction","shopkeeper"]:
		var model: Node3D=NPCCatalog.instantiate(id)
		var meshes: Array=model.find_children("*","MeshInstance3D",true,false)
		var found: bool=false
		for mesh: MeshInstance3D in meshes:
			if mesh.find_blend_shape_by_name("JawOpen")>=0:
				var components: Array=[]
				for surface: int in range(mesh.mesh.get_surface_count()): components.append(hash(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]))
				signatures[hash(components)]=true
				found=true
		check(found and meshes.size()>2,"rigged face and authored outfit geometry: "+id)
		model.free()
	check(signatures.size()>=6,"at least six geometrically distinct human variants, beyond recoloring")
	check(game.dante is CityNPC and game.dante.appearance_id=="dante","named Dante uses fixed distinct model identity")
	check(game.people.all(func(p:CityNPC)->bool:return NPCCatalog.profile(p.appearance_id).model!=NPCCatalog.profile("dante").model),"ambient population does not duplicate named Dante identity")
	check(game.people.size()>=8 and game.navigation.built,"population and collision-aware route grid integrated into actual district")
	var path: PackedVector3Array=game.navigation.path(Vector3(-18,0.2,22),Vector3(-10,0.2,22))
	check(path.size()>4,"navigation routes around fence instead of through it")
	var voices: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/voice_profiles.json")).profiles
	var voice_ids: Dictionary={}
	for name: String in voices:
		voice_ids[voices[name].voice]=true
		var clip: AudioStreamWAV=load(voices[name].sample_audio)
		check(clip.get_length()>1 and clip.mix_rate==24000 and float(voices[name].peak)<=0.891,"local normalized neural voice: "+name)
	check(voice_ids.size()==8 and voices.Adrian.voice!=voices.Dante.voice,"eight distinct fixed voice profiles")
	game._menu_action("Dialogue volume -")
	check(is_equal_approx(game.dialogue_director.audio.volume_db,game.dialogue_volume),"dialogue volume control reaches playback stream")
	# Gallery is an inspection of the same models instantiated in gameplay.
	game.harbor.solid(Vector3(200,-0.5,0),Vector3(80,1,80))
	game.harbor.surface(Vector3(200,0.01,0),Vector2(80,80),"concrete",Color.WHITE,3,0.8)
	var light:=OmniLight3D.new()
	light.position=Vector3(200,6,-3)
	light.omni_range=45
	light.light_energy=8
	game.add_child(light)
	var i: int=0
	for id: String in ["industrial_worker","dock_supervisor","security","pedestrian","delivery_driver","mechanic","police","faction","shopkeeper"]:
		var npc: CityNPC=subject(Vector3(190+i*2.5,0.05,10),id)
		npc._play("Idle")
		npc.visual.rotation.y=PI
		npc.set_physics_process(false)
		i+=1
	view(Vector3(200,3,-14),Vector3(200,1.1,10))
	await frames(20)
	await capture("appearance-gallery")
	for group: int in range(3):
		var x: float=192.5+group*7.5
		view(Vector3(x,1.8,3),Vector3(x,1.2,10))
		await capture("appearance-close-%d"%group)
	for npc: CityNPC in targets: npc.queue_free()
	targets.clear()
	await frames(2)
	var near: CityNPC=await contact_trial(8,3)
	check(near.vehicle_hit_count==0,"proximity without contact causes no NPC damage")
	near.queue_free()
	await frames(2)
	var low: CityNPC=await contact_trial(3)
	check(low.vehicle_hit_count==1 and low.health<70 and low.health>50,"low speed confirmed contact causes bounded nonfatal stagger")
	check(low.state!=HarborGuard.State.KNOCKED_DOWN,"minor impact does not trigger severe knockdown")
	low.queue_free()
	await frames(2)
	var medium: CityNPC=await contact_trial(12)
	check(medium.vehicle_hit_count==1 and medium.state==HarborGuard.State.KNOCKED_DOWN,"actual moderate vehicle contact transitions to knockdown")
	check(medium.knock_velocity.length()<=6.1 and medium.position.y<2,"contact response remains bounded and grounded")
	view(medium.position+Vector3(4,2,4),medium.position+Vector3.UP*0.5)
	await capture("vehicle-npc-knockdown")
	var hits: int=medium.vehicle_hit_count
	await frames(30)
	check(medium.vehicle_hit_count==hits,"sustained contact does not repeat NPC damage every frame")
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(212,0.8,-10)))
	await frames(220)
	check(medium.state!=HarborGuard.State.KNOCKED_DOWN and medium.state!=HarborGuard.State.DEFEATED,"surviving NPC recovers after clearance-checked knockdown")
	check(game.memory.events.has("npc_vehicle_injury_"+medium.name),"significant NPC incident persists in city memory")
	medium.queue_free()
	await frames(2)
	var severe: CityNPC=await contact_trial(23)
	check(severe.vehicle_hit_count==1 and severe.knock_velocity.length()<=6.1 and severe.position.y<2,"severe vehicle contact produces bounded non-graphic knockdown")
	severe.queue_free()
	await frames(2)
	# Ray-only component geometry avoids chassis proxy masking real windows/tires.
	game.car.repair()
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,0)))
	game.car.occupied=false
	await frames(30)
	var pane: Dictionary=game.car.damage.glass[0]
	var point: Vector3=game.car.to_global(pane.center)
	var hit: Dictionary=await shoot_region(point,point+Vector3(0,0,3),"glass")
	check(game.car.damage.glass[0].state>0 and game.car.damage.glass[1].state==0,"bullet cracks only the struck glazing component")
	await capture("bullet-glass-stage")
	if not hit.is_empty() and hit.collider is VehicleHitRegion:
		for n: int in range(2): hit.collider.receive_hit(hit.position,Vector3(0,0,-1),35)
	check(game.car.damage.glass[0].state==3,"repeated validated window hits shatter selected pane")
	var wheel: VehicleWheel3D=game.car.wheels[0]
	point=wheel.global_position
	hit=await shoot_region(point,point+Vector3(-3,0,0),"tire")
	if not hit.is_empty() and hit.collider is VehicleHitRegion: hit.collider.receive_hit(hit.position,Vector3.RIGHT,35)
	await frames(3)
	check(game.car.damage.tires[0]>=60 and game.car.damage.tires[3]==0,"bullet tire damage remains local")
	check(game.car.wheels[0].wheel_friction_slip<1.5 and game.car.wheels[0].wheel_radius<0.38,"damaged tire visibly shrinks and reduces stable tire grip")
	view(game.car.position+Vector3(-4,2,4),game.car.position)
	await capture("bullet-tire")
	point=game.car.to_global(Vector3(-0.62,-0.06,2.04))
	hit=await shoot_region(point,point+Vector3(0,0,3),"light")
	if not hit.is_empty() and hit.collider is VehicleHitRegion: hit.collider.receive_hit(hit.position,Vector3(0,0,-1),35)
	await frames(3)
	check(game.car.damage.light_damage[0]>=60 and game.car.damage.light_damage[1]==0 and not game.car.lamps[0].visible and game.car.lamps[1].visible,"validated gunfire breaks only the struck headlight and spotlight")
	var old_position: Vector3=game.player.position
	var old_camera: Transform3D=game.player.camera.transform
	game.player.position=game.car.position+Vector3(3,0,-3)
	game.player.set_physics_process(false)
	point=game.car.to_global(game.car.damage.glass[1].center)
	game.player.camera.global_position=point+Vector3(0,0,-3)
	game.player.camera.look_at(point)
	game.cooldown=0
	game.ammunition=12
	game._fire()
	check(game.ammunition==11 and game.car.damage.glass[1].damage>0,"actual player weapon dispatches hitscan into vehicle component damage")
	game.player.camera.transform=old_camera
	game.player.position=old_position
	game.player.set_physics_process(true)
	point=game.car.to_global(Vector3(0.95,-0.1,0.5))
	hit=await shoot_region(point,point+Vector3(3,0,0),"body")
	check(game.car.damage.bullet_marks.size()==1 and game.car.damage.zones.right_front>0,"body bullet hit records local mark and region damage")
	for n: int in range(35):
		if not hit.is_empty() and hit.collider is VehicleHitRegion: hit.collider.receive_hit(hit.position,Vector3.LEFT,35)
	view(game.car.position+Vector3(4,1.5,2),game.car.position)
	await capture("bullet-panel-marks")
	check(game.car.damage.bullet_marks.size()==24 and game.car.damage.mark_pool.size()<=24,"bullet decal/history pool stays bounded")
	var snapshot: Dictionary=game.car.damage_snapshot()
	game.people[1].health=24
	game._save()
	game.car.repair()
	game._load()
	check(game.car.damage.tires[0]>=60 and game.car.damage.glass[0].state==3 and game.car.damage.bullet_marks.size()==24,"checkpoint preserves gunfire component condition and marks")
	check(is_equal_approx(game.people[1].health,24),"checkpoint preserves significant population health outcomes")
	game.car.repair()
	await frames(2)
	check(game.car.damage.tires.all(func(value:float)->bool:return value==0) and game.car.damage.bullet_marks.is_empty(),"repair clears gunfire condition and pooled marks")
	var civilian: CityNPC=game.people[0]
	var panic: int=civilian.panic_count
	game.events.publish("gunshot",civilian.position,30,"validation")
	game.events.publish("gunshot",civilian.position,30,"validation")
	check(civilian.panic_count==panic+1 and civilian.activity=="flee","shared danger event produces one civilian panic transition")
	var target: CityNPC=subject(Vector3(203,0.05,3),"faction")
	target.take_damage(20,Vector3.RIGHT,target.position+Vector3.UP)
	check(target.bullet_hit_count==1 and target.state==HarborGuard.State.STAGGER,"NPC combat damage has explicit stagger state")
	await frames(35)
	check(target.state!=HarborGuard.State.STAGGER,"NPC combat stagger recovers")
	view(Vector3(7,3,22),Vector3(-10,1,-20))
	await capture("populated-harbor")
	if DisplayServer.get_name()!="headless": await populated_benchmarks()
	var hero:=HeroValidation.new()
	hero.game=game
	game.add_child(hero)
	await hero.run()
	passes+=hero.passes
	failures+=hero.failures
	print("LIVING_VALIDATION ",passes," passed ",failures," failed")
	get_tree().quit(1 if failures else 0)

func _process(_delta: float) -> void:
	var now: int=Time.get_ticks_usec()
	if measuring and last_tick>0: timing.append((now-last_tick)/1000.0)
	last_tick=now

func measure(name: String, ticks: int=180) -> void:
	timing.clear()
	measuring=true
	await frames(ticks)
	measuring=false
	if timing.is_empty(): return
	var total: float=0
	for value: float in timing: total+=value
	timing.sort()
	var slow: float=0
	var n: int=maxi(1,int(timing.size()*0.01))
	for i: int in range(n):slow+=timing[timing.size()-1-i]
	benchmarks[name]={"frames":timing.size(),"mean_ms":total/timing.size(),"average_fps":1000/(total/timing.size()),"p95_ms":timing[int(timing.size()*0.95)],"one_percent_low_fps":1000/(slow/n),"max_ms":timing[-1],"population":game.people.size(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}

func populated_benchmarks() -> void:
	game.car.repair()
	game.car.reset_pose(Transform3D(Basis(Vector3.UP,PI),Vector3(4,0.9,4)))
	game.player.position=Vector3(0,0.1,20)
	game.player.yaw=0
	game.player.camera.current=true
	await frames(120)
	Input.action_press("forward")
	await measure("populated_walk")
	Input.action_release("forward")
	game.player.position=game.car.position
	game._interact()
	Input.action_press("forward")
	await measure("driving")
	Input.action_release("forward")
	Input.action_press("handbrake")
	await frames(150)
	Input.action_release("handbrake")
	game._leave_car(true)
	game.player.position=Vector3(0,0.1,-40)
	for i: int in range(3):
		var guard:=HarborGuard.new()
		guard.game=game
		guard.name="BenchmarkGuard%d"%i
		guard.position=Vector3(4+i*3,0.1,-55-i*4)
		game.add_child(guard)
		game.guards.append(guard)
	await frames(30)
	timing.clear()
	measuring=true
	for i: int in range(180):
		if i%20==0:
			for guard: HarborGuard in game.guards:
				if guard.state!=HarborGuard.State.DEFEATED:
					game.player.camera.look_at(guard.position+Vector3.UP*1.2)
					game._fire()
					break
		await frames(1)
	measuring=false
	# Retain measured combat frames while reusing the summary calculation.
	var combat: Array[float]=timing.duplicate()
	await measure("combat_tail",1)
	timing=combat
	var sum: float=0
	for value: float in timing:sum+=value
	timing.sort()
	if not timing.is_empty(): benchmarks["combat"]={"frames":timing.size(),"mean_ms":sum/timing.size(),"average_fps":1000/(sum/timing.size()),"p95_ms":timing[int(timing.size()*0.95)],"max_ms":timing[-1],"population":game.people.size(),"combatants":game.guards.size(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	benchmarks.erase("combat_tail")
	var file:=FileAccess.open("user://living-verification/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"resolution":"1920x1080","quality":"Balanced","scope":"Short populated walk, driving and combat samples; not sustained/thermal or isolated GPU profiling","phases":benchmarks},"\t"))
