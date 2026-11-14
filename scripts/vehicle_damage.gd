class_name VehicleDamage
extends Node

# Gameplay deformation of original/rest meshes. Not a crash simulation.
const ZONES: Array[String] = ["front_left", "front_center", "front_right", "left_front", "left_rear", "right_front", "right_rear", "rear_left", "rear_center", "rear_right", "roof", "underbody"]
var car: RigidBody3D
var zones: Dictionary = {}
var hits: Array[Dictionary] = []
var parts: Array[Dictionary] = []
var glass: Array[Dictionary] = []
var debris: Array[RigidBody3D] = []
var max_displacement: float = 0
var rebuild_count: int = 0

func setup(body: Node3D, owner_car: RigidBody3D) -> void:
	car = owner_car
	for zone: String in ZONES: zones[zone] = 0.0
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var mat: Material = mesh.get_active_material(0)
		if mat and mat.resource_name.contains("glazing"):
			var shader := ShaderMaterial.new()
			shader.shader = load("res://shaders/damaged_glass.gdshader")
			mesh.material_override = shader
			glass.append({"node": mesh, "state": 0, "damage": 0.0, "material": shader, "origin": Vector2(0.5,0.5), "center": car.to_local(mesh.to_global(mesh.mesh.get_aabb().get_center()))})
		else:
			var paint: ShaderMaterial
			if mat and mat.resource_name.contains("lacquer"):
				paint = ShaderMaterial.new()
				paint.shader = load("res://shaders/damaged_paint.gdshader")
				mesh.material_override = paint
			parts.append({"node": mesh, "rest": mesh.mesh, "transform": mesh.transform, "paint": paint, "detached": false})

static func zone_at(point: Vector3, normal: Vector3 = Vector3.ZERO) -> String:
	if absf(normal.x) > 0.7:
		return ("left" if point.x < 0 else "right") + ("_front" if point.z > 0 else "_rear")
	if point.y > 0.48: return "roof"
	if point.y < -0.52: return "underbody"
	var side: String = "left" if point.x < -0.3 else ("right" if point.x > 0.3 else "center")
	if point.z > 1.15: return "front_" + side
	if point.z < -1.15: return "rear_" + side
	return ("left" if point.x < 0 else "right") + ("_front" if point.z > 0 else "_rear")

func impact(point: Vector3, inward: Vector3, speed: float, effects: bool = true) -> void:
	if not point.is_finite() or not inward.is_finite() or not is_finite(speed) or speed < 2.8: return
	var zone: String = zone_at(point, inward)
	var amount: float = clampf((speed - 2.8) * 3.5, 0, 65)
	zones[zone] = minf(100, float(zones[zone]) + amount)
	var record: Dictionary = {"p": [point.x, point.y, point.z], "n": [inward.x, inward.y, inward.z], "strength": clampf(amount / 60, 0, 1)}
	# Twelve spatially merged dents bound rebuild work and save size.
	var merged: bool = false
	for hit: Dictionary in hits:
		var p := Vector3(hit.p[0], hit.p[1], hit.p[2])
		if p.distance_to(point) < 0.55:
			hit.strength = minf(1, float(hit.strength) + float(record.strength))
			merged = true
			break
	if not merged:
		if hits.size() < 12: hits.append(record)
		else: hits[0] = record
	for pane: Dictionary in glass:
		if (pane.center as Vector3).distance_to(point) < 0.90 and point.y > -0.12:
			var previous: int = pane.state
			if previous==0: pane.origin=_pane_uv(pane.node,car.to_global(point))
			pane.damage = minf(100, float(pane.damage) + amount * 1.5)
			pane.state = 3 if pane.damage >= 70 else (2 if pane.damage >= 35 else 1)
			if effects and pane.state == 3 and previous < 3: burst(car.to_global(pane.center), true)
	_rebuild(effects)
	if effects: burst(car.to_global(point), false)

