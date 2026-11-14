extends SceneTree

var failures: int = 0
var measured_peak: float = 0
var observed_pose := Quaternion.IDENTITY

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition: failures += 1

func frames(count: int) -> void:
	for i: int in range(count): await physics_frame

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(120)
	var dynamics: HumanDynamics = game.player.dynamics
	var skeleton: Skeleton3D = dynamics.get_skeleton()
	check(skeleton.get_bone_count() >= 32, "original skeleton extended with eight deforming secondary bones")
	for name: String in ["HairCrown", "HairFringe", "HemLeft", "HemRight"]:
		check(skeleton.find_bone(name) >= 0 and skeleton.find_bone(name + "Tip") >= 0, "secondary chain: " + name)
	var hair: int = skeleton.find_bone("HairCrown")
	dynamics.modification_processed.connect(func() -> void:
		observed_pose = skeleton.get_bone_pose_rotation(hair)
		measured_peak = maxf(measured_peak, dynamics.hair_angle.length())
	)
	game.harbor.wind_strength = 0
	dynamics.reset_state()
	await frames(120)
	var rest: Quaternion = skeleton.get_bone_rest(hair).basis.get_rotation_quaternion()
	check(observed_pose.angle_to(rest) < 0.01, "secondary modifier preserves imported bone rest orientation")
	Input.action_press("forward")
	Input.action_press("sprint")
	await frames(35)
	check(measured_peak > 0.005 and dynamics.hem_angle.length() > 0.001, "movement acceleration excites hair and garment springs")
	check(observed_pose.angle_to(rest) > 0.001, "post-animation modifier changes actual hair bone pose")
	Input.action_release("forward")
	Input.action_release("sprint")
	await frames(240)
	check(dynamics.hair_angle.length() < 0.005 and dynamics.hem_angle.length() < 0.01, "hair and hem settle after stopping")
	game.harbor.wind_strength = 3
	await frames(120)
	check(dynamics.hair_angle.length() > 0.005, "shared district wind drives secondary motion")
	check(dynamics.hair_angle.length() <= 0.16 and dynamics.hem_angle.length() <= 0.25, "secondary angular limits prevent unbounded motion")
	game.player.position += Vector3(0, 0, 10)
	var reset_before: int = dynamics.reset_count
	await frames(2)
	check(dynamics.reset_count > reset_before, "teleport resets transient spring state")
	game.player.position = game.car.position
	game._interact()
	await frames(90)
	check(game.player.driving and game.player.visual.visible, "visible seated driver replaces hidden character")
	check(game.player.current_animation == "Drive", "seated animation is integrated with occupancy")
	var hip: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin
	var local_hip: Vector3 = game.car.to_local(hip)
	print("DRIVER_LOCAL_HIP ",local_hip)
	check(local_hip.y > -0.4 and local_hip.y < 0.1, "driver pelvis is inside seat height bounds")
	var hand: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin
	check(hand.distance_to(game.car.steering_visual.global_position) < 0.35, "driver hand reaches steering wheel region")
	Input.action_press("left")
	await frames(30)
	Input.action_release("left")
	check(absf(game.car.steering_visual.rotation.z) > 0.05, "steering wheel responds to vehicle input")
	game._leave_car()
	check(game.player.visual.position.is_zero_approx(), "exit restores walking visual transform")
	check(game.harbor.shutters.size() == 19, "warehouse expansion preserves original fourteen plus five side-road buildings")
	check(game.harbor.wind_materials.size() == 3, "shared wind also drives hanging fabric")
	game.queue_free()
	await create_timer(0.7).timeout
	quit(1 if failures else 0)
