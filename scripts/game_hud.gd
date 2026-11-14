class_name GameHUD
extends CanvasLayer

signal command(action: String)
var gameplay: Control
var modal: ColorRect
var modal_column: VBoxContainer
var objective: Label
var status: Label
var ammo: Label
var prompt: Label
var subtitles: Label
var subtitle_panel: PanelContainer
var health: ProgressBar
var crosshair: Label
var current_screen: String = ""

func label(text: String, size: int = 18, color: Color = Color(0.87, 0.89, 0.89)) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

func panel() -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.055, 0.92)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.border_width_left = 2
	style.border_color = Color(0.8, 0.55, 0.25)
	node.add_theme_stylebox_override("panel", style)
	return node

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	gameplay = MarginContainer.new()
	gameplay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		gameplay.add_theme_constant_override("margin_" + edge, 28)
	root.add_child(gameplay)
	var stack := VBoxContainer.new()
	gameplay.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	var goal_panel := panel()
	goal_panel.custom_minimum_size.x = 370
	goal_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(goal_panel)
	var goals := VBoxContainer.new()
	goal_panel.add_child(goals)
	goals.add_child(label("THE LAST ADDRESS", 14, Color(0.86, 0.63, 0.35)))
	objective = label("")
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 330
	goals.add_child(objective)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	status = label("", 16)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status)
	var middle := Control.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(middle)
	crosshair = label("·", 36)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	middle.add_child(crosshair)
	prompt = label("", 17, Color(0.95, 0.8, 0.54))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(prompt)
	subtitle_panel = panel()
	stack.add_child(subtitle_panel)
	subtitles = label("", 20)
	subtitles.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_panel.add_child(subtitles)
	var bottom := HBoxContainer.new()
	stack.add_child(bottom)
	health = ProgressBar.new()
	health.custom_minimum_size = Vector2(150, 8)
	health.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health.show_percentage = false
	var health_group := VBoxContainer.new()
	health_group.add_child(label("HEALTH", 11))
	health_group.add_child(health)
	bottom.add_child(health_group)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(gap)
	ammo = label("", 18)
	bottom.add_child(ammo)
	modal = ColorRect.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.color = Color(0.012, 0.022, 0.034, 0.98)
	root.add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 550)
	center.add_child(scroll)
	modal_column = VBoxContainer.new()
	modal_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_column.add_theme_constant_override("separation", 12)
	scroll.add_child(modal_column)
	_pass_gameplay_mouse(gameplay)
	modal.hide()

func show_screen(screen: String) -> void:
	current_screen = screen
	gameplay.visible = screen.is_empty()
	modal.visible = not screen.is_empty()
	for child: Node in modal_column.get_children():
		modal_column.remove_child(child)
		child.queue_free()
	if screen.is_empty():
		return
	modal_column.add_child(label("OUTLAW SYNDICATE", 32))
	modal_column.add_child(label("THE CITY THAT SOLD ITS SOUL", 13, Color(0.8, 0.57, 0.32)))
	var actions: Array[String] = []
	match screen:
		"main": actions = ["New game", "Continue", "Driving course", "Crash Test Facility", "Living City Laboratory", "Movement Audio Laboratory", "Human Motion Laboratory", "Settings", "Controls", "Credits", "Exit"]
		"pause": actions = ["Resume", "Save checkpoint", "Load checkpoint", "Settings", "Controls", "Main menu", "Exit"]
		"settings": actions = ["Graphics: Low", "Graphics: Balanced", "Graphics: High", "Sensitivity +", "Sensitivity -", "Dialogue volume +", "Dialogue volume -", "Movement volume +", "Movement volume -", "Subtitles toggle", "Reduced shake toggle", "Back"]
		"controls":
			var controls := label("WASD / Left stick — walk or drive\nMouse / Right stick — look\nShift — sprint    Space / A — jump or brake\nE / Y — interact or enter / exit vehicle\nRight mouse — aim    Left mouse / RB — fire\nR / X — reload    Esc / Start — pause\nF5 — save    F9 — load\nEnter / A — skip cinematic\n\nExit a vehicle only when moving slowly.", 17)
			modal_column.add_child(controls)
			actions = ["Back"]
		"credits":
			modal_column.add_child(label("Original harbor kit / Sable vehicle: project-authored\nHuman / Walk / Run: vibeassets CC0, Meshy-origin\nAsphalt / Concrete: Rob Tuytel, Poly Haven CC0\nGodot Engine / Jolt: MIT\nSee assets/licenses and docs/asset-licenses.md", 16))
			actions = ["Back"]
		"defeat": actions = ["Retry checkpoint", "New game", "Main menu"]
	for title: String in actions:
		var button := Button.new()
		button.text = title
		button.custom_minimum_size.y = 42
		button.add_theme_font_size_override("font_size", 18)
		modal_column.add_child(button)
		button.pressed.connect(func() -> void: command.emit(title))
		if title == actions[0]:
			call_deferred("_focus_button", weakref(button))

func _focus_button(reference: WeakRef) -> void:
	var button: Button = reference.get_ref()
	if is_instance_valid(button) and button.is_inside_tree():
		button.grab_focus()

func _pass_gameplay_mouse(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children(): _pass_gameplay_mouse(child)
