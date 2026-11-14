class_name CityNPC
extends HarborGuard

var npc_id: String = ""
var story_actor: bool = false
var route: PackedVector3Array = []
var route_index: int = 0
var path_points: PackedVector3Array = []
var path_index: int = 0
var plan_time: float = 0
var activity_time: float = 0
var danger_time: float = 0
var panic_count: int = 0
var activity: String = "routine"
var threat := Vector3.ZERO
var profile: Dictionary

func _ready() -> void:
	set_meta("protected_story",story_actor)
	set_meta("civilian",NPCCatalog.profile(appearance_id).role not in ["police","faction","security"])
	super._ready()
	profile=NPCCatalog.profile(appearance_id)
	if weapon: weapon.hide()
	if npc_id.is_empty(): npc_id=name
	if dynamics:
		dynamics.clock=abs(hash(npc_id)%31)*0.4
		dynamics.posture_bias=float(profile.posture)
	if route.is_empty(): route=PackedVector3Array([position,position+Vector3(0,0,6)])
	if is_instance_valid(game.events): game.events.incident.connect(_on_incident)
	if game.memory.events.has("npc_absent_"+npc_id) and not story_actor:
		state=State.DEFEATED
		visual.hide()
		collision_layer=0
		collision_mask=0

func can_see_player() -> bool:
	return super.can_see_player() if profile.role in ["police","faction","security"] and suspicion>=1 else false

func _on_incident(event: Dictionary) -> void:
	if state==State.DEFEATED or position.distance_to(event.position)>(16 if event.kind=="defeat" else 32): return
	if event.kind=="defeat":
		var sight:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.4,event.position+Vector3.UP*0.4,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
		if not get_world_3d().direct_space_state.intersect_ray(sight).is_empty():return
	threat=event.position
	if story_actor:
		if dynamics:
			dynamics.has_head_target=true
			dynamics.head_target=threat+Vector3.UP
		return
	if profile.role in ["police","faction","security"] and event.kind in ["gunshot","vehicle_person","defeat"]:
		suspicion=1
		last_seen=game.player.position
		state=State.INVESTIGATE
		if weapon: weapon.show()
		return
	if event.kind in ["gunshot","vehicle_person","crash","glass","defeat"]:
		if danger_time<=0: panic_count+=1
		danger_time=6
		activity="flee"
		plan_time=0

func _physics_process(delta: float) -> void:
	if game.paused or game.cinematic_active: return
	if _update_injury(delta): return
	if profile.role in ["police","faction","security"] and suspicion>=1:
		super._physics_process(delta)
		return
	clock+=delta
	if dynamics:
		dynamics.wind=game.harbor.wind_vector
		dynamics.active=position.distance_to(game.player.position)<55
	if animation: animation.speed_scale=float(profile.animation_rate)
	if story_actor:
		velocity=Vector3(0,velocity.y-delta*24,0)
		move_and_slide()
		_play("Idle")
		return
	danger_time=maxf(0,danger_time-delta)
	activity_time-=delta
	plan_time-=delta
	var target: Vector3=route[route_index]
	var fleeing: bool=danger_time>0
	if fleeing:
		var away: Vector3=(position-threat).normalized()
		target=Vector3(clampf(position.x+away.x*8,-115,115),position.y,clampf(position.z+away.z*8,-205,60))
	else:
		activity="routine"
		if position.distance_to(target)<1.0:
			if activity_time<=0:
				route_index=(route_index+1)%route.size()
				activity_time=4.0 if profile.role in ["work","inspect","repair","trade"] else 1.0
			else:
				velocity=Vector3(0,velocity.y-delta*24,0)
				move_and_slide()
				_play("Interact" if profile.role in ["work","repair","inspect"] else "Idle")
				return
	if plan_time<=0:
		path_points=game.navigation.path(position,target)
		path_index=0
		plan_time=1.4
	var next: Vector3=target
	while path_index<path_points.size() and Vector2(path_points[path_index].x-position.x,path_points[path_index].z-position.z).length()<0.7: path_index+=1
	if path_index<path_points.size(): next=path_points[path_index]
	var direction: Vector3=next-position
	direction.y=0
	direction=direction.normalized()
	var ray:=PhysicsRayQueryParameters3D.create(position+Vector3.UP,position+Vector3.UP+direction*0.8,CollisionLayers.PROP|CollisionLayers.VEHICLE)
	ray.exclude=[get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): direction=Vector3.ZERO
	var speed: float=3.5 if fleeing else float(profile.pace)
	velocity.x=direction.x*speed
	velocity.z=direction.z*speed
	velocity.y-=delta*24
	move_and_slide()
	if direction.length()>0.1:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(direction.x,direction.z),delta*5)
	_play("Run" if fleeing else "Walk")

func take_damage(amount: float, direction: Vector3 = Vector3.ZERO, point: Vector3 = Vector3.ZERO) -> void:
	super.take_damage(amount,direction,point)
	if state==State.DEFEATED and not story_actor: game.memory.remember("npc_absent_"+npc_id,{"district":"iron_harbor","cause":"injury"})
	else:
		danger_time=8
		activity="flee"

func restore_outcome(value: float) -> void:
	if ragdoll:ragdoll.stop()
	health=clampf(value,1 if story_actor else 0,70)
	if health>=70 and injuries: injuries.restore([])
	injury_time=0
	fall_angle=0
	knock_velocity=Vector3.ZERO
	visual.basis=Basis.IDENTITY
	visual.position=Vector3.ZERO
	body_collision.shape.height=1.8
	body_collision.position.y=0.9
	danger_time=0
	suspicion=0
	state=State.PATROL if health>0 else State.DEFEATED
	visual.visible=health>0
	collision_layer=CollisionLayers.NPC if health>0 else 0
	collision_mask=CollisionLayers.SOLIDS if health>0 else 0
	if dynamics:
		dynamics.active=health>0
		dynamics.reset_state()
