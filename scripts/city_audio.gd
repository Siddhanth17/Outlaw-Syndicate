class_name CityAudio
extends Node
const BUSES: Array[String]=["Music","Dialogue","Vehicles","Weapons","Footsteps","Environment","UI"]
var shot_index: int=0
var shots: int=0
var last_space: String="outdoor"
var levels: Dictionary={}
func _ready() -> void:
	for name: String in BUSES:
		if AudioServer.get_bus_index(name)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,name)
			AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	if AudioServer.get_bus_effect_count(0)==0:
		var limiter:=AudioEffectLimiter.new()
		limiter.ceiling_db=-1
		AudioServer.add_bus_effect(0,limiter)
	var cfg:=ConfigFile.new()
	cfg.load("user://city-audio.cfg")
	for name: String in BUSES:
		levels[name]=clampf(float(cfg.get_value("mix",name,0)),-40,0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(name),levels[name])
func adjust(name: String,delta: float) -> void:
	if not levels.has(name):return
	levels[name]=clampf(levels[name]+delta,-40,0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(name),levels[name])
	var cfg:=ConfigFile.new()
	for bus: String in BUSES:cfg.set_value("mix",bus,levels[bus])
	cfg.save("user://city-audio.cfg")
func _process(_delta: float) -> void:
	if get_parent().get("paused")!=null:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Vehicles"),float(levels.get("Vehicles",0))+(-14 if get_parent().paused else 0))
func fire(at: Vector3) -> void:
	shots+=1
	shot_index=(shot_index+1)%4
	var inside:=PhysicsRayQueryParameters3D.create(at+Vector3.UP,at+Vector3.UP*7,CollisionLayers.STATIC)
	last_space="interior" if not get_parent().get_world_3d().direct_space_state.intersect_ray(inside).is_empty() else "outdoor"
	var voice:=AudioStreamPlayer3D.new()
	voice.stream=load("res://assets/audio/veyra3/sidearm_%d.wav"%shot_index)
	voice.bus="Weapons"
	voice.position=at;voice.unit_size=8;voice.max_distance=130;voice.volume_db=-3
	voice.pitch_scale=1+float(shot_index-2)*.018
	voice.max_polyphony=2
	get_parent().add_child(voice)
	voice.finished.connect(voice.queue_free)
	if DisplayServer.get_name()!="headless":voice.play()
	else:voice.queue_free()
	if last_space=="interior":
		# One bounded, quieter reflection, not an unbounded echo voice chain.
		await get_tree().create_timer(.075).timeout
		var tail:=AudioStreamPlayer3D.new()
		tail.stream=load("res://assets/audio/veyra3/sidearm_%d.wav"%shot_index)
		tail.bus="Weapons";tail.volume_db=-29;tail.pitch_scale=.82;tail.max_distance=45
		get_parent().add_child(tail);tail.position=at
		tail.finished.connect(tail.queue_free)
		if DisplayServer.get_name()!="headless":tail.play()
		else:tail.queue_free()
