class_name LawValidation
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
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	await frames(6)
	game._menu_action("New game")
	game.living.set_process(false)
	game.living.set_physics_process(false)
	for actor: CityNPC in game.people:
		actor.set_physics_process(false);actor.abstracted=true
	var caller: CityNPC=game.people[0]
	caller.abstracted=false;caller.position=Vector3(-7,.2,76)
	var at:=Vector3(-7,.2,80)
	await frames(2)
	check(game.law.witnesses(at).has(caller.npc_id),"an active healthy resident has physical line of sight to the incident")
	var wall: StaticBody3D=game.harbor.solid(Vector3(-7,1.1,78),Vector3(3,2,.3))
	await frames(2)
	game.events.publish("gunshot",at,35,"player")
	check(game.law.records.size()==1 and game.law.records[0].status=="unreported","a real occluding wall prevents a witness report")
	wall.queue_free();await frames(2)
	game.events.recent.clear();game.law.restore(null)
	game.events.publish("gunshot",at,35,"security")
	check(game.law.records.is_empty(),"security gunfire is not attributed to the player")
	game.events.publish("gunshot",at,35,"player")
	check(game.law.records.size()==1 and game.law.reported_count()==0,"a witnessed incident queues a call rather than instantly reporting")
	game.paused=true;await frames(150)
	check(game.law.reported_count()==0 and game.law.records[0].remaining>1.9,"pause suspends pending witness calls")
	game.paused=false;await frames(30)
	game._save()
	var saved: Dictionary=game.law.snapshot()
	game.law.restore(null);game._load()
	check(game.law.records.size()==1 and is_equal_approx(float(game.law.records[0].remaining),float(saved.records[0].remaining)),"checkpoint load restores the actual in-flight call timer")
	await frames(130)
	check(game.law.reported_count()==1,"a surviving witness submits the delayed report")
	game._save();game.law.restore(null);game._load()
	check(game.law.reported_count()==1,"confirmed crime reports persist through the real checkpoint path")
	if DisplayServer.get_name()!="headless":
		await frames(10)
		game.phone.toggle();game.phone.crime_reports()
		await frames(20)
		check(game.phone.opened and game.phone.shell.visible,"exported phone opens the confirmed-report page")
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://law-verification")
		game.get_viewport().get_texture().get_image().save_png("user://law-verification/reported-case.png")
		game.phone.close()
	var valid: Dictionary=game.law.snapshot()
	check(game.law.validate(JSON.parse_string(JSON.stringify(valid))),"JSON-round-tripped report state validates")
	var malformed: Dictionary=valid.duplicate(true);malformed.records[0].witnesses=["unknown_person"]
	check(not game.law.validate(malformed),"unknown witness identities cannot enter restored state")
	malformed=valid.duplicate(true);malformed.records[0].position=[0,INF,0]
	check(not game.law.validate(malformed),"non-finite crime locations are rejected")
	malformed=valid.duplicate(true);malformed.records.append(malformed.records[0].duplicate(true))
	check(not game.law.validate(malformed),"duplicate report identifiers are rejected")
	game.law.restore(null);game.events.recent.clear()
	# Loading restores crowd activation; re-establish the sole-witness fixture.
	for actor: CityNPC in game.people:
		actor.set_physics_process(false);actor.abstracted=true
	caller.abstracted=false;caller.position=Vector3(-7,.2,76);caller.restore_outcome(70)
	game.events.publish("gunshot",at,35,"player")
	check(game.law.records[0].witnesses==[caller.npc_id],"the incapacitation scenario contains exactly one physically observed witness")
	caller.restore_outcome(0)
	await frames(130)
	check(game.law.reported_count()==0,"an incapacitated sole witness cannot complete a pending call")
	check(game.law.validate(null),"legacy checkpoints without a law component remain valid")
	game.law.restore(null)
	for i: int in range(70):game.law.observe({"kind":"gunshot","source":"player","position":Vector3(500,0,500),"severity":20})
	check(game.law.records.size()==64 and game.law.records[0].id==7,"crime history remains bounded with monotonic report identifiers")
	game.phone.crime_reports()
	check(game.phone.column.get_child_count()>=2,"crime status is rendered through the existing phone layout")
	game._menu_action("New game")
	check(game.law.records.is_empty() and game.law.next_id==1,"New Game clears prior crime history")
	print("LAW_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
