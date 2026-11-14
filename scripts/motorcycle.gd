class_name HarborMotorcycle
extends VehicleBody3D

# Assisted upright two-wheel prototype; lean is visual, not free balance dynamics.
var game: Node3D
var rider: ValePlayer
var wheels: Array[VehicleWheel3D] = []
var model: Node3D
var engine: AudioStreamPlayer3D
var mounting: bool = false
var mount_direction: bool = true
var mount_clock: float = 0
var mount_from: Vector3
var dismount_at: Vector3
var lean: float = 0
var contact_cooldown: float = 0
var world_contacts: int = 0
var rider_ik: RiderIK
var handlebar: Node3D

func contact_point(point: String) -> Vector3:
	if point == "seat": return model.to_global(Vector3(0,0.92,-0.25))
	var side: float = 1 if point.begins_with("Left") else -1
	if point.ends_with("Hand"):
		var pivot := Vector3(0,1.17,0.29)
		return model.to_global(pivot+Basis(Vector3.UP,steering)*Vector3(side*0.35,0,0))
	return model.to_global(Vector3(side*0.24,0.46,-0.15))

func _ready() -> void:
	mass=220
	collision_layer=CollisionLayers.VEHICLE
	collision_mask=CollisionLayers.SOLIDS
	continuous_cd=true
	axis_lock_angular_x=true
	axis_lock_angular_z=true
	angular_damp=3
	center_of_mass_mode=RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass=Vector3(0,-0.3,0)
	contact_monitor=true
	max_contacts_reported=8
	var shape:=CollisionShape3D.new()
	var hull:=BoxShape3D.new()
	hull.size=Vector3(0.52,0.65,1.65)
	shape.shape=hull
	shape.position.y=0.1
	add_child(shape)
	model=load("res://assets/vehicles/harrier_bike.glb").instantiate()
	model.position.y=-0.55
	add_child(model)
	handlebar=Node3D.new()
	model.add_child(handlebar)
	handlebar.position=Vector3(0,1.17,0.29)
	for part: Node in model.find_children("*","MeshInstance3D",true,false):
		if str(part.name).begins_with("Grip") or str(part.name).begins_with("Mirror") or str(part.name).begins_with("Handlebar"):
			part.reparent(handlebar,true)
	for z: float in [-0.72,0.72]:
		var wheel:=VehicleWheel3D.new()
		wheel.position=Vector3(0,-0.05,z)
		wheel.wheel_radius=0.32
		wheel.wheel_rest_length=0.18
		wheel.suspension_travel=0.16
		wheel.suspension_stiffness=35
		wheel.damping_compression=3
		wheel.damping_relaxation=4
		wheel.wheel_friction_slip=3.5
		wheel.use_as_steering=z>0
		wheel.use_as_traction=z<0
		add_child(wheel)
		wheel.add_child(load("res://assets/vehicles/harrier_wheel.glb").instantiate())
		wheels.append(wheel)
	engine=AudioStreamPlayer3D.new()
	var stream: AudioStreamWAV=load("res://assets/audio/bike-engine.wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_end=stream.data.size()/2
	engine.stream=stream
	engine.max_distance=35
	engine.volume_db=-35
	add_child(engine)
	if DisplayServer.get_name()!="headless":engine.play()

func outside_point() -> Variant:
	var point:=to_global(Vector3(-1.0,0,0))
	var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point-Vector3.UP*3,CollisionLayers.STATIC)
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.y<0.7:return null
	point.y=hit.position.y+0.05
	var query:=PhysicsShapeQueryParameters3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.32
	capsule.height=1.8
	query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*0.9)
	query.collision_mask=CollisionLayers.SOLIDS
	query.exclude=[get_rid(),game.player.get_rid()]
	return point if get_world_3d().direct_space_state.intersect_shape(query).is_empty() else null

