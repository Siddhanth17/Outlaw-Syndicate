class_name MetropolisValidation
extends Node

var game: Node3D
var passes: int=0
var failures: int=0

func check(value: bool, text: String) -> void:
	print(("PASS " if value else "FAIL ")+text)
	if value: passes+=1
	else: failures+=1

func frames(count: int) -> void:
	for i: int in range(count): await get_tree().physics_frame

func press(text: String) -> bool:
	for item: Node in game.phone.column.get_children():
		if item is Button and item.text==text:
			item.pressed.emit()
			return true
	return false

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://metropolis-verification/"+name+".png")

func run() -> void:
	game.test_mode=true
	game._menu_action("New game")
	await frames(12)
	check(not game.story_active and not game.cinematic_active,"New Game starts free roam without a cinematic or active story")
	game.player.position=Vector3(-1,0.1,-1)
	game._interact()
	await frames(3)
	check(game.memory.stage==0 and not game.story_active,"garage proximity and interaction cannot silently accept story")
	game.phone.close()
	game.phone.toggle()
	check(game.phone.opened and not game.player.is_physics_processing() and not game.player.camera_input_enabled,"phone captures movement and camera focus")
	var ammo: int=game.ammunition
	var fire:=InputEventAction.new()
	fire.action="fire"
	fire.pressed=true
	game._unhandled_input(fire)
	check(game.ammunition==ammo,"phone input cannot fire through into gameplay")
	check(not game.phone.dante_contact,"Dante number is not granted by proximity")
	game.phone.talk_to_dante()
	check(press("Greet") and press("Ask about work") and press("Ask for his number") and game.phone.dante_contact,"conversation buttons earn Dante's contact through distinct interactions")
	await game.phone.call_dante()
	check(game.phone.call_state=="connected" and game.phone.call_audio.stream is AudioStreamWAV,"earned contact connects to an actual recorded voice stream")
	game.phone.end_call()
	check(not game.phone.call_audio.playing and game.phone.call_state=="idle","ending call stops audio")
	var previous_health: float=game.dante.health
	game.dante.health=0 # Stable unavailability fixture; knockdown can legitimately recover during ringing.
	await game.phone.call_dante()
	check(game.phone.call_state=="busy" and not game.phone.call_audio.playing,"unavailable mechanic returns busy without voice playback")
	game.dante.health=previous_health
	game.phone.end_call()
	var cash: int=game.memory.money
	game.car.integrity=60
	game.car.linear_velocity=Vector3.ZERO
	var receipt: String=game.phone.repair_sable()
	check(game.car.integrity==100 and game.memory.money==cash-50,"garage repair charges cash and resets actual car damage")
	game.phone.repair_sable()
	check(game.memory.money==cash-50,"undamaged vehicle cannot be charged repeatedly")
	game.car.integrity=70
	game.memory.money=20
	game.phone.repair_sable()
	check(game.car.integrity==70 and game.memory.money==20,"insufficient cash leaves damage and balance unchanged")
	game.memory.money=cash-50
	game.phone.home()
	DirAccess.make_dir_recursive_absolute("user://metropolis-verification")
	await frames(18)
	await capture("phone")
	await game.phone.capture_photo()
	if DisplayServer.get_name()!="headless":
		check(game.phone.photos.size()==1,"camera writes an actual viewport photo")
		game.phone.gallery()
		await capture("gallery")
	var close_key:=InputEventKey.new()
	close_key.physical_keycode=game.phone.key_code
	close_key.pressed=true
	Input.parse_input_event(close_key)
	await frames(2)
	close_key.pressed=false
	Input.parse_input_event(close_key)
	check(not game.phone.opened and game.player.is_physics_processing() and game.player.camera_input_enabled,"actual phone key closes a focused GUI and restores movement/orbit")
	game._save()
	game.story_active=true
	game._load()
	check(not game.story_active,"free roam checkpoint restores without activating story")
	check(game.phone.dante_contact and game.memory.money==cash-50 and game.car.integrity==70,"relationship, balance and car condition persist together")
	if DisplayServer.get_name()!="headless": check(game.phone.photos.size()==1,"gallery index survives checkpoint restoration")
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.SAVE_PATH))
	old.erase("open_world")
	var legacy:=FileAccess.open(game.SAVE_PATH,FileAccess.WRITE)
	legacy.store_string(JSON.stringify(old))
	legacy.close()
	game._load()
	check(game.story_active,"legacy checkpoint without open-world fields retains active mission")
	game.story_active=false
	game.start_story()
	check(game.story_active and game.memory.stage==0,"story requires intentional acceptance and preserves stage zero")
	game._save()
	game.story_active=false
	game._load()
	check(game.story_active,"accepted story survives checkpoint restoration")
	await frames(5)
	game.bike.position=Vector3(-70,0.8,15)
	game.bike.rotation=Vector3.ZERO
	game.bike.linear_velocity=Vector3.ZERO
	await frames(120)
	game.player.position=game.bike.position+Vector3.LEFT
	check(game.bike.interact(),"stationary motorcycle accepts mount")
	await frames(90)
	check(game.player.riding_bike,"mount completes into riding state")
	if DisplayServer.get_name()!="headless":
		var times: Array[float]=[]
		var before:=Time.get_ticks_usec()
		for i: int in range(180):
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			times.append((now-before)/1000.0)
			before=now
		var total: float=0
		for t: float in times: total+=t
		times.sort()
		var report: Dictionary={"scope":"180 rendered frames, stationary mounted rider in existing harbor; automated route", "mean_fps":180000.0/total,"p95_ms":times[170],"max_ms":times.back(),"texture_buffer_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
		var output:=FileAccess.open("user://metropolis-verification/performance.json",FileAccess.WRITE)
		output.store_string(JSON.stringify(report,"  "))
		output.close()
		print("RENDER_SAMPLE ",report)
	print("CONTACT ERRORS ",game.bike.rider_ik.errors)
	for endpoint: String in ["LeftHand","RightHand","LeftFoot","RightFoot"]:
		check(float(game.bike.rider_ik.errors.get(endpoint,999))<0.055,endpoint+" remains within 5.5cm of modeled contact")
	check(game.bike.handlebar.get_child_count()>=7,"modeled handlebar, grips and mirrors remain separate steerable parts")
	game.ui.gameplay.hide()
	game.cine_camera.current=true
	for view: String in ["front","side","rear"]:
		var offset:=Vector3(0,1.15,3.2) if view=="front" else (Vector3(3.2,1.1,0) if view=="side" else Vector3(0,1.2,-3.2))
		game.cine_camera.position=game.bike.position+offset
		game.cine_camera.look_at(game.bike.position+Vector3.UP*0.7)
		await frames(8)
		await capture("rider-"+view)
	Input.action_press("forward")
	Input.action_press("left",0.5)
	await frames(110)
	Input.action_release("forward")
	Input.action_release("left")
	check(absf(game.bike.lean)>0.015,"wheel forces produce a turning visual lean")
	for endpoint: String in ["LeftHand","RightHand","LeftFoot","RightFoot"]:
		check(float(game.bike.rider_ik.errors.get(endpoint,999))<0.055,endpoint+" tracks contact while steering and leaning")
	game.cine_camera.position=game.bike.position+Vector3(3,1.4,3)
	game.cine_camera.look_at(game.bike.position+Vector3.UP*0.7)
	await capture("rider-turn")
	game.bike.release()
	check(not game.player.riding_bike and game.player.collision_layer==CollisionLayers.PLAYER,"dismount restores on-foot collision")
	print("METROPOLIS RESULTS %d PASS / %d FAIL"%[passes,failures])
	get_tree().quit(1 if failures else 0)
