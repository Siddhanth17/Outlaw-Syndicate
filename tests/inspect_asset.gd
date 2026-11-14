extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i: int in range(30): await physics_frame
	print("WEAPON ", game.player.weapon.global_position, " scale ", game.player.weapon.global_basis.get_scale(), " player ", game.player.position)
	for node: Node in game.player.visual.find_children("*", "Skeleton3D", true, false):
		print("SKELETON ", node.get_path(), " scale ", node.global_basis.get_scale(), " hand ", node.get_bone_global_pose(node.find_bone("RightHand")))
	game.queue_free()
	await create_timer(0.7).timeout
	quit()
