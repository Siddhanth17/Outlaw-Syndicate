class_name StreetTraffic
extends Node3D

# Two retained legacy controllers plus eight closure-aware lane-graph drivers.
# All cars use actual VehicleBody3D forces, never transform playback or respawn recovery.
var game: Node3D
var cars: Array[VeyraCar]=[]
var targets: Array[int]=[1,3]
var route: Array[Vector3]=[Vector3(-67,0,70),Vector3(-67,0,215),Vector3(69,0,215),Vector3(69,0,61)]
var reasons: Array[String]=["starting","starting"]
var elapsed: float=0
var enabled: bool=true
var signals: Array[Dictionary]=[]
var network:=VeyraRoadNetwork.new()
var fleet: Array[Dictionary]=[]
var retained: Array[Dictionary]=[]
var fleet_enabled: bool=true # Balanced six-car candidate; ten-car stress mode stays test-only.
var fleet_target: int=4 # Balanced candidate: add four cars gradually, spread across both extensions.
var legacy_reservations: Dictionary={}
var spawn_pending: bool=false
var simulation_us: int=0
var pending_restore: Dictionary={}

func activate_configured_fleet() -> void:
	if fleet_enabled:set_fleet_enabled(true)

func state_of(car: VeyraCar) -> Dictionary:
	return {"position":[car.position.x,car.position.y,car.position.z],"velocity":[car.linear_velocity.x,car.linear_velocity.y,car.linear_velocity.z],"yaw":car.rotation.y,"health":car.integrity,"damage":car.damage_snapshot()}

func snapshot() -> Dictionary:
	var states: Dictionary={}
	for driver: Dictionary in retained+fleet:
		var state: Dictionary=state_of(driver.car)
		for key: String in ["a","b","c","index","admitted","completed"]:state[key]=driver[key]
		states[driver.id]=state
	var legacy: Array=[]
	for i: int in range(mini(2,cars.size())):legacy.append(state_of(cars[i]))
	return {"version":1,"enabled":fleet_enabled,"target":fleet_target,"elapsed":elapsed,"drivers":states,"legacy":legacy,"targets":targets.duplicate()}

func valid_state(state: Variant) -> bool:
	if not state is Dictionary or not LivingWorld.valid_point(state.get("position")) or not LivingWorld.valid_point(state.get("velocity")):return false
	for key: String in ["yaw","health"]:
		var number: Variant=state.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or absf(float(number))>10000:return false
	return state.health>=0 and state.health<=100 and state.get("damage",{}) is Dictionary

func validate(value: Variant) -> bool:
	if value==null:return true
	if not value is Dictionary or value.get("version")!=1 or not value.get("enabled") is bool or not value.get("drivers") is Dictionary or value.drivers.size()>10:return false
	for key: String in ["target","elapsed"]:
		var number: Variant=value.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>1000000000:return false
	if value.target>8 or float(value.target)!=floor(float(value.target)):return false
	var owners: Dictionary={}
	for id: Variant in value.drivers:
		if not id is String or not id in ["retained_00","retained_01","traffic_00","traffic_01","traffic_02","traffic_03","traffic_04","traffic_05","traffic_06","traffic_07"]:return false
		var state: Variant=value.drivers[id]
		if not valid_state(state) or not state.get("admitted") is bool:return false
		for key: String in ["a","b","c","index","completed"]:
			var number: Variant=state.get(key)
			if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>1000000000 or float(number)!=floor(float(number)):return false
		if state.index>6 or not network.connected(int(state.a),int(state.b)) or not network.connected(int(state.b),int(state.c)):return false
		if state.admitted:
			if owners.has(int(state.b)):return false
			owners[int(state.b)]=id
	if not value.get("legacy") is Array or value.legacy.size()!=2 or not value.get("targets") is Array or value.targets.size()!=2:return false
	for state: Variant in value.legacy:
		if not valid_state(state):return false
	for number: Variant in value.targets:
		if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>3 or float(number)!=floor(float(number)):return false
	return true

