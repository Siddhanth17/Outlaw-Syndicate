class_name CombatLab
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
var measuring: bool=false
var previous: int=0
var samples: Array[float]=[]
var physics_ms: Array[float]=[]
var evidence_camera: Camera3D
func _process(_delta: float) -> void:
	if not measuring:return
	var now: int=Time.get_ticks_usec()
	if previous>0:samples.append((now-previous)/1000.0)
	previous=now
	physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(count: int) -> void:
	for i: int in range(count):await get_tree().physics_frame
func target(actor: HarborGuard,region: String) -> NPCHitRegion:
	for hitbox: NPCHitRegion in actor.hit_regions:
		if hitbox.region==region:return hitbox
	return null
func ray_to(area: NPCHitRegion) -> Dictionary:
	var center: Vector3=area.get_child(0).global_position
	var query:=PhysicsRayQueryParameters3D.create(center+Vector3(0,0,3),center-Vector3(0,0,.3),CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE|NPCHitRegion.LAYER)
	query.collide_with_areas=true
	return game.get_world_3d().direct_space_state.intersect_ray(query)
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	await frames(6)
	game._menu_action("New game")
	game.player.position=Vector3(0,.2,24)
	game.player.yaw=PI;game.player.pitch=-.06
	var actor:=HarborGuard.new();actor.game=game;actor.position=Vector3(0,.1,30)
	game.add_child(actor);actor.set_physics_process(false)
	await frames(5)
	if DisplayServer.get_name()!="headless":
		evidence_camera=Camera3D.new();game.add_child(evidence_camera)
		evidence_camera.global_position=Vector3(1.8,1.5,32.5)
		evidence_camera.look_at(Vector3(0,1,30),Vector3.UP);evidence_camera.current=true
	check(actor.hit_regions.size()==14,"fourteen bone-attached collision segments cover eight gameplay regions")
	for region: String in ["head","neck","upper_torso","lower_torso","left_arm","right_arm","left_leg","right_leg"]:
		var area: NPCHitRegion=target(actor,region)
		var hit: Dictionary=ray_to(area)
		print("REGION_RAY ",region," -> ",hit.get("collider"))
		check(not hit.is_empty() and hit.collider is NPCHitRegion and hit.collider.actor==actor and hit.collider.region==region,"actual physics ray identifies "+region+" on the intended actor")
	var arm: NPCHitRegion=target(actor,"left_arm")
	var before: Vector3=arm.get_child(0).global_position
	for name: String in actor.animation.get_animation_list():
		if name.ends_with("Walk"):actor.animation.play(name);break
	await frames(20)
	check(arm.get_child(0).global_position.distance_to(before)>.005,"hit regions move with the playing character skeleton")
	actor._play("Idle");await frames(10)
	actor.receive_projectile("left_leg",target(actor,"left_leg").get_child(0).global_position,Vector3.FORWARD)
	check(is_equal_approx(actor.health,43) and actor.state==HarborGuard.State.STAGGER,"limb hit applies documented 27 damage and directional stagger")
	actor.health=70;actor.combat_profile="police"
	actor.receive_projectile("upper_torso",target(actor,"upper_torso").get_child(0).global_position,Vector3.FORWARD)
	check(is_equal_approx(actor.health,49.75) and actor.last_damage.protection==.55,"police torso protection reduces a real regional hit to 20.25 damage")
	var head: NPCHitRegion=target(actor,"head")
	var center: Vector3=head.get_child(0).global_position
	game.cooldown=0;game.reload_time=0
	game.player.camera.global_position=center+Vector3(0,0,3)
	game.player.camera.look_at(center,Vector3.UP)
	game._fire()
	check(actor.health==0 and actor.last_damage.region=="head" and actor.last_damage.critical,"actual player fire defeats an unprotected head regardless of torso armor")
	check(actor.ragdoll.active and actor.ragdoll.bones.size()==13,"critical defeat activates the preserved thirteen-segment articulated rig")
	var count: int=actor.bullet_hit_count
	actor.receive_projectile("head",center,Vector3.FORWARD)
	check(actor.bullet_hit_count==count,"defeated actors ignore repeated damage activation")
	game.character_impacts.hit(Vector3(2,1.2,30),Vector3.DOWN,35)
	await frames(90)
	check(game.character_impacts.collision_contacts>0,"ballistic droplet segments contact actual world geometry")
	check(game.character_impacts.marks.any(func(mark: Decal) -> bool:return mark.visible),"supported droplet contacts leave bounded surface stains")
	check(game.character_impacts.drops.size()==72 and game.character_impacts.marks.size()==12,"liquid-look approximation uses fixed droplet and stain budgets")
	if DisplayServer.get_name()!="headless":
		evidence_camera.global_position=Vector3(3,2.5,33)
		evidence_camera.look_at(Vector3(0,.4,30),Vector3.UP);evidence_camera.current=true
		await frames(20);await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("user://combat-lab")
		game.get_viewport().get_texture().get_image().save_png("user://combat-lab/critical-ragdoll-stains.png")
		for mark: Decal in game.character_impacts.marks:
			if mark.visible:print("STAIN_CONTACT ",mark.global_position," size=",mark.size)
		evidence_camera.global_position=Vector3(2,1.4,31.4)
		evidence_camera.look_at(Vector3(2,0,30),Vector3.UP)
		await frames(2);await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://combat-lab/stain-closeup.png")
	if OS.get_cmdline_user_args().has("--combat-stress"):
		if evidence_camera:
			evidence_camera.global_position=Vector3(6,4,37)
			evidence_camera.look_at(Vector3(0,.4,32),Vector3.UP)
		for i: int in range(5):
			var extra:=HarborGuard.new();extra.game=game;extra.position=Vector3(-4+i*2,.2,33+float(i%2)*2)
			game.add_child(extra);await frames(2)
			extra.receive_projectile("head",extra.position+Vector3.UP*1.6,Vector3(sin(i),0,cos(i)))
		await frames(60)
		var started: int=Time.get_ticks_usec();measuring=true
		for i: int in range(3600):
			if i%15==0:game.character_impacts.hit(Vector3(-2+float(i%5),1.3,30),Vector3(.5,.3,.5),35)
			await frames(1)
		measuring=false
		var seconds: float=(Time.get_ticks_usec()-started)/1000000.0
		var metrics:=ExpansionValidation.new()
		var stats: Dictionary=metrics.statistics(samples)
		var worst: float=0;var worst_count: int=maxi(1,int(ceil(samples.size()*.01)))
		for i: int in range(samples.size()-worst_count,samples.size()):worst+=samples[i]
		var report: Dictionary={"seconds":seconds,"frames":samples.size(),"average_fps":1000/stats.mean,"one_percent_low_fps":1000/(worst/worst_count),"frame_ms":stats,"physics_ms":metrics.statistics(physics_ms),"droplet_budget":72,"stain_budget":12,"ragdolls":6,"render_size":[1920,1080],"scope":"automated stationary combat lab; six articulated defeats, four fresh blood impacts per simulation second, normal city/traffic; no recording during measurement","audio_dsp_cpu":"NOT MEASURED"}
		DirAccess.make_dir_recursive_absolute("user://combat-lab")
		FileAccess.open("user://combat-lab/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
		metrics.free()
		print("COMBAT_PERFORMANCE ",JSON.stringify(report))
	print("COMBAT_LAB %d passed %d failed"%[passes,failures])
	get_tree().quit(1 if failures else 0)
