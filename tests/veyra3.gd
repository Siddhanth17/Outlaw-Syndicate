extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var validation:=Veyra3Validation.new()
	validation.game=game;game.add_child(validation)
	validation.run()
