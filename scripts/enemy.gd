class_name HarborGuard
extends CharacterBody3D

enum State { PATROL, SUSPICION, INVESTIGATE, ENGAGE, DEFEATED }
var crash_reactions: int = 0
var state: State = State.PATROL
var health: float = 70
var suspicion: float = 0
var game: Node3D
var origin := Vector3.ZERO
var destination := Vector3.ZERO
var clock: float = 0
var shot_timer: float = 0
var visual: Node3D
var animation: AnimationPlayer
var last_seen := Vector3.ZERO
var reaction: float = 0
var weapon: Node3D
var dynamics: HumanDynamics

func _ready() -> void:
	collision_layer = CollisionLayers.NPC
	collision_mask = CollisionLayers.SOLIDS
	origin = position
	destination = origin + Vector3(3, 0, 4)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collider.position.y = 0.9
	collider.shape = capsule
	add_child(collider)
	visual = load("res://assets/characters/adrian.glb").instantiate()
	add_child(visual)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		animation = players[0]
		for name: String in animation.get_animation_list():
			if name.ends_with("Walk") or name.ends_with("Idle") or name.ends_with("Aim"):
				animation.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	var skeletons := visual.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		dynamics = HumanDynamics.new()
		dynamics.actor = self
		skeletons[0].add_child(dynamics)
		dynamics.reset_state()
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = "RightHand"
		skeletons[0].add_child(attachment)
		weapon = load("res://assets/vehicles/sidearm.glb").instantiate()
		attachment.add_child(weapon)
		weapon.scale = Vector3.ONE * 100
		weapon.position = Vector3(0, 7, 0)

func can_see_player() -> bool:
	var target: ValePlayer = game.player
	var offset: Vector3 = target.global_position - global_position
	if offset.length() > (42 if game.faction_rep < -3 else 35):
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.4, target.global_position + Vector3.UP)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and (hit.collider == target or hit.collider == game.car and target.driving)

func _physics_process(delta: float) -> void:
	if game.paused or game.cinematic_active or state == State.DEFEATED:
		return
	clock += delta
	if dynamics: dynamics.wind = game.harbor.wind_vector
	if is_instance_valid(weapon): weapon.global_basis = Basis(Vector3.UP, visual.global_rotation.y)
	shot_timer -= delta
	reaction -= delta
	if can_see_player():
		last_seen = game.player.position
		suspicion = minf(1, suspicion + delta * (1.2 if game.faction_rep < -3 else 0.7))
		state = State.ENGAGE if suspicion >= 1 else State.SUSPICION
	elif state in [State.ENGAGE, State.SUSPICION]:
		state = State.INVESTIGATE
		destination = last_seen
	match state:
		State.PATROL:
			if position.distance_to(destination) < 1:
				destination = origin + Vector3(sin(clock) * 4, 0, cos(clock) * 4)
		State.SUSPICION: destination = position
		State.ENGAGE:
			var distance: float = position.distance_to(game.player.position)
			var offset: Vector3 = game.player.position - position
			visual.rotation.y = atan2(offset.x, offset.z)
			destination = game.player.position if distance > 12 else position
			if shot_timer <= 0 and reaction <= 0 and distance < 27:
				game.damage_player(8, (game.player.position - position).normalized())
				game.sound("shot", position)
				shot_timer = 1.25
		State.INVESTIGATE:
			if position.distance_to(destination) < 1:
				suspicion = maxf(0, suspicion - delta * 0.3)
				if suspicion <= 0:
					state = State.PATROL
	var direction := (destination - position)
	direction.y = 0
	if direction.length() > 0.7 and reaction <= 0:
		direction = direction.normalized()
		velocity.x = direction.x * 2.3
		velocity.z = direction.z * 2.3
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta * 6)
		_play("Walk")
	else:
		velocity.x = 0
		velocity.z = 0
		_play("Aim" if state == State.ENGAGE else "Idle")
	velocity.y -= delta * 24
	move_and_slide()

func _play(clip: String) -> void:
	if not animation:
		return
	for name: String in animation.get_animation_list():
		if name.ends_with(clip) and animation.current_animation != name:
			animation.play(name, 0.15)

func take_damage(amount: float) -> void:
	if state == State.DEFEATED:
		return
	health -= amount
	if dynamics: dynamics.impact += Vector3.FORWARD * minf(amount * 0.1, 6)
	reaction = 0.3
	suspicion = 1
	state = State.ENGAGE
	game.memory.remember("guard_alert_" + name, {"district": "iron_harbor", "faction": "rell_security", "reputation": -1})
	if health <= 0:
		state = State.DEFEATED
		if dynamics: dynamics.active = false
		collision_layer = 0
		collision_mask = 0
		if animation: animation.stop()
		var tween := create_tween()
		tween.tween_property(visual, "rotation:z", PI / 2, 0.35)
		game.memory.remember("guard_defeated_" + name, {"district": "iron_harbor"})

func hear_crash(at: Vector3, speed: float) -> void:
	if state==State.DEFEATED or position.distance_to(at)>24 or speed<3: return
	crash_reactions+=1
	last_seen=at
	destination=at
	reaction=0.5
	if state!=State.ENGAGE: state=State.INVESTIGATE
	if dynamics:
		dynamics.has_head_target=true
		dynamics.head_target=at+Vector3.UP
