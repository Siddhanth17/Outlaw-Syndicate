class_name ExpansionValidation
extends Node
var game: Node3D
var samples: Array[float]=[]
var npc_us: Array[float]=[]
var traffic_us: Array[float]=[]
var physics_ms: Array[float]=[]
var measuring: bool=false
var previous: int=0
var passes: int=0
var failures: int=0
var texture_bytes: float=0
var static_bytes: float=0
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func _process(_delta: float) -> void:
	if not measuring:return
	var now: int=Time.get_ticks_usec()
	if previous>0:samples.append((now-previous)/1000.0)
	previous=now
	npc_us.append(game.living.npc_cost_us)
	traffic_us.append(game.traffic.simulation_us)
	physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	texture_bytes=maxf(texture_bytes,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	static_bytes=maxf(static_bytes,Performance.get_monitor(Performance.MEMORY_STATIC))
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--capture-expansion"):return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://expansion-verification/"+name+".png")
func statistics(values: Array[float]) -> Dictionary:
	if values.is_empty():return {}
	values.sort()
	var total: float=0
	for value: float in values:total+=value
	return {"mean":total/values.size(),"p95":values[int((values.size()-1)*.95)],"p99":values[int((values.size()-1)*.99)],"max":values[-1]}
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	for i: int in range(6):await get_tree().physics_frame
	game._menu_action("New game")
	game.traffic.set_fleet_enabled(true,4)
	game.quarter.minutes=60 if OS.get_cmdline_user_args().has("--night") else 600
	game.quarter.apply_clock()
	game.car.reset_pose(Transform3D(Basis(Vector3.UP,-PI/2),Vector3(-98,.9,61)))
	game._enter_car_immediate();game.car.autonomous=true
	for i: int in range(30):await get_tree().physics_frame
	DirAccess.make_dir_recursive_absolute("user://expansion-verification")
	var network: VeyraRoadNetwork=game.traffic.network
	var route: Array[int]=[0,9,10,11,2,5,8,14,13,12,6,3,0]
	var stage: int=0
	var index: int=0
	var admitted: bool=false
	var points: PackedVector3Array=network.movement(route[0],route[1],route[2])
	var west: bool=false;var east: bool=false
	var traveled: float=0
	var last: Vector3=game.car.position
	var on_road: int=0
	var ticks: int=0
	measuring=DisplayServer.get_name()!="headless"
	var started: int=Time.get_ticks_usec()
	for i: int in range(24000):
		ticks+=1
		var car: VeyraCar=game.car
		var b: int=route[stage+1]
		var direction: Vector3=network.direction(route[stage],b)
		var distance: float=(network.nodes[b]-car.position).dot(direction)
		var waiting: bool=false
		if not admitted and distance<25 and distance>0:
			if game.traffic.green(absf(direction.z)>.5) and network.reserve(b,"acceptance_driver"):admitted=true
			elif distance<24:waiting=true
		if Vector2(car.position.x-points[index].x,car.position.z-points[index].z).length()<2.5:
			index+=1
			if index>=points.size():
				network.release(b,"acceptance_driver")
				stage+=1
				print("EXPANSION_JUNCTION ",stage," position=",car.position)
				if stage in [1,4,7,10]:await capture("district-stage-%02d"%stage)
				if stage>=route.size()-2:break
				points=network.movement(route[stage],route[stage+1],route[stage+2]);index=0;admitted=false
		var offset: Vector3=points[index]-car.position
		var angle: float=angle_difference(car.rotation.y,atan2(offset.x,offset.z))
		var desired: float=3.5 if index>0 or absf(angle)>.3 else 7
		var blocked: bool=game.traffic.obstacle(car)
		car.ai_steer=clampf(angle*.9,-.38,.38)
		car.ai_throttle=0 if waiting or blocked or car.linear_velocity.length()>desired else .55
		car.ai_brake=50 if waiting or blocked else (15 if car.linear_velocity.length()>desired+1 else 0)
		await get_tree().physics_frame
		traveled+=car.position.distance_to(last);last=car.position
		west=west or car.position.x<-110;east=east or car.position.x>115
		var street: bool=false
		for x: float in VeyraQuarter.XS:street=street or absf(car.position.x-x)<7
		for z: float in VeyraQuarter.ZS:street=street or absf(car.position.z-z)<7
		if street and car.position.y>0 and car.position.y<2:on_road+=1
	measuring=false
	var seconds: float=(Time.get_ticks_usec()-started)/1000000.0
	check(stage==route.size()-2 and west and east,"actual vehicle completes the connected west/original/east road circuit through eleven junctions")
	check(traveled>650 and float(on_road)/maxi(ticks,1)>.99,"long physics drive remains on road rather than crossing buildings or empty scenery")
	check(game.car.integrity>85,"district traversal preserves vehicle condition")
	check(game.people.size()==36 and not game.story_active,"expanded traversal retains resident identities and optional story")
	if DisplayServer.get_name()!="headless" and not samples.is_empty():
		var times: Dictionary=statistics(samples)
		var worst: float=0
		var count: int=maxi(1,int(ceil(samples.size()*.01)))
		for j: int in range(samples.size()-count,samples.size()):worst+=samples[j]
		var report: Dictionary={"seconds":seconds,"frames":samples.size(),"mean_fps":1000/times.mean,"one_percent_low_fps":1000/(worst/count),"frame_ms":times,"npc_cpu_us_per_physics_step":statistics(npc_us),"traffic_cpu_us_per_physics_step":statistics(traffic_us),"all_physics_ms":statistics(physics_ms),"texture_buffer_bytes_peak":texture_bytes,"static_alloc_bytes_peak":static_bytes,"traveled_meters":traveled,"junctions_completed":stage,"traffic_vehicles":game.traffic.cars.filter(func(c: VeyraCar) -> bool:return c.visible).size(),"render_size":[1920,1080],"audio_dsp_cpu":"NOT MEASURED; engine parameter updates are inside vehicle physics, not mixer-thread timing","scope":"automated physics circuit at normal driving camera, west/original/east streaming, 36 identities and six traffic vehicles; capture opt-in only; default benchmark performs no image readback or recording"}
		FileAccess.open("user://expansion-verification/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		print("EXPANSION_PERFORMANCE ",JSON.stringify(report))
		check(game.get_viewport().get_texture().get_size()==Vector2(1920,1080),"sustained district drive renders at native 1920x1080")
	game.car.autonomous=false
	print("EXPANSION_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
