class_name RuntimeVerification
extends Node

# Opt-in developer capture route for verifying the exported executable itself.
# Never enabled by normal menu flows. Captures are inspection shots, not playtests.
var game: Node3D
var frames: int = 0
var stage: int = -1
var pending: bool = false
var names: Array[String] = ["character", "vehicle", "harbor", "driver", "running", "dialogue"]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://verification")
	game._set_pause(false)
	game.get_window().size = Vector2i(1920, 1080)

func view(at: Vector3, target: Vector3, fov: float = 50) -> void:
	game.cine_camera.current = true
	game.cine_camera.position = at
	game.cine_camera.look_at(target)
	game.cine_camera.fov = fov

func _process(_delta: float) -> void:
	frames += 1
	if frames < 150: return
	var next: int = (frames - 150) / 90
	if next >= names.size():
		Input.action_release("forward")
		Input.action_release("sprint")
		print("EXPORTED_CAPTURE_COMPLETE ", ProjectSettings.globalize_path("user://verification"))
		game.get_tree().quit()
		return
	if next != stage:
		stage = next
		match stage:
			0: view(Vector3(0.65, 1.65, 10.8), Vector3(0, 1.55, 12), 36)
			1: view(Vector3(8, 1.5, 8), game.car.position + Vector3(0, 0.15, 0), 45)
			2: view(Vector3(7, 3.3, 24), Vector3(-12, 2, -40), 58)
			3:
				game.player.position = game.car.position
				game._interact()
				view(game.car.global_transform * Vector3(0.55, 0.65, 0.9), game.car.global_transform * Vector3(-0.38, 0.35, 0.15), 64)
			4:
				game._leave_car()
				game.player.position = Vector3(0, 0.05, 25)
				game.player.camera.current = true
				Input.action_press("forward")
				Input.action_press("sprint")
			5:
				Input.action_release("forward")
				Input.action_release("sprint")
				game._start_cinematic(true)
	if (frames - 150) % 90 == 65 and not pending:
		pending = true
		_capture(names[stage])

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error: Error = game.get_viewport().get_texture().get_image().save_png("user://verification/" + name + ".png")
	print("EXPORTED_CAPTURE ", name, " ", error)
	pending = false
