extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var validation:=HeroValidation.new()
	validation.game=game
	game.add_child(validation)
	DirAccess.make_dir_recursive_absolute("user://living-verification")
	await validation.run()
	quit(1 if validation.failures else 0)
