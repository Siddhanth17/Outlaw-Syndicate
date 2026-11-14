extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._set_pause(false)
	DirAccess.make_dir_recursive_absolute("user://physics-verification")
	var validation:=ActingValidation.new()
	validation.game=game
	game.add_child(validation)
	await validation.run()
	quit(1 if validation.failures else 0)
