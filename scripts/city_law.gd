class_name CityLaw
extends Node

# One persistent witness/case registry; bounded physical dispatch prototype.
const KINDS: Array[String]=["gunshot","vehicle_person","defeat","assault","crash"]
const LIMIT: int=64
var game: Node3D
var records: Array[Dictionary]=[]
var next_id: int=1
var cases: Array[Dictionary]=[]
var unit: PoliceUnit
var pending_unit_restore: Variant=null
var stage: String="free"
var booked_case: int=0
var booking_timer: float=0
var restraint: ArrestPose
var legal_rules: Dictionary={}
var call_cues: Array[AudioStreamPlayer3D]=[]
var cue_index: int=0

var simulation_us: int=0

func _ready() -> void:
	for i: int in range(4):
		var cue:=AudioStreamPlayer3D.new();cue.bus="Dialogue";cue.stream=load("res://assets/audio/law/call_connected.wav");cue.volume_db=-22;cue.max_distance=30;game.add_child(cue);call_cues.append(cue)
	game.events.incident.connect(observe)
	call_deferred("start_unit")

func witness(id: String) -> CityNPC:
	for actor: CityNPC in game.people:
		if actor.npc_id==id:return actor
	return null

func eligible(actor: CityNPC) -> bool:
	return actor.health>0 and not actor.abstracted and actor.state not in [HarborGuard.State.DEFEATED,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER] and actor.injury_time<=0

func witnesses(at: Vector3) -> Array[String]:
	var ids: Array[String]=[]
	for actor: CityNPC in game.people:
		if not eligible(actor) or actor.position.distance_to(at)>28:continue
		var ray:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.4,at+Vector3.UP,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
		ray.exclude=[actor.get_rid()]
		if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():ids.append(actor.npc_id)
	return ids

func observe(event: Dictionary) -> void:
	if event.get("source")!="player" or not event.get("kind") in KINDS:return
	var at: Vector3=event.position
	var ids: Array[String]=witnesses(at)
	var vehicle_description: String=""
	if event.kind in ["crash","vehicle_person"] and (game.player.driving or game.player.riding_bike):
		var vehicle: PhysicsBody3D=game.car if game.player.driving else game.bike
		for actor: CityNPC in game.people:
			if not eligible(actor) or actor.position.distance_to(vehicle.position)>28:continue
			var ray:=PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*1.4,vehicle.position+Vector3.UP*.2,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
			var seen: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ray)
			if not seen.is_empty() and seen.collider==vehicle:
				if not ids.has(actor.npc_id):ids.append(actor.npc_id)
				vehicle_description="sable_gt" if game.player.driving else "harrier"
	# The hidden player's logical anchor is not an observable face inside a car.
	var shooter_ids: Array[String]=[]
	if not game.player.driving:shooter_ids=witnesses(game.player.position)
	var identified: bool=ids.any(func(id: String) -> bool:return shooter_ids.has(id))
	var heard_only: bool=ids.is_empty() and event.kind=="gunshot" and unit and unit.is_physics_processing() and unit.officer and unit.officer.health>0 and unit.car.position.distance_to(at)<32
	if heard_only:ids.append(unit.officer.npc_id);identified=false
	records.append({"id":next_id,"kind":event.kind,"position":[at.x,at.y,at.z],"severity":clampf(float(event.severity),0,100),"witnesses":ids,"status":"reported" if heard_only else ("pending" if not ids.is_empty() else "unreported"),"remaining":2.0,"outfit":game.residence.outfit,"confidence":1.0 if identified else 0.0,"day":game.quarter.day,"minute":game.quarter.minutes,"vehicle_description":vehicle_description})
	if heard_only:
		records[-1]["method"]="officer_hearing";enqueue(records[-1])
	for id: String in ([] if heard_only else ids):
		var actor: CityNPC=witness(id)
		if actor.phone_pose:actor.phone_pose.begin()
	next_id+=1
	if records.size()>LIMIT:records.pop_front()

func _physics_process(delta: float) -> void:
	var began: int=Time.get_ticks_usec()
	_simulate_law(delta)
	simulation_us=Time.get_ticks_usec()-began

