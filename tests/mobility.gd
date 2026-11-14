extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	var validation:=MobilityValidation.new()
	validation.game=scene
	scene.add_child(validation)
	validation.call_deferred("run")