func _rebuild(effects: bool) -> void:
	rebuild_count += 1
	max_displacement = 0
	for part: Dictionary in parts:
		var node: MeshInstance3D = part.node
		var rest: Mesh = part.rest
		var result := ArrayMesh.new()
		for index: int in range(rest.get_surface_count()):
			var arrays: Array = rest.surface_get_arrays(index).duplicate(true)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var to_car: Transform3D = car.global_transform.affine_inverse() * node.global_transform
			for i: int in range(vertices.size()):
				var original: Vector3 = to_car * vertices[i]
				var displacement := Vector3.ZERO
				for hit: Dictionary in hits:
					var p := Vector3(hit.p[0], hit.p[1], hit.p[2])
					var n := Vector3(hit.n[0], hit.n[1], hit.n[2]).normalized()
					var falloff: float = maxf(0, 1 - original.distance_to(p) / 1.05)
					displacement += n * float(hit.strength) * 0.38 * falloff * falloff
				displacement = displacement.limit_length(0.40)
				max_displacement = maxf(max_displacement, displacement.length())
				vertices[i] += to_car.basis.inverse() * displacement
			arrays[Mesh.ARRAY_VERTEX] = vertices
			var source := ArrayMesh.new()
			source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var surface := SurfaceTool.new()
			surface.create_from(source, 0)
			surface.generate_normals()
			surface.commit(result)
			result.surface_set_material(index, rest.surface_get_material(index))
		node.mesh = result
		if part.paint:
			var points := PackedVector4Array()
			for i: int in range(12):
				var p := Vector3(1000,1000,1000)
				var strength: float = 0
				if i < hits.size():
					p = node.to_local(car.to_global(Vector3(hits[i].p[0],hits[i].p[1],hits[i].p[2])))
					strength = hits[i].strength
				points.append(Vector4(p.x,p.y,p.z,strength))
			part.paint.set_shader_parameter("hits", points)
		var center: Vector3 = car.to_local(node.to_global(rest.get_aabb().get_center()))
		var local_zone: String = zone_at(center)
		var condition: float = float(zones.get(local_zone, 0))
		if node.name.contains("bumper"):
			condition = float(zones["front_center"] if center.z > 0 else zones["rear_center"])
			for side: String in ["left", "right"]: condition = maxf(condition, zones[("front_" if center.z > 0 else "rear_") + side])
			if condition > 75 and not part.detached:
				if effects: detach(node)
				part.detached = true
			node.visible = not part.detached
		elif node.name.contains("Headlamp") or node.name.contains("Tail lamp"):
			node.visible = condition < 55
	for pane: Dictionary in glass:
		pane.node.visible = pane.state < 3
		pane.material.set_shader_parameter("stage", float(pane.state))
		pane.material.set_shader_parameter("origin",pane.origin)

func detach(node: MeshInstance3D) -> void:
	if debris.size() >= 8: return
	var body := RigidBody3D.new()
	body.mass = 8
	body.collision_layer = CollisionLayers.PROP
	body.collision_mask = CollisionLayers.STATIC | CollisionLayers.PROP
	car.get_parent().add_child(body)
	body.global_transform = node.global_transform
	var visible := MeshInstance3D.new()
	visible.mesh = node.mesh
	body.add_child(visible)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = node.mesh.get_aabb().size.max(Vector3.ONE * 0.08)
	collider.shape = box
	collider.position = node.mesh.get_aabb().get_center()
	body.add_child(collider)
	body.linear_velocity = car.linear_velocity.limit_length(12) + Vector3.UP
	debris.append(body)
	var reference: WeakRef = weakref(body)
	get_tree().create_timer(12).timeout.connect(func() -> void:
		var remaining: RigidBody3D = reference.get_ref()
		if remaining:
			debris.erase(remaining)
			remaining.queue_free())

func burst(at: Vector3, is_glass: bool) -> void:
	if DisplayServer.get_name() == "headless": return
	if is_glass:
		var sound:=AudioStreamPlayer3D.new()
		sound.stream=load("res://assets/audio/glass_break.wav")
		sound.volume_db=-8
		add_child(sound)
		sound.global_position=at
		sound.finished.connect(sound.queue_free)
		sound.play()
	# Hard cap concurrent effects; no persistent fragments.
	if get_child_count() >= 6: return
	var particles := GPUParticles3D.new()
	particles.amount = 20 if is_glass else 12
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.explosiveness = 1
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 80
	process.initial_velocity_min = 1.5
	process.initial_velocity_max = 4
	process.gravity = Vector3(0,-9.8,0)
	particles.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.016
	mesh.height = 0.032
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6,0.8,0.9) if is_glass else Color(0.8,0.48,0.15)
	mesh.material = mat
	particles.draw_pass_1 = mesh
	add_child(particles)
	particles.global_position = at
	particles.top_level = true
	particles.emitting = true
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