func apply_car_state(car: VeyraCar,state: Dictionary) -> void:
	car.reset_pose(Transform3D(Basis(Vector3.UP,float(state.yaw)),LivingWorld.point(state.position)),LivingWorld.point(state.velocity))
	car.restore_damage(state.get("damage",{}));car.integrity=float(state.health)

func apply_driver_states(value: Dictionary) -> void:
	network.reservations.clear()
	for driver: Dictionary in retained+fleet:
		if not value.drivers.has(driver.id):continue
		var state: Dictionary=value.drivers[driver.id]
		for key: String in ["a","b","c","index","completed"]:driver[key]=int(state[key])
		driver.admitted=state.admitted
		driver.points=network.movement(driver.a,driver.b,driver.c)
		if driver.admitted:network.reserve(driver.b,driver.id)
		apply_car_state(driver.car,state)
	if fleet.size()>=fleet_target:pending_restore.clear()

func restore(value: Variant) -> void:
	if value==null:return # Legacy saves did not include traffic; keep safe current simulation.
	pending_restore=value.duplicate(true)
	elapsed=float(value.elapsed)
	network.reservations.clear();legacy_reservations.clear()
	set_fleet_enabled(bool(value.enabled),int(value.target))
	if value.enabled:apply_driver_states(value)
	else:
		for i: int in range(2):apply_car_state(cars[i],value.legacy[i]);targets[i]=int(value.targets[i])
		pending_restore.clear()

func set_fleet_enabled(value: bool,count: int=-1) -> void:
	if count>=0:fleet_target=clampi(count,0,8)
	fleet_enabled=value
	if value and retained.is_empty():
		for i: int in range(mini(2,cars.size())):
			var car: VeyraCar=cars[i]
			var best: float=INF
			var a: int=0;var b: int=1
			for from: int in network.links:
				for to: int in network.links[from]:
					var start: Vector3=network.nodes[from]+network.lane_offset(from,to)
					var end: Vector3=network.nodes[to]+network.lane_offset(from,to)
					var offset: Vector3=end-start
					var t: float=clampf((car.position-start).dot(offset)/offset.length_squared(),0,1)
					var cost: float=car.position.distance_squared_to(start+offset*t)+(1-car.global_basis.z.dot(network.direction(from,to)))*25
					if cost<best:best=cost;a=from;b=to
			var c: int=network.next_junction(a,b,i)
			retained.append({"id":"retained_%02d"%i,"car":car,"a":a,"b":b,"c":c,"points":network.movement(a,b,c),"index":0,"admitted":false,"completed":0,"reason":"starting"})
		for i: int in legacy_reservations:network.release(legacy_reservations[i],"legacy_%d"%i)
		legacy_reservations.clear()
	if not value:
		for driver: Dictionary in retained:network.release(driver.b,driver.id)
		retained.clear()
	if value and fleet.size()<fleet_target:request_fleet_spawn()
	for driver: Dictionary in retained+fleet:
		var car: VeyraCar=driver.car
		car.freeze=not value
		car.set_physics_process(value)
		car.visible=value
		car.collision_layer=CollisionLayers.VEHICLE if value else 0
		car.collision_mask=CollisionLayers.SOLIDS if value else 0
		if not value:
			network.release(driver.b,driver.id);driver.admitted=false
			car.sound_model.update(1,0,0,true,car.integrity,false)
			car.tire_audio.volume_db=-80

func request_fleet_spawn() -> void:
	if spawn_pending or not fleet_enabled or fleet.size()>=fleet_target:return
	spawn_pending=true
	# Wait until the physics space contains the complete district before querying clearance.
	await get_tree().physics_frame
	await get_tree().physics_frame
	spawn_pending=false
	if fleet_enabled and fleet.size()<fleet_target:spawn_fleet()

