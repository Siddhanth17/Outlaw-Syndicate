class_name CharacterImpacts
extends Node3D

# Small restrained flecks and soft marks. Fixed pools; no anatomical gore.
var bursts: Array[GPUParticles3D]=[]
var marks: Array[Decal]=[]
var sounds: Array[AudioStreamPlayer3D]=[]
var cursor: int=0
var density: float=0.6

func _ready() -> void:
	var texture:=GradientTexture2D.new()
	var gradient:=Gradient.new()
	gradient.set_color(0,Color(0.23,0.025,0.02,0.45))
	gradient.set_color(1,Color(0.23,0.025,0.02,0))
	texture.gradient=gradient
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(0.95,0.95)
	for i: int in range(12):
		var burst:=GPUParticles3D.new()
		burst.amount=8
		burst.lifetime=0.28
		burst.one_shot=true
		burst.explosiveness=1
		burst.emitting=false
		var mesh:=SphereMesh.new()
		mesh.radius=0.009
		mesh.height=0.018
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(0.25,0.025,0.02)
		material.roughness=0.9
		mesh.material=material
		burst.draw_pass_1=mesh
		var process:=ParticleProcessMaterial.new()
		process.gravity=Vector3(0,-8,0)
		process.initial_velocity_min=0.4
		process.initial_velocity_max=1.1
		process.spread=30
		burst.process_material=process
		add_child(burst)
		bursts.append(burst)
		var mark:=Decal.new()
		mark.texture_albedo=texture
		mark.size=Vector3(0.17,0.10,0.17)
		mark.visible=false
		add_child(mark)
		marks.append(mark)
		var sound:=AudioStreamPlayer3D.new()
		sound.stream=load("res://assets/audio/movement/cloth_%02d.wav"%(i%4))
		sound.volume_db=-14
		sound.max_distance=24
		add_child(sound)
		sounds.append(sound)

func hit(at: Vector3, direction: Vector3, severity: float) -> void:
	if density<=0 or not at.is_finite():return
	var index:=cursor%bursts.size()
	cursor+=1
	var burst:=bursts[index]
	burst.global_position=at
	(burst.process_material as ParticleProcessMaterial).direction=direction.limit_length(1) if direction.length()>0.1 else Vector3.UP
	burst.amount_ratio=density
	if DisplayServer.get_name()!="headless":
		burst.emitting=true
		burst.restart()
	sounds[index].global_position=at
	if DisplayServer.get_name()!="headless":sounds[index].play()
	if severity>=20:
		var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*2,CollisionLayers.STATIC)
		var ground:=get_world_3d().direct_space_state.intersect_ray(ray)
		if not ground.is_empty() and ground.normal.y>0.6:
			marks[index].global_position=ground.position+Vector3.UP*0.03
			marks[index].visible=true

func reset() -> void:
	cursor=0
	for burst: GPUParticles3D in bursts:burst.emitting=false
	for mark: Decal in marks:mark.hide()
	for sound: AudioStreamPlayer3D in sounds:sound.stop()
