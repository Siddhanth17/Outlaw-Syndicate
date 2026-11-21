class_name DispatchLab
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var observer: Camera3D
var profile: LawProfile
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):await get_tree().physics_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or OS.get_cmdline_user_args().has("--law-benchmark"):return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://dispatch-lab")
	game.get_viewport().get_texture().get_image().save_png("user://dispatch-lab/"+name+".png")
func floor_gap() -> float:
	var at: Vector3=game.player.position
	var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.4,at-Vector3.UP,CollisionLayers.STATIC)
	var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(ray)
	return absf(at.y-hit.position.y) if not hit.is_empty() else INF
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	await frames(8)
	game._menu_action("New game")
	game.memory.remember("dispatch_lab_funding",{"reward":1000}) # Isolated laboratory funds, not a campaign grant.
	if OS.get_cmdline_user_args().has("--law-benchmark"):
		profile=LawProfile.new();profile.game=game;game.add_child(profile);profile.begin()
	game.player.position=Vector3(-7,.2,64)
	if OS.get_cmdline_user_args().has("--pursuit-lab"):game.car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(3,.9,66)))
	var unit: PoliceUnit=game.law.unit
	check(unit!=null and unit.officer.npc_id=="officer_01","one persistent officer is assigned to an actual patrol vehicle")
	var victim: CityNPC=game.law.witness("worker_01")
	var caller: CityNPC=game.law.witness("resident_00")
	victim.position=Vector3(-3,.2,60);victim.route=PackedVector3Array([victim.position]);victim.route_index=0
	caller.position=Vector3(-10,.2,60);caller.daily_destinations={"home":caller.position,"work":caller.position,"break":caller.position};caller.schedule_period=""
	game.living.set_active(victim,true);game.living.set_active(caller,true)
	await frames(3)
	if DisplayServer.get_name()!="headless":
		observer=Camera3D.new();game.add_child(observer)
		observer.position=Vector3(-5,2,67);observer.look_at(Vector3(-5,1,61),Vector3.UP);observer.current=true
	var head: NPCHitRegion
	for area: NPCHitRegion in victim.hit_regions:
		if area.region=="head":head=area;break
	var center: Vector3=head.get_child(0).global_position
	var camera_transform: Transform3D=game.player.camera.transform
	game.player.camera.global_position=game.player.position+Vector3.UP*1.5
	game.player.camera.look_at(center,Vector3.UP)
	game.cooldown=0
	if OS.get_cmdline_user_args().has("--fine-lab"):game.events.publish("crash",game.player.position,3,"player")
	else:game._fire()
	game.player.camera.transform=camera_transform
	if not OS.get_cmdline_user_args().has("--fine-lab"):check(victim.health==0 and victim.ragdoll.active,"one real player headshot causes the expected defeat and articulated ragdoll")
	check(not game.law.records.is_empty() and game.law.records[0].status=="pending","the actual gunshot enters the shared witness pipeline")
	await frames(45)
	check(caller.phone_pose.calling and caller.phone_pose.handset.visible and caller.phone_pose.hand_error<.13,"a conscious witness visibly raises the actual handset to the ear")
	check(caller.phone_pose.handset.global_basis.get_scale().is_equal_approx(Vector3.ONE),"the meter-authored handset retains unit world scale on the centimeter character rig")
	if observer:
		observer.position=caller.position+Vector3(2.5,1.5,2)
		observer.look_at(caller.position+Vector3.UP*1.3,Vector3.UP)
	await capture("witness-call")
	await frames(90)
	check(game.law.reported_count()>0 and not game.law.cases.is_empty(),"completed posed calls create persistent reports and bounded dispatch cases")
	check(unit.case_id>0 and unit.duty=="respond","an available physical patrol receives the confirmed case")
	check(unit.command_history.has("dispatch_ack") and (DisplayServer.get_name()=="headless" or unit.command_voice.playing),"confirmed dispatch starts its authored spatial radio acknowledgement")
	game._set_pause(true);await frames(2)
	if DisplayServer.get_name()=="headless":print("NOT RUN physical officer audio pause in headless mode; streams are intentionally not started")
	else:check(unit.command_voice.stream_paused,"pause suspends the active officer command stream")
	game._set_pause(false);await frames(2)
	if DisplayServer.get_name()!="headless":check(not unit.command_voice.stream_paused,"resume restores the officer command stream")
	var initial: Vector3=unit.car.position
	game._save()
	var saved: Dictionary=unit.snapshot()
	game._load()
	check(unit.case_id==int(saved.case_id) and unit.car.position.distance_to(LivingWorld.point(saved.car.position))<.2,"save/load retains the responding unit and actual vehicle transform")
	check(unit.command_history.is_empty() and not unit.command_voice.playing,"loading a checkpoint does not replay an old dispatch command")
	var observed: Array=[]
	for i: int in range(18000):
		if observer:
			if unit.duty in ["respond","patrol"]:
				observer.position=unit.car.position+Vector3(7,3,-7);observer.look_at(unit.car.position+Vector3.UP*.6,Vector3.UP)
			else:
				observer.position=game.player.position+Vector3(5,2,5);observer.look_at((unit.officer.position+game.player.position)*.5+Vector3.UP,Vector3.UP)
		if i%120==0:
			var row: Dictionary={"second":i/60.0,"duty":unit.duty,"position":[unit.car.position.x,unit.car.position.y,unit.car.position.z],"officer":[unit.officer.position.x,unit.officer.position.y,unit.officer.position.z],"a":unit.a,"b":unit.b,"c":unit.c}
			observed.append(row);print("DISPATCH_TRACE ",JSON.stringify(row))
		if unit.duty in ["arrest_offer","officer_down","route_unavailable","obstructed"]:break
		await frames(1)
	check(unit.travel_meters>100 and unit.car.position.distance_to(initial)>20,"dispatch travels through the physical road network rather than teleporting beside the player")
	check(unit.car.integrity>85 and unit.car.position.y>0,"responding patrol keeps valid road contact and vehicle condition")
	check(unit.duty=="arrest_offer" and unit.officer.position.distance_to(game.player.position)<3.3,"officer exits, navigates, identifies the reported suspect and approaches for an arrest offer")
	check(game.law.cases[0].identified,"suspect identification is recorded from actual nearby officer sight")
	check(unit.command_history.has("officer_stop") and (DisplayServer.get_name()=="headless" or unit.command_voice.playing),"the actual first officer stop plays its authored spoken command")
	await capture("police-arrival")
	var case_id: int=unit.case_id
	if OS.get_cmdline_user_args().has("--pursuit-lab"):
		game.law.refuse(case_id)
		var walking:=HomeValidation.new();walking.game=game;game.add_child(walking)
		check(await walking.walk(game.car.position-Vector3.RIGHT*2.3,600,.65),"refusing suspect physically reaches the nearby vehicle door")
		game._interact();await frames(120)
		check(game.player.driving,"suspect enters the Sable through the real vehicle interaction")
		for i: int in range(2400):
			if unit.duty=="pursuit":break
			await frames(1)
		check(unit.duty=="pursuit","identified vehicle flight makes the officer physically return and board for pursuit")
		check(not unit.command_history.has("dispatch_ack"),"boarding for the same pursuit does not replay a new-dispatch acknowledgement")
		var pursuit_start: Vector3=unit.car.position
		for i: int in range(600):
			if game.car.linear_velocity.length()<6:Input.action_press("forward")
			else:Input.action_release("forward")
			await frames(1)
		Input.action_release("forward")
		check(unit.car.position.distance_to(pursuit_start)>15 and unit.travel_meters>100,"pursuit advances the actual police vehicle through the road network")
		check(game.law.active_case(case_id).get("known_vehicle","")=="sable_gt","vehicle description is acquired from actual officer sight")
		game._save();var state: Dictionary=unit.snapshot();game._load()
		check(unit.duty==state.duty and unit.case_id==int(state.case_id),"active pursuit and its assignment survive checkpoint load")
		if profile:profile.finish()
		print("PURSUIT_LAB %d passed %d failed"%[passes,failures]);get_tree().quit(1 if failures else 0);return
	if OS.get_cmdline_user_args().has("--fine-lab"):
		var cash_before: int=game.memory.money
		var fine: int=int(game.law.rules(game.law.active_case(case_id).rule).fine)
		var at: Vector3=game.player.position
		check(fine==25 and game.law.pay_fine(case_id) and game.memory.money==cash_before-25,"minor collision citation charges its configured fine through the ledger")
		check(not game.law.pay_fine(case_id),"a paid citation cannot charge the player twice")
		game._load()
		check(game.law.active_case(case_id).outcome=="fine_paid" and game.law.active_case(case_id).arrests==0,"citation payment persists without inventing an arrest")
		check(game.player.position.distance_to(at)<1 and game.law.stage=="free","paying a minor fine preserves the free-roam location")
		if profile:profile.finish()
		print("FINE_LAB %d passed %d failed"%[passes,failures]);get_tree().quit(1 if failures else 0);return

	var mission_stage: int=game.memory.stage
	var ammunition: int=game.ammunition
	check(game.law.begin_arrest(case_id),"compliance starts one real proximity-checked arrest")
	check(not game.law.begin_arrest(case_id),"an active arrest rejects duplicate compliance")
	check(unit.command_history.count("comply")==1 and (DisplayServer.get_name()=="headless" or unit.command_voice.playing),"accepted compliance plays one command without duplicate arrest playback")
	await frames(30)
	game._save();var saved_restraint_time: float=game.law.booking_timer
	game.law.booking_timer=9;game._load()
	check(game.law.stage=="arresting" and is_equal_approx(game.law.booking_timer,saved_restraint_time) and not game.player.is_physics_processing(),"loading a restraint checkpoint restores its timer, custody and movement lock")
	await capture("restraint")
	await frames(110)
	print("ARREST_POSE error=",game.law.restraint.hand_error if game.law.restraint else -1," stage=",game.law.stage)
	check(game.law.stage=="processing" and game.player.position.distance_to(VeyraStation.PROCESS_POINT)<1,"completed procedural restraint transfers to the furnished police reception")
	await capture("processing-bail")
	await frames(300);game._save();game._load()
	check(game.law.stage=="processing" and game.law.booking_timer==0,"reading the processing menu does not expire or invalidate the saved booking timer")
	check(floor_gap()<.01,"loading custody places the feet within one centimeter of the actual station floor")
	game._set_pause(true);game._menu_action("Resume")
	check(not game.player.is_physics_processing() and not game.player.camera_input_enabled,"pause-menu resume cannot unlock a player in custody")
	game.phone.close()
	check(not game.player.is_physics_processing() and not game.player.camera_input_enabled,"closing the processing phone cannot unlock custody between physics steps")
	var custody_at: Vector3=game.player.position
	Input.action_press("forward");await frames(30);Input.action_release("forward")
	check(game.player.position.distance_to(custody_at)<.005,"custody input cannot move the player through the station")
	game._save()
	var custody_checkpoint: String=FileAccess.get_file_as_string(game.SAVE_PATH)
	var report_count: int=game.law.reported_count()
	var arrest_count: int=int(game.law.active_case(case_id).arrests)
	var money_before: int=game.memory.money
	var amount: int=int(game.law.rules(game.law.active_case(case_id).rule).bail)
	game.memory.money=0;game.living.bank=0
	check(not game.law.pay_bail() and game.memory.money==0 and game.living.bank==0,"unaffordable bail leaves both balances unchanged")
	game.memory.money=money_before
	check(game.living.transfer(900,true),"laboratory funds are deposited through the existing bank transaction path")
	var balance_before: int=game.memory.money+game.living.bank
	check(game.law.pay_bail() and game.memory.money+game.living.bank==balance_before-amount,"fictional bail deducts its exact amount from combined cash and bank funds")
	var money_after: int=game.memory.money
	var bank_after: int=game.living.bank
	check(not game.law.pay_bail() and game.memory.money==money_after,"duplicate bail submission cannot charge money twice")
	game.memory.money+=7;game.living.bank+=11
	game.living.ledger.clear();game.law.active_case(case_id).arrests+=3
	game._load()
	check(game.memory.money==money_after and game.living.bank==bank_after and game.law.active_case(case_id).outcome=="bail_paid" and game.law.reported_count()>0,"release checkpoint retains payment and criminal history")
	check(game.law.stage=="free" and game.player.is_physics_processing() and game.player.camera.current,"release restores free movement and the gameplay camera")
	check(game.law.reported_count()==report_count and game.law.active_case(case_id).arrests==arrest_count and game.living.ledger.filter(func(row: Dictionary) -> bool:return row.category=="legal_bail").size()==1,"reload restores report, arrest and payment counts without duplication")
	var released_at: Vector3=game.player.position
	Input.action_press("back");await frames(30);Input.action_release("back")
	check(game.player.position.distance_to(released_at)>.3 and game.player.is_on_floor(),"release restores real grounded movement from player input")
	# Branch the same pre-outcome checkpoint in this isolated QA profile to cover detention.
	var branch_file:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	branch_file.store_string(custody_checkpoint);branch_file.close()
	game._load()
	var before_clock: float=game.quarter.day*1440+game.quarter.minutes
	check(game.law.stage=="processing" and game.law.serve_detention(),"declining bail enters the actual holding area")
	await frames(30);game._save()
	game.law.stage="free";game.player.set_physics_process(true);game._load()
	check(game.law.stage=="detained" and not game.player.is_physics_processing(),"detention survives checkpoint restoration")
	check(floor_gap()<.01,"detention checkpoint restores actual holding-room floor contact")
	await capture("holding-room")
	await frames(190)
	var after_clock: float=game.quarter.day*1440+game.quarter.minutes
	var expected_hours: int=int(game.law.rules(game.law.active_case(case_id).rule).detention_hours)
	check(after_clock-before_clock>=expected_hours*60 and after_clock-before_clock<expected_hours*60+5,"detention advances the configured fictional world time exactly once")
	check(game.law.active_case(case_id).outcome=="served" and game.player.position.distance_to(VeyraStation.RELEASE_POINT)<1,"serving detention releases the player while retaining case outcome")
	check(game.memory.money==money_before and game.memory.stage==mission_stage and game.ammunition==ammunition,"detention preserves money, mission progression and carried ammunition")
	game._load()
	check(game.law.stage=="free" and game.law.active_case(case_id).outcome=="served","resolved detention stays resolved after load")
	DirAccess.make_dir_recursive_absolute("user://dispatch-lab")
	FileAccess.open("user://dispatch-lab/trace.json",FileAccess.WRITE).store_string(JSON.stringify(observed,"  "))
	if profile:profile.finish()
	print("DISPATCH_LAB %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
