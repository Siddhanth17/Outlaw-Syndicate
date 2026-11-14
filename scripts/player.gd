class_name ValePlayer
extends CharacterBody3D

var injuries: InjuryVisuals
var recoil_offset:=Vector2.ZERO
var recoil_impulses: int=0
var camera_input_enabled: bool = true
var yaw: float = 0.0
var pitch: float = -0.12
var sensitivity: float = 0.0025
var driving: bool = false
var aiming: bool = false
var health: float = 100
var pivot: Node3D
var camera: Camera3D
var arm: SpringArm3D
var visual: Node3D
var animator: AnimationPlayer
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var current_animation: String = ""
var action_time: float = 0
var action_name: String = ""
var was_grounded: bool = true
var reduced_shake: bool = true
var weapon: Node3D
var last_yaw: float = 0
var step_time: float = 0
var footstep: AudioStreamPlayer3D
var vehicle: VeyraCar
var camera_manual_time: float = 0
var dynamics: HumanDynamics

func _ready() -> void:
	collision_layer = CollisionLayers.PLAYER
	collision_mask = CollisionLayers.SOLIDS
	floor_snap_length = 0.25
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	visual = load("res://assets/characters/adrian_signature.glb").instantiate()
	visual.name = "AdrianVisual"
	add_child(visual)
	visual.rotation.y = PI
	injuries=InjuryVisuals.new()
	add_child(injuries)
	injuries.setup(visual)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		animator = players[0]
		_setup_animation()
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position = Vector3(0.52, 1.50, 0)
	arm = SpringArm3D.new()
	arm.spring_length = 4.0
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	arm.shape = sphere
	arm.margin = 0.15
	arm.collision_mask = CollisionLayers.STATIC | CollisionLayers.VEHICLE | CollisionLayers.PROP
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 66
	camera.near = 0.08
	camera.far = 400
	arm.add_child(camera)
	weapon = load("res://assets/vehicles/sidearm.glb").instantiate()
	var skeletons := visual.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		var skeleton: Skeleton3D = skeletons[0]
		dynamics = HumanDynamics.new()
		dynamics.actor = self
		skeleton.add_child(dynamics)
		dynamics.reset_state()
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = "RightHand"
		skeleton.add_child(attachment)
		attachment.add_child(weapon)
		weapon.scale = Vector3.ONE * 100
		weapon.position = Vector3(0, 7, 0)
	weapon.hide()
	footstep = AudioStreamPlayer3D.new()
	footstep.stream = load("res://assets/audio/step.wav")
	footstep.volume_db = -12
	add_child(footstep)

func _setup_animation() -> void:
	tree = AnimationTree.new()
	add_child(tree)
	tree.anim_player = tree.get_path_to(animator)
	tree.root_node = tree.get_path_to(animator.get_node(animator.root_node))
	var states := AnimationNodeStateMachine.new()
	var names: Array[String] = []
	for key: String in ["Idle", "Walk", "Run", "Sprint", "Interact", "Aim", "Shoot", "Reload", "Jump", "Land", "Turn", "Enter", "Exit", "Drive"]:
		for animation: String in animator.get_animation_list():
			if animation.ends_with(key):
				var clip := animator.get_animation(animation)
				clip.loop_mode = Animation.LOOP_LINEAR if key in ["Idle", "Walk", "Run", "Sprint", "Aim", "Drive"] else Animation.LOOP_NONE
				var node := AnimationNodeAnimation.new()
				node.animation = animation
				if key in ["Walk", "Run", "Sprint"]:
					var locomotion := AnimationNodeBlendTree.new()
					locomotion.add_node("Clip", node)
					locomotion.add_node("Rate", AnimationNodeTimeScale.new())
					locomotion.connect_node("Rate", 0, "Clip")
					locomotion.connect_node("output", 0, "Rate")
					states.add_node(key, locomotion)
				else:
					states.add_node(key, node)
				names.append(key)
	var walk_name: String=""
	var aim_name: String=""
	for animation: String in animator.get_animation_list():
		if animation.ends_with("Walk"): walk_name=animation
		if animation.ends_with("Aim"): aim_name=animation
	if not walk_name.is_empty() and not aim_name.is_empty():
		var blended:=AnimationNodeBlendTree.new()
		var walk_node:=AnimationNodeAnimation.new()
		walk_node.animation=walk_name
		var aim_node:=AnimationNodeAnimation.new()
		aim_node.animation=aim_name
		var mix:=AnimationNodeBlend2.new()
		mix.filter_enabled=true
		var clip:=animator.get_animation(aim_name)
		for index: int in range(clip.get_track_count()):
			var path: NodePath=clip.track_get_path(index)
			if path.get_subname_count()>0 and str(path.get_subname(0)) in ["Spine","Spine1","Spine2","Neck","Head","LeftShoulder","LeftArm","LeftForeArm","LeftHand","RightShoulder","RightArm","RightForeArm","RightHand"]: mix.set_filter_path(path,true)
		blended.add_node("Walk",walk_node)
		blended.add_node("Rate",AnimationNodeTimeScale.new())
		blended.add_node("UpperAim",aim_node)
		blended.add_node("Mix",mix)
		blended.connect_node("Rate",0,"Walk")
		blended.connect_node("Mix",0,"Rate")
		blended.connect_node("Mix",1,"UpperAim")
		blended.connect_node("output",0,"Mix")
		states.add_node("AimWalk",blended)
		names.append("AimWalk")
	for a: String in names:
		for b: String in names:
			if a != b:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.14
				states.add_transition(a, b, transition)
	tree.tree_root = states
	tree.active = true
	tree.set("parameters/AimWalk/Mix/blend_amount",1.0)
	playback = tree.get("parameters/playback")
	if names.has("Idle"):
		playback.start("Idle")

