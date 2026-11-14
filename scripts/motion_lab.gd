extends "res://scripts/main.gd"

var inspection: bool = false

func _ready() -> void:
	super._ready()
	_set_pause(false)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -350
	panel.offset_right = -28
	panel.offset_top = 130
	layer.add_child(panel)
	var text := Label.new()
	text.text = "HUMAN MOTION LABORATORY\n1 Walk  2 Run  3 Sprint  4 Stop\n5 Jump  6 Seat / exit  7 Wind\nF2 Face inspection  Esc Pause\nUses the real Iron Harbor character.\nDraft facial morphs in dialogue; full foot IK absent."
	text.add_theme_font_size_override("font_size", 16)
	panel.add_child(text)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_1, KEY_2, KEY_3:
			Input.action_release("sprint")
			Input.action_press("forward", 0.5 if event.physical_keycode == KEY_1 else 1.0)
			if event.physical_keycode == KEY_3: Input.action_press("sprint")
		KEY_4:
			Input.action_release("forward")
			Input.action_release("sprint")
		KEY_5:
			Input.action_press("jump")
			get_tree().create_timer(0.1).timeout.connect(func() -> void: Input.action_release("jump"))
		KEY_6:
			Input.action_release("forward")
			Input.action_release("sprint")
			if not player.driving:
				player.position = car.position + Vector3(2.5, 0, 0)
				player.dynamics.reset_state()
			_interact()
		KEY_7: harbor.wind_strength = 0.0 if harbor.wind_strength > 1 else harbor.wind_strength + 0.6
		KEY_F2:
			inspection = not inspection
			if not inspection: player.camera.current = true

func _process(delta: float) -> void:
	super._process(delta)
	if inspection and not cinematic_active:
		cine_camera.current = true
		cine_camera.position = player.position + Vector3(0.7, 1.7, -1.1)
		cine_camera.look_at(player.position + Vector3(0, 1.57, 0))
		cine_camera.fov = 36

func _menu_action(title: String) -> void:
	if title == "Main menu":
		Input.action_release("forward")
		Input.action_release("sprint")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		super._menu_action(title)