func _simulate_law(delta: float) -> void:
	if game.paused or game.cinematic_active:return
	justice_tick(delta)
	for actor: CityNPC in game.people:
		if actor.phone_pose and actor.phone_pose.calling:
			if not eligible(actor):actor.phone_pose.finish()
			else:actor.phone_pose.elapsed+=delta
	for record: Dictionary in records:
		if record.status!="pending":continue
		record.remaining=maxf(0,float(record.remaining)-delta)
		if record.remaining>0:continue
		var callers: Array[String]=[]
		for id: String in record.witnesses:
			var actor: CityNPC=witness(id)
			if actor and actor.health>0 and actor.injury_time<=0 and actor.state not in [HarborGuard.State.DEFEATED,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER] and actor.position.distance_to(LivingWorld.point(record.position))<45 and actor.phone_pose and actor.phone_pose.calling and actor.phone_pose.hand_error<.13 and actor.phone_pose.elapsed>=1.6:callers.append(id)
		record.status="reported" if not callers.is_empty() else "unreported"
		if record.status=="reported":
			enqueue(record)
			game.events.publish("emergency_call",LivingWorld.point(record.position),5,callers[0])
			var cue: AudioStreamPlayer3D=call_cues[cue_index%call_cues.size()];cue_index+=1;cue.position=witness(callers[0]).position
			if DisplayServer.get_name()!="headless":cue.play()
		record.witnesses=callers
	for actor: CityNPC in game.people:
		if actor.phone_pose and actor.phone_pose.calling:
			var pending: bool=records.any(func(record: Dictionary) -> bool:return record.status=="pending" and record.witnesses.has(actor.npc_id))
			if not pending:actor.phone_pose.finish()

	if not locked() and unit and unit.duty=="patrol":
		for case: Dictionary in cases:
			if case.phase=="queued" and unit.assign(int(case.id),LivingWorld.point(case.position)):
				case.phase="responding";break

func reported_count() -> int:
	return records.filter(func(record: Dictionary) -> bool:return record.status=="reported").size()

func snapshot() -> Dictionary:return {"version":1,"next_id":next_id,"records":records.duplicate(true),"enforcement":{"version":2,"cases":cases.duplicate(true),"unit":unit.snapshot() if unit else null,"booking":{"stage":stage,"case_id":booked_case,"timer":booking_timer}}}

