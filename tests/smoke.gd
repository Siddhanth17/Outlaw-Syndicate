extends SceneTree

var failures: int = 0

func check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var memory := CityMemory.new()
	check(memory.remember("ledger", {"reward": 500}), "first event accepted")
	check(not memory.remember("ledger", {"reward": 500}), "duplicate event rejected")
	check(memory.money == 650, "reward is idempotent")
	var restored := CityMemory.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(memory.snapshot()))), "save JSON round trip")
	check(restored.events.has("ledger") and restored.money == 650, "persistent consequence restored")
	check(not restored.restore({"version": 99}), "unsupported save rejected")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	for i: int in range(180):
		await physics_frame
	check(game.player.is_on_floor(), "player settles on collision floor")
	check(game.car.position.y > 0 and game.car.position.y < 3, "Jolt vehicle remains on road")
	var initial_z: float = game.player.position.z
	Input.action_press("forward")
	for i: int in range(30):
		await physics_frame
	Input.action_release("forward")
	check(game.player.position.z < initial_z - 1, "movement input traverses world")
	check(game.player.camera.current, "third person camera active")
	check(game.car.get_child_count() >= 7, "vehicle wheels and body created")
	game.player.position = Vector3(0, 1, 0)
	game._interact()
	check(game.memory.stage == 1, "garage objective advances")
	game.player.position = game.car.position
	game._interact()
	check(game.player.driving and game.car.occupied, "vehicle entry")
	game.car.position = Vector3(0, 1, -85)
	game._process(0.01)
	check(game.memory.stage == 2, "driving objective advances")
	game._leave_car()
	game.player.position = Vector3(12, 1, -95)
	game._interact()
	check(game.memory.stage == 3 and game.memory.heat == 100, "ledger triggers search")
	game.player.position = Vector3(0, 1, 0)
	game._process(21)
	check(game.memory.stage == 4, "escape advances after search decays")
	game._interact()
	check(game.memory.stage == 5 and game.memory.money == 650, "mission completes with reward")
	game._save()
	game.memory.money = 0
	game._load()
	check(game.memory.money == 650 and game.memory.stage == 5, "checkpoint restores campaign and economy")
	game._save()
	var broken := FileAccess.open("user://veyra-save.json", FileAccess.WRITE)
	broken.store_string("interrupted invalid JSON")
	broken.close()
	game.memory.money = 0
	game._load()
	check(game.memory.money == 650, "corrupted primary recovers from backup")
	game._save()
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