func snapshot() -> Dictionary:
	var windows: Array = []
	for pane: Dictionary in glass: windows.append(float(pane.damage))
	var origins: Array=[]
	for pane: Dictionary in glass: origins.append([pane.origin.x,pane.origin.y])
	return {"version": 1, "zones": zones.duplicate(), "hits": hits.duplicate(true), "windows": windows, "window_origins": origins}

func restore(data: Dictionary) -> void:
	for body: RigidBody3D in debris:
		if is_instance_valid(body): body.queue_free()
	debris.clear()
	hits.clear()
	var saved_zones: Dictionary=data.get("zones",{}) if data.get("zones",{}) is Dictionary else {}
	for zone: String in ZONES: zones[zone] = _number(saved_zones.get(zone,0),100)
	var saved_hits: Array=data.get("hits",[]) if data.get("hits",[]) is Array else []
	for hit: Variant in saved_hits:
		if hits.size() >= 12: break
		if not hit is Dictionary or not hit.get("p") is Array or not hit.get("n") is Array: continue
		if hit.p.size() != 3 or hit.n.size() != 3: continue
		var safe: bool = true
		for component: Variant in hit.p + hit.n:
			if not (component is float or component is int) or not is_finite(float(component)) or absf(float(component)) > 10: safe = false
		if safe: hits.append({"p": hit.p, "n": hit.n, "strength": _number(hit.get("strength",0),1)})
	for part: Dictionary in parts: part.detached = false
	var windows: Array = data.get("windows", []) if data.get("windows",[]) is Array else []
	for i: int in range(glass.size()):
		var origins: Array = data.get("window_origins",[]) if data.get("window_origins",[]) is Array else []
		glass[i].origin=Vector2(_number(origins[i][0],1),_number(origins[i][1],1)) if i<origins.size() and origins[i] is Array and origins[i].size()==2 else Vector2(0.5,0.5)
		glass[i].damage = _number(windows[i],100) if i < windows.size() else 0.0
		glass[i].state = 3 if glass[i].damage >= 70 else (2 if glass[i].damage >= 35 else (1 if glass[i].damage > 0 else 0))
	_rebuild(false)

func _pane_uv(mesh: MeshInstance3D, world_point: Vector3) -> Vector2:
	var point: Vector3=mesh.to_local(world_point)
	var arrays: Array=mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var best: float=INF
	var result:=Vector2(0.5,0.5)
	for i: int in range(0,indices.size(),3):
		var a: int=indices[i]
		var b: int=indices[i+1]
		var c: int=indices[i+2]
		var v0: Vector3=vertices[b]-vertices[a]
		var v1: Vector3=vertices[c]-vertices[a]
		var v2: Vector3=point-vertices[a]
		var denom: float=v0.dot(v0)*v1.dot(v1)-v0.dot(v1)*v0.dot(v1)
		if absf(denom)<0.000001: continue
		var y: float=clampf((v1.dot(v1)*v2.dot(v0)-v0.dot(v1)*v2.dot(v1))/denom,0,1)
		var z: float=clampf((v0.dot(v0)*v2.dot(v1)-v0.dot(v1)*v2.dot(v0))/denom,0,1-y)
		var x: float=1-y-z
		var closest: Vector3=vertices[a]*x+vertices[b]*y+vertices[c]*z
		var distance: float=closest.distance_squared_to(point)
		if distance<best:
			best=distance
			result=uv[a]*x+uv[b]*y+uv[c]*z
	return result

func _number(value: Variant, maximum: float) -> float:
	if not (value is int or value is float): return 0
	return clampf(float(value),0,maximum) if is_finite(float(value)) else 0
