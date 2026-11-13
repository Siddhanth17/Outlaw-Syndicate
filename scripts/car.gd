class_name VeyraCar
extends VehicleBody3D

var occupied: bool = false
var integrity: float = 100

func _ready() -> void:
	mass = 1250
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 0.8, 4.1)
	collision.shape = box
	add_child(collision)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.16, 0.07)
	mat.metallic = 0.65
	body.material_override = mat
	add_child(body)
	var cabin := MeshInstance3D.new()
	var top := BoxMesh.new()
	top.size = Vector3(1.65, 0.65, 1.9)
	cabin.mesh = top
	cabin.position = Vector3(0, 0.65, 0.15)
	add_child(cabin)
	for x: float in [-0.95, 0.95]:
		for z: float in [-1.35, 1.35]:
			var wheel := VehicleWheel3D.new()
			wheel.position = Vector3(x, -0.2, z)
			wheel.wheel_radius = 0.38
			wheel.wheel_rest_length = 0.3
			wheel.suspension_stiffness = 35
			wheel.damping_compression = 4
			wheel.damping_relaxation = 5
			wheel.wheel_friction_slip = 2.5
			wheel.use_as_steering = z < 0
			wheel.use_as_traction = z > 0
			add_child(wheel)
			var tire := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.38
			cylinder.bottom_radius = 0.38
			cylinder.height = 0.22
			tire.mesh = cylinder
			tire.rotation.z = PI / 2
			wheel.add_child(tire)

func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("back", "forward") if occupied else 0.0
	engine_force = throttle * 2100 * clampf(integrity / 100, 0.3, 1)
	var target: float = Input.get_axis("right", "left") * 0.4 if occupied else 0.0
	steering = move_toward(steering, target, delta * 1.5)
	brake = 40 if not occupied or Input.is_action_pressed("handbrake") else 0
