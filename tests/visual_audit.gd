extends SceneTree

# Baseline evidence only. This does not validate the next visual milestone.
func _initialize() -> void:
	call_deferred("run_audit")

func capture(name: String) -> void:
	for i: int in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/artifacts/" + name + ".png")

func run_audit() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i: int in range(120):
		await process_frame
	await capture("audit-player")
	game.player.position = game.car.position + Vector3(4, 0, 5)
	game.player.yaw = 0.55
	await capture("audit-car")
	game.player.position = Vector3(0, 1, -60)
	game.player.yaw = -0.6
	await capture("audit-district")
	game._pause()
	await capture("audit-pause")
	game._pause()
	var times: Array[float] = []
	var previous: int = Time.get_ticks_usec()
	for i: int in range(600):
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append(float(now - previous) / 1000.0)
		previous = now
	var total: float = 0
	for value: float in times:
		total += value
	times.sort()
	var report := {
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"resolution": str(root.size), "samples": times.size(),
		"mean_frame_ms": total / times.size(),
		"average_fps": 1000.0 * times.size() / total,
		"p95_frame_ms": times[int(times.size() * 0.95)],
		"camera_fov": game.player.camera.fov,
		"camera_near": game.player.camera.near,
		"camera_far": game.player.camera.far,
		"camera_position": str(game.player.camera.global_position),
		"draw_calls_last_frame": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"scope": "Stationary graybox, 600 process-frame intervals; includes scheduling and VSync. Not GPU timing, target-art performance or a gameplay benchmark."
	}
	var file := FileAccess.open("res://tests/artifacts/audit-baseline.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	quit()
