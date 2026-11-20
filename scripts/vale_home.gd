class_name ValeHome
extends Node3D
const ADDRESS:=Vector3(-119,.14,80)
var game: Node3D
var door: Node3D
var door_open: bool=false
var door_busy: bool=false
var outfit: int=0
var storage: Dictionary={"coffee":0,"sandwich":0}
var finishes: Array[Dictionary]=[]
var door_tween: Tween
var spots: Dictionary={"door":Vector3(0,.1,5),"rest":Vector3(-3.5,.1,-.6),"save":Vector3(-3.5,.1,3.9),"wardrobe":Vector3(-4.85,.1,-4),"storage":Vector3(-5.25,.1,2.65),"documents":Vector3(3.4,.1,.7)}
func spawn_point() -> Vector3:return ADDRESS+Vector3(-3,.12,2.5)
func solid(at: Vector3,size: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new()
	body.collision_layer=CollisionLayers.STATIC
	body.set_meta("foot_surface","interior")
	add_child(body);body.position=at
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;shape.shape=box;body.add_child(shape)
	return body
func _ready() -> void:
	position=ADDRESS
	add_child(load("res://assets/environment/vale_home_shell.glb").instantiate())
	add_child(load("res://assets/environment/vale_home_furniture.glb").instantiate())
	for spec: Array in [[Vector3(0,-.08,0),Vector3(12,.16,10)],[Vector3(0,3.2,0),Vector3(12,.18,10)],[Vector3(-6,1.55,0),Vector3(.22,3.1,10)],[Vector3(6,1.55,0),Vector3(.22,3.1,10)],[Vector3(0,1.55,-5),Vector3(12,3.1,.22)],[Vector3(-3.55,1.55,5),Vector3(4.9,3.1,.22)],[Vector3(3.55,1.55,5),Vector3(4.9,3.1,.22)],[Vector3(-.8,1.5,-2.5),Vector3(.15,3,5)],[Vector3(-.8,1.5,4),Vector3(.15,3,2)],[Vector3(4.15,1.5,-2.2),Vector3(3.7,3,.12)],[Vector3(.45,1.5,-2.2),Vector3(.9,3,.12)],[Vector3(.9,1.5,-3.6),Vector3(.12,3,2.7)],[Vector3(-3.5,.42,-.6),Vector3(2.25,.84,2.35)],[Vector3(-4.85,1.1,-4.42),Vector3(1.8,2.2,.65)],[Vector3(-3.5,.38,3.9),Vector3(2.5,.76,.85)],[Vector3(-5.25,.35,2.65),Vector3(.85,.7,1.1)],[Vector3(3.6,.6,2.5),Vector3(3,.95,1.15)],[Vector3(3.4,.25,.7),Vector3(2.1,.5,.85)],[Vector3(3.85,.5,-1.48),Vector3(3.75,1,1.2)],[Vector3(4.6,.6,-4),Vector3(.8,1.2,1.1)],[Vector3(2.1,.5,-4.2),Vector3(1.2,1,.8)]]:solid(spec[0],spec[1])
	door=Node3D.new();add_child(door);door.position=Vector3(-.98,0,5)
	door.add_child(load("res://assets/environment/vale_home_door.glb").instantiate())
	var door_body:=solid(Vector3.ZERO,Vector3(1.96,2.6,.12))
	door_body.reparent(door,false);door_body.position=Vector3(.98,1.3,0)
	for at: Vector3 in [Vector3(-3,2.65,0),Vector3(3,2.65,1),Vector3(3,2.65,-3.5)]:
		var light:=OmniLight3D.new();light.position=at;light.light_color=Color(1,.78,.51);light.light_energy=1.4;light.omni_range=7
		light.shadow_enabled=at.x<0
		light.distance_fade_enabled=true;light.distance_fade_begin=25;light.distance_fade_length=10
		add_child(light)
	for x: float in [-5.1,-1.9]:solid(Vector3(x,.34,-1.5),Vector3(.62,.68,.64))
	for at: Vector3 in [Vector3(5.3,.25,4.15),Vector3(-5.3,.25,4.2)]:solid(at,Vector3(.48,.5,.48))
	var sign:=Label3D.new();sign.text="18 / VALE";sign.position=Vector3(1.5,1.7,5.15);sign.font_size=32;sign.pixel_size=.006;add_child(sign)
	MovementAudio.region(self,Vector3(0,.04,0),Vector3(11.8,.03,9.8),"wood")
func target() -> String:
	if game.player.driving or game.player.riding_bike:return ""
	var nearest: String="";var distance: float=2.1
	for key: String in spots:
		var offset: Vector3=game.player.position-to_global(spots[key]);offset.y=0
		if offset.length()<distance:nearest=key;distance=offset.length()
	return nearest
func toggle_door() -> bool:
	if door_busy:return false
	if door_open:
		var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2.1,2.5,.65);query.shape=shape
		query.transform=Transform3D(Basis.IDENTITY,to_global(Vector3(0,1.3,5)))
		query.collision_mask=CollisionLayers.PLAYER|CollisionLayers.NPC|CollisionLayers.VEHICLE|CollisionLayers.PROP
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
			game._say("Home","Clear the doorway before closing it.");return false
	door_open=not door_open;door_busy=true
	door_tween=create_tween();door_tween.tween_property(door,"rotation:y",-PI/2 if door_open else 0,.55)
	door_tween.finished.connect(func() -> void:door_busy=false)
	return true
