class_name PhysicsValidation
extends Node

var game: Node3D
var failures: int = 0
var passes: int = 0
var obstacle: StaticBody3D
var record_frames: bool = false
var timing: Array[float] = []
var previous_tick: int = 0

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if ok: passes += 1
	else: failures += 1

func frames(n: int) -> void:
	for i: int in range(n):
		await get_tree().physics_frame

func mouse(delta: Vector2) -> void:
	await frames(3)
	var event := InputEventMouseMotion.new()
	event.screen_relative = delta
	event.relative = delta
	event.position = Vector2(640,360)
	Input.parse_input_event(event)
	await frames(2)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://physics-verification/" + name + ".png")

func crash(at: Vector3, velocity: Vector3, wall_at: Vector3, size: Vector3, duration: int = 100, heading: float = 0.0) -> void:
	if is_instance_valid(obstacle):
		obstacle.queue_free()
		await frames(2)
	obstacle = game.harbor.solid(wall_at, size)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	obstacle.add_child(mesh)
	game.car.repair()
	game.car.occupied = true
	game.car.reset_pose(Transform3D(Basis(Vector3.UP,heading), at), velocity)
	if OS.get_cmdline_user_args().has("--record-crashes"):
		game.cine_camera.current=true
		game.cine_camera.position=at+Vector3(5,3,8)
		game.cine_camera.look_at(wall_at)
		for frame: int in range(duration):
			await frames(1)
			if frame%4==0: await capture("crash-%02d-frame-%03d"%[passes,frame])
	else: await frames(duration)
	print("CONTACT_RESULT position=",game.car.position," velocity=",game.car.linear_velocity," zones=",game.car.damage.zones," panes=",game.car.damage.snapshot().windows)

func view(offset: Vector3) -> void:
	game.cine_camera.current = true
	game.cine_camera.position = game.car.position + offset
	game.cine_camera.look_at(game.car.position + Vector3.UP*0.1)
	game.ui.subtitles.text="PHYSICAL CRASH VALIDATION / developer inspection"
	game.dialogue_time=20
	game.ui.objective.text="CRASH TEST FACILITY"

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if record_frames and previous_tick > 0: timing.append((now-previous_tick)/1000.0)
	previous_tick = now

