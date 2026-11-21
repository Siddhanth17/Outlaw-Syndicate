extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	var validation:=TransitionValidation.new();validation.game=game;game.add_child(validation);validation.call_deferred("run")
