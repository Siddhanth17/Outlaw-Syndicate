class_name CharacterImpacts
extends Node3D

# Bounded ballistic droplets and contact-projected stains; visual approximation, no fluid solver.
var bursts: Array[GPUParticles3D]=[]
var marks: Array[Decal]=[]
var sounds: Array[AudioStreamPlayer3D]=[]
var cursor: int=0
var density: float=0.6
var drops: Array[Dictionary]=[]
var droplets: MultiMeshInstance3D
var stain_age: Array[float]=[]
var stain_cursor: int=0
var collision_contacts: int=0

func _ready() -> void:
	var texture:=GradientTexture2D.new()
	var gradient:=Gradient.new()
	gradient.set_color(0,Color(0.23,0.025,0.02,0.45))
	gradient.set_color(1,Color(0.23,0.025,0.02,0))
	texture.gradient=gradient
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(0.95,0.95)
	var image:=Image.create(64,64,false,Image.FORMAT_RGBA8)
	for x: int in range(64):
		for y: int in range(64):
			var uv:=Vector2(x/63.0-.5,y/63.0-.5)
			var angle: float=atan2(uv.y,uv.x)
			var radius: float=.28+.045*sin(angle*5)+.035*cos(angle*9)
			var alpha: float=1-smoothstep(radius-.025,radius+.025,uv.length())
			image.set_pixel(x,y,Color(.16,.009,.006,alpha*.8))
	var stain_texture:=ImageTexture.create_from_image(image)
	droplets=MultiMeshInstance3D.new();add_child(droplets)
	var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var drop_mesh:=SphereMesh.new();drop_mesh.radius=1;drop_mesh.height=2;drop_mesh.radial_segments=8;drop_mesh.rings=4
	var drop_material:=StandardMaterial3D.new();drop_material.albedo_color=Color(.16,.008,.006);drop_material.roughness=.18
	drop_mesh.material=drop_material;multimesh.mesh=drop_mesh;multimesh.instance_count=72;droplets.multimesh=multimesh
	for i: int in range(72):
		drops.append({"p":Vector3.ZERO,"v":Vector3.ZERO,"life":0.0})
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	for i: int in range(12):
		var burst:=GPUParticles3D.new()
		burst.amount=8
		burst.lifetime=0.12
		burst.one_shot=true
		burst.explosiveness=1
		burst.emitting=false
		var mesh:=SphereMesh.new()
		mesh.radius=0.009
		mesh.height=0.018
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color(0.25,0.025,0.02)
		material.roughness=0.22
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
		mark.texture_albedo=stain_texture
		mark.size=Vector3(0.17,0.10,0.17)
		mark.visible=false
		add_child(mark)
		marks.append(mark)
		stain_age.append(0.0)
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
	var game: Node3D=get_parent()
	if at.distance_to(game.player.position)>55:return
	for j: int in range(6):
		var slot: int=(index*6+j)%drops.size()
		var jitter:=Vector3(sin(cursor*2.3+j*1.7),.4+float(j%3)*.15,cos(cursor*.7+j*2.1))
		var velocity: Vector3=direction.limit_length(1)*(1.0+float(j%3)*.25)+jitter*.65
		drops[slot]={"p":at,"v":velocity,"life":.85}

func _physics_process(delta: float) -> void:
	if get_parent().paused:return
	for i: int in range(drops.size()):
		var drop: Dictionary=drops[i]
		if drop.life<=0:continue
		var before: Vector3=drop.p
		drop.v+=Vector3.DOWN*9.8*delta
		var after: Vector3=before+drop.v*delta
		var query:=PhysicsRayQueryParameters3D.create(before,after,CollisionLayers.STATIC|CollisionLayers.PROP)
		var contact: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
		drop.life-=delta
		if not contact.is_empty():
			stamp(contact.position,contact.normal);drop.life=0;collision_contacts+=1
		drop.p=after
		var transform:=Transform3D(Basis.IDENTITY,after)
		if drop.life<=0:transform.basis=Basis.IDENTITY.scaled(Vector3.ZERO)
		else:
			var direction: Vector3=drop.v.normalized()
			transform.basis=Basis(Quaternion(Vector3.UP,direction)).scaled(Vector3(.012,.025,.012))
		droplets.multimesh.set_instance_transform(i,transform)
	for i: int in range(marks.size()):
		if not marks[i].visible:continue
		stain_age[i]+=delta
		marks[i].modulate.a=clampf((45-stain_age[i])/10,0,1)
		if stain_age[i]>=45:marks[i].hide()

func stamp(at: Vector3,normal: Vector3) -> void:
	var index: int=stain_cursor%marks.size();stain_cursor+=1
	var mark:=marks[index]
	mark.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,normal.normalized())),at+normal*.12)
	mark.size=Vector3(.18+float(index%4)*.035,.4,.22+float(index%3)*.04)
	mark.modulate=Color(.72,.6,.57,1);mark.show();stain_age[index]=0

func reset() -> void:
	cursor=0
	stain_cursor=0;collision_contacts=0
	for i: int in range(drops.size()):
		drops[i].life=0
		droplets.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
	for burst: GPUParticles3D in bursts:burst.emitting=false
	for mark: Decal in marks:mark.hide()
	for sound: AudioStreamPlayer3D in sounds:sound.stop()
