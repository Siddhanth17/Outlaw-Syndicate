class_name StreetTraffic
extends Node3D

# Two persistent, force-driven demonstration cars. No teleport recovery/despawning.
# Left-hand lane circuit, separated from owned vehicles and mission state.
var game: Node3D
var cars: Array[VeyraCar]=[]
var targets: Array[int]=[1,3]
var route: Array[Vector3]=[Vector3(-67,0,70),Vector3(-67,0,215),Vector3(69,0,215),Vector3(69,0,61)]
var reasons: Array[String]=["starting","starting"]
var elapsed: float=0
var enabled: bool=true
var signals: Array[Dictionary]=[]

func green(north_south: bool) -> bool:
	var phase: float=fposmod(elapsed,28)
	return phase<11 if north_south else phase>=14 and phase<25

func _ready() -> void:
	for i: int in range(2):
		var car:=VeyraCar.new()
		car.autonomous=true
		car.position=Vector3(-67,.9,88) if i==0 else Vector3(69,.9,190)
		car.rotation.y=0 if i==0 else PI
		add_child(car)
		cars.append(car)
	for x: float in VeyraQuarter.XS:
		for z: float in VeyraQuarter.ZS:
			for axis: int in range(2):
				var head: Node3D=load("res://assets/environment/urban_signal.glb").instantiate()
				head.position=Vector3(x+8+axis,.14,z+8-axis)
				head.rotation.y=axis*PI/2
				add_child(head)
				for part: Node in head.find_children("*","MeshInstance3D",true,false):
					for surface: int in range(part.mesh.get_surface_count()):
						var source: Material=part.get_active_material(surface)
						if source is StandardMaterial3D and (source.resource_name=="Signal red" or source.resource_name=="Signal green" or source.resource_name=="Signal amber"):
							var mat: StandardMaterial3D=source.duplicate()
							part.set_surface_override_material(surface,mat)
							signals.append({"material":mat,"color":source.albedo_color,"axis":axis==0,"kind":source.resource_name})

func obstacle(car: VeyraCar) -> bool:
	var speed: float=car.linear_velocity.length()
	for offset: float in [-.65,0,.65]:
		var start:=car.to_global(Vector3(offset,0,2.2))
		var ray:=PhysicsRayQueryParameters3D.create(start,start+car.global_basis.z*(4+speed*.9),CollisionLayers.SOLIDS)
		ray.exclude=[car.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return true
	return false

func _physics_process(delta: float) -> void:
	var stopped: bool=game.paused or game.cinematic_active or not enabled
	for car: VeyraCar in cars:
		car.freeze=stopped
		car.set_physics_process(not stopped)
	if stopped:return
	elapsed+=delta
	var phase: float=fposmod(elapsed,28)
	for lens: Dictionary in signals:
		var amber: bool=(phase>=11 and phase<12) if lens.axis else (phase>=25 and phase<26)
		var active: bool=green(lens.axis) if lens.kind=="Signal green" else (amber if lens.kind=="Signal amber" else not green(lens.axis) and not amber)
		lens.material.albedo_color=lens.color if active else Color(.018,.022,.025)
		lens.material.emission_enabled=active
	for i: int in range(cars.size()):
		var car:=cars[i]
		var point:=route[targets[i]]
		var offset:=point-car.position
		offset.y=0
		if offset.length()<7:
			targets[i]=(targets[i]+1)%route.size()
			offset=route[targets[i]]-car.position
			offset.y=0
		var angle:=angle_difference(car.rotation.y,atan2(offset.x,offset.z))
		car.ai_steer=clampf(angle*.85,-.38,.38)
		var speed: float=car.linear_velocity.length()
		var desired_speed: float=3.2 if absf(angle)>.35 else 7
		var waiting: bool=false
		var north_south: bool=absf(car.global_basis.z.z)>.7
		for x: float in VeyraQuarter.XS:
			for z: float in VeyraQuarter.ZS:
				var ahead:=car.to_local(Vector3(x,car.position.y,z))
				if ahead.z>9 and ahead.z<16+speed and absf(ahead.x)<5 and not green(north_south):waiting=true
		var blocked:=obstacle(car)
		reasons[i]="obstacle" if blocked else ("signal" if waiting else "driving")
		car.ai_throttle=0 if blocked or waiting or speed>desired_speed else .55
		car.ai_brake=50 if blocked or waiting else (12 if speed>desired_speed+1 else 0)
