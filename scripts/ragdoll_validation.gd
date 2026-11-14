class_name RagdollValidation
extends Node

var game: Node3D
var passes: int=0
var failures: int=0
var results: Dictionary={}

func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1

func frames(count: int) -> void:
	for i: int in range(count):await get_tree().physics_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://ragdoll-verification/"+name+".png")

func scenario(kind: String,direction: Vector3) -> Dictionary:
	var fixtures: Array[Node3D]=[]
	var at:=Vector3(200,0.05,0)
	if kind=="wall":fixtures.append(game.harbor.solid(Vector3(200,1.4,2),Vector3(6,2.8,0.3)))
	if kind=="stairs":
		for i: int in range(6):
			fixtures.append(game.harbor.solid(Vector3(200,(i+1)*0.09,0.4+i*0.45),Vector3(5,(i+1)*0.18,0.45)))
		at=Vector3(200,1.15,2.6)
	if kind=="slope":
		var slope: StaticBody3D=game.harbor.solid(Vector3(200,0.45,0),Vector3(6,0.2,6))
		slope.rotation.x=deg_to_rad(-12)
		fixtures.append(slope)
		at=Vector3(200,1.15,2)
	for fixture: Node3D in fixtures:
		var shape: CollisionShape3D=fixture.get_child(0)
		var mesh:=MeshInstance3D.new()
		var box:=BoxMesh.new()
		box.size=(shape.shape as BoxShape3D).size
		mesh.mesh=box
		fixture.add_child(mesh)
	var npc:=CityNPC.new()
	npc.game=game
	npc.npc_id="Ragdoll_"+kind
	npc.name=npc.npc_id
	npc.appearance_id="security"
	npc.position=at
	npc.route=PackedVector3Array([at,at+Vector3(0,0,5)]) if kind=="running" else PackedVector3Array([at])
	game.add_child(npc)
	await frames(30)
	var before: Vector3=npc.global_position
	npc.take_damage(80,direction,npc.global_position+Vector3.UP*1.3)
	var rag:=npc.ragdoll
	check(rag.active and rag.bones.size()==13 and rag.simulator.is_simulating_physics(),kind+": thirteen articulated physical segments activate")
	var minimum_y: float=100
	var minimum_support_y: float=100
	var highest: float=-100
	var speed: float=0
	var self_contacts: int=0
	var contacts: int=0
	var angular_error: float=0
	var angular_debug: String=""
	var start_joints: Dictionary={}
	for name: String in rag.bones:start_joints[name]=rag.bones[name].global_position
	game.cine_camera.current=true
	game.cine_camera.position=Vector3(204,3.2,-4) if kind=="wall" else (Vector3(204,3.4,-1) if kind=="stairs" else Vector3(204,3.2,6))
	game.cine_camera.look_at(Vector3(200,0.7,1.5))
	game.cine_camera.fov=48
	for frame: int in range(240):
		await frames(1)
		var error: float=rag.limit_error_degrees()
		if error>angular_error:
			angular_error=error
			angular_debug=rag.limit_diagnostic+" frame "+str(frame)
		for body: HarborPhysicalBone in rag.bones.values():
			minimum_y=minf(minimum_y,body.global_position.y)
			for shape: Node in body.get_children():
				if shape is CollisionShape3D and shape.shape is CapsuleShape3D:
					var world: Transform3D=body.global_transform*shape.transform
					var capsule: CapsuleShape3D=shape.shape
					minimum_support_y=minf(minimum_support_y,world.origin.y-absf(world.basis.y.y)*(capsule.height*0.5-capsule.radius)-capsule.radius)
			highest=maxf(highest,body.global_position.y)
			speed=maxf(speed,body.peak_speed)
		if OS.get_cmdline_user_args().has("--record-ragdoll") and frame%12==0:await capture(kind+"-%03d"%frame)
		if frame==30:await capture(kind+"-fall")
		if frame==180:await capture(kind+"-rest")
	check(not game.paused and game.player.health>0,kind+": scenario completes without external defeat pausing physics")
	for body: HarborPhysicalBone in rag.bones.values():
		contacts+=body.contacts
		self_contacts+=body.self_contacts
	check(minimum_support_y>=-0.045 and highest<4 and speed<=8.01,kind+": physical segments remain above the ground and velocity bounds")
	check(angular_error<12,kind+": hinge and cone angular limits remain within solver tolerance")
	check(rag.peak_joint_gap<0.12,kind+": constrained joints avoid excessive separation")
	check(contacts>0 and rag.max_speed()<0.6,kind+": actual contacts occur and the body settles")
	var torso: Vector3=rag.bones.Head.global_position-rag.bones.Hips.global_position
	var folded: bool=false
	for name: String in ["LeftForeArm","RightForeArm","LeftLeg","RightLeg"]:
		if rag.bones[name].global_basis.get_rotation_quaternion().angle_to(rag.bones.Hips.global_basis.get_rotation_quaternion())>0.25:folded=true
	check(folded and rag.cached.size()==32,kind+": limbs articulate and physical poses drive the skinned rig")
	if kind=="wall":check(rag.bones.Head.global_position.z<2.15, "wall: head does not pass through the barrier")
	var result: Dictionary={"player_health":game.player.health,"paused":game.paused,"minimum_capsule_support_y":minimum_support_y,"minimum_center_y":minimum_y,"highest_center_y":highest,"peak_speed":speed,"peak_joint_gap":rag.peak_joint_gap,"self_contacts":self_contacts,"contacts":contacts,"angular_debug":angular_debug,"angular_limit_excess_degrees":angular_error,"rest_speed":rag.max_speed(),"torso_direction":[torso.x,torso.y,torso.z]}
	if kind=="frontal":
		check(rag.frozen,"settled defeated body sleeps without disappearing or losing collision")
		var camera_before: Transform3D=game.player.camera.transform
		game.player.set_physics_process(false)
		game.player.camera.global_position=rag.pelvis_position()+Vector3(2,1.2,0)
		game.player.camera.look_at(rag.pelvis_position())
		game.cooldown=0
		game.ammunition=12
		game._fire()
		await frames(2)
		check(not rag.frozen and game.ammunition==11,"actual player hitscan reaches and wakes a settled physical body")
		game.player.camera.transform=camera_before
		game.player.set_physics_process(true)
		game._set_pause(true)
		await frames(2)
		var frozen_at: Vector3=rag.pelvis_position()
		await frames(20)
		check(rag.pelvis_position().distance_to(frozen_at)<0.005,"pause holds the articulated body without drift")
		game._set_pause(false)
		npc.restore_outcome(70)
		await frames(2)
		check(not rag.active and not npc.body_collision.disabled and npc.collision_layer==CollisionLayers.NPC,"checkpoint restoration cancels physical simulation")
	npc.queue_free()
	for fixture: Node3D in fixtures:fixture.queue_free()
	await frames(3)
	return result

