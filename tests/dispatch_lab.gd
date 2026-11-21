extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	var lab:=DispatchLab.new();lab.game=game;game.add_child(lab);lab.call_deferred("run")
