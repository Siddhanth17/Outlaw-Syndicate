class_name PoliceUnit
extends Node3D
const ID: String="veyra_patrol_01"
var game: Node3D
var officer: CityNPC
var car: VeyraCar
var network: VeyraRoadNetwork
var duty: String="patrol"
var case_id: int=0
var destination_node: int=-1
var a: int=3
var b: int=4
var c: int=5
var index: int=0
var admitted: bool=false
var points:=PackedVector3Array()
var travel_meters: float=0
var previous:=Vector3.ZERO
var blocked_seconds: float=0
var transition: float=0
var exit_point:=Vector3.ZERO
var lights: Array[MeshInstance3D]=[]
var clock: float=0
var sight_clock: float=0
var last_seen:=Vector3.ZERO
var search_seconds: float=0
var officer_target:=Vector3.INF
var siren: AudioStreamPlayer3D
var siren_clock: float=-12
var resume_pursuit: bool=false
var boarding_from:=Vector3.ZERO
var flash: OmniLight3D
var command_voice: AudioStreamPlayer3D
var command_lines: Dictionary={}
var command_history: Array[String]=[]
var command_at_car: bool=false

var simulation_us: int=0

func _ready() -> void:
	network=game.traffic.network
	car=VeyraCar.new();car.name="VeyraPatrolCar01";car.autonomous=true
	car.position=Vector3(3,.9,108);add_child(car);previous=car.position
	for x: float in [-.25,.25]:
		var lamp:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(.36,.06,.18);lamp.mesh=mesh
		var material:=StandardMaterial3D.new();material.albedo_color=Color(.035,.12,.7);material.emission_enabled=true;material.emission=Color(.05,.15,1);material.emission_energy_multiplier=2
		lamp.material_override=material;car.add_child(lamp);lamp.position=Vector3(x,.8,0);lamp.hide();lights.append(lamp)
	siren=AudioStreamPlayer3D.new();siren.bus="Vehicles";siren.stream=load("res://assets/audio/law/patrol_siren.wav");siren.volume_db=-24;siren.max_distance=75;car.add_child(siren)
	command_lines=JSON.parse_string(FileAccess.get_file_as_string("res://data/police_voices.json"))
	command_voice=AudioStreamPlayer3D.new();command_voice.bus="Dialogue";command_voice.volume_db=-12;command_voice.max_distance=40;add_child(command_voice)
	for side: float in [-1,1]:
		var badge:=Label3D.new();badge.text="VEYRA\nPOLICE";badge.font_size=48;badge.pixel_size=.002;badge.modulate=Color(.85,.92,1);car.add_child(badge);badge.position=Vector3(side*.97,-.08,.35);badge.rotation.y=side*PI/2
	flash=OmniLight3D.new();flash.light_color=Color(.08,.2,1);flash.light_energy=2;flash.omni_range=8;flash.shadow_enabled=false;flash.distance_fade_enabled=true;flash.distance_fade_begin=35;flash.distance_fade_length=20;car.add_child(flash);flash.position=Vector3(0,.85,0);flash.hide()
	points=network.movement(a,b,c)
	officer=game.law.witness("officer_01")
	if officer:
		officer.citizen_name="Rowan Hale"
		if game.living.identities.has(officer.npc_id):game.living.identities[officer.npc_id].name="Officer Rowan Hale"
		seat_officer()

func seat_officer() -> void:
	if not officer or officer.health<=0:return
	officer.set_physics_process(false);officer.collision_layer=0;officer.collision_mask=0
	for region: NPCHitRegion in officer.hit_regions:region.collision_layer=0
	officer.visual.hide();officer.position=car.to_global(Vector3(-.45,-.55,0))