func whole(value: Variant,low: int,high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high and float(value)==floor(float(value))

func validate(value: Variant) -> bool:
	if value==null:return true
	if not value is Dictionary or value.get("version")!=1 or not whole(value.get("next_id"),1,1000000000) or not value.get("records") is Array or value.records.size()>LIMIT:return false
	var previous: int=0
	for record: Variant in value.records:
		if not record is Dictionary or not whole(record.get("id"),previous+1,int(value.next_id)-1) or not record.get("kind") in KINDS or not LivingWorld.valid_point(record.get("position")):return false
		previous=int(record.id)
		if record.has("outfit") and not whole(record.outfit,0,1):return false
		if record.has("confidence") and (not (record.confidence is float or record.confidence is int) or not is_finite(float(record.confidence)) or record.confidence<0 or record.confidence>1):return false
		if not record.get("status") in ["pending","reported","unreported"] or not record.get("witnesses") is Array or record.witnesses.size()>64:return false
		for id: Variant in record.witnesses:
			if not id is String or not witness(id) or record.witnesses.count(id)!=1:return false
		if record.status in ["pending","reported"] and record.witnesses.is_empty():return false
		for key: String in ["severity","remaining"]:
			var number: Variant=record.get(key)
			if not (number is float or number is int) or not is_finite(float(number)) or number<0 or number>(100 if key=="severity" else 2):return false
	var enforcement: Variant=value.get("enforcement")
	if enforcement!=null:
		if not enforcement is Dictionary or not whole(enforcement.get("version"),1,2) or not enforcement.get("cases") is Array or enforcement.cases.size()>16:return false
		var ids: Array[int]=[]
		for case: Variant in enforcement.cases:
			if not case is Dictionary or not whole(case.get("id"),1,1000000000) or ids.has(int(case.id)) or not LivingWorld.valid_point(case.get("position")):return false
			ids.append(int(case.id))
			if not case.get("phase") in ["queued","responding","suspended","resolved"] or not whole(case.get("outfit"),0,1):return false
			if not case.get("rule","public_gunfire") in ["minor_traffic","property_damage","public_gunfire","assault","serious_violence"]:return false
			if not case.get("outcome","pending") in ["pending","fine_paid","bail_paid","served"] or not case.get("identified",false) is bool or not case.get("consequence_done",false) is bool or not whole(case.get("arrests",0),0,1000000):return false
			for key: String in ["confidence","severity"]:
				var number: Variant=case.get(key,0)
				if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>(1 if key=="confidence" else 100):return false
			if not case.get("vehicle_description","") in ["","sable_gt","harrier"]:return false
			if case.has("known_vehicle") and not case.known_vehicle in ["sable_gt","harrier","on_foot"]:return false
			if not case.get("contested",false) is bool:return false
			if case.has("created_world") and (not (case.created_world is int or case.created_world is float) or not is_finite(float(case.created_world)) or case.created_world<0 or case.created_world>1000000000):return false
			if not case.get("witnesses",[]) is Array or case.get("witnesses",[]).size()>64:return false
			for id: Variant in case.get("witnesses",[]):
				if not id is String or not witness(id):return false
		if unit and not unit.validate(enforcement.get("unit")):return false
		if not unit and enforcement.get("unit")!=null:
			var probe:=PoliceUnit.new();probe.game=game;probe.network=game.traffic.network
			var valid_unit: bool=probe.validate(enforcement.unit);probe.free()
			if not valid_unit:return false
		if enforcement.get("unit") is Dictionary and int(enforcement.unit.case_id)>0 and not ids.has(int(enforcement.unit.case_id)):return false
		var booking: Variant=enforcement.get("booking")
		if enforcement.version==2 and booking==null:return false
		if booking!=null:
			if not booking is Dictionary or not booking.get("stage") in ["free","arresting","processing","detained"] or not whole(booking.get("case_id"),0,1000000000):return false
			var timer: Variant=booking.get("timer")
			if not (timer is int or timer is float) or not is_finite(float(timer)) or timer< -3 or timer>10:return false
			if booking.stage!="free":
				if enforcement.get("unit")==null or not ids.has(int(booking.case_id)):return false
				var matching: Array=enforcement.cases.filter(func(case: Dictionary) -> bool:return int(case.id)==int(booking.case_id))
				if matching.is_empty() or matching[0].get("outcome","pending")!="pending":return false
	return true

func restore(value: Variant) -> void:
	for actor: CityNPC in game.people:
		if actor.phone_pose:actor.phone_pose.finish()
	unlock_player()
	stage="free";booked_case=0;booking_timer=0
	records.clear();cases.clear();next_id=1
	pending_unit_restore=null
	if unit:unit.reset_unit()
	if value is Dictionary:
		next_id=int(value.next_id)
		for record: Dictionary in value.records:
			records.append(record.duplicate(true))
			if record.status=="pending":
				for id: String in record.witnesses:
					var actor: CityNPC=witness(id)
					if actor and actor.phone_pose:actor.phone_pose.begin(2-float(record.remaining))

	if value is Dictionary and value.get("enforcement") is Dictionary:
		for case: Dictionary in value.enforcement.cases:cases.append(case.duplicate(true))
		pending_unit_restore=value.enforcement.get("unit")
		if unit:unit.restore(pending_unit_restore);pending_unit_restore=null
		var booking: Dictionary=value.enforcement.get("booking",{})
		stage=booking.get("stage","free");booked_case=int(booking.get("case_id",0));booking_timer=float(booking.get("timer",0))
		if locked():lock_player()

func start_unit() -> void:
	for i: int in range(3):await get_tree().physics_frame
	unit=PoliceUnit.new();unit.game=game;game.add_child(unit)
	if pending_unit_restore!=null:unit.restore(pending_unit_restore);pending_unit_restore=null

func enqueue(record: Dictionary) -> void:
	var observed: float=float(record.get("day",game.quarter.day))*1440+float(record.get("minute",game.quarter.minutes))
	var charge: String="public_gunfire"
	match String(record.kind):
		"crash":charge="minor_traffic" if float(record.severity)<6 else "property_damage"
		"vehicle_person","assault":charge="assault"
		"defeat":charge="serious_violence"
	for case: Dictionary in cases:
		if int(case.id)==int(record.id):return
		if case.phase in ["queued","responding"] and LivingWorld.point(case.position).distance_to(LivingWorld.point(record.position))<12 and absf(observed-float(case.get("created_world",-10000)))<4:
			if int(rules(charge).tier)>int(rules(case.get("rule","public_gunfire")).tier):case.rule=charge
			return
	if cases.size()>=16:
		for i: int in range(cases.size()):
			if cases[i].phase in ["suspended","resolved"]:cases.remove_at(i);break
	if cases.size()>=16:return
	cases.append({"id":int(record.id),"position":record.position.duplicate(),"outfit":int(record.get("outfit",0)),"confidence":float(record.get("confidence",0)),"vehicle_description":record.get("vehicle_description",""),"severity":float(record.severity),"phase":"queued","identified":false,"rule":charge,"outcome":"pending","arrests":0,"consequence_done":false,"witnesses":record.witnesses.duplicate(),"created_world":observed})
	cases.sort_custom(func(left: Dictionary,right: Dictionary) -> bool:return int(rules(left.rule).priority)>int(rules(right.rule).priority))

func case_position(id: int) -> Vector3:
	for case: Dictionary in cases:
		if int(case.id)==id:return LivingWorld.point(case.position)
	return Vector3.ZERO

func matches_suspect(id: int) -> bool:
	for case: Dictionary in cases:
		if int(case.id)==id:return (bool(case.get("identified",false)) or (game.player.driving and case.get("vehicle_description","")=="sable_gt") or (game.player.riding_bike and case.get("vehicle_description","")=="harrier") or (not game.player.driving and not game.player.riding_bike and float(case.get("confidence",0))>=.8 and int(case.outfit)==game.residence.outfit)) and case.phase=="responding"
	return false

func suspend_case(id: int) -> void:
	for case: Dictionary in cases:
		if int(case.id)==id:case.phase="suspended"

func identify_case(id: int) -> void:
	for case: Dictionary in cases:
		if int(case.id)==id:case.identified=true

func rules(key: String) -> Dictionary:
	if legal_rules.is_empty():legal_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/crime_rules.json"))
	return legal_rules.get(key,legal_rules.public_gunfire)

func active_case(id: int) -> Dictionary:
	for case: Dictionary in cases:
		if int(case.id)==id:return case
	return {}

func locked() -> bool:return stage!="free"

func lock_player() -> void:
	if stage=="processing":game.player.position=VeyraStation.PROCESS_POINT
	elif stage=="detained":game.player.position=VeyraStation.HOLD_POINT
	elif stage=="arresting":
		var ground:=PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP*.5,game.player.position-Vector3.UP*1.5,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
		var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ground)
		if not hit.is_empty() and hit.normal.y>.7:game.player.position.y=hit.position.y+.001
	game.player.velocity=Vector3.ZERO;game.player.set_physics_process(false);game.player.camera_input_enabled=false
	if stage=="arresting":
		if not restraint:
			var skeletons: Array[Node]=game.player.visual.find_children("*","Skeleton3D",true,false)
			if not skeletons.is_empty():
				restraint=ArrestPose.new();restraint.restrained_player=game.player;skeletons[0].add_child(restraint)
		if restraint:restraint.enabled=true;restraint.elapsed=maxf(0,1.5-booking_timer)
		game.player.perform("Idle",1.5)
		game.cine_camera.position=game.player.position+Vector3(2,1.7,2)
		game.cine_camera.look_at(game.player.position+Vector3.UP,Vector3.UP);game.cine_camera.current=true
	elif stage=="processing":
		game.cine_camera.position=VeyraStation.PROCESS_POINT+Vector3(2.5,1.6,-2.5)
		game.cine_camera.look_at(VeyraStation.PROCESS_POINT+Vector3.UP,Vector3.UP);game.cine_camera.current=true
	elif stage=="detained":
		game.cine_camera.position=VeyraStation.ADDRESS+Vector3(.7,1.8,-.7)
		game.cine_camera.look_at(VeyraStation.HOLD_POINT+Vector3.UP,Vector3.UP);game.cine_camera.current=true

