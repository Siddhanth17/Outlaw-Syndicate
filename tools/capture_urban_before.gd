extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i(1920,1080)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.test_mode=true
	game._menu_action("New game")
	game.ui.gameplay.hide()
	game.cine_camera.current=true
	DirAccess.make_dir_recursive_absolute("user://urban-before")
	for setup: Array in [[Vector3(5,2,126),Vector3(25,5,100),"night-avenue-before"],[Vector3(5,1.5,-190),Vector3(0,18,-220),"harbor-background-before"]]:
		game.cine_camera.position=setup[0]
		game.cine_camera.look_at(setup[1])
		for i: int in range(15):await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://urban-before/"+setup[2]+".png")
	quit()