func interact() -> bool:
	if mounting or linear_velocity.length()>2:return false
	var point: Variant=outside_point()
	if point==null:
		game._say("Adrian","Move the bike to a clear space before mounting or dismounting.")
		return false
	mount_direction=rider==null
	rider=game.player
	if not is_instance_valid(rider_ik):
		rider_ik=RiderIK.new()
		rider_ik.bike=self
		rider.dynamics.get_parent().add_child(rider_ik)
	dismount_at=point
	mount_from=rider.global_position
	mount_clock=0
	mounting=true
	rider.transitioning=true
	rider.collision_layer=0
	rider.collision_mask=0
	rider.weapon.hide()
	rider.perform("Ride" if mount_direction else "Exit",2)
	rider.movement_audio.reset_motion()
	freeze=true
	return true

func release() -> void:
	if rider:
		rider.riding_bike=false
		rider.transitioning=false
		rider.velocity=Vector3.ZERO
		rider.collision_layer=CollisionLayers.PLAYER
		rider.collision_mask=CollisionLayers.SOLIDS
		rider.visual.transform=Transform3D.IDENTITY
		rider.arm.remove_excluded_object(get_rid())
		rider.perform("Exit",0.45)
		rider.global_position=dismount_at if dismount_at.is_finite() and dismount_at.length()>0 else global_position+Vector3.LEFT
		rider.reset_physics_interpolation()
	rider=null
	mounting=false
	freeze=false

func _process(delta: float) -> void:
	if not rider or game.paused or game.cinematic_active:return
	if mounting:
		mount_clock+=delta
		var t: float=smoothstep(0,0.9,mount_clock)
		var seat: Vector3=global_position+Vector3.UP*0.1
		rider.global_position=mount_from.lerp(seat if mount_direction else dismount_at,t)
		rider.visual.global_transform=Transform3D(global_basis,rider.global_position-Vector3.UP*0.4)
		if mount_clock>=0.9:
			mounting=false
			rider.transitioning=false
			freeze=false
			if mount_direction:
				rider.riding_bike=true
				rider.perform("Ride",99999)
				rider.arm.add_excluded_object(get_rid())
			else:release()
	elif rider.riding_bike:
		rider.global_position=global_position+Vector3.UP*0.1
		rider.velocity=linear_velocity
		# Match the model's roll axis and origin; IK then seats the pelvis precisely.
		rider.visual.global_transform=model.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0.25,0))

func _physics_process(delta: float) -> void:
	var occupied: bool=rider!=null and rider.riding_bike and not mounting
	var throttle: float=Input.get_axis("back","forward") if occupied else 0
	var speed: float=linear_velocity.dot(global_basis.z)
	engine_force=throttle*780*clampf(1-absf(speed)/32,0.1,1)
	steering=move_toward(steering,Input.get_axis("right","left")*0.48/(1+linear_velocity.length()*0.045) if occupied else 0,delta*1.8)
	brake=18 if not occupied else (38 if Input.is_action_pressed("handbrake") or throttle*speed < -1 else 0)
	lean=lerpf(lean,clampf(-steering*linear_velocity.length()*0.07,-0.40,0.40),1-exp(-delta*6))
	model.rotation.z=lean
	handlebar.rotation.y=steering
	engine.pitch_scale=0.8+minf(1.4,linear_velocity.length()*0.065+absf(throttle)*0.3)
	engine.volume_db=-20 if occupied else -40
	contact_cooldown=maxf(0,contact_cooldown-delta)
	if global_position.y < -15:
		release()
		global_position=Vector3(-5,0.8,10)
		linear_velocity=Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	world_contacts+=state.get_contact_count()
	if contact_cooldown>0:return
	for i: int in range(state.get_contact_count()):
		var actor: Object=state.get_contact_collider_object(i)
		if actor is CharacterBody3D and actor.has_method("receive_vehicle_contact") and linear_velocity.length()>3:
			var normal:=state.get_contact_local_normal(i)
			var closing: float=-(linear_velocity-actor.velocity).dot(normal)
			if closing>1.5:
				actor.call_deferred("receive_vehicle_contact",closing,-normal,state.get_contact_local_position(i))
				contact_cooldown=0.9
