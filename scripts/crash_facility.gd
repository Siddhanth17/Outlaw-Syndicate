extends "res://scripts/main.gd"

var wall: StaticBody3D
var scenario: String = "Free driving"
var lab_label: Label

func _ready() -> void:
	super._ready()
	_set_pause(false)
	wall = harbor.solid(Vector3(200, 1.5, 10), Vector3(12, 3, 0.35))
	_box_visual(wall, Vector3(12, 3, 0.35), Color(0.32,0.35,0.36))
	harbor.solid(Vector3(200,-0.5,0), Vector3(90,1,100))
	harbor.surface(Vector3(200,0.01,0), Vector2(90,100), "asphalt", Color.WHITE, 3, 0.6)
	var steel := harbor.solid(Vector3(216,0.7,6), Vector3(8,1.4,0.2))
	_box_visual(steel, Vector3(8,1.4,0.2), Color(0.26,0.32,0.34))
	for x: float in [190,193,196]: harbor.movable_cargo(Vector3(x,0.05,-8))
	var parked := VeyraCar.new()
	parked.position = Vector3(221,1,-10)
	add_child(parked)
	var moving := VeyraCar.new()
	moving.position = Vector3(215,1,-10)
	add_child(moving)
	moving.occupied = false
	var slope := harbor.solid(Vector3(180,0.5,0), Vector3(8,1,12))
	slope.rotation.x = 0.13
	_box_visual(slope, Vector3(8,1,12), Color(0.3,0.31,0.32))
	for x: float in [185,190]:
		var pole := harbor.solid(Vector3(x,1.8,9), Vector3(0.25,3.6,0.25))
		_box_visual(pole, Vector3(0.25,3.6,0.25), Color(0.7,0.45,0.12))
	car.reset_pose(Transform3D(Basis.IDENTITY, Vector3(200,0.9,-5)))
	player.position = Vector3(202,0.1,-6)
	player.yaw = PI
	lab_label = ui.label("", 15)
	lab_label.position = Vector2(28,145)
	lab_label.size.x=1100
	lab_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	lab_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lab_label)

func _box_visual(body: Node3D, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)

func _input(event: InputEvent) -> void:
	if paused or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
			car.repair()
			if not player.driving:
				player.position=car.position
				_interact()
			var x: float = 200 if event.physical_keycode != KEY_2 else 193.4
			var speed: float = 28 if event.physical_keycode == KEY_3 else 13
			car.reset_pose(Transform3D(Basis.IDENTITY, Vector3(x,0.85,-2)), Vector3(0,0,speed))
			scenario = "Controlled front crash: %d m/s" % speed
		KEY_4:
			car.repair()
			scenario = "Repaired"
		KEY_5:
			car.reset_pose(Transform3D(Basis.IDENTITY, Vector3(200,0.9,-5)))
			scenario = "Reset pose; damage retained"

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(lab_label): return
	lab_label.visible = not paused
	var regions: PackedStringArray=[]
	for key: String in car.damage.zones:
		if float(car.damage.zones[key])>0: regions.append("%s %.0f%%"%[key,float(car.damage.zones[key])])
	lab_label.text = "CRASH FACILITY / engineering fixtures\n[E] enter car  [1] front  [2] corner  [3] high speed  [4] repair  [5] reset\n[C] rear view while driving / mouse orbit\n%s\nCondition %.0f%% / dents %d / glass %d panes\n%s" % [scenario, car.integrity, car.damage.hits.size(), car.damage.glass.size(), "Damaged regions: "+("none" if regions.is_empty() else ", ".join(regions))]

func _menu_action(title: String) -> void:
	if title=="Main menu": get_tree().change_scene_to_file("res://scenes/main.tscn")
	else: super._menu_action(title)