func unlock_player() -> void:
	if restraint:restraint.enabled=false
	if not is_instance_valid(game.player):return
	game.player.set_physics_process(not game.paused);game.player.camera_input_enabled=not game.paused
	game.player.camera.current=true;game.player.perform("Idle",.1)

func interact() -> bool:
	if locked():return true
	if unit and unit.duty=="arrest_offer" and unit.officer.position.distance_to(game.player.position)<3.5:
		offer_menu();return true
	if not game.player.driving and game.player.position.distance_to(VeyraStation.PROCESS_POINT)<3:
		legal_menu();return true
	return false

func offer_menu() -> void:
	var case: Dictionary=active_case(unit.case_id)
	if case.is_empty():return
	if not game.phone.opened:game.phone.toggle()
	if not game.phone.opened:return
	game.phone.clear("VEYRA POLICE / STOP")
	game.phone.note(rules(case.get("rule","public_gunfire")).title+"\nCase #%d"%case.id)
	var fine: int=int(rules(case.get("rule","public_gunfire")).fine)
	if fine>0:game.phone.button("Pay fine • $%d"%fine,pay_fine.bind(int(case.id)))
	if int(rules(case.get("rule","public_gunfire")).tier)==1:game.phone.button("Acknowledge citation",accept_citation.bind(int(case.id)))
	else:game.phone.button("Comply",begin_arrest.bind(int(case.id)))
	game.phone.button("Refuse",refuse.bind(int(case.id)))