func spawn_fleet() -> void:
	if not fleet_enabled:return
	var pairs: Array=[[9,10],[13,12],[0,1],[1,2],[2,5],[5,8],[8,7],[7,6]]
	for i: int in range(mini(fleet_target,pairs.size())):
		var id: String="traffic_%02d"%i
		if fleet.any(func(driver: Dictionary) -> bool:return driver.id==id):continue
		var a: int=pairs[i][0]
		var b: int=pairs[i][1]
		var at: Vector3=(network.nodes[a]+network.nodes[b])*.5+network.lane_offset(a,b)+Vector3.UP*.9
		var yaw: float=atan2(network.direction(a,b).x,network.direction(a,b).z)
		if pending_restore.get("drivers",{}).has(id):
			at=LivingWorld.point(pending_restore.drivers[id].position)
			yaw=float(pending_restore.drivers[id].yaw)
		var query:=PhysicsShapeQueryParameters3D.new()
		var shape:=BoxShape3D.new()
		shape.size=Vector3(2.2,1.1,4.8)
		query.shape=shape
		query.transform=Transform3D(Basis(Vector3.UP,yaw),at)
		query.collision_mask=CollisionLayers.SOLIDS
		var hits: Array[Dictionary]=get_world_3d().direct_space_state.intersect_shape(query,1)
		if not hits.is_empty():
			print("SPAWN_BLOCKED ",i," at=",at," hit=",hits[0].collider," pos=",hits[0].collider.global_position)
			continue
		var car:=VeyraCar.new()
		car.autonomous=true
		car.position=at
		car.rotation.y=yaw
		add_child(car)
		cars.append(car)
		var c:=network.next_junction(a,b,i)
		fleet.append({"id":"traffic_%02d"%i,"car":car,"a":a,"b":b,"c":c,"points":network.movement(a,b,c),"index":0,"admitted":false,"completed":0,"reason":"starting"})
	if not pending_restore.is_empty():apply_driver_states(pending_restore.duplicate(true))

func drive_fleet() -> void:
	if not fleet_enabled:return
	for driver: Dictionary in retained+fleet:
		var car: VeyraCar=driver.car
		if driver.reason=="closure" and network.next_junction(driver.b,driver.c,driver.completed)<0:
			car.ai_throttle=0;car.ai_brake=50;continue
		var point: Vector3=driver.points[driver.index]
		if Vector2(car.position.x-point.x,car.position.z-point.z).length()<2.5:
			driver.index+=1
			if driver.index>=driver.points.size():
				network.release(driver.b,driver.id)
				var next: int=network.next_junction(driver.b,driver.c,driver.completed+int(driver.id.right(2)))
				if next<0:
					car.ai_throttle=0;car.ai_brake=50;driver.index-=1;driver.reason="closure";continue
				driver.a=driver.b;driver.b=driver.c;driver.c=next
				driver.points=network.movement(driver.a,driver.b,driver.c)
				driver.index=0;driver.admitted=false;driver.completed+=1
			point=driver.points[driver.index]
		var direction: Vector3=network.direction(driver.a,driver.b)
		var distance: float=(network.nodes[driver.b]-car.position).dot(direction)
		var speed: float=car.linear_velocity.length()
		var waiting: bool=false
		if not driver.admitted and distance<25 and distance>0:
			if green(absf(direction.z)>.5) and network.reserve(driver.b,driver.id):driver.admitted=true
			elif distance<24:waiting=true
		var offset:=point-car.position
		var angle:=angle_difference(car.rotation.y,atan2(offset.x,offset.z))
		car.ai_steer=clampf(angle*.9,-.38,.38)
		var desired: float=3.5 if driver.index>0 or absf(angle)>.3 else 6
		var blocked:=obstacle(car)
		driver.reason="obstacle" if blocked else ("signal_or_priority" if waiting else "driving")
		car.ai_throttle=0 if blocked or waiting or speed>desired else .55
		car.ai_brake=50 if blocked or waiting else (15 if speed>desired+1 else 0)

func green(north_south: bool) -> bool:
	var phase: float=fposmod(elapsed,28)
	return phase<11 if north_south else phase>=14 and phase<25

