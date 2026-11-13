extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i: int in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
	root.get_texture().get_image().save_png("res://tests/artifacts/harbor.png")
	quit()
