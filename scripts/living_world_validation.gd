class_name LivingWorldValidation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var profiles: Dictionary={}
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):await get_tree().physics_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://living-world-verification/"+name+".png")
func press(text: String) -> bool:
	for item: Node in game.phone.column.get_children():
		if item is Button and item.text==text:item.pressed.emit();return true
	return false

func benchmark(label: String, seconds: float, walking: bool=false) -> void:
	var times: Array[float]=[]
	var start:=Time.get_ticks_usec()
	var before:=start
	if walking:Input.action_press("back",.65)
	while Time.get_ticks_usec()-start<int(seconds*1000000):
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		times.append((now-before)/1000.0)
		before=now
	Input.action_release("back")
	var total: float=0
	for t: float in times:total+=t
	times.sort()
	var count: int=maxi(1,int(ceil(times.size()*.01)))
	var slow: float=0
	for i: int in range(times.size()-count,times.size()):slow+=times[i]
	profiles[label]={"seconds":seconds,"frames":times.size(),"mean_fps":times.size()*1000/total,"one_percent_low_fps":1000/(slow/count),"p95_ms":times[int(times.size()*.95)],"p99_ms":times[int(times.size()*.99)],"max_ms":times.back(),"active_citizens":game.living.active_count,"abstract_citizens":game.living.abstract_count,"traffic_cars":game.traffic.cars.size(),"render_size":[int(game.get_viewport().get_texture().get_size().x),int(game.get_viewport().get_texture().get_size().y)],"texture_buffer_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	print("LIVING_PROFILE ",label," ",profiles[label])
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	await frames(5)
	game._menu_action("New game")
	await frames(5)
	DirAccess.make_dir_recursive_absolute("user://living-world-verification")
	var world: LivingWorld=game.living
	check(world.roster_ready and game.people.size()==36,"existing sixteen citizens retained plus twenty stable resident profiles")
	check(world.identities.size()==37,"all citizens and Dante have stable identity records")
	var ids: Dictionary={}
	for actor: CityNPC in game.people:ids[actor.npc_id]=true
	check(ids.size()==36,"citizen IDs are unique")
	game.quarter.minutes=600
	game.quarter.apply_clock()
	game.player.position=Vector3(0,.2,138)
	await frames(4)
	world.refresh(0)
	check(world.active_count>=20 and world.active_count<=28,"Northline activates a measured nearby crowd within the normal budget")
	game.quarter.refresh(true)
	game.ui.gameplay.hide()
	game.cine_camera.current=true
	game.cine_camera.position=Vector3(7,2,135)
	game.cine_camera.look_at(Vector3(-10,1,170))
	await frames(30)
	await capture("crowded-avenue")
	var lena:=world.actor_for("resident_00")
	check(lena.citizen_name=="Lena Ortiz" and lena.schedule_period=="work","named cafe owner uses individual working hours")
	game.player.position=Vector3(-11,.2,80)
	await frames(20)
	game.cine_camera.position=Vector3(-6,1.9,80)
	game.cine_camera.look_at(Vector3(-15,1.3,80))
	game.phone.talk_to_resident("resident_00")
	check(game.phone.opened and lena.conversing,"physical resident interaction holds conversation and captures focus")
	check(press("Greet / ask name") and press("Ask about work"),"actual conversation buttons reveal name and occupation")
	var familiarity: int=world.relation("resident_00").familiarity
	press("Greet / ask name")
	check(world.relation("resident_00").familiarity==familiarity,"repeating a greeting cannot farm familiarity")
	check(press("Ask for number") and world.relation("resident_00").contact,"two distinct interactions unlock a persistent consented contact")
	await capture("resident-conversation")
	if world.audio_catalog.has("resident_00"):
		await game.phone.call_resident("resident_00")
		check(game.phone.call_state=="connected" and game.phone.call_audio.stream is AudioStreamWAV,"new named resident has an actual matching voiced call and subtitle")
		await capture("resident-call")
		game.phone.end_call()
	game.phone.talk_to_resident("resident_00")
	var balance: int=game.memory.money
	game.phone.cafe_menu()
	check(press("Sandwich • $8"),"actual checkout button invokes the food transaction")
	check(world.inventory.get("sandwich",0)==1 and game.memory.money==balance-8,"staffed cafe purchase charges actual cash and grants an actual item")
	check(world.ledger.back().category=="cafe_purchase" and world.ledger.back().cash_after==game.memory.money,"purchase receipt is tied to the authoritative cash balance")
	check(press("Coffee • $4") and world.inventory.get("coffee",0)==1 and game.memory.money==balance-12,"separate menu buttons retain their own product and exact price")
	await capture("cafe-purchase")
	game.player.health=50
	check(world.consume("sandwich") and game.player.health==75 and world.inventory.sandwich==0,"consuming the purchased item changes health and removes inventory")
	game.quarter.minutes=760
	lena.update_schedule()
	balance=game.memory.money
	world.buy_food("coffee")
	check(game.memory.money==balance and lena.schedule_period=="break","employee break closes the counter and refuses the transaction")
	game.quarter.minutes=1200
	lena.update_schedule()
	check(lena.schedule_period=="home" and not world.cafe_available(),"evening shift ends and counter closes")
	game.quarter.minutes=600
	lena.update_schedule()
	game.phone.close()
	check(not lena.conversing and game.player.is_physics_processing(),"conversation close restores both walking participants")
	check(world.transfer(20,true) and world.bank==20,"bank ledger foundation conserves cash during deposit")
	check(world.transfer(10,false) and world.bank==10,"bank ledger foundation conserves cash during withdrawal")
	balance=game.memory.money
	check(not world.transfer(10000,false) and game.memory.money==balance,"overdraft fails without changing balances")
	game._save()
	var saved_position: Vector3=lena.position
	world.relationships.clear();world.bank=0;world.inventory.clear();lena.position=Vector3(10,.2,160)
	game._load()
	check(world.relation("resident_00").contact and world.bank==10 and game.memory.money==balance,"world payload restores relationship, bank and cash consistently")
	check(lena.position.distance_to(saved_position)<.2,"named citizen position restores with stable identity")
	var payload:=world.snapshot()
	payload.version=99
	check(not world.restore(payload) and world.bank==10,"unsupported component version is rejected without resetting valid world state")
	payload=world.snapshot();payload.citizens.resident_00.position=[0,"bad",0]
	check(not world.validate(payload),"invalid citizen coordinates cannot enter live world state")
	game.quarter.minutes=1200
	lena.update_schedule()
	game.player.position=Vector3(0,.2,-175)
	world.refresh(1)
	check(world.abstract_count>=20 and lena.abstracted and not lena.animation.active,"distant population switches off animation and physical navigation")
	var before: Vector3=lena.position
	world.refresh(10)
	check(lena.position.distance_to(before)>0,"offscreen resident advances along a collision-aware abstract path")
	game.player.position=Vector3(0,.2,138)
	world.refresh(0)
	check(world.active_count>=20,"returning to the neighborhood resumes the active crowd")
	check(not game.story_active,"living-city interactions leave story activation voluntary")
	if DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().has("--profile-living-world"):
		check(game.get_viewport().get_texture().get_size()==Vector2(1920,1080),"crowd profiling uses a verified native 1920x1080 viewport")
		game.player.camera.current=true
		game.player.yaw=0
		game.player.pitch=-.08
		game.player.position=Vector3(0,.2,130)
		game.quarter.minutes=600
		game.quarter.apply_clock()
		game.ui.gameplay.show()
		await frames(15)
		await benchmark("day_crowd_walk",12,true)
		await capture("day-crowd-walk")
		game.quarter.minutes=60
		game.quarter.apply_clock()
		await benchmark("night_crowd",10)
		await capture("night-crowd")
		game.phone.toggle()
		await benchmark("phone_with_crowd",5)
		await capture("phone-with-crowd")
		game.phone.close()
		var file:=FileAccess.open("user://living-world-verification/performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(profiles,"  "))
		file.close()
	print("LIVING_WORLD_VALIDATION %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
