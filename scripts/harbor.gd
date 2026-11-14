class_name IronHarbor
extends Node3D

var environment: WorldEnvironment
var local_lights: Array[Light3D] = []
var physical_props: Array[RigidBody3D] = []
var shutters: Array[Node3D] = []
var wind_strength: float = 0.8
var wind_vector := Vector3(0.8, 0, 0.3)
var wind_materials: Array[ShaderMaterial] = []

func asset(path: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	var model: Node3D = load("res://assets/" + path + ".glb").instantiate()
	add_child(model)
	model.position = at
	model.rotation.y = yaw
	return model

func solid(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = at
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)
	body.collision_layer = CollisionLayers.STATIC
	body.collision_mask = CollisionLayers.SOLIDS
	return body

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
	if kind == "asphalt":
		var road := ShaderMaterial.new()
		road.shader = load("res://shaders/road.gdshader")
		road.set_shader_parameter("albedo_map", mat.albedo_texture)
		road.set_shader_parameter("normal_map", mat.normal_texture)
		road.set_shader_parameter("rough_map", mat.roughness_texture)
		model.material_override = road
	add_child(model)
	model.position = at
	return model

func _ready() -> void:
	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://shaders/harbor_sky.gdshader")
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.sky = sky
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
			var building := asset("environment/warehouse_realism_%d" % (i % 3), Vector3(side * 32, 0, z), PI / 2 if side < 0 else -PI / 2)
			_weather_building(building, i)
			shutters.append(building)
			for dock_x: float in [-7.0, 0.0, 7.0]:
				attached_solid(building, Vector3(dock_x, 0.38, 8.7), Vector3(5.6, 0.4, 0.75))
				for dx: float in [-2.8, 2.8]:
					attached_solid(building, Vector3(dock_x + dx, 0.65, 8.9), Vector3(0.24, 1.3, 0.24))
			solid(Vector3(side * 32, 3.5, z), Vector3(16, 7, 24))
		for i: int in range(9):
			var z: float = 34 - i * 24
			var mast := asset("environment/streetlamp", Vector3(side * 11, 0.14, z), -side * PI / 2)
			attached_solid(mast, Vector3(0, 3.5, 0), Vector3(0.20, 7, 0.20))
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
		var fence := asset("environment/fence", Vector3(-15, 0, 22 - i * 4), PI / 2)
		attached_solid(fence, Vector3(0, 1.3, 0), Vector3(4.1, 2.6, 0.16))
	for i: int in range(16):
		movable_cargo(Vector3(13 + (i % 2) * 2, 0.15, 24 - i * 9), i * 0.7)
	for crane_z: float in [-60.0, -126.0]:
		asset("environment/crane", Vector3(54, 0, crane_z), 0.0)
		for dx: float in [-6.0, 6.0]:
			for dz: float in [-4.0, 4.0]:
				solid(Vector3(54 + dx, 3, crane_z + dz), Vector3(0.8, 6, 0.8))
	for z: float in [-26.0, -84.0, -140.0]:
		var flood := SpotLight3D.new()
		flood.position = Vector3(22, 6, z)
		flood.light_color = Color(0.80, 0.86, 0.93)
		flood.light_energy = 8
		flood.spot_range = 19
		flood.spot_angle = 48
		flood.shadow_enabled = true
		add_child(flood)
		flood.look_at(Vector3(14, 0.2, z))
	var skyline := MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = BoxMesh.new()
	instances.instance_count = 22
	var backdrop := ShaderMaterial.new()
	backdrop.shader = load("res://shaders/skyline.gdshader")
	skyline.material_override = backdrop
	for i: int in range(22):
		var height: float = 12 + ((i * 17) % 29)
		var basis := Basis.IDENTITY.scaled(Vector3(5 + i % 5, height, 8))
		instances.set_instance_transform(i, Transform3D(basis, Vector3(-85 + i * 8, height / 2, -219 - (i % 3) * 12)))
	skyline.multimesh = instances
	add_child(skyline)
	for at: Vector3 in [Vector3(2, 0.023, -20), Vector3(-3, 0.023, -75), Vector3(4, 0.023, -125)]:
		asset("environment/manhole", at)
	for i: int in range(14):
		asset("environment/drain", Vector3(7.75, 0.025, 30 - i * 14))
	for at: Vector3 in [Vector3(18, 0.1, -26), Vector3(-19, 0.1, -91), Vector3(18, 0.1, -135)]:
		var forklift := asset("environment/forklift", at, 0.8)
		attached_solid(forklift, Vector3(0, 1.1, 0), Vector3(1.45, 2.2, 2.2))
		attached_solid(forklift, Vector3(0, 0.16, 1.75), Vector3(0.9, 0.12, 1.4))
	for i: int in range(3):
		var flag := MeshInstance3D.new()
		var fabric := PlaneMesh.new()
		fabric.size = Vector2(1.3, 0.7)
		fabric.subdivide_width = 14
		fabric.subdivide_depth = 6
		flag.mesh = fabric
		flag.rotation.x = PI / 2
		flag.position = Vector3(19, 4.5, -25 - i * 55)
		var fabric_mat := ShaderMaterial.new()
		fabric_mat.shader = load("res://shaders/wind_fabric.gdshader")
		flag.material_override = fabric_mat
		wind_materials.append(fabric_mat)
		add_child(flag)
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

func _process(_delta: float) -> void:
	var time: float = Time.get_ticks_msec() / 1000.0
	wind_vector = Vector3(0.8 + sin(time * 0.7) * 0.18, 0, 0.25) * wind_strength
	for mat: ShaderMaterial in wind_materials:
		mat.set_shader_parameter("strength", wind_strength)

func _weather_building(building: Node3D, index: int) -> void:
	var colors: Array[Color] = [Color(0.24, 0.30, 0.30), Color(0.33, 0.29, 0.23), Color(0.21, 0.27, 0.32)]
	for node: Node in building.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface_index: int in range(mesh.mesh.get_surface_count()):
			var old: Material = mesh.get_active_material(surface_index)
			if old and old.resource_name.contains("Galvanized"):
				var replacement := ShaderMaterial.new()
				replacement.shader = load("res://shaders/industrial_finish.gdshader")
				replacement.set_shader_parameter("paint", colors[index % 3])
				replacement.set_shader_parameter("age", 0.25 + (index % 4) * 0.2)
				mesh.set_surface_override_material(surface_index, replacement)
			elif old and old.resource_name.contains("Weathered concrete"):
				var concrete := StandardMaterial3D.new()
				concrete.albedo_texture = load("res://assets/textures/concrete_diff.jpg")
				concrete.normal_enabled = true
				concrete.normal_texture = load("res://assets/textures/concrete_normal.jpg")
				concrete.normal_scale = 0.4
				concrete.roughness = 0.85
				concrete.uv1_triplanar = true
				concrete.uv1_world_triplanar = true
				concrete.uv1_scale = Vector3.ONE * 0.4
				mesh.set_surface_override_material(surface_index, concrete)

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

func attached_solid(model: Node3D, center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = CollisionLayers.STATIC
	body.collision_mask = CollisionLayers.SOLIDS
	model.add_child(body)
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body

func movable_cargo(at: Vector3, yaw: float = 0) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = 85
	body.collision_layer = CollisionLayers.PROP
	body.collision_mask = CollisionLayers.SOLIDS
	body.continuous_cd = true
	var mat := PhysicsMaterial.new()
	mat.friction = 0.7
	mat.bounce = 0.05
	body.physics_material_override = mat
	add_child(body)
	body.position = at
	body.rotation.y = yaw
	body.add_child(load("res://assets/environment/cargo.glb").instantiate())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.28, 1.05)
	collider.position.y = 0.64
	collider.shape = shape
	body.add_child(collider)
	physical_props.append(body)
	return body

func pause_props(value: bool) -> void:
	for body: RigidBody3D in physical_props:
		if is_instance_valid(body): body.freeze = value
