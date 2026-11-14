extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var route:=MissionRouteValidation.new()
	route.game=game
	game.add_child(route)
	route.run()
