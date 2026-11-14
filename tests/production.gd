extends SceneTree

var failures: int = 0

func check(value: bool, description: String) -> void:
	print(("PASS " if value else "FAIL ") + description)
	if not value: failures += 1

func frames(count: int) -> void:
	for i: int in range(count): await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(120)
	check(ProjectSettings.get_setting("physics/3d/physics_engine") == "Jolt Physics", "Jolt preserved")
	check(not game.player.visual is MeshInstance3D, "human scene replaces capsule visual")
	var skeletons: Array[Node] = game.player.visual.find_children("*", "Skeleton3D", true, false)
	check(skeletons.size() == 1 and skeletons[0].get_bone_count() >= 24, "human has imported skeleton")
	var tree: AnimationTree = game.player.tree
	check(tree.active and game.player.playback != null, "AnimationTree state machine active")
	for clip: String in ["Idle", "Walk", "Run", "Sprint", "Interact", "Aim", "Shoot", "Reload", "Jump", "Land", "Turn"]:
		check((tree.tree_root as AnimationNodeStateMachine).has_node(clip), "animation integrated: " + clip)
	var skeleton: Skeleton3D = skeletons[0]
	var leg: int = skeleton.find_bone("LeftUpLeg")
	Input.action_press("forward")
	await frames(8)
	var first: Quaternion = skeleton.get_bone_pose_rotation(leg)
	await frames(12)
	var second: Quaternion = skeleton.get_bone_pose_rotation(leg)
	Input.action_release("forward")
	check(not first.is_equal_approx(second), "walking deforms skeleton over time")
	Input.action_press("aim")
	await frames(30)
	check(game.player.camera.fov < 60 and game.player.arm.spring_length < 3, "aim camera transition")
	Input.action_release("aim")
	game.player.position = Vector3(22.2, 0.2, 0)
	game.player.yaw = PI / 2
	await frames(50)
	check(game.player.arm.get_hit_length() < game.player.arm.spring_length - 0.1 and game.player.camera.global_position.x < 24, "spring arm prevents camera entering warehouse")
	game.player.position = Vector3(0, 0.1, 12)
	game.player.yaw = 0
	game.player.position = Vector3(7, 0.1, 20)
	await frames(20)
	Input.action_press("right")
	await frames(45)
	Input.action_release("right")
	check(game.player.position.x > 8.5 and game.player.position.y > 0.1, "character steps onto raised sidewalk without jumping")
	game._pause()
	check(not game.ui.gameplay.visible and game.ui.modal.visible, "pause hides entire gameplay HUD")
	game._menu_action("Controls")
	check(game.ui.current_screen == "controls", "controls accessible in pause menu")
	game._menu_action("Back")
	check(game.ui.current_screen == "pause", "controls returns to pause")
	game._pause()
	game._start_cinematic(false)
	check(game.cinematic_active and game.cine_camera.current, "opening cinematic camera")
	game._end_cinematic()
	check(not game.cinematic_active and game.player.camera.current, "cinematic skip restores gameplay camera")
	game.car.position = Vector3(0, 1.1, 15)
	game.car.rotation = Vector3(0, PI, 0)
	game.player.position = game.car.position
	game._interact()
	var start_z: float = game.car.position.z
	Input.action_press("forward")
	await frames(150)
	Input.action_release("forward")
	check(game.player.driving and game.car.position.z < start_z - 2, "input drives modeled vehicle forward")
	check(game.car.wheels.size() == 4 and game.car.wheels[0].get_child_count() > 0, "four separate visual wheels")
	Input.action_press("left")
	await frames(20)
	check(absf(game.car.steering) > 0.05, "steering responds to input")
	Input.action_release("left")
	Input.action_press("handbrake")
	await frames(120)
	Input.action_release("handbrake")
	check(game.car.linear_velocity.length() < 3, "braking permits safe vehicle exit")
	game._leave_car()
	game.car.integrity = 47
	game._save()
	game.car.integrity = 100
	game._load()
	check(is_equal_approx(game.car.integrity, 47), "vehicle damage persists")
	game.memory.stage = 3
	game.memory.heat = 100
	game._spawn_guards()
	game.player.position = Vector3(9, 0.1, -92)
	await frames(130)
	check(game.guards[0].state == HarborGuard.State.ENGAGE, "enemy perception transitions to engagement")
	check(game.player.health < 100, "enemy encounter causes gameplay damage")
	var guard: HarborGuard = game.guards[0]
	game.player.camera.look_at(guard.global_position + Vector3.UP * 1.1)
	var old_ammo: int = game.ammunition
	game.cooldown = 0
	game._fire()
	check(game.ammunition == old_ammo - 1 and guard.health < 70, "camera raycast damages enemy and consumes ammo")
	game.cooldown = 0
	game._fire()
	check(guard.state == HarborGuard.State.DEFEATED, "enemy can be defeated")
	check(game.memory.events.has("guard_defeated_" + guard.name), "combat consequence recorded")
	game.ammunition = 0
	game._reload()
	await frames(100)
	check(game.ammunition == 12 and game.reserve == 60, "reload transfers reserve ammunition")
	game._save()
	game.damage_player(1000)
	check(game.paused and game.ui.current_screen == "defeat", "health depletion opens checkpoint retry")
	game._menu_action("Retry checkpoint")
	check(not game.paused and game.player.health > 0, "retry restores playable health")
	game.harbor.preset(0)
	check(not game.harbor.environment.environment.ssao_enabled, "low graphics preset disables SSAO")
	game.harbor.preset(2)
	check(game.harbor.environment.environment.volumetric_fog_enabled, "high preset enables volumetric fog")
	game._end_cinematic()
	game.queue_free()
	await process_frame
	await process_frame
	# Let queued one-shot audio/light timers finish before auditing shutdown.
	await create_timer(0.7).timeout
	quit(1 if failures else 0)