func next_for_goal() -> int:
	if duty=="pursuit" and b==destination_node:
		var best: int=-1;var score: float=-INF
		for next: int in network.links[b]:
			if next==a or not network.connected(b,next):continue
			var alignment: float=network.direction(b,next).dot((last_seen-network.nodes[b]).normalized())
			if alignment>score:score=alignment;best=next
		if best>=0:return best
	if destination_node<0 or b==destination_node:return network.next_junction(a,b,case_id+index)
	# Search directed-edge states, so dispatch never asks the sedan for an
	# unsupported instantaneous U-turn at the very next intersection.
	var queue: Array=[PackedInt32Array([a,b])]
	var visited: Dictionary={network.key(a,b):true}
	while not queue.is_empty():
		var path: PackedInt32Array=queue.pop_front()
		var previous_node: int=path[-2];var node: int=path[-1]
		if node==destination_node and path.size()>2:return path[2]
		for next: int in network.links[node]:
			if next==previous_node or not network.connected(node,next) or visited.has(network.key(node,next)):continue
			visited[network.key(node,next)]=true
			var extension: PackedInt32Array=path.duplicate();extension.append(next);queue.append(extension)
	return -1

func assign(id: int,at: Vector3) -> bool:
	if duty!="patrol" or not officer or officer.health<=0:return false
	var new_assignment: bool=case_id!=id
	case_id=id;destination_node=0
	for j: int in range(network.nodes.size()):
		if at.distance_squared_to(network.nodes[j])<at.distance_squared_to(network.nodes[destination_node]):destination_node=j
	duty="respond";blocked_seconds=0
	if index==0 and not admitted:
		var next: int=next_for_goal()
		if next>=0:c=next;points=network.movement(a,b,c)
	if new_assignment:command("dispatch_ack")
	return true

func command(key: String) -> bool:
	if not command_lines.has(key) or not officer or officer.health<=0:return false
	command_at_car=key=="dispatch_ack"
	command_voice.global_position=car.global_position if command_at_car else officer.global_position+Vector3.UP*1.4
	command_voice.stream=load(command_lines[key].audio)
	if DisplayServer.get_name()!="headless":command_voice.play()
	command_history.append(key)
	if command_history.size()>16:command_history.pop_front()
	game._say("Officer Hale",command_lines[key].line+(" [E] Respond to officer." if key=="officer_stop" else ""))
	return true

func drive(delta: float) -> void:
	var direction: Vector3=network.direction(a,b)
	var distance: float=(network.nodes[b]-car.position).dot(direction)
	if duty in ["respond","pursuit"] and b==destination_node and distance<20 and distance>0 and not (duty=="pursuit" and (game.player.driving or game.player.riding_bike)):
		car.ai_throttle=0;car.ai_brake=50
		if car.linear_velocity.length()<.45:begin_exit()
		return
	if Vector2(car.position.x-points[index].x,car.position.z-points[index].z).length()<2.5:
		index+=1
		if index>=points.size():
			network.release(b,ID);a=b;b=c;index=0;admitted=false
			c=next_for_goal()
			if c<0:duty="route_unavailable";car.ai_throttle=0;car.ai_brake=50;return
			points=network.movement(a,b,c)
	var waiting: bool=false
	if not admitted and distance<25 and distance>0:
		var priority_response: bool=duty in ["respond","pursuit"] and response_tier()>=4 and not game.traffic.obstacle(car)
		if (game.traffic.green(absf(direction.z)>.5) or priority_response) and network.reserve(b,ID):admitted=true
		elif distance<24:waiting=true
	var blocked: bool=game.traffic.obstacle(car)
	blocked_seconds=blocked_seconds+delta if blocked else 0
	var offset: Vector3=points[index]-car.position
	var angle: float=angle_difference(car.rotation.y,atan2(offset.x,offset.z))
	var desired: float=3.5 if index>0 or absf(angle)>.3 else (7 if duty in ["respond","pursuit"] else 6)
	car.ai_steer=clampf(angle*.9,-.38,.38)
	car.ai_throttle=0 if waiting or blocked or car.linear_velocity.length()>desired else .55
	car.ai_brake=50 if waiting or blocked else (15 if car.linear_velocity.length()>desired+1 else 0)
	if blocked_seconds>25:duty="obstructed";car.ai_throttle=0;car.ai_brake=50