func refuse(id: int) -> void:
	var case: Dictionary=active_case(id)
	if case.is_empty():return
	case["refused"]=true
	game.phone.close()
	if int(rules(case.get("rule","public_gunfire")).tier)<=2:
		case.phase="suspended";unit.duty="returning";unit.walk_to(unit.exit_point)
	else:unit.duty="approach";unit.walk_to(game.player.position)

func begin_arrest(id: int) -> bool:
	if locked() or not unit or unit.duty!="arrest_offer" or unit.case_id!=id or unit.officer.position.distance_to(game.player.position)>3.5 or unit.officer.health<=0 or unit.officer.injury_time>0 or game.player.driving or game.player.riding_bike or not game.player.is_on_floor():return false
	var case: Dictionary=active_case(id)
	if case.is_empty() or not case.get("identified",false):return false
	game.phone.close();stage="arresting";booked_case=id;booking_timer=1.5
	case.arrests=int(case.get("arrests",0))+1
	lock_player();return true

func justice_tick(delta: float) -> void:
	if stage=="free":return
	game.player.set_physics_process(false);game.player.camera_input_enabled=false
	if stage in ["arresting","detained"]:booking_timer-=delta
	else:booking_timer=0
	if stage=="arresting":
		if not unit or unit.officer.health<=0:
			suspend_case(booked_case);stage="free";unlock_player();return
		if restraint:restraint.elapsed+=delta
		if booking_timer<=0 and restraint and restraint.hand_error<.15:
			if restraint:restraint.enabled=false
			stage="processing";booking_timer=0;game.player.position=VeyraStation.PROCESS_POINT;game.player.velocity=Vector3.ZERO
			game.cine_camera.position=VeyraStation.PROCESS_POINT+Vector3(2.5,1.6,-2.5)
			game.cine_camera.look_at(VeyraStation.PROCESS_POINT+Vector3.UP,Vector3.UP);game.cine_camera.current=true
			game.player.yaw=0;game.player.pitch=-.08
			legal_menu()
		elif booking_timer< -3:
			stage="free";unlock_player();game._say("Police","The restraint interaction was interrupted.")
	elif stage=="processing":
		if not game.phone.opened:legal_menu()
	elif stage=="detained" and booking_timer<=0:
		var case: Dictionary=active_case(booked_case)
		var duration: float=float(rules(case.get("rule","public_gunfire")).detention_hours)*60
		var minutes: float=game.quarter.minutes+duration
		game.quarter.day+=int(minutes/1440);game.quarter.minutes=fposmod(minutes,1440);game.quarter.apply_clock()
		finish_case("served")

func legal_menu() -> void:
	if stage=="processing":
		game.phone.open_for_custody()
		var case: Dictionary=active_case(booked_case)
		game.phone.clear("VEYRA / PROCESSING")
		if case.is_empty():return
		var charge: Dictionary=rules(case.get("rule","public_gunfire"))
		game.phone.note("Case #%d • %s\nBail $%d • detention %dh\nCash $%d / bank $%d"%[case.id,charge.title,charge.bail,charge.detention_hours,game.memory.money,game.living.bank])
		if int(charge.bail)>0:game.phone.button("Pay bail • $%d"%charge.bail,pay_bail)
		game.phone.button("Serve detention",serve_detention)
		game.phone.note("Bail permits release. The report and arrest remain in your record.")
	else:
		if not game.phone.opened:game.phone.toggle()
		if not game.phone.opened:return
		game.phone.clear("VEYRA / LEGAL STATUS")
		game.phone.note("Current alert • "+alert_state())
		for case: Dictionary in cases:
			game.phone.note("Case #%d • %s • %s\nArrests %d"%[case.id,rules(case.get("rule","public_gunfire")).title,String(case.get("outcome","pending")).replace("_"," ").capitalize(),case.get("arrests",0)])
			var fine: int=int(rules(case.get("rule","public_gunfire")).fine)
			if fine>0 and case.get("outcome","pending")=="pending" and case.get("identified",false):game.phone.button("Pay fine #%d • $%d"%[case.id,fine],pay_fine.bind(int(case.id)))
			if case.get("outcome","pending")!="pending" and not case.get("contested",false):game.phone.button("Request review of case #%d"%case.id,contest_case.bind(int(case.id)))
		game.phone.button("Back",game.phone.home)

