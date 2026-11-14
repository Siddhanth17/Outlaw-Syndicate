class_name VehicleTransition
extends Node

var game: Node3D
var active: bool = false
var entering: bool = true
var clock: float = 0
var force_animation: bool = false
var start: Vector3
var outside: Vector3
var phase: String = ""

func clear_outside() -> Variant:
	var car: VeyraCar = game.car
	var point: Vector3 = car.to_global(Vector3(-1.65,-0.74,0.35))
	var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.5,point-Vector3.UP*2,CollisionLayers.STATIC)
	var ground:=game.get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty() or ground.normal.y<0.7:return null
	point.y=ground.position.y+0.05
	var query:=PhysicsShapeQueryParameters3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.radius=0.34
	capsule.height=1.8
	query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*0.9)
	query.collision_mask=CollisionLayers.SOLIDS
	query.exclude=[car.get_rid(),game.player.get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty():return null
	# Door sweep envelope is deliberately conservative; reject blocked approaches.
	var sweep:=BoxShape3D.new()
	sweep.size=Vector3(1.2,1.3,1.5)
	query.shape=sweep
	query.transform=car.global_transform*Transform3D(Basis.IDENTITY,Vector3(-1.32,0.08,0.25))
	if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty():return null
	return point

func begin(wants_entry: bool) -> bool:
	if active or game.car.linear_velocity.length()>1.5:return false
	var destination: Variant=clear_outside()
	if destination==null:
		game._say("Adrian","The driver door is blocked. Move to a clear space.")
		return false
	entering=wants_entry
	outside=destination
	start=game.player.global_position
	clock=0
	active=true
	game.player.transitioning=true
	game.player.velocity=Vector3.ZERO
	game.player.collision_layer=0
	game.player.collision_mask=0
	game.player.weapon.hide()
	game.player.movement_audio.reset_motion()
	game.player.perform("Enter" if entering else "Exit",3.0)
	game.car.occupied=false
	game.car.freeze=true
	return true

func _process(delta: float) -> void:
	if not active or game.paused:return
	clock+=delta
	var t: float=clampf(clock/2.8,0,1)
	var player: ValePlayer=game.player
	var car: VeyraCar=game.car
	var seat: Vector3=car.to_global(Vector3(-0.38,-0.8,0))
	var progress: float=t if entering else 1-t
	var align: float=smoothstep(0,0.18,t)
	var sit: float=smoothstep(0.36,0.77,progress)
	phase="align" if t<0.18 else ("reach/open" if t<0.36 else ("seat transition" if t<0.77 else "close/settle"))
	var angle: float=sin(smoothstep(0.13,0.93,t)*PI)*1.18
	car.set_driver_door(angle)
	var standing: Vector3=start.lerp(outside,align) if entering else outside
	player.global_position=standing.lerp(seat,sit)
	var facing:=car.global_basis*Basis(Vector3.UP,PI/2*(1-sit))
	player.visual.global_transform=Transform3D(facing,player.global_position)
	if entering and progress>0.59 and player.action_name!="Drive":player.perform("Drive",99999)
	if t>=1:
		active=false
		player.transitioning=false
		car.set_driver_door(0)
		car.freeze=false
		if entering:
			game._enter_car_immediate()
		else:
			game._leave_car(true)
			player.global_position=outside
			player.reset_physics_interpolation()

func cancel() -> void:
	if not active:return
	active=false
	game.player.transitioning=false
	game.car.set_driver_door(0)
	game.car.freeze=game.paused
	game.player.collision_layer=CollisionLayers.PLAYER
	game.player.collision_mask=CollisionLayers.SOLIDS
	game.player.visual.transform=Transform3D.IDENTITY
