class_name VeyraStation
extends Node3D
const ADDRESS:=Vector3(-119,.14,160)
const PROCESS_POINT:=Vector3(-119,.142,163.4)
const HOLD_POINT:=Vector3(-115,.142,156.8)
const RELEASE_POINT:=Vector3(-119,.15,167)
func solid(at: Vector3,size: Vector3) -> void:
	var body:=StaticBody3D.new();body.collision_layer=CollisionLayers.STATIC;body.set_meta("foot_surface","interior");add_child(body);body.position=at
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;shape.shape=box;body.add_child(shape)
func _ready() -> void:
	position=ADDRESS
	add_child(load("res://assets/environment/veyra_station_shell.glb").instantiate())
	add_child(load("res://assets/environment/veyra_station_equipment.glb").instantiate())
	for spec: Array in [[Vector3(0,-.08,0),Vector3(12,.16,10)],[Vector3(0,3.3,0),Vector3(12,.22,10)],[Vector3(-6,1.6,0),Vector3(.22,3.2,10)],[Vector3(6,1.6,0),Vector3(.22,3.2,10)],[Vector3(0,1.6,-5),Vector3(12,3.2,.22)],[Vector3(-3.55,1.55,5),Vector3(4.9,3.1,.22)],[Vector3(3.55,1.55,5),Vector3(4.9,3.1,.22)],[Vector3(3.85,1.3,-1.4),Vector3(3.3,2.6,.1)],[Vector3(2.2,1.3,-3.05),Vector3(.1,2.6,3.3)],[Vector3(4,.45,-4.25),Vector3(2.4,.1,.48)]]:solid(spec[0],spec[1])
	solid(Vector3(0,.5,1.6),Vector3(3.8,1,1.2))
	for at: Vector3 in [Vector3(-3,.4,-2),Vector3(-3,.4,1),Vector3(1.5,.4,-3.5)]:solid(at,Vector3(1.7,.8,.8))
	for at: Vector3 in [Vector3(-3,2.6,1),Vector3(3,2.6,-2)]:
		var light:=OmniLight3D.new();light.position=at;light.light_color=Color(.83,.9,1);light.light_energy=1.5;light.omni_range=8;light.shadow_enabled=at.x<0;add_child(light)
	MovementAudio.region(self,Vector3(0,.03,0),Vector3(11.8,.03,9.8),"interior")