func outside_point() -> Variant:
	for side: float in [-1,1]:
		var at: Vector3=car.to_global(Vector3(side*2.3,-.5,0))
		var ground:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP*3,CollisionLayers.STATIC)
		var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(ground)
		if hit.is_empty() or hit.normal.y<.7:continue
		at=hit.position+Vector3.UP*.05
		var query:=PhysicsShapeQueryParameters3D.new();var shape:=CapsuleShape3D.new();shape.radius=.34;shape.height=1.8
		query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*.9);query.collision_mask=CollisionLayers.SOLIDS
		query.exclude=[car.get_rid(),officer.get_rid()]
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return at
	return null

func begin_exit() -> void:
	var at: Variant=outside_point()
	if at==null:return
	exit_point=at;transition=0;duty="exiting";network.release(b,ID);admitted=false
	officer.visual.show();officer._play("Exit")

func walk_to(at: Vector3) -> void:
	if officer_target.is_finite() and officer_target.distance_to(at)<.5:return
	officer_target=at
	officer.suspicion=0;officer.danger_time=0
	officer.daily_destinations={"home":at,"work":at,"break":at}
	officer.schedule_config["stationary_work"]=true
	officer.schedule_period="";officer.update_schedule()
	officer.route=PackedVector3Array([at]);officer.route_index=0
	officer.activity_time=0;officer.planned_target=Vector3.INF

