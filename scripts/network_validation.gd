class_name NetworkValidation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var tick: int=0
var recorded: int=0
var frame_ms: Array[float]=[]
func _process(delta: float) -> void:
	if tick>120 and tick<3600:frame_ms.append(delta*1000.0)
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frame() -> void:
	await get_tree().physics_frame
	tick+=1
	if DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().has("--record-network") and tick%12==0:
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://network-verification/intersection-%03d.png"%recorded)
		recorded+=1
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	for i: int in range(5):await get_tree().physics_frame
	game._menu_action("New game")
	game.traffic.set_fleet_enabled(true,8)
	for i: int in range(3):await get_tree().physics_frame
	game.player.position=Vector3(7,.2,126)
	game.player.yaw=PI*.75
	game.player.pitch=-.12
	game.quarter.minutes=600
	game.quarter.apply_clock()
	game.quarter.refresh(true)
	game.player.camera.current=true
	DirAccess.make_dir_recursive_absolute("user://network-verification")
	var road:=VeyraRoadNetwork.new()
	var edge_count: int=0
	for links: Array in road.links.values():edge_count+=links.size()
	check(road.nodes.size()==15 and edge_count==44,"fifteen junction IDs connect west, old quarter and east through forty-four directed edges")
	check(road.route(0,8).size()==5,"lane graph finds a connected cross-quarter route")
	road.close_lane(0,1,true)
	check(road.route(0,2).size()>3 and road.route(0,2)[1]!=1,"road closure changes routing instead of retaining a blocked edge")
	road.close_lane(0,1,false)
	check(road.reserve(4,"a") and not road.reserve(4,"b"),"conflicting intersection admission has a single owner")
	road.release(4,"a")
	check(road.reserve(4,"b"),"cleared intersection admission can be acquired by another driver")
	check(game.traffic.cars.size()==10 and game.traffic.fleet.size()==8,"ten physical traffic vehicles pass spawn-clearance checks")
	var lead: VeyraCar=game.traffic.fleet[2].car
	var obstacle: StaticBody3D=game.harbor.solid(lead.position+Vector3(0,.4,12),Vector3(3,2,1))
	await get_tree().physics_frame
	for i: int in range(480):
		await get_tree().physics_frame
		if i>30 and game.traffic.fleet[2].reason=="obstacle" and lead.linear_velocity.length()<.5:break
	print("GRAPH_OBSTACLE position=",lead.position," speed=",lead.linear_velocity.length()," reason=",game.traffic.fleet[2].reason," barrier=",obstacle.position)
	check(game.traffic.fleet[2].reason=="obstacle" and lead.linear_velocity.length()<1 and lead.position.z<obstacle.position.z-3,"graph driver stops within eight seconds with physical clearance before a lane obstruction")
	var stopped_at: Vector3=lead.position
	obstacle.queue_free()
	game.traffic.elapsed=0
	for i: int in range(240):await get_tree().physics_frame
	check(lead.position.distance_to(stopped_at)>3,"graph driver resumes after a temporary lane obstruction is removed")
	var start: Array[Vector3]=[]
	for car: VeyraCar in game.traffic.cars:start.append(car.position)
	var last: Array[Vector3]=start.duplicate()
	var traveled: Array[float]=[]
	traveled.resize(game.traffic.cars.size());traveled.fill(0)
	for i: int in range(3600):
		await frame()
		for j: int in range(game.traffic.cars.size()):
			traveled[j]+=game.traffic.cars[j].position.distance_to(last[j])
			last[j]=game.traffic.cars[j].position
	print("RESERVATIONS ",game.traffic.network.reservations," legacy=",game.traffic.legacy_reservations," targets=",game.traffic.targets," reasons=",game.traffic.reasons)
	var moved: int=0
	var intact: int=0
	var on_road: int=0
	for i: int in range(game.traffic.cars.size()):
		var car: VeyraCar=game.traffic.cars[i]
		if traveled[i]>15:moved+=1
		if car.integrity>85:intact+=1
		var street: bool=false
		for x: float in VeyraQuarter.XS:street=street or absf(car.position.x-x)<6.3
		for z: float in [58,138,218]:street=street or absf(car.position.z-z)<6.3
		if street and car.position.y>0 and car.position.y<2:on_road+=1
		print("TRAFFIC_FINAL ",i," ",car.position," integrity=",car.integrity," actual_distance=",traveled[i]," net_displacement=",car.position.distance_to(start[i]))
	var completed: int=0
	var drivers: int=0
	for driver: Dictionary in game.traffic.fleet:
		completed+=driver.completed
		if driver.completed>0:drivers+=1
		print("ROUTE_FINAL ",driver.id," completed=",driver.completed," reason=",driver.reason," admitted=",driver.admitted," a/b/c=",[driver.a,driver.b,driver.c]," point=",driver.index)
	check(moved==10,"all ten cars actually traverse more than fifteen meters during a minute of simulation")
	check(drivers>=6 and completed>=10,"multiple independent graph drivers clear successive junction movements")
	check(intact==10,"traffic minute avoids destructive collisions")
	check(on_road==10,"traffic remains on the physical road network without falling or entering buildings")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://network-verification/intersection-final.png")
		check(game.get_viewport().get_texture().get_size()==Vector2(1920,1080),"ten-car rendering capture uses native 1920x1080")
		frame_ms.sort()
		if not frame_ms.is_empty():
			var total: float=0
			for ms: float in frame_ms:total+=ms
			var report: Dictionary={"frames":frame_ms.size(),"mean_fps":1000.0*frame_ms.size()/total,"p95_ms":frame_ms[int((frame_ms.size()-1)*.95)],"p99_ms":frame_ms[int((frame_ms.size()-1)*.99)],"max_ms":frame_ms[-1],"scope":"fixed intersection camera; ten physical cars, ordinary citizen activation; short sample"}
			FileAccess.open("user://network-verification/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
			print("NETWORK_PERFORMANCE ",JSON.stringify(report))
	print("NETWORK_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
