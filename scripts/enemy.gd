class_name HarborGuard
extends CharacterBody3D

enum State { PATROL, SUSPICION, INVESTIGATE, ENGAGE, DEFEATED, STAGGER, KNOCKED_DOWN, RECOVER }
var injuries: InjuryVisuals
var appearance_id: String = "security"
var body_collision: CollisionShape3D
var injury_time: float = 0
var knock_velocity := Vector3.ZERO
var fall_axis:=Vector3.RIGHT
var fall_base:=Basis.IDENTITY
var fall_angle: float = 0
var vehicle_hit_count: int = 0
var last_vehicle_hit: float = -10
var bullet_hit_count: int = 0
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
	if is_instance_valid(game.events): game.events.incident.connect(_hear_event)
	origin = position
	destination = origin + Vector3(3, 0, 4)
	var collider := CollisionShape3D.new()
	body_collision=collider
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collider.position.y = 0.9
	collider.shape = capsule
	add_child(collider)
	visual = NPCCatalog.instantiate(appearance_id)
	add_child(visual)
	injuries=InjuryVisuals.new()
	add_child(injuries)
	injuries.setup(visual)
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		animation = players[0]
		for name: String in animation.get_animation_list():
			if name.ends_with("Walk") or name.ends_with("Run") or name.ends_with("Idle") or name.ends_with("Aim"):
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
	if game.paused or game.cinematic_active: return
	if _update_injury(delta): return
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
				if is_instance_valid(game.events): game.events.publish("gunshot",position,20,"security")
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

func take_damage(amount: float, direction: Vector3 = Vector3.ZERO, point: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEFEATED:
		return
	_choose_fall_direction(direction)
	if injuries: injuries.hit(point if point!=Vector3.ZERO else global_position+Vector3.UP*1.25,amount)
	bullet_hit_count+=1
	health=maxf(1 if get_meta("protected_story",false) else 0,health-amount)
	knock_velocity=direction.limit_length(1)*minf(amount*0.06,2.5)
	if dynamics: dynamics.impact+=direction.limit_length(1)*5
	injury_time=0.35
	reaction=0.35
	suspicion=1
	state=State.STAGGER
	if get_meta("civilian",false): game.memory.remember("civilian_injury_"+name,{"district":"iron_harbor","cause":"combat"})
	else: game.memory.remember("guard_alert_"+name,{"district":"iron_harbor","faction":"rell_security","reputation":-1})
	if health<=0:
		state=State.DEFEATED
		injury_time=1000
		if dynamics: dynamics.active=false
		game.memory.remember("guard_defeated_"+name,{"district":"iron_harbor"})

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

func receive_vehicle_contact(speed: float, direction: Vector3, point: Vector3) -> void:
	var now: float=game.elapsed
	if speed<1.5 or now-last_vehicle_hit<0.9 or state in [State.DEFEATED,State.KNOCKED_DOWN,State.RECOVER]: return
	last_vehicle_hit=now
	_choose_fall_direction(direction)
	if injuries: injuries.hit(point,clampf(speed*2,3,40))
	vehicle_hit_count+=1
	var damage: float=clampf((speed-1.0)*3.0,1,65)
	health=maxf(1 if get_meta("protected_story",false) else 0,health-damage)
	knock_velocity=direction.normalized()*clampf(speed*0.26,0.5,6)
	knock_velocity.y=minf(speed*0.04,0.8)
	injury_time=0.6 if speed<6 else 3.0
	state=State.STAGGER if speed<6 else State.KNOCKED_DOWN
	if health<=0: state=State.DEFEATED
	if dynamics: dynamics.impact+=direction.normalized()*minf(speed,7)
	if is_instance_valid(game.events): game.events.publish("vehicle_person",point,speed,name)
	game.memory.heat=minf(100,game.memory.heat+(8 if speed<6 else 25))
	game.memory.remember("npc_vehicle_injury_"+name,{"severity":speed,"district":"iron_harbor"})

func _can_stand() -> bool:
	var query:=PhysicsShapeQueryParameters3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.33
	capsule.height=1.8
	query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*0.94)
	query.exclude=[get_rid()]
	query.collision_mask=CollisionLayers.SOLIDS
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _update_injury(delta: float) -> bool:
	if state not in [State.STAGGER,State.KNOCKED_DOWN,State.RECOVER,State.DEFEATED]: return false
	injury_time-=delta
	var down: bool=state in [State.KNOCKED_DOWN,State.DEFEATED,State.RECOVER]
	if down:
		if animation: animation.stop()
		if weapon: weapon.hide()
		var capsule: CapsuleShape3D=body_collision.shape
		capsule.height=0.68
		body_collision.position.y=0.34
		if state==State.KNOCKED_DOWN and injury_time<=0 and _can_stand(): state=State.RECOVER
		var target: float=0 if state==State.RECOVER else PI/2
		fall_angle=move_toward(fall_angle,target,delta*2.8)
		var fallen: Basis=Basis(Quaternion(fall_axis,fall_angle))*fall_base
		visual.basis=fallen
		visual.position=Vector3.UP*lerpf(0.9,0.34,sin(fall_angle))-fallen*Vector3.UP*0.9
		if state==State.RECOVER and fall_angle<0.01:
			visual.basis=fall_base
			visual.position=Vector3.ZERO
			capsule.height=1.8
			body_collision.position.y=0.9
			state=State.PATROL
			if dynamics: dynamics.reset_state()
			_play("Idle")
	else:
		if dynamics: dynamics.impact+=knock_velocity*delta*4
		_play("Land")
		if injury_time<=0: state=State.ENGAGE if suspicion>=1 else State.PATROL
	velocity.x=knock_velocity.x
	velocity.z=knock_velocity.z
	velocity.y=clampf(velocity.y-delta*24,-18,1)
	knock_velocity=knock_velocity.move_toward(Vector3.ZERO,delta*5)
	move_and_slide()
	return true

func _choose_fall_direction(direction: Vector3) -> void:
	var push: Vector3=global_basis.inverse()*direction
	push.y=0
	if push.length()<0.1: push=-visual.basis.z
	fall_axis=Vector3(push.z,0,-push.x).normalized()
	fall_base=visual.basis

func _hear_event(event: Dictionary) -> void:
	if event.kind in ["crash","glass"]: hear_crash(event.position,maxf(float(event.severity),3))
	elif event.kind=="gunshot" and state==State.PATROL and position.distance_to(event.position)<28:
		last_seen=event.position
		destination=event.position
		state=State.INVESTIGATE