func perform(action: String, duration: float) -> void:
	action_name = action
	action_time = duration
	if playback:
		playback.travel(action)
	current_animation = action

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and camera_input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_manual_time = 1.5
		yaw -= event.screen_relative.x * sensitivity
		pitch = clampf(pitch - event.screen_relative.y * sensitivity, -0.85, 0.45)

func _physics_process(delta: float) -> void:
	var rx: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	yaw -= (rx if absf(rx) > 0.15 else 0.0) * delta * 2
	pitch = clampf(pitch - (ry if absf(ry) > 0.15 else 0.0) * delta * 2, -0.85, 0.45)
	recoil_offset=recoil_offset.move_toward(Vector2.ZERO,delta*0.12)
	camera_manual_time -= delta
	if driving and is_instance_valid(vehicle) and absf(rx) < 0.15 and camera_manual_time <= 0:
		yaw = lerp_angle(yaw, vehicle.rotation.y + PI, 1 - exp(-delta * 1.3))
	aiming = Input.is_action_pressed("aim") and not driving
	var offset := Basis(Vector3.UP, yaw) * Vector3(0.55 if not driving else 0.0, 1.45 if not driving else 1.6, 0)
	pivot.position = pivot.position.lerp(offset, 1 - exp(-delta * 9))
	pivot.rotation = Vector3(pitch+recoil_offset.x, yaw+recoil_offset.y + (PI if driving and Input.is_action_pressed("rear_view") else 0.0), 0)
	arm.spring_length = lerpf(arm.spring_length, 6.8 if driving else (2.3 if aiming else 3.6), 1 - exp(-delta * 6))
	camera.fov = lerpf(camera.fov, 74 if driving else (52 if aiming else 66), delta * 6)
	if driving:
		return
	var axis := Input.get_vector("left", "right", "forward", "back")
	var direction := Basis(Vector3.UP, yaw) * Vector3(axis.x, 0, axis.y)
	var speed: float = 6.5 if Input.is_action_pressed("sprint") else (3.4 if axis.length() > 0.8 else 1.8)
	if Input.is_action_pressed("crouch") or aiming:
		speed = 1.8
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 20)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 20)
	if not is_on_floor():
		velocity.y -= 24 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 7
		perform("Jump", 0.6)
	if is_on_floor() and direction.length() > 0.1:
		_step_up(direction.normalized())
	move_and_slide()
	for i: int in range(get_slide_collision_count()):
		var contact := get_slide_collision(i)
		if contact.get_collider() is RigidBody3D:
			var rigid: RigidBody3D = contact.get_collider()
			if rigid.collision_layer & CollisionLayers.PROP:
				rigid.apply_central_impulse(-contact.get_normal() * minf(rigid.mass * 0.6, 25))
	if is_on_floor() and not was_grounded:
		perform("Land", 0.25)
	was_grounded = is_on_floor()
	if direction.length() > 0.1 or aiming:
		var facing: float = yaw + PI if aiming else atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, facing, delta * 12)
	action_time -= delta
	var locomotion: String = "Sprint" if speed > 5 else ("Run" if speed > 2.5 else "Walk")
	if tree:
		var nominal: float = 6.5 if locomotion == "Sprint" else (3.4 if locomotion == "Run" else 1.8)
		tree.set("parameters/" + locomotion + "/Rate/scale", clampf(Vector2(velocity.x, velocity.z).length() / nominal, 0.15, 1.3))
	if tree: tree.set("parameters/AimWalk/Rate/scale",clampf(Vector2(velocity.x,velocity.z).length()/1.8,0.15,1.3))
	var turning: bool = absf(angle_difference(last_yaw, yaw)) > 0.01 and axis.length() < 0.1
	var state: String = action_name if action_time > 0 else ("Jump" if not is_on_floor() else (("AimWalk" if axis.length()>0.1 else "Aim") if aiming else (locomotion if axis.length() > 0.1 else ("Turn" if turning else "Idle"))))
	if turning:
		visual.rotation.y = lerp_angle(visual.rotation.y, yaw + PI, delta * 7)
	last_yaw = yaw
	if state != current_animation and playback:
		playback.travel(state)
		current_animation = state
	weapon.visible = aiming or action_name in ["Shoot", "Reload"] and action_time > 0
	if weapon.visible:
		weapon.global_basis = Basis(Vector3.UP, visual.global_rotation.y)
	step_time -= delta
	if is_on_floor() and direction.length() > 0.1 and step_time <= 0:
		if DisplayServer.get_name() != "headless": footstep.play()
		step_time = 0.29 if speed > 3 else 0.45
	if position.y < -20:
		position = Vector3(0, 2, 12)

func _step_up(direction: Vector3) -> void:
	var ahead := position + direction * 0.5
	var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.35, ahead - Vector3.UP * 0.1)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.dot(Vector3.UP) < 0.8: return
	var rise: float = hit.position.y - position.y
	if rise > 0.035 and rise < 0.24:
		var raised := global_transform
		raised.origin.y += rise + 0.01
		if not test_move(global_transform, Vector3.UP * (rise + 0.01)) and not test_move(raised, direction * 0.10):
			position.y += rise + 0.01

func apply_recoil() -> void:
	recoil_impulses+=1
	var amount: float=0.007 if reduced_shake else 0.024
	recoil_offset.x=maxf(-0.055,recoil_offset.x-amount)
	recoil_offset.y=clampf(recoil_offset.y+sin(recoil_impulses*2.4)*amount*0.2,-0.012,0.012)
	if dynamics: dynamics.impact-=visual.global_basis.z*1.5