func run() -> void:
	Input.use_accumulated_input = false
	DirAccess.make_dir_recursive_absolute("user://physics-verification")
	game._set_pause(false)
	game.get_window().size = Vector2i(1920,1080)
	await frames(30)
	var old: float = game.player.yaw
	await mouse(Vector2(120,40))
	check(is_equal_approx(game.player.yaw-old,-120*game.player.sensitivity),"mouse event changes yaw through visible HUD")
	check(game.player.pitch < -0.12,"mouse event changes pitch")
	await mouse(Vector2(0,10000))
	check(is_equal_approx(game.player.pitch,-0.85),"mouse pitch clamp")
	game.player.pitch = -0.12
	var sensitivity: float = game.player.sensitivity
	game.player.sensitivity = 0.005
	old = game.player.yaw
	await mouse(Vector2(100,0))
	check(is_equal_approx(game.player.yaw-old,-0.5),"sensitivity changes actual mouse response")
	game.player.sensitivity = sensitivity
	game._set_pause(true)
	old = game.player.yaw
	await mouse(Vector2(100,0))
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and is_equal_approx(old,game.player.yaw),"pause releases capture and blocks look")
	game._set_pause(false)
	await mouse(Vector2(100,0))
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not is_equal_approx(old,game.player.yaw),"resume restores capture and mouse look")
	Input.action_press("aim")
	old=game.player.yaw
	await mouse(Vector2(60,0))
	check(game.player.aiming and not is_equal_approx(old,game.player.yaw),"aiming mouse look")
	Input.action_release("aim")
	await capture("exploration")
	game.player.position = game.car.position
	game._interact()
	old=game.player.yaw
	await mouse(Vector2(100,0))
	check(game.player.driving and not is_equal_approx(old,game.player.yaw),"mouse orbit after vehicle entry")
	old=game.player.yaw
	await frames(20)
	check(is_equal_approx(old,game.player.yaw),"driving recenter waits after mouse movement")
	game.car.linear_velocity=Vector3.ZERO
	game._leave_car()
	old=game.player.yaw
	await mouse(Vector2(100,0))
	check(not game.player.driving and not is_equal_approx(old,game.player.yaw),"mouse look after vehicle exit")
	game._save()
	game._load()
	old=game.player.yaw
	await mouse(Vector2(100,0))
	print("CAMERA_AFTER_LOAD ",old," -> ",game.player.yaw," enabled=",game.player.camera_input_enabled," paused=",game.paused," mode=",Input.mouse_mode)
	check(not is_equal_approx(old,game.player.yaw),"mouse look after save load")
	game._start_cinematic(false)
	game._end_cinematic()
	old=game.player.yaw
	await mouse(Vector2(100,0))
	check(not is_equal_approx(old,game.player.yaw),"skip returns mouse control")
	if OS.get_cmdline_user_args().has("--camera-only"):
		get_tree().quit(1 if failures else 0)
		return
	var q:=PhysicsRayQueryParameters3D.create(Vector3(-17,1,22),Vector3(-13,1,22),CollisionLayers.STATIC)
	check(not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty(),"modeled fence has solid collision")
	game.player.position=Vector3(22,0.2,0)
	game.player.yaw=0
	Input.action_press("right")
	await frames(100)
	Input.action_release("right")
	check(game.player.position.x<23.8,"player cannot walk through warehouse wall")
	game.player.position=Vector3(0,0.1,12)
	var npc := HarborGuard.new()
	npc.game=game
	npc.position=Vector3(-17,0.1,22)
	game.add_child(npc)
	npc.destination=Vector3(-13,0.1,22)
	await frames(80)
	check(npc.position.x < -15.3,"NPC movement cannot cross solid fence")
	npc.queue_free()
	game.harbor.solid(Vector3(200,-0.5,0),Vector3(90,1,90))
	game.harbor.surface(Vector3(200,0.01,0),Vector2(90,90),"asphalt",Color.WHITE,3,0.7)
	var light := OmniLight3D.new()
	light.position=Vector3(200,8,-3)
	light.omni_range=40
	light.light_energy=8
	game.add_child(light)
	var observer:=HarborGuard.new()
	observer.game=game
	observer.position=Vector3(205,0.1,-2)
	game.add_child(observer)
	game.guards.append(observer)
	await crash(Vector3(200,0.8,-7),Vector3(0,0,14),Vector3(200,1.5,0),Vector3(10,3,0.3))
	check(observer.crash_reactions>0,"NPC hears confirmed nearby physical crash")
	game.guards.erase(observer)
	observer.queue_free()
	check(game.car.position.z < -1.9 and absf(game.car.linear_velocity.z)<4,"front crash stops at concrete wall")
	check(float(game.car.damage.zones.front_center)+float(game.car.damage.zones.front_left)+float(game.car.damage.zones.front_right)>0,"confirmed front contact causes front damage")
	check(float(game.car.damage.zones.rear_center)==0,"front crash leaves rear damage untouched")
	check(game.car.damage.max_displacement>0.01 and game.car.damage.max_displacement<=0.401,"contact produces bounded mesh deformation")
	view(Vector3(-4,2.3,5));await capture("front-crash")
	await crash(Vector3(200,0.8,-7),Vector3(0,0,18),Vector3(199.25,1.5,0),Vector3(0.45,3,0.3))
	check(float(game.car.damage.zones.front_left)>0 and float(game.car.damage.zones.rear_right)==0,"front left barrier localizes damage")
	for child: Node in obstacle.get_children():
		if child is MeshInstance3D: child.hide()
	view(Vector3(-3,1.8,4));await capture("front-left")
	game.car.damage.impact(Vector3(-0.9,-0.1,1.32),Vector3(0,0,-1),20,false)
	await frames(2)
	check(game.car.wheels[1].wheel_friction_slip<3.2 and game.car.wheels[1].suspension_stiffness<45,"front wheel zone damage changes traction and suspension")
	await crash(Vector3(200,0.8,-7),Vector3(0,0,32),Vector3(200,1.5,0),Vector3(10,3,0.12))
	check(game.car.position.z < -1.8 and game.car.position.is_finite(),"32 m/s thin barrier CCD has no tunneling")
	check(game.car.integrity<80,"high speed increases severity")
	await crash(Vector3(198,0.8,0),Vector3(20,0,0),Vector3(200,1.5,0),Vector3(0.3,3,10))
	check(float(game.car.damage.zones.right_front)+float(game.car.damage.zones.right_rear)>0,"right side crash maps to right side")
	view(Vector3(4,1.8,3));await capture("right-side")
	await crash(Vector3(200,0.8,7),Vector3(0,0,-14),Vector3(200,1.5,0),Vector3(10,3,0.3))
	check(float(game.car.damage.zones.rear_left)+float(game.car.damage.zones.rear_right)+float(game.car.damage.zones.rear_center)>0,"rear crash maps to rear")
	await crash(Vector3(193,0.8,0),Vector3(14,0,0),Vector3(200,1.5,0),Vector3(0.3,3,10),100,PI/2)
	check(float(game.car.damage.zones.front_left)+float(game.car.damage.zones.front_center)+float(game.car.damage.zones.front_right)>0 and float(game.car.damage.zones.rear_left)==0,"rotated chassis contact maps into local front zones")
	await crash(Vector3(200,0.8,-2.3),Vector3(0,0,1),Vector3(200,1.5,0),Vector3(10,3,0.3),60)
	check(game.car.damage.hits.is_empty(),"minor physical contact does not dent body")
	# Narrow elevated strike reaches cabin glass, not the lower bumper.
	await crash(Vector3(198.5,0.8,0),Vector3(23,0,0),Vector3(200,1.18,0.45),Vector3(0.12,0.22,0.18))
	check(game.car.damage.glass.size()==6,"six independent authored glass components")
	var damaged: int=0
	for pane: Dictionary in game.car.damage.glass:
		if pane.state>0: damaged+=1
	check(damaged>0 and damaged<6,"eligible cabin contact affects nearby windows only")
	check(game.car.damage.glass.any(func(p:Dictionary)->bool:return p.state==3),"heavy physical window impact reaches shattered state")
	view(Vector3(3,1.6,2));await capture("glass-impact")
	# Same contact-location entry point, isolated visual-stage and accumulation tests.
	game.car.repair()
	var center: Vector3=game.car.damage.glass[0].center
	game.car.damage.impact(center,Vector3(0,0,-1),5)
	check(game.car.damage.glass[0].state==1,"selected window initial crack stage")
	view(Vector3(3,1.6,3));await capture("cracked-window")
	game.car.damage.impact(center,Vector3(0,0,-1),30)
	check(game.car.damage.glass[0].state==3 and not game.car.damage.glass[0].node.visible,"selected window shatters at threshold")
	await capture("shattered-window")
	game.car.damage.impact(Vector3(-0.65,-0.2,2),Vector3(0,0,-1),30)
	game.car.damage.impact(Vector3(-0.65,-0.2,2),Vector3(0,0,-1),30)
	check(game.car.damage.parts.any(func(p: Dictionary)->bool: return p.detached),"severe repeated front impact detaches bumper")
	check(game.car.damage.max_displacement<=0.401 and game.car.damage.hits.size()<=12,"repeat impacts stay bounded")
	view(Vector3(-3,1.8,4));await capture("detached-bumper")
	var saved: Dictionary=game.car.damage_snapshot()
	game._save()
	game.car.repair()
	check(game.car.damage.hits.is_empty() and game.car.damage.glass.all(func(p: Dictionary)->bool:return p.state==0),"repair resets geometry and glass")
	game._load()
	var restored: Dictionary = game.car.damage_snapshot()
	check(restored.hits.size()==saved.hits.size() and restored.windows==saved.windows and is_equal_approx(float(restored.zones.front_left),float(saved.zones.front_left)),"save load preserves localized damage and glass")
	# Two genuinely physical vehicle bodies.
	if is_instance_valid(obstacle): obstacle.queue_free()
	var other:=VeyraCar.new()
	other.position=Vector3(200,0.8,0)
	game.add_child(other)
	other.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,0)))
	other.occupied=true
	await frames(10)
	game.car.repair()
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,-7)),Vector3(0,0,14))
	await frames(100)
	print("VEHICLE_TRANSFER ",other.position," vs ",game.car.position)
	check(other.position.z>0.5 and game.car.position.z<other.position.z-3,"vehicle transfers momentum to another vehicle")
	other.queue_free()
	var cargo: RigidBody3D=game.harbor.movable_cargo(Vector3(200,0.05,0))
	await frames(10)
	game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,-7)),Vector3(0,0,10))
	await frames(100)
	check(cargo.position.distance_to(Vector3(200,0.05,0))>0.5,"car pushes dynamic cargo through physical contact")
	var acting := ActingValidation.new()
	acting.game=game
	game.add_child(acting)
	await acting.run()
	passes+=acting.passes
	failures+=acting.failures
	view(Vector3(-5,3,8))
	await frames(120)
	record_frames=true
	await frames(300)
	record_frames=false
	if timing.size()>0:
		var total: float=0
		for t: float in timing: total+=t
		timing.sort()
		var report: Dictionary={"mean_ms":total/timing.size(),"average_fps":1000/(total/timing.size()),"p95_ms":timing[int(timing.size()*0.95)],"samples":timing.size(),"scope":"short rendered crash scene; not full mission or isolated GPU","headless":DisplayServer.get_name()=="headless","video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
		var file:=FileAccess.open("user://physics-verification/performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print("PHYSICS_VALIDATION ",passes," passed ",failures," failed")
	get_tree().quit(1 if failures else 0)