func can_identify() -> bool:
	if not officer or officer.position.distance_to(game.player.position)>(45 if duty=="pursuit" else 30):return false
	var ray:=PhysicsRayQueryParameters3D.create(officer.position+Vector3.UP*1.4,game.player.position+Vector3.UP,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
	ray.exclude=[car.get_rid()]
	var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (game.player.driving and hit.collider==game.car) or (game.player.riding_bike and hit.collider==game.bike)

func _physics_process(delta: float) -> void:
	var began: int=Time.get_ticks_usec()
	_simulate_unit(delta)
	simulation_us=Time.get_ticks_usec()-began

func _simulate_unit(delta: float) -> void:
	car.freeze=game.paused or game.cinematic_active
	command_voice.stream_paused=car.freeze
	command_voice.global_position=car.global_position if command_at_car else officer.global_position+Vector3.UP*1.4
	if car.freeze:
		if siren:siren.stop()
		return
	if game.law.locked():car.ai_throttle=0;car.ai_brake=50;return
	clock+=delta
	if duty in ["respond","pursuit"] and response_tier()>=3 and clock-siren_clock>12 and car.position.distance_to(game.player.position)<75:
		siren_clock=clock
		if DisplayServer.get_name()!="headless":siren.play()
	for i: int in range(lights.size()):lights[i].visible=duty in ["respond","pursuit","investigate","approach","arrest_offer"] and response_tier()>=3 and int(clock*5)%2==i
	flash.visible=duty in ["respond","pursuit","investigate","approach","arrest_offer"] and response_tier()>=3 and int(clock*5)%2==0
	travel_meters+=car.position.distance_to(previous);previous=car.position
	if not officer or officer.health<=0:duty="officer_down";car.ai_throttle=0;car.ai_brake=50;command_voice.stop();return
	if duty in ["patrol","respond","pursuit"]:
		seat_officer()
		if duty=="pursuit":
			search_seconds-=delta;sight_clock-=delta
			if sight_clock<=0:
				sight_clock=.3
				if can_identify():
					last_seen=game.player.position;search_seconds=15+response_tier()*3
					var case: Dictionary=game.law.active_case(case_id)
					case.position=[last_seen.x,last_seen.y,last_seen.z]
					case["known_vehicle"]="sable_gt" if game.player.driving else ("harrier" if game.player.riding_bike else "on_foot")
					destination_node=nearest_node(last_seen)
					if index==0 and not admitted:
						var next: int=next_for_goal()
						if next>=0:c=next;points=network.movement(a,b,c)
			if search_seconds<=0:
				game.law.suspend_case(case_id);case_id=0;destination_node=-1;duty="patrol"
			elif (game.player.driving or game.player.riding_bike) and car.position.distance_to(last_seen)<12 and can_identify():
				car.ai_throttle=0;car.ai_brake=50;return
		drive(delta);return
	car.ai_throttle=0;car.ai_brake=50
	if duty=="exiting":
		transition=minf(1,transition+delta/.75)
		car.set_driver_door(sin(transition*PI)*1.1)
		officer.position=car.to_global(Vector3(-.45,-.55,0)).lerp(exit_point,transition)
		if transition>=1:
			car.set_driver_door(0)
			officer.restore_outcome(officer.health);game.living.set_active(officer,true)
			walk_to(game.law.case_position(case_id));duty="investigate";search_seconds=15+response_tier()*5
		return
	if duty in ["investigate","approach","arrest_offer"]:
		search_seconds-=delta;sight_clock-=delta
		if sight_clock<=0:
			sight_clock=.3
			if can_identify() and game.law.matches_suspect(case_id):
				game.law.identify_case(case_id)
				last_seen=game.player.position;search_seconds=10+response_tier()*3
				if (game.player.driving or game.player.riding_bike) and response_tier()>=3:
					resume_pursuit=true;duty="returning";walk_to(exit_point);return
				if officer.position.distance_to(last_seen)<3.2 and not game.player.driving and not game.player.riding_bike:
					if duty!="arrest_offer":command("officer_stop")
					duty="arrest_offer";walk_to(officer.position)
				else:duty="approach";walk_to(last_seen)
			elif duty in ["arrest_offer","approach"]:duty="investigate";walk_to(last_seen)
		if search_seconds<=0:
			game.law.suspend_case(case_id);duty="returning";walk_to(exit_point)
	elif duty=="returning":
		if resume_pursuit and can_identify():last_seen=game.player.position
		if officer.position.distance_to(exit_point)<1:
			duty="boarding";boarding_from=officer.position;transition=0;officer._play("Enter")
			officer.set_physics_process(false);officer.collision_layer=0;officer.collision_mask=0
			for region: NPCHitRegion in officer.hit_regions:region.collision_layer=0
	elif duty=="boarding":
		transition=minf(1,transition+delta/.75)
		car.set_driver_door(sin(transition*PI)*1.1)
		officer.position=boarding_from.lerp(car.to_global(Vector3(-.45,-.55,0)),transition)
		if transition>=1:
			car.set_driver_door(0);seat_officer();duty="patrol"
			if resume_pursuit:
				assign(case_id,last_seen);duty="pursuit";search_seconds=15+response_tier()*3;resume_pursuit=false
			else:case_id=0;destination_node=-1
	elif duty=="obstructed" and not game.traffic.obstacle(car):
		duty="respond" if case_id>0 else "patrol";blocked_seconds=0

func snapshot() -> Dictionary:
	return {"id":ID,"duty":duty,"case_id":case_id,"a":a,"b":b,"c":c,"index":index,"admitted":admitted,"car":game.traffic.state_of(car),"travel_meters":travel_meters,"last_seen":[last_seen.x,last_seen.y,last_seen.z],"search_seconds":search_seconds,"exit_point":[exit_point.x,exit_point.y,exit_point.z],"officer_position":[officer.position.x,officer.position.y,officer.position.z],"transition":transition,"resume_pursuit":resume_pursuit,"boarding_from":[boarding_from.x,boarding_from.y,boarding_from.z]}

func reset_unit() -> void:
	for node: Variant in network.reservations.keys():network.release(int(node),ID)
	a=3;b=4;c=5;index=0;admitted=false;case_id=0;duty="patrol";destination_node=-1;resume_pursuit=false
	points=network.movement(a,b,c);travel_meters=0;search_seconds=0;blocked_seconds=0
	officer_target=Vector3.INF
	clock=0;siren_clock=-12
	if siren:siren.stop()
	if command_voice:command_voice.stop()
	command_history.clear()
	car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(3,.9,108)));previous=car.position
	if officer:officer.daily_destinations.clear();seat_officer()

