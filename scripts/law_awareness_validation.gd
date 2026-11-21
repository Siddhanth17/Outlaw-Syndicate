class_name LawAwarenessValidation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):await get_tree().physics_frame
func run() -> void:
	game.test_mode=true;await frames(8);game._menu_action("New game")
	for actor: CityNPC in game.people:actor.abstracted=true;actor.set_physics_process(false)
	game.player.set_physics_process(false)
	game.living.set_process(false);game.living.set_physics_process(false)
	game.events.publish("gunshot",Vector3(500,0,500),35,"player")
	check(game.law.records[-1].status=="unreported" and game.law.cases.is_empty(),"an isolated unwitnessed incident creates no magical police dispatch")
	var at: Vector3=game.law.unit.car.position+Vector3(0,0,12)
	game.events.publish("gunshot",at,35,"player")
	check(game.law.records[-1].get("method","")=="officer_hearing" and game.law.records[-1].confidence==0,"nearby officer hearing reports an unidentified sound rather than inventing a shooter")
	await frames(2)
	var id: int=game.law.unit.case_id
	check(id>0 and not game.law.matches_suspect(id),"hearing creates an investigation without identifying the distant player")
	await frames(600)
	check(game.law.unit.duty!="arrest_offer" and not game.law.active_case(id).identified,"the officer cannot arrest an unrelated unseen suspect")
	var valid: Dictionary=JSON.parse_string(JSON.stringify(game.law.snapshot()))
	check(game.law.validate(valid),"enforcement version2 survives a real JSON numeric round trip")
	var malformed: Dictionary=valid.duplicate(true);malformed.enforcement.booking={"stage":"processing","case_id":99999,"timer":0}
	check(not game.law.validate(malformed),"custody cannot reference a nonexistent legal case")
	malformed=valid.duplicate(true);malformed.enforcement.booking.stage="unknown"
	check(not game.law.validate(malformed),"unknown custody phases are rejected before restoring world state")
	malformed=valid.duplicate(true);malformed.enforcement.cases.append(malformed.enforcement.cases[0].duplicate(true))
	check(not game.law.validate(malformed),"duplicate dispatch cases are rejected")
	malformed=valid.duplicate(true);malformed.enforcement.unit.last_seen=[0,INF,0]
	check(not game.law.validate(malformed),"non-finite pursuit observations are rejected")
	malformed=valid.duplicate(true);malformed.enforcement.version=99
	check(not game.law.validate(malformed),"unknown enforcement schema versions are rejected")
	check(game.traffic.cars.size()==6 and is_instance_valid(game.law.unit.car),"response reuses one persistent unit alongside the six civilian traffic vehicles")
	var caller: CityNPC=game.law.witness("resident_00")
	game.car.position=Vector3(-3,.9,60);game.car.freeze=true
	game.player.position=game.car.position;game.player.driving=true
	caller.position=Vector3(-10,.2,60);caller.abstracted=false
	await frames(2)
	game.events.publish("crash",game.car.position,12,"player")
	var report: Dictionary=game.law.records[-1]
	check(report.vehicle_description=="sable_gt" and report.witnesses.has(caller.npc_id),"a witness can report the actually visible vehicle despite its occluded driver")
	check(report.confidence==0,"seeing a reported car does not invent a visible driver identity")
	game.law.enqueue(report)
	game.law.cases[-1].phase="responding"
	check(game.law.matches_suspect(int(report.id)),"a reported occupied vehicle can be investigated without fabricated facial recognition")
	game.player.driving=false
	check(not game.law.matches_suspect(int(report.id)),"an unobserved driver on foot does not inherit vehicle identification")
	print("LAW_AWARENESS %d passed %d failed"%[passes,failures]);get_tree().quit(1 if failures else 0)
