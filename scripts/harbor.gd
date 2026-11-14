class_name IronHarbor
extends Node3D

var environment: WorldEnvironment
var local_lights: Array[Light3D] = []
var shutters: Array[Node3D] = []

func asset(path: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var model: Node3D = load("res://assets/" + path + ".glb").instantiate()
	add_child(model)
	model.position = at
	model.rotation.y = yaw
	return model

func solid(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = at
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)

func surface(at: Vector3, size: Vector2, kind: String, tint: Color, scale_uv: float, roughness: float) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	model.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = load("res://assets/textures/" + kind + "_diff.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/" + kind + "_normal.jpg")
	mat.normal_scale = 0.45
	mat.uv1_scale = Vector3(size.x / scale_uv, size.y / scale_uv, 1)
	mat.roughness = roughness
	if kind == "asphalt":
		mat.roughness_texture = load("res://assets/textures/asphalt_rough.jpg")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	model.material_override = mat
	add_child(model)
	model.position = at
	return model

func _ready() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.002, 0.004, 0.009)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.35, 0.55)
	env.ambient_light_energy = 0.36
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.25
	env.fog_enabled = true
	env.fog_light_color = Color(0.09, 0.16, 0.24)
	env.fog_light_energy = 0.7
	env.fog_density = 0.004
	env.glow_enabled = true
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 0.7
	env.ssr_enabled = false
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -22, 0)
	moon.light_color = Color(0.34, 0.49, 0.72)
	moon.light_energy = 0.65
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 90
	add_child(moon)
	solid(Vector3(0, -0.5, -60), Vector3(150, 1, 245))
	surface(Vector3(0, 0.005, -60), Vector2(150, 245), "concrete", Color(0.42, 0.47, 0.50), 3, 0.8)
	surface(Vector3(0, 0.02, -60), Vector2(16, 225), "asphalt", Color(0.5, 0.58, 0.62), 3, 0.38)
	for side: int in [-1, 1]:
		# Raised sidewalk and modeled curb segments, collision kept simple.
		solid(Vector3(side * 10, 0.07, -60), Vector3(4, 0.14, 225))
		surface(Vector3(side * 10, 0.145, -60), Vector2(4, 225), "concrete", Color(0.65, 0.66, 0.65), 2, 0.78)
		for i: int in range(7):
			var z: float = 24 - i * 29
			var building := asset("environment/warehouse", Vector3(side * 32, 0, z), PI / 2 if side < 0 else -PI / 2)
			shutters.append(building)
			solid(Vector3(side * 32, 3.5, z), Vector3(16, 7, 24))
		for i: int in range(9):
			var z: float = 34 - i * 24
			asset("environment/streetlamp", Vector3(side * 11, 0.14, z), -side * PI / 2)
			var lamp := OmniLight3D.new()
			add_child(lamp)
			lamp.position = Vector3(side * 9.5, 6.9, z)
			lamp.light_color = Color(1, 0.53, 0.23)
			lamp.light_energy = 7
			lamp.omni_range = 15
			lamp.omni_attenuation = 1.5
			lamp.shadow_enabled = i % 3 == 0
			lamp.distance_fade_enabled = true
			lamp.distance_fade_begin = 42
			lamp.distance_fade_length = 12
			local_lights.append(lamp)
	for i: int in range(12):
		var at := Vector3(15 + (i % 3) * 3.2, (i / 6) * 2.6, -55 - (i % 6) * 8)
		asset("environment/container", at)
		solid(at + Vector3(0, 1.3, 0), Vector3(2.45, 2.6, 6.1))
	for i: int in range(10):
		asset("environment/fence", Vector3(-15, 0, 22 - i * 4), PI / 2)
	for i: int in range(16):
		asset("environment/cargo", Vector3(13 + (i % 2) * 2, 0.15, 24 - i * 9), i * 0.7)
	asset("environment/crane", Vector3(54, 0, -60), 0.0)
	asset("environment/crane", Vector3(54, 0, -126), 0.0)
	# Painted road strokes are thin planes, not floating solid boxes.
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.75, 0.61, 0.34)
	stripe_mat.roughness = 0.65
	for i: int in range(28):
		var line := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(0.10, 3.4)
		line.mesh = plane
		line.material_override = stripe_mat
		add_child(line)
		line.position = Vector3(0, 0.026, 45 - i * 8)
	for spec: Array in [["CROSS / MOTOR WORKS", Vector3(-13, 3.4, 0)], ["09 / BONDED STORAGE", Vector3(14, 4, -95)], ["IRON HARBOR", Vector3(0, 9, -160)]]:
		var sign := Label3D.new()
		sign.text = spec[0]
		sign.position = spec[1]
		sign.font_size = 76
		sign.pixel_size = 0.009
		sign.modulate = Color(0.8, 0.72, 0.48)
		add_child(sign)
	var probe := ReflectionProbe.new()
	probe.position = Vector3(0, 4, -48)
	probe.size = Vector3(35, 16, 130)
	probe.max_distance = 85
	probe.intensity = 0.65
	add_child(probe)

func preset(quality: int) -> void:
	var env := environment.environment
	env.ssao_enabled = quality > 0
	env.glow_enabled = quality > 0
	env.ssr_enabled = quality == 2
	env.volumetric_fog_enabled = quality == 2
	env.volumetric_fog_density = 0.012
	for i: int in range(local_lights.size()):
		local_lights[i].shadow_enabled = quality > 0 and i % 3 == 0

func consequence(exposed: bool) -> void:
	# Evidence recovery causes an actual district light change.
	for i: int in range(local_lights.size()):
		if i > 8:
			local_lights[i].light_color = Color(0.9, 0.12, 0.07) if exposed else Color(1, 0.53, 0.23)