func run() -> void:
	game.test_mode=true
	game._set_pause(false)
	game._end_cinematic()
	DirAccess.make_dir_recursive_absolute("user://ragdoll-verification")
	RagdollLaboratory.build_ground(game)
	game.player.position=Vector3(205,0.05,6)
	game.player.health=100
	game.player.velocity=Vector3.ZERO
	await frames(5)
	for kind: String in ["frontal","side","running","wall","stairs","slope"]:
		results[kind]=await scenario(kind,Vector3.RIGHT if kind=="side" else (Vector3(0,0,-1) if kind in ["stairs","slope"] else Vector3(0,0,1)))
	var self_contacts: int=0
	for result: Dictionary in results.values():self_contacts+=int(result.self_contacts)
	check(self_contacts>0,"non-adjacent limbs and torso make actual self-collision contacts")
	var a: Array=results.frontal.torso_direction
	var b: Array=results.side.torso_direction
	check(Vector3(a[0],a[1],a[2]).normalized().dot(Vector3(b[0],b[1],b[2]).normalized())<0.9,"frontal and side impulses produce distinct resting orientations")
	check(game.character_impacts.bursts.size()==12 and game.character_impacts.marks.size()==12,"restrained impact particles and floor marks use fixed pools")
	var witness:=CityNPC.new()
	witness.game=game
	witness.appearance_id="pedestrian"
	witness.position=Vector3(200,0.05,5)
	witness.route=PackedVector3Array([witness.position])
	game.add_child(witness)
	await frames(3)
	var event: Dictionary={"kind":"defeat","position":Vector3(200,0,0),"severity":30}
	witness._on_incident(event)
	check(witness.panic_count==1,"nearby civilian notices an unobstructed defeat")
	witness.danger_time=0
	var blocker: StaticBody3D=game.harbor.solid(Vector3(200,1.2,2.5),Vector3(4,2.4,0.2))
	await frames(3)
	witness._on_incident(event)
	check(witness.panic_count==1,"wall occlusion prevents magical defeat awareness")
	witness.queue_free()
	blocker.queue_free()
	await frames(3)
	if DisplayServer.get_name()!="headless":await benchmark()
	var file:=FileAccess.open("user://ragdoll-verification/physics-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("RAGDOLL_VALIDATION ",passes," passed ",failures," failed")
	get_tree().quit(1 if failures else 0)

func benchmark() -> void:
	game.quality=1
	game.harbor.preset(1)
	game.get_window().size=Vector2i(1920,1080)
	game.player.position=Vector3(204,0.1,6)
	game.player.health=100
	game.player.yaw=0
	var crowd: Array[CityNPC]=[]
	for i: int in range(9):
		var actor:=CityNPC.new()
		actor.game=game
		actor.appearance_id="industrial_worker"
		actor.position=Vector3(196+(i%3)*2.5,0.05,-5+(i/3)*3)
		actor.route=PackedVector3Array([actor.position,actor.position+Vector3(0,0,3)])
		actor.npc_id="BudgetSubject_%d"%i
		game.add_child(actor)
		crowd.append(actor)
	await frames(45)
	for i: int in range(6):crowd[i].take_damage(80,Vector3(0.4,0,1).normalized(),crowd[i].global_position+Vector3.UP*1.2)
	game.player.camera.current=true
	Input.action_press("forward")
	var timing: Array[float]=[]
	var physics: Array[float]=[]
	var start:=Time.get_ticks_usec()
	var previous: int=start
	while Time.get_ticks_usec()-start<3000000:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		timing.append((now-previous)/1000.0)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		previous=now
	Input.action_release("forward")
	timing.sort()
	var total: float=0
	for value: float in timing:total+=value
	var slow: float=0
	var count: int=maxi(1,int(ceil(timing.size()*0.01)))
	for i: int in range(count):slow+=timing[-1-i]
	var physics_sum: float=0
	for value: float in physics:physics_sum+=value
	var report: Dictionary={"resolution":"1920x1080","quality":"Balanced","scope":"Three-second uncapped render sample with six newly activated ragdolls, three nearby animated workers, player traversal and the existing global population. No capture encoding during measurement; no traffic or world streaming test.","frames":timing.size(),"average_fps":1000/(total/timing.size()),"mean_ms":total/timing.size(),"p95_ms":timing[int(timing.size()*0.95)],"one_percent_low_fps":1000/(slow/count),"max_ms":timing[-1],"physics_process_mean_ms":physics_sum/physics.size(),"engine_static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"physical_segments":78,"nearby_animated_workers":3,"global_ambient_population":game.people.size()}
	var file:=FileAccess.open("user://ragdoll-verification/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	check(crowd.slice(0,6).all(func(actor: CityNPC) -> bool:return actor.ragdoll.active and actor.ragdoll.pelvis_position().is_finite()),"six concurrent ragdolls remain valid during player traversal")
	await capture("populated-physics-budget")
	for actor: CityNPC in crowd:actor.queue_free()
