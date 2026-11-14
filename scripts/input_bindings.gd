class_name GameInputs
extends RefCounted

static func install() -> void:
	if InputMap.has_action("aim"): return
	InputMap.add_action("aim")
	var keys: Dictionary = {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE, "interact": KEY_E, "handbrake": KEY_SPACE, "save": KEY_F5, "load": KEY_F9, "pause": KEY_ESCAPE, "fire": KEY_F, "reload": KEY_R, "skip": KEY_ENTER}
	for action: String in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for spec: Array in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["forward", JOY_AXIS_LEFT_Y, -1.0], ["back", JOY_AXIS_LEFT_Y, 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = spec[1]
		axis.axis_value = spec[2]
		InputMap.action_add_event(spec[0], axis)
	for spec: Array in [["jump", JOY_BUTTON_A], ["handbrake", JOY_BUTTON_A], ["sprint", JOY_BUTTON_B], ["aim", JOY_BUTTON_LEFT_SHOULDER], ["skip", JOY_BUTTON_A], ["interact", JOY_BUTTON_Y], ["fire", JOY_BUTTON_RIGHT_SHOULDER], ["reload", JOY_BUTTON_X], ["pause", JOY_BUTTON_START]]:
		var button := InputEventJoypadButton.new()
		button.button_index = spec[1]
		InputMap.action_add_event(spec[0], button)
	for spec: Array in [["fire", MOUSE_BUTTON_LEFT], ["aim", MOUSE_BUTTON_RIGHT]]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = spec[1]
		InputMap.action_add_event(spec[0], mouse)
