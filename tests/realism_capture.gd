extends SceneTree

var game: Node3D
var folder: String

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count): await process_frame

func capture(name: String) -> void:
	await frames(24)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + "/" + name + ".png")

func view(at: Vector3, target: Vector3, fov: float = 50) -> void:
	game.cine_camera.position = at
	game.cine_camera.look_at(target)
	game.cine_camera.fov = fov
	game.cine_camera.current = true

func run() -> void:
	folder = "res://tests/artifacts/reference-before" if OS.get_cmdline_user_args().has("--before") else "res://tests/artifacts/realism-after"
	DirAccess.make_dir_recursive_absolute(folder)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(120)
	root.size = Vector2i(1920, 1080)
	if OS.get_cmdline_user_args().has("--warehouse-only"):
		view(Vector3(17, 2.2, -4), Vector3(26, 3, -5), 62)
		await capture("warehouse-clear")
		game.queue_free()
		await create_timer(0.7).timeout
		quit()
		return
	view(Vector3(0.65, 1.65, 10.8), Vector3(0, 1.55, 12), 36)
	await capture("character-close")
	view(Vector3(8, 1.5, 8), game.car.position + Vector3(0, 0.15, 0), 45)
	await capture("vehicle-close")
	view(Vector3(7, 3.3, 24), Vector3(-12, 2, -40), 58)
	await capture("harbor-wide")
	view(Vector3(11, 2.2, -65), Vector3(26, 3, -65), 55)
	await capture("warehouse")
	view(Vector3(5, 1.8, 18), Vector3(0, 0.1, -5), 52)
	await capture("road")
	game.player.position = game.car.position
	game._interact()
	await frames(60)
	view(game.car.position + Vector3(-2.3, 0.7, 0.8), game.car.position + Vector3(-0.38, 0.25, 0), 40)
	await capture("driver-close")
	view(game.car.global_transform * Vector3(0.55, 0.65, 0.9), game.car.global_transform * Vector3(-0.38, 0.35, 0.15), 64)
	await capture("driver-cabin")
	game._leave_car()
	game.player.position = Vector3(0, 0.05, 12)
	game.player.camera.current = true
	Input.action_press("forward")
	Input.action_press("sprint")
	await capture("running")
	Input.action_release("forward")
	Input.action_release("sprint")
	await capture("stopped")
	game._start_cinematic(true)
	await frames(60)
	await capture("dialogue")
	game._end_cinematic()
	game.memory.stage = 3
	game.memory.heat = 100
	game._spawn_guards()
	game.player.position = Vector3(9, 0.1, -92)
	game.player.yaw = 0
	game.player.camera.current = true
	Input.action_press("aim")
	await capture("combat")
	Input.action_release("aim")
	game._clear_guards()
	game.player.position = Vector3(0, 0.1, 25)
	game.player.yaw = 0
	Input.action_press("forward")
	Input.action_press("sprint")
	for i: int in range(20):
		if i == 9:
			Input.action_release("forward")
			Input.action_release("sprint")
		for j: int in range(4): await physics_frame
		view(game.player.position + Vector3(0.65, 1.65, -1.1), game.player.position + Vector3(0, 1.5, 0), 40)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + "/secondary-%02d.png" % i)
	game.player.position = Vector3(0, 0.1, -65)
	game.player.yaw = -0.65
	game.player.camera.current = true
	game.harbor.preset(1)
	await frames(120)
	var samples: Array[float] = []
	var last: int = Time.get_ticks_usec()
	for i: int in range(600):
		await RenderingServer.frame_post_draw
		await process_frame
		var now: int = Time.get_ticks_usec()
		samples.append((now - last) / 1000.0)
		last = now
	var total: float = 0
	for value: float in samples: total += value
	samples.sort()
	var worst: float = 0
	for i: int in range(594, 600): worst += samples[i]
	var report := {"resolution": str(root.size), "renderer": RenderingServer.get_current_rendering_method(), "frames": 600, "mean_ms": total / 600, "fps": 600000 / total, "p95_ms": samples[570], "one_percent_low_fps": 6000 / worst, "video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "scope": "Short rendered inspection view, Balanced, wall frame intervals; not sustained or isolated GPU profiling."}
	var file := FileAccess.open(folder + "/performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	game.queue_free()
	await create_timer(0.7).timeout
	quit()
