class_name MissionRouteValidation
extends Node

var game: Node3D
var ticks: int = 0
var failures: int = 0

func check(value: bool, description: String) -> bool:
	print(("PASS " if value else "FAIL ") + description)
	if not value: failures += 1
	return value

func step(count: int = 1) -> void:
	for i: int in range(count):
		await get_tree().physics_frame
		ticks += 1

func stop_input() -> void:
	for action: String in ["forward", "back", "left", "right", "handbrake"]:
		Input.action_release(action)

func walk_to(at: Vector3, limit: int = 1000, radius: float = 1.8) -> bool:
	game.player.yaw = 0
	for i: int in range(limit):
		var offset: Vector3 = at - game.player.position
		offset.y = 0
		if offset.length() < radius:
			stop_input()
			await step(15)
			return true
		offset = offset.normalized()
		stop_input()
		Input.action_press("right" if offset.x > 0 else "left", absf(offset.x))
		Input.action_press("back" if offset.z > 0 else "forward", absf(offset.z))
		await step()
	stop_input()
	return false

func brake() -> void:
	stop_input()
	Input.action_press("handbrake")
	for i: int in range(300):
		await step()
		if game.car.linear_velocity.length() < 0.5: break
	Input.action_release("handbrake")

func run() -> void:
	game.test_mode = true
	game._menu_action("New game")
	game.start_story() # Story routes now require explicit acceptance.
	game._end_cinematic()
	await step(90)
	check(await walk_to(Vector3.ZERO), "walk to Dante using movement input")
	game._interact()
	check(game.memory.stage == 1, "Dante dialogue starts driving objective")
	check(await walk_to(game.car.position, 1000, 3.5), "walk to parked car")
	game._interact()
	check(game.player.driving, "enter car during mission")
	Input.action_press("forward")
	for i: int in range(1800):
		await step()
		if game.memory.stage == 2: break
	await brake()
	check(game.memory.stage == 2, "drive actual physics route to warehouse")
	game._interact()
	check(not game.player.driving, "exit stopped vehicle")
	check(await walk_to(Vector3(12, 0, -95)), "walk from car to ledger")
	game._interact()
	check(game.memory.stage == 3 and game.guards.size() == 2, "ledger starts security encounter")
	for guard: HarborGuard in game.guards:
		for shot: int in range(4):
			if guard.state == HarborGuard.State.DEFEATED: break
			await step(20)
			game.player.camera.look_at(guard.global_position + Vector3.UP * 1.1)
			game._fire()
	check(game.guards.all(func(guard: HarborGuard) -> bool: return guard.state == HarborGuard.State.DEFEATED), "mission guards defeated through weapon hit detection")
	check(await walk_to(game.car.position, 1000, 3.5), "return to getaway car on foot")
	game._interact()
	check(game.player.driving, "re-enter getaway car")
	print("MISSION_REENTRY car=",game.car.position," integrity=",game.car.integrity," vel=",game.car.linear_velocity," steering=",game.car.steering)
	Input.action_press("back")
	for i: int in range(1800):
		await step()
		if game.car.position.z > -4: break
	await brake()
	for i: int in range(1500):
		await step()
		if game.memory.stage == 4: break
	print("MISSION_ESCAPE car=",game.car.position," integrity=",game.car.integrity," damage=",game.car.damage.zones," stage=",game.memory.stage," heat=",game.memory.heat)
	check(game.memory.stage == 4, "escape search by leaving warehouse area and waiting")
	game._interact()
	check(await walk_to(Vector3.ZERO), "return to Dante using movement")
	game._interact()
	check(game.memory.stage == 5 and game.memory.money == 650, "physical mission route completes and rewards once")
	print("SIMULATED_PHYSICS_SECONDS ", float(ticks) / Engine.physics_ticks_per_second, " (automated, not human campaign playtime)")
	stop_input()
	await get_tree().create_timer(0.7).timeout
	get_tree().quit(1 if failures else 0)