func pay_bail() -> bool:
	if stage!="processing":return false
	var case: Dictionary=active_case(booked_case)
	if case.is_empty() or case.get("outcome","pending")!="pending":return false
	var amount: int=int(rules(case.get("rule","public_gunfire")).bail)
	if amount<=0 or game.memory.money+game.living.bank<amount:
		game.phone.note("Insufficient funds. No payment was made.");return false
	var from_bank: int=maxi(0,amount-game.memory.money)
	if from_bank>0 and not game.living.transfer(from_bank,false):return false
	if not game.living.transact(-amount,"legal_bail","case_%d"%booked_case):return false
	finish_case("bail_paid");return true

func serve_detention() -> bool:
	if stage!="processing":return false
	game.phone.close();stage="detained";booking_timer=3
	game.player.position=VeyraStation.HOLD_POINT;game.player.velocity=Vector3.ZERO
	game.cine_camera.position=VeyraStation.ADDRESS+Vector3(.7,1.8,-.7)
	game.cine_camera.look_at(VeyraStation.HOLD_POINT+Vector3.UP,Vector3.UP);game.cine_camera.current=true
	game.player.yaw=0;game.player.pitch=-.05
	lock_player()
	game._say("Detention","Time passes in the holding room.")
	return true

func finish_case(outcome: String,from_custody: bool=true) -> void:
	var case: Dictionary=active_case(booked_case)
	if case.is_empty():return
	case.outcome=outcome;case.phase="suspended" if outcome=="bail_paid" else "resolved"
	game.memory.remember("legal_case_%d"%case.id,{"charge":case.get("rule","public_gunfire"),"outcome":outcome,"arrests":int(case.get("arrests",0))})
	if not bool(case.get("consequence_done",false)):
		game.faction_rep+=int(rules(case.get("rule","public_gunfire")).reputation)
		for id: String in case.get("witnesses",[]):
			if game.living.identities.has(id):game.living.relation(id).trust=maxi(0,int(game.living.relation(id).trust)-1)
		case.consequence_done=true
	game.phone.close();stage="free";booking_timer=0
	if from_custody:game.player.position=VeyraStation.RELEASE_POINT
	game.player.velocity=Vector3.ZERO
	unlock_player()
	if unit and unit.case_id==booked_case and unit.officer and unit.officer.health>0:unit.duty="returning";unit.resume_pursuit=false;unit.walk_to(unit.exit_point)
	game._save();game._say("Release","Released. Your case history remains in Legal status.")

func alert_state() -> String:
	if locked():return "In custody"
	if unit:
		match unit.duty:
			"respond":return "Reported incident"
			"pursuit":return "High-priority vehicle pursuit" if unit.response_tier()>=4 else "Vehicle pursuit"
			"obstructed":return "Response delayed"
			"investigate":return "Searching last observed area"
			"approach":return "Suspect confirmed"
			"arrest_offer":return "Officer stop"
	return "No active alert"

func pay_fine(id: int) -> bool:
	if locked():return false
	var case: Dictionary=active_case(id)
	if case.is_empty() or case.get("outcome","pending")!="pending" or not case.get("identified",false):return false
	var amount: int=int(rules(case.get("rule","public_gunfire")).fine)
	if amount<=0 or game.memory.money+game.living.bank<amount:return false
	var from_bank: int=maxi(0,amount-game.memory.money)
	if from_bank>0 and not game.living.transfer(from_bank,false):return false
	if not game.living.transact(-amount,"legal_fine","case_%d"%id):return false
	booked_case=id;finish_case("fine_paid",false);return true

func accept_citation(id: int) -> bool:
	var case: Dictionary=active_case(id)
	if case.is_empty() or not unit or unit.case_id!=id or unit.duty!="arrest_offer":return false
	case.phase="suspended";unit.duty="returning";unit.walk_to(unit.exit_point);game.phone.close();game._save();return true

func contest_case(id: int) -> bool:
	var case: Dictionary=active_case(id)
	if case.is_empty() or case.get("outcome","pending")=="pending" or case.get("contested",false):return false
	case["contested"]=true
	game.memory.remember("case_review_%d"%id,{"requested":true})
	game._save();legal_menu();game.phone.note("Review requested. The existing record and outcome remain in place.")
	return true
