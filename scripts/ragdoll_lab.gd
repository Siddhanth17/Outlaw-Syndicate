class_name RagdollLaboratory
extends "res://scripts/main.gd"

var subjects: Array[CityNPC]=[]
var label: Label
var fixtures: Array[Node3D]=[]

func _ready() -> void:
	super._ready()
	build_ground(self)
	var layer:=CanvasLayer.new()
	add_child(layer)
	label=Label.new()
	label.position=Vector2(30,220)
	label.add_theme_font_size_override("font_size",17)
	layer.add_child(label)
	call_deferred("begin")

static func build_ground(game: Node3D) -> void:
	game.harbor.solid(Vector3(200,-0.5,0),Vector3(55,1,35))
	game.harbor.surface(Vector3(200,0.003,0),Vector2(55,35),"asphalt",Color(0.65,0.66,0.68),3,0.75)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-35,0)
	sun.light_energy=1.2
	sun.shadow_enabled=true
	game.add_child(sun)

func begin() -> void:
	_set_pause(false)
	player.position=Vector3(203,0.1,6)
	player.yaw=0.5
	spawn_case(1)

func spawn_case(number: int) -> void:
	for body: CityNPC in subjects:
		if is_instance_valid(body):body.queue_free()
	for fixture: Node3D in fixtures:
		if is_instance_valid(fixture):fixture.queue_free()
	subjects.clear()
	fixtures.clear()
	var at:=Vector3(200,0.05,0)
	var direction:=Vector3(0,0,1)
	if number==2:direction=Vector3.RIGHT
	if number==4:
		fixtures.append(harbor.solid(Vector3(200,1.4,2),Vector3(6,2.8,0.3)))
		var wall:=MeshInstance3D.new()
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(6,2.8,0.3)
		wall.mesh=mesh
		wall.position=Vector3(200,1.4,2)
		add_child(wall)
		fixtures.append(wall)
	if number==5:
		for i: int in range(6):
			var center:=Vector3(200,(i+1)*0.09,0.4+i*0.45)
			fixtures.append(harbor.solid(center,Vector3(5,(i+1)*0.18,0.45)))
			var tread:=MeshInstance3D.new()
			var mesh:=BoxMesh.new()
			mesh.size=Vector3(5,(i+1)*0.18,0.45)
			tread.mesh=mesh
			tread.position=center
			add_child(tread)
			fixtures.append(tread)
		at=Vector3(200,1.15,2.6)
		direction=Vector3(0,0,-1)
	var npc:=CityNPC.new()
	npc.game=self
	npc.npc_id="LaboratorySubject"
	npc.appearance_id="security"
	npc.position=at
	npc.route=PackedVector3Array([at,at+Vector3(0,0,5)]) if number==3 else PackedVector3Array([at])
	add_child(npc)
	subjects.append(npc)
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(npc):npc.take_damage(80,direction,npc.global_position+Vector3.UP*1.25)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not paused:
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_5:spawn_case(event.physical_keycode-KEY_1+1)

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(label):
		label.visible=not paused
		label.text="ARTICULATED PHYSICS LAB\n1 frontal / 2 side / 3 running / 4 wall / 5 stairs\nEngineering fixtures, not finished district art. Normal movement, look and weapon controls apply."
		if not subjects.is_empty() and is_instance_valid(subjects[0]) and subjects[0].ragdoll.active:
			var rag:=subjects[0].ragdoll
			label.text+="\n13 segments / joint separation %.3f m / settled %s"%[rag.joint_gap(),str(rag.settled)]
