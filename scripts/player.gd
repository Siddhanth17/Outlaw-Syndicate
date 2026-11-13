class_name ValePlayer
extends CharacterBody3D

var yaw: float = 0.0
var pitch: float = -0.18
var sensitivity: float = 0.0025
var driving: bool = false
var health: float = 100
var pivot: Node3D
var camera: Camera3D
var visual: MeshInstance3D

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	visual = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	visual.mesh = mesh
	visual.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.22, 0.28)
	visual.material_override = mat
	add_child(visual)
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 1.5
	var arm := SpringArm3D.new()
	arm.spring_length = 5.5
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.current = true
	arm.add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -0.9, 0.4)

func _physics_process(delta: float) -> void:
	yaw -= Input.get_joy_axis(0, JOY_AXIS_RIGHT_X) * delta * 2
	pitch = clampf(pitch - Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y) * delta * 2, -0.9, 0.4)
	pivot.rotation = Vector3(pitch, yaw, 0)
	if driving:
		return
	var axis := Input.get_vector("left", "right", "forward", "back")
	var direction := Basis(Vector3.UP, yaw) * Vector3(axis.x, 0, axis.y)
	var speed: float = 9.0 if Input.is_action_pressed("sprint") else 5.0
	if Input.is_action_pressed("crouch"):
		speed = 2.2
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 25)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 25)
	if not is_on_floor():
		velocity.y -= 24 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 8
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta * 12)
	if position.y < -20:
		position = Vector3(0, 2, 12)