func interact() -> bool:
	var key:=target()
	if key.is_empty():return false
	if key=="door":toggle_door();return true
	if not game.phone.opened:game.phone.toggle()
	game.phone.clear("18 / VALE RESIDENCE")
	match key:
		"rest":game.phone.note("Your bedroom. Rest restores health and advances eight hours.");game.phone.button("Rest • eight hours",rest)
		"save":game.phone.note("Personal desk / checkpoint.");game.phone.button("Save checkpoint",func() -> void:game._save();game.phone.note("Checkpoint saved."))
		"wardrobe":game.phone.note("Two owned jacket finishes.");game.phone.button("Charcoal leather",set_outfit.bind(0));game.phone.button("Weathered brown leather",set_outfit.bind(1))
		"storage":storage_menu();return true
		"documents":game.phone.note("Mara's envelope\n\nDo not lose this address. Wait until you know who you can trust.\n\nAdrian's keys and old harbor paperwork. The Last Address remains optional in Messages.")
	game.phone.button("Property information",info)
	game.phone.button("Close",game.phone.close)
	return true
func rest() -> void:
	var time: float=game.quarter.minutes+480
	game.quarter.day+=int(time/1440);game.quarter.minutes=fposmod(time,1440);game.quarter.apply_clock()
	game.player.health=100
	game.phone.close();game._say("Home","Rested. Eight hours have passed.")
func set_outfit(value: int) -> void:
	outfit=clampi(value,0,1)
	if finishes.is_empty():
		for node: Node in game.player.visual.find_children("*","MeshInstance3D",true,false):
			for i: int in range(node.mesh.get_surface_count()):
				var source: Material=node.mesh.surface_get_material(i)
				if source is StandardMaterial3D and source.resource_name.contains("grained charcoal leather"):
					var active: Material=node.get_active_material(i)
					if active is StandardMaterial3D:
						active=active.duplicate();node.set_surface_override_material(i,active)
					finishes.append({"material":active,"base":source.albedo_color})
	for record: Dictionary in finishes:
		var color: Color=record.base if outfit==0 else Color(.4,.19,.075)
		if record.material is ShaderMaterial:record.material.set_shader_parameter("tint",color)
		elif record.material is StandardMaterial3D:record.material.albedo_color=color
func storage_menu() -> void:
	game.phone.clear("HOME / STORAGE")
	for item: String in ["coffee","sandwich"]:
		game.phone.note("%s • stored %d / carried %d"%[item.capitalize(),storage[item],game.living.inventory.get(item,0)])
		game.phone.button("Store one "+item,transfer_item.bind(item,true))
		game.phone.button("Take one "+item,transfer_item.bind(item,false))
	game.phone.button("Close",game.phone.close)
func transfer_item(item: String,deposit: bool) -> void:
	if not storage.has(item):return
	var carried: int=game.living.inventory.get(item,0)
	if deposit and carried>0 and storage[item]<20:storage[item]+=1;game.living.inventory[item]=carried-1
	elif not deposit and storage[item]>0 and carried<20:storage[item]-=1;game.living.inventory[item]=carried+1
	if game.phone.opened:storage_menu()
func info() -> void:
	game.phone.clear("PROPERTY / 18 VALE")
	game.phone.note("Adrian Vale • starting residence\nWest Northline • owned\nBedroom, living room, kitchen, bathroom\nWardrobe, item storage and checkpoint desk\n\nSable GT and Harrier are at Cross Motor Works in Iron Harbor.")
	game.phone.button("Close",game.phone.close)
func snapshot() -> Dictionary:return {"version":1,"outfit":outfit,"storage":storage.duplicate(),"door_open":door_open}
func validate(value: Variant) -> bool:
	if value==null:return true
	if not value is Dictionary or value.get("version")!=1 or not value.get("door_open") is bool or not value.get("storage") is Dictionary:return false
	var selected: Variant=value.get("outfit")
	if not (selected is int or selected is float) or not is_finite(float(selected)) or float(selected)!=floor(float(selected)) or selected<0 or selected>1:return false
	for item: Variant in value.storage:
		var count: Variant=value.storage[item]
		if not item in ["coffee","sandwich"] or not (count is int or count is float) or not is_finite(float(count)) or float(count)!=floor(float(count)) or count<0 or count>20:return false
	return true
func restore(value: Variant) -> void:
	if door_tween:door_tween.kill()
	door_busy=false
	storage={"coffee":0,"sandwich":0};set_outfit(0);door_open=false
	if value is Dictionary:
		set_outfit(int(value.outfit));storage.merge(value.storage,true);door_open=value.door_open
	door.rotation.y=-PI/2 if door_open else 0
func repair_saved_location() -> void:
	var p: Vector3=game.player.position-ADDRESS
	if absf(p.x)>6.5 or absf(p.z)>5.5 or game.player.driving:return
	var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.31;capsule.height=1.75;query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,game.player.position+Vector3.UP*.92);query.collision_mask=CollisionLayers.STATIC|CollisionLayers.PROP
	if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():game.player.position=spawn_point();game.player.velocity=Vector3.ZERO