func validate(value: Variant) -> bool:
	if value==null:return true
	if not value is Dictionary or value.get("id")!=ID or not game.traffic.valid_state(value.get("car")):return false
	if not value.get("duty") in ["patrol","respond","exiting","investigate","approach","arrest_offer","returning","route_unavailable","obstructed","officer_down","boarding","pursuit"] or not value.get("admitted") is bool:return false
	for key: String in ["a","b","c","index","case_id"]:
		if not game.law.whole(value.get(key),0,1000000000):return false
	if value.index>6 or not network.connected(int(value.a),int(value.b)) or not network.connected(int(value.b),int(value.c)):return false
	for key: String in ["travel_meters","search_seconds","transition"]:
		var number: Variant=value.get(key)
		if not (number is float or number is int) or not is_finite(float(number)) or number< -100 or number>100000000:return false
	if value.transition<0 or value.transition>1:return false
	for key: String in ["last_seen","exit_point","officer_position"]:
		if not LivingWorld.valid_point(value.get(key)):return false
	if not value.get("resume_pursuit",false) is bool or not LivingWorld.valid_point(value.get("boarding_from",[0,0,0])):return false
	return true

func restore(value: Variant) -> void:
	reset_unit()
	if not value is Dictionary:return
	a=int(value.a);b=int(value.b);c=int(value.c);index=int(value.index);case_id=int(value.case_id);duty=value.duty
	points=network.movement(a,b,c);admitted=bool(value.admitted) and network.reserve(b,ID)
	game.traffic.apply_car_state(car,value.car);previous=car.position;travel_meters=float(value.travel_meters)
	last_seen=LivingWorld.point(value.last_seen);exit_point=LivingWorld.point(value.exit_point)
	search_seconds=float(value.search_seconds);transition=float(value.transition)
	resume_pursuit=bool(value.get("resume_pursuit",false));boarding_from=LivingWorld.point(value.get("boarding_from",[0,0,0]))
	if case_id>0:
		destination_node=0;var at: Vector3=game.law.case_position(case_id)
		for j: int in range(network.nodes.size()):
			if at.distance_squared_to(network.nodes[j])<at.distance_squared_to(network.nodes[destination_node]):destination_node=j
	if officer.health<=0:duty="officer_down";return
	if duty in ["patrol","respond","pursuit","exiting"]:seat_officer()
	else:
		if duty=="boarding":
			officer.position=LivingWorld.point(value.officer_position);officer.set_physics_process(false);officer.collision_layer=0;officer.collision_mask=0;officer.visual.show()
			for region: NPCHitRegion in officer.hit_regions:region.collision_layer=0
			return
		officer.restore_outcome(officer.health);officer.position=LivingWorld.point(value.officer_position)
		if duty in ["investigate","approach","arrest_offer"]:walk_to(last_seen if duty=="approach" else game.law.case_position(case_id))
		elif duty=="returning":walk_to(exit_point)

func nearest_node(at: Vector3) -> int:
	var result: int=0
	for j: int in range(network.nodes.size()):
		if at.distance_squared_to(network.nodes[j])<at.distance_squared_to(network.nodes[result]):result=j
	return result

func response_tier() -> int:
	var case: Dictionary=game.law.active_case(case_id)
	return int(game.law.rules(case.get("rule","public_gunfire")).tier) if not case.is_empty() else 0
