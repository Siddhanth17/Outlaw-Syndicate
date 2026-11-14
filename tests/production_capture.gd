extends SceneTree

var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count): await process_frame

func capture(name: String) -> void:
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/artifacts/production-" + name + ".png")

func benchmark(name: String, count: int) -> Dictionary:
	await frames(120)
	var times: Array[float] = []
	var last: int = Time.get_ticks_usec()
	for i: int in range(count):
		await RenderingServer.frame_post_draw
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append(float(now - last) / 1000)
		last = now
	var total: float = 0
	for t: float in times: total += t
	times.sort()
	return {"scenario": name, "resolution": str(root.size), "renderer": RenderingServer.get_current_rendering_method(), "samples": count, "mean_ms": total / count, "p95_ms": times[int(count * 0.95)], "fps": count * 1000 / total, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "video_memory_estimate_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(120)
	game.player.visual.rotation.y = PI
	await capture("player")
	Input.action_press("forward")
	await capture("walk-a")
	await frames(12)
	await capture("walk-b")
	Input.action_release("forward")
	Input.action_press("aim")
	await capture("aim")
	Input.action_release("aim")
	game.player.position = Vector3(9, 0.1, 5)
	game.player.yaw = 1.1
	game.player.pitch = -0.18
	await capture("car")
	game.player.position = Vector3(0, 0.1, -65)
	game.player.yaw = -0.65
	await capture("district")
	game.player.perform("Interact", 1)
	await capture("interaction")
	game._pause()
	await capture("pause")
	game._menu_action("Controls")
	await capture("controls")
	game.ui.show_screen("main")
	await capture("main-menu")
	game._set_pause(false)
	root.size = Vector2i(1920, 1080)
	await frames(60)
	await capture("1080p")
	var results: Array[Dictionary] = []
	for preset: int in [0, 1, 2]:
		game.harbor.preset(preset)
		results.append(await benchmark("1080p on-foot district, " + ["Low", "Balanced", "High"][preset], 600))
	game.harbor.preset(1)
	root.size = Vector2i(2560, 1080)
	await capture("ultrawide")
	game._pause()
	await capture("ultrawide-pause")
	game._pause()
	root.size = Vector2i(1280, 720)
	game.car.position = Vector3(0, 1.1, 25)
	game.car.rotation = Vector3(0, PI, 0)
	game.player.position = game.car.position
	game._interact()
	Input.action_press("forward")
	await frames(150)
	await capture("driving")
	results.append(await benchmark("720p vehicle accelerating, Balanced", 600))
	Input.action_release("forward")
	Input.action_press("handbrake")
	await frames(120)
	Input.action_release("handbrake")
	game._leave_car()
	game._start_cinematic(false)
	await frames(60)
	await capture("cinematic")
	game._end_cinematic()
	game.memory.stage = 3
	game._spawn_guards()
	game.player.position = Vector3(9, 0.1, -92)
	game.player.yaw = 0
	Input.action_press("aim")
	await frames(120)
	await capture("encounter")
	Input.action_release("aim")
	game._clear_guards()
	game._set_pause(false)
	# Demonstrate motion with untouched frames from actual gameplay.
	game.player.position = Vector3(0, 0.1, 12)
	game.player.yaw = 0
	Input.action_press("forward")
	for i: int in range(16):
		for j: int in range(4): await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/artifacts/motion-%02d.png" % i)
	Input.action_release("forward")
	var output := {"results": results, "scope": "Rendered source game, short fixed scenarios after 120-frame warmup. Wall-clock frame intervals include presentation/scheduling; memory is Godot-reported. Not isolated GPU timing, sustained thermal testing, or a full playthrough."}
	var file := FileAccess.open("res://tests/artifacts/production-performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	print(JSON.stringify(output))
	game.queue_free()
	await frames(5)
	await create_timer(0.7).timeout
	quit()
