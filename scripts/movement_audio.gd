class_name MovementAudio
extends Node3D

const SURFACE_LAYER: int = 256
var actor: CharacterBody3D
var profiles: Dictionary = {}
var pool: Array[AudioStreamPlayer3D] = []
var samples: Dictionary = {}
var previous_sample: Dictionary = {}
var cursor: int = 0
var distance: float = 0
var previous_speed: float = 0
var airborne_speed: float = 0
var cooldown: float = 0
var volume_db: float = -5
var last_surface: String = "concrete"
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var cloth: AudioStreamPlayer3D
var steps: int = 0

func _ready() -> void:
	actor = get_parent()
	rng.randomize()
	profiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/movement_audio.json"))
	for profile: Dictionary in profiles.values():
		for path: String in profile.samples:
			if not samples.has(path): samples[path] = load(path)
	for i: int in range(4):
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 22
		voice.unit_size = 2
		voice.position.y = 0.1
		add_child(voice)
		pool.append(voice)
	cloth = AudioStreamPlayer3D.new()
	cloth.max_distance = 8
	add_child(cloth)

static func region(parent: Node3D, at: Vector3, size: Vector3, material: String) -> Area3D:
	var area := Area3D.new()
	area.name = "FootSurface_" + material
	area.collision_layer = SURFACE_LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("foot_surface", material)
	parent.add_child(area)
	area.position = at
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	area.add_child(collider)
	return area

func surface_at(point: Vector3) -> String:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.25, point - Vector3.UP * 0.55, CollisionLayers.STATIC | CollisionLayers.PROP | SURFACE_LAYER)
	query.collide_with_areas = true
	query.exclude = [actor.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var material: String = hit.collider.get_meta("foot_surface", "concrete")
		if profiles.has(material): return material
	return "concrete"

func emit_contact(kind: String, speed: float, surface: String = "") -> void:
	last_surface = surface_at(actor.global_position) if surface.is_empty() else surface
	var profile: Dictionary = profiles.get(last_surface, profiles.concrete)
	var paths: Array = profile.samples
	var index: int = rng.randi_range(0, paths.size() - 1)
	if paths.size() > 1 and index == int(previous_sample.get(last_surface, -1)): index = (index + 1) % paths.size()
	previous_sample[last_surface] = index
	var voice := pool[cursor % pool.size()]
	cursor += 1
	voice.stream = samples[paths[index]]
	var strength: float = clampf(speed / 6.5, 0, 1)
	voice.volume_db = volume_db + float(profile.gain_db) + lerpf(-8, -2, strength) + (3.0 if kind == "land" else (-6.0 if kind == "stop" else 0.0))
	voice.pitch_scale = float(profile.pitch) * rng.randf_range(0.96, 1.04) * (0.9 if kind == "land" else 1.0)
	events.append({"kind":kind,"surface":last_surface,"sample":paths[index],"speed":speed,"gain_db":voice.volume_db})
	if events.size() > 32: events.pop_front()
	if DisplayServer.get_name() != "headless": voice.play()
	if kind in ["step", "land"]:
		steps += 1
		if steps % 3 == 0 or kind == "land":
			cloth.stream = samples[profiles.cloth.samples[steps % 4]]
			cloth.volume_db = volume_db - 24 + strength * 3
			cloth.pitch_scale = rng.randf_range(0.86, 1.02)
			if DisplayServer.get_name() != "headless": cloth.play()

func update_motion(delta: float, grounded: bool, landed: bool, displacement: float, speed: float, vertical_speed: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if not grounded:
		airborne_speed = maxf(airborne_speed, -vertical_speed)
		distance = 0
		previous_speed = speed
		return
	if landed:
		emit_contact("land", maxf(speed, airborne_speed))
		airborne_speed = 0
		cooldown = 0.16
		distance = 0
	elif speed < 0.2 and previous_speed > 0.25 and cooldown <= 0:
		emit_contact("stop", previous_speed)
		cooldown = 0.18
	var stride: float = 1.65 if speed > 5 else (1.02 if speed > 2.5 else 0.68)
	if speed > 0.25 and displacement < 1.0:
		distance += displacement
		if distance >= stride and cooldown <= 0:
			emit_contact("step", speed)
			distance = fmod(distance, stride)
			cooldown = 0.17
	else: distance = 0
	previous_speed = speed

func reset_motion() -> void:
	distance = 0
	previous_speed = 0
	airborne_speed = 0
	for voice: AudioStreamPlayer3D in pool: voice.stop()
	if cloth: cloth.stop()