func _ready() -> void:
	for i: int in range(2):
		var car:=VeyraCar.new()
		car.autonomous=true
		car.position=Vector3(-67,.9,88) if i==0 else Vector3(69,.9,190)
		car.rotation.y=0 if i==0 else PI
		add_child(car)
		cars.append(car)
	call_deferred("activate_configured_fleet")
	for x: float in VeyraQuarter.XS:
		for z: float in VeyraQuarter.ZS:
			for axis: int in range(2):
				var head: Node3D=load("res://assets/environment/urban_signal.glb").instantiate()
				head.position=Vector3(x+8+axis,.14,z+8-axis)
				head.rotation.y=axis*PI/2
				add_child(head)
				for part: Node in head.find_children("*","MeshInstance3D",true,false):
					for surface: int in range(part.mesh.get_surface_count()):
						var source: Material=part.get_active_material(surface)
						if source is StandardMaterial3D and (source.resource_name=="Signal red" or source.resource_name=="Signal green" or source.resource_name=="Signal amber"):
							var mat: StandardMaterial3D=source.duplicate()
							part.set_surface_override_material(surface,mat)
							signals.append({"material":mat,"color":source.albedo_color,"axis":axis==0,"kind":source.resource_name})

func obstacle(car: VeyraCar) -> bool:
	var speed: float=car.linear_velocity.length()
	for offset: float in [-.65,0,.65]:
		var start:=car.to_global(Vector3(offset,0,2.2))
		var ray:=PhysicsRayQueryParameters3D.create(start,start+car.global_basis.z*(4+speed*.9),CollisionLayers.SOLIDS)
		ray.exclude=[car.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return true
	return false

func _physics_process(delta: float) -> void:
	var started: int=Time.get_ticks_usec()
	_simulate_traffic(delta)
	simulation_us=Time.get_ticks_usec()-started

func _simulate_traffic(delta: float) -> void:
	var stopped: bool=game.paused or game.cinematic_active or not enabled
	for i: int in range(cars.size()):
		var car:=cars[i]
		if i>=2 and not fleet_enabled:continue
		car.freeze=stopped
		car.set_physics_process(not stopped)
	if stopped:return
	elapsed+=delta
	var phase: float=fposmod(elapsed,28)
	for lens: Dictionary in signals:
		var amber: bool=(phase>=11 and phase<12) if lens.axis else (phase>=25 and phase<26)
		var active: bool=green(lens.axis) if lens.kind=="Signal green" else (amber if lens.kind=="Signal amber" else not green(lens.axis) and not amber)
		lens.material.albedo_color=lens.color if active else Color(.018,.022,.025)
		lens.material.emission_enabled=active
	for i: int in range(0 if fleet_enabled else mini(2,cars.size())):
		var car:=cars[i]
		var point:=route[targets[i]]
		var offset:=point-car.position
		offset.y=0
		if offset.length()<7:
			targets[i]=(targets[i]+1)%route.size()
			offset=route[targets[i]]-car.position
			offset.y=0
		var angle:=angle_difference(car.rotation.y,atan2(offset.x,offset.z))
		car.ai_steer=clampf(angle*.85,-.38,.38)
		var speed: float=car.linear_velocity.length()
		var desired_speed: float=3.2 if absf(angle)>.35 else 7
		var waiting: bool=false
		var legacy_id: String="legacy_%d"%i
		if legacy_reservations.has(i):
			var node: int=legacy_reservations[i]
			if car.position.distance_to(network.nodes[node])>23:
				network.release(node,legacy_id)
				legacy_reservations.erase(i)
		var north_south: bool=absf(car.global_basis.z.z)>.7
		for x: float in VeyraQuarter.XS:
			for z: float in VeyraQuarter.ZS:
				var ahead:=car.to_local(Vector3(x,car.position.y,z))
				if ahead.z>6 and ahead.z<24 and absf(ahead.x)<5 and not green(north_south):waiting=true
				if ahead.z>0 and ahead.z<24 and absf(ahead.x)<5:
					var node: int=network.nodes.find(Vector3(x,0,z))
					if green(north_south) and network.reserve(node,legacy_id):legacy_reservations[i]=node
					elif ahead.z>9 and ahead.z<16+speed:waiting=true
		var blocked:=obstacle(car)
		reasons[i]="obstacle" if blocked else ("signal" if waiting else "driving")
		car.ai_throttle=0 if blocked or waiting or speed>desired_speed else .55
		car.ai_brake=50 if blocked or waiting else (12 if speed>desired_speed+1 else 0)
	drive_fleet()
	for i: int in range(retained.size()):reasons[i]=retained[i].reason
