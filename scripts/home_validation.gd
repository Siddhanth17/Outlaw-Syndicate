class_name HomeValidation
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
func stop() -> void:
	for key: String in ["forward","back","left","right"]:Input.action_release(key)
func walk(at: Vector3,limit: int=500,radius: float=.65) -> bool:
	game.player.yaw=0
	for i: int in range(limit):
		var offset: Vector3=at-game.player.position;offset.y=0
		if offset.length()<radius:stop();await frames(4);return true
		offset=offset.normalized()
		stop()
		Input.action_press("right" if offset.x>0 else "left",absf(offset.x))
		Input.action_press("back" if offset.z>0 else "forward",absf(offset.z))
		await frames(1)
	print("HOME_WALK_BLOCKED at=",game.player.position," target=",at," collisions=",game.player.get_slide_collision_count())
	for i: int in range(game.player.get_slide_collision_count()):print("HOME_WALK_COLLIDER ",game.player.get_slide_collision(i).get_collider())
	stop();return false
func local(at: Vector3) -> Vector3:return ValeHome.ADDRESS+at
func press(text: String) -> bool:
	for node: Node in game.phone.column.get_children():
		if node is Button and node.text==text:node.pressed.emit();return true
	return false
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://home-verification/"+name+".png")
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	await frames(6)
	game._menu_action("New game")
	DirAccess.make_dir_recursive_absolute("user://home-verification")
	await frames(60)
	check(game.player.position.distance_to(game.residence.spawn_point())<.5 and game.player.is_on_floor(),"New Game starts on physical bedroom floor inside Adrian's furnished home")
	check(not game.story_active and not game.cinematic_active,"home opening leaves free roam and main story voluntary")
	await capture("new-game-bedroom")
	game._interact()
	check(game.phone.opened and press("Save checkpoint"),"physical home desk opens a real checkpoint action")
	game.phone.close()
	check(await walk(local(Vector3(-2,.2,2))),"walk clear of the bed and storage")
	await walk(local(Vector3(-1.25,.2,2)),500,.15)
	check(await walk(local(Vector3(-1.25,.2,-3.2)),500,.15) and await walk(local(Vector3(-4,.2,-3.2))),"walk physically around the bed and bedside furniture to the wardrobe")
	game._interact()
	check(press("Weathered brown leather") and game.residence.outfit==1 and not game.residence.finishes.is_empty(),"wardrobe button changes actual hero jacket material while retaining injury shader")
	game.phone.close()
	await capture("wardrobe")
	await walk(local(Vector3(-1.25,.2,-3.2)),500,.15);await walk(local(Vector3(-1.25,.2,0)),500,.15);await walk(local(Vector3(-2,.2,0)),500,.15)
	game._interact()
	var minutes: float=game.quarter.minutes
	var day: int=game.quarter.day
	game.player.health=50
	check(press("Rest • eight hours") and game.player.health==100 and game.quarter.day*1440+game.quarter.minutes>day*1440+minutes+479,"bed rest restores health and advances the real day/clock by eight hours")
	game.phone.close()
	await walk(local(Vector3(-2,.2,2)))
	check(await walk(local(Vector3(-4.3,.2,2.5)),500,.2),"walk close enough to address the storage chest rather than the adjacent desk")
	print("STORAGE_TARGET ",game.residence.target()," at=",game.player.position)
	game.living.inventory.coffee=1
	game._interact()
	check(press("Store one coffee") and game.living.inventory.coffee==0 and game.residence.storage.coffee==1,"physical storage transfers the actual carried item without duplication")
	game.phone.close()
	game._save()
	game.residence.set_outfit(0);game.residence.storage.coffee=0
	game._load();await frames(10)
	print("HOME_RESTORED ",game.residence.snapshot())
	check(game.residence.outfit==1 and game.residence.storage.coffee==1,"checkpoint restores home storage and selected jacket finish")
	var invalid: Dictionary=game.residence.snapshot();invalid.storage.coffee=INF
	check(not game.residence.validate(invalid),"nonfinite home inventory is rejected before restoring live game state")
	await walk(local(Vector3(-2,.2,2)));await walk(local(Vector3(0,.2,2)))
	await walk(local(Vector3(0,.2,3.6)))
	game._interact();await frames(45)
	check(game.residence.door_open and not game.residence.door_busy,"home entrance opens the modeled door and its physical collision")
	check(await walk(local(Vector3(0,.2,7))),"player actually walks through the doorway into West Northline")
	await capture("home-exterior")
	check(game.quarter.centers.size()==8,"west/east expansion adds four accessible blocks to the retained original four")
	var west: PackedVector3Array=game.navigation.path(Vector3(-130,.2,90),Vector3(-10,.2,90))
	var east: PackedVector3Array=game.navigation.path(Vector3(10,.2,90),Vector3(132,.2,90))
	check(west.size()>10 and east.size()>10,"collision/ground-sampled paths connect both west and east districts to the original quarter")
	game.phone.toggle();game.phone.city_map();await capture("connected-district-map");game.phone.close()
	print("HOME_VALIDATION %d passed %d failed"%[passes,failures])
	if failures or OS.get_cmdline_user_args().has("--home-only"):
		get_tree().quit(1 if failures else 0);return
	# Continue physically from home to the pre-existing optional opening mission.
	var route: PackedVector3Array=game.navigation.path(game.player.position,Vector3(0,.2,12),true)
	check(not route.is_empty(),"home exterior connects to the garage approach")
	for point: Vector3 in route:
		if not await walk(point,240,.35):
			check(false,"physical walk from home reaches garage approach");get_tree().quit(1);return
	check(true,"physical walk from home reaches garage approach")
	var mission:=MissionRouteValidation.new();mission.game=game;game.add_child(mission)
	await mission.run(true)
