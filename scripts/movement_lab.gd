extends "res://scripts/main.gd"

const MATERIALS: Array[String] = ["asphalt","concrete","warehouse","metal","dirt","grass","wood","interior","stairs"]

func _ready() -> void:
	super._ready()
	build_pads(self)
	call_deferred("begin_lab")

static func build_pads(game: Node3D) -> void:
	for i: int in range(MATERIALS.size()):
		var at:=Vector3(200+i*5,0,10)
		var floor_body: StaticBody3D=game.harbor.solid(at-Vector3.UP*0.5,Vector3(4.8,1,20))
		floor_body.set_meta("foot_surface",MATERIALS[i])
		MovementAudio.region(game.harbor,at+Vector3.UP*0.018,Vector3(4.8,0.025,20),MATERIALS[i])
		var model:=MeshInstance3D.new()
		var plane:=PlaneMesh.new()
		plane.size=Vector2(4.8,20)
		model.mesh=plane
		var material:=StandardMaterial3D.new()
		material.albedo_color=Color.from_hsv(float(i)/MATERIALS.size(),0.22,0.28)
		material.roughness=0.8
		model.material_override=material
		game.harbor.add_child(model)
		model.position=at+Vector3.UP*0.005
		var label:=Label3D.new()
		label.text=MATERIALS[i].to_upper()+"\nACOUSTIC TEST PAD"
		label.position=at+Vector3(0,1.8,-1)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=42
		game.harbor.add_child(label)

func begin_lab() -> void:
	_set_pause(false)
	player.position=Vector3(200,0.1,18)
	player.yaw=0

func _process(delta: float) -> void:
	super._process(delta)
	if not paused:
		ui.objective.text="MOVEMENT AUDIO LAB\nWalk along each labeled pad; jump, sprint and stop."
		ui.status.text="SURFACE: "+player.movement_audio.last_surface.to_upper()+"\nPause > Settings > Movement volume"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or paused: return
	if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_9:
		player.position=Vector3(200+(event.physical_keycode-KEY_1)*5,0.1,18)
		player.velocity=Vector3.ZERO
		player.movement_audio.reset_motion()
