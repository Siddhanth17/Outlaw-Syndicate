class_name InjuryVisuals
extends Node

var root: Node3D
var marks: Array[Dictionary]=[]
var surfaces: Array[Dictionary]=[]

func setup(model: Node3D) -> void:
	root=model
	for mesh: Node in model.find_children("*","MeshInstance3D",true,false):
		if mesh.find_blend_shape_by_name("JawOpen")<0 and not mesh.name.contains("jacket"): continue
		for index: int in range(mesh.mesh.get_surface_count()):
			var old: Material=mesh.get_active_material(index)
			if not old is StandardMaterial3D or old.resource_name.to_lower().contains("hair"): continue
			if not old.albedo_texture: continue
			var material:=ShaderMaterial.new()
			material.shader=load("res://shaders/injury_surface.gdshader")
			material.set_shader_parameter("albedo_map",old.albedo_texture)
			material.set_shader_parameter("tint",old.albedo_color)
			material.set_shader_parameter("base_roughness",old.roughness)
			material.set_shader_parameter("mark_units_per_meter",1.0/maxf(mesh.global_basis.get_scale().x,.0001))
			if old.roughness_texture:
				material.set_shader_parameter("roughness_map",old.roughness_texture)
				material.set_shader_parameter("use_roughness_map",true)
				material.set_shader_parameter("roughness_channel",old.roughness_texture_channel)
			mesh.set_surface_override_material(index,material)
			surfaces.append({"mesh":mesh,"material":material})
	_sync()

func hit(world_point: Vector3, severity: float) -> void:
	if not is_instance_valid(root) or not world_point.is_finite(): return
	var point: Vector3=root.to_local(world_point)
	marks.append({"p":[point.x,point.y,point.z],"strength":clampf(severity/50,0.15,0.8)})
	if marks.size()>4: marks.pop_front()
	_sync()

func snapshot() -> Array:
	return marks.duplicate(true)

func restore(data: Array) -> void:
	marks.clear()
	for mark: Variant in data:
		if marks.size()>=4: break
		if not mark is Dictionary or not mark.get("p") is Array or mark.p.size()!=3: continue
		var valid: bool=true
		for value: Variant in mark.p:
			if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value))>5: valid=false
		if valid: marks.append({"p":mark.p,"strength":clampf(float(mark.get("strength",0)),0,0.8)})
	_sync()

func _sync() -> void:
	for surface: Dictionary in surfaces:
		var points:=PackedVector4Array()
		for i: int in range(4):
			var point:=Vector3(1000,1000,1000)
			var strength: float=0
			if i<marks.size():
				var mark: Dictionary=marks[i]
				point=surface.mesh.to_local(root.to_global(Vector3(mark.p[0],mark.p[1],mark.p[2])))
				strength=mark.strength
			points.append(Vector4(point.x,point.y,point.z,strength))
		surface.material.set_shader_parameter("marks",points)
