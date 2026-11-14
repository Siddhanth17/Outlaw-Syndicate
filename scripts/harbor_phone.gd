class_name HarborPhone
extends CanvasLayer

var game: Node3D
var opened: bool = false
var shell: PanelContainer
var column: VBoxContainer
var photos: Array[String] = []
var taking_photo: bool = false
var slide: Tween
var photo_index: int = -1
var key_code: int = KEY_TAB
var greeted: bool = false
var asked_job: bool = false
var dante_contact: bool = false
var call_serial: int = 0
var call_state: String = "idle"
var call_audio: AudioStreamPlayer
var focus_queued: bool = false

func reset_social() -> void:
	greeted=false
	asked_job=false
	dante_contact=false

func social_snapshot() -> Dictionary:
	return {"greeted":greeted,"asked_job":asked_job,"contact":dante_contact}

func restore_social(value: Variant) -> void:
	reset_social()
	if not value is Dictionary: return
	greeted=bool(value.get("greeted",false))
	asked_job=bool(value.get("asked_job",false))
	dante_contact=greeted and asked_job and bool(value.get("contact",false))

func mechanic_available() -> bool:
	return game.dante.health>0 and game.dante.state not in [HarborGuard.State.STAGGER,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER,HarborGuard.State.DEFEATED]

func talk_to_dante() -> void:
	if not opened: toggle()
	if not opened: return
	clear("DANTE / AT THE GARAGE")
	if not mechanic_available(): note("Dante cannot talk right now."); button("Back",home); return
	if not greeted: button("Greet",func() -> void: greeted=true; talk_to_dante())
	if not asked_job: button("Ask about work",func() -> void: asked_job=true; talk_to_dante())
	note("Dante Cross • mechanic\nI keep the Sables running. Bring yours here if it needs work.")
	if greeted and asked_job and not dante_contact:
		button("Ask for his number",func() -> void: dante_contact=true; talk_to_dante())
	if dante_contact:
		note("Dante's number saved to Contacts.")
		button("Repair Sable • $50",func() -> void: var result:=repair_sable(); clear("CROSS MOTOR WORKS"); note(result); button("Back",home))
	button("Back",home)

func repair_sable() -> String:
	if not dante_contact: return "Get to know Dante and ask for his number first."
	if not mechanic_available(): return "Dante is unavailable."
	if game.player.position.distance_to(game.dante.position)>4 or game.car.position.distance_to(game.dante.position)>10 or game.car.linear_velocity.length()>0.5:
		return "Park the Sable beside the garage and speak to Dante on foot."
	var damage: Dictionary=game.car.damage_snapshot()
	var damaged: bool=game.car.integrity<99 or not damage.get("hits",[]).is_empty() or not damage.get("bullet_marks",[]).is_empty()
	for value: Variant in damage.get("zones",{}).values(): damaged=damaged or float(value)>0
	for key: String in ["windows","tires","lights"]:
		for value: Variant in damage.get(key,[]): damaged=damaged or float(value)>0
	if not damaged: return "The Sable needs no repair."
	if game.memory.money<50: return "Not enough cash. No charge made."
	# Synchronous transaction: checks, charge and real damage reset occur together.
	game.memory.money-=50
	game.car.repair()
	game.memory.remember("cross_repair",{"paid":50})
	return "Paid $50. Engine and body damage repaired."

func contacts() -> void:
	clear("CONTACTS")
	if dante_contact: button("Dante Cross • call",call_dante)
	else: note("No saved numbers. Meet Dante at Cross Motor Works, greet him and ask about his work before requesting his number.")
	button("Back",home)

func call_dante() -> void:
	if not dante_contact: return
	call_serial+=1
	var token:=call_serial
	call_state="ringing"
	clear("CALLING DANTE")
	note("Ringing…")
	button("End call",func() -> void: end_call(); home())
	# Original synthesized ring, followed by the existing credited Dante recording.
	var ring:=AudioStreamWAV.new()
	ring.format=AudioStreamWAV.FORMAT_16_BITS
	ring.mix_rate=22050
	var samples:=PackedByteArray()
	samples.resize(11025*2)
	for i: int in range(11025): samples.encode_s16(i*2,int(sin(i*TAU*440/22050.0)*1800*sin(PI*i/11025.0)))
	ring.data=samples
	call_audio.stream=ring
	if DisplayServer.get_name()!="headless": call_audio.play()
	await get_tree().create_timer(0.8).timeout
	if token!=call_serial or not opened: return
	clear("DANTE CROSS")
	if not mechanic_available():
		call_audio.stop()
		call_state="busy"
		note("Unavailable. Try again later.")
	else:
		call_state="connected"
		note("Connected\nDante: She left her car here. The ledger is in warehouse nine.")
		call_audio.stream=load("res://assets/audio/dialogue/greeting_dante.wav")
		call_audio.volume_db=game.dialogue_volume
		if DisplayServer.get_name()!="headless": call_audio.play()
	button("End call",func() -> void: end_call(); home())

func end_call() -> void:
	call_serial+=1
	call_state="idle"
	if is_instance_valid(call_audio): call_audio.stop()

func bind_key(value: int) -> void:
	key_code=KEY_O if value==KEY_O else KEY_TAB
	if not InputMap.has_action("phone"): InputMap.add_action("phone")
	InputMap.action_erase_events("phone")
	var key:=InputEventKey.new()
	key.physical_keycode=key_code
	InputMap.action_add_event("phone",key)

func key_label() -> String: return "O" if key_code==KEY_O else "Tab"

func _ready() -> void:
	layer=5
	call_audio=AudioStreamPlayer.new()
	add_child(call_audio)
	shell=PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	shell.offset_left=-350
	shell.offset_top=-510
	shell.offset_right=-24
	shell.offset_bottom=-24
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("101c29")
	style.set_corner_radius_all(20)
	style.set_content_margin_all(20)
	style.set_border_width_all(2)
	style.border_color=Color("657b88")
	shell.add_theme_stylebox_override("panel",style)
	add_child(shell)
	column=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	shell.add_child(column)
	shell.hide()
	bind_key(key_code)

func toggle() -> void:
	if opened: close(); return
	if game.paused or game.cinematic_active or game.vehicle_transition.active or game.bike.mounting: return
	if not game.player.is_on_floor(): return
	if game.player.driving or game.player.riding_bike:
		game._say("Phone","Step off the vehicle to use the phone.")
		return
	opened=true
	game.player.camera_input_enabled=false
	game.player.set_physics_process(false)
	game.player.velocity=Vector3.ZERO
	game.player.perform("Idle",0.1)
	game.ui.gameplay.hide()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	shell.show()
	if slide: slide.kill()
	shell.position.y=get_viewport().get_visible_rect().size.y
	slide=create_tween()
	slide.tween_property(shell,"position:y",get_viewport().get_visible_rect().size.y-510,0.2)
	home()

func close() -> void:
	end_call()
	opened=false
	if slide: slide.kill()
	shell.hide()
	if is_instance_valid(game.player):
		game.player.camera_input_enabled=not game.paused and not game.cinematic_active
		game.player.set_physics_process(not game.paused and not game.cinematic_active)
		game.ui.gameplay.visible=not game.paused
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.paused else Input.MOUSE_MODE_CAPTURED

func clear(title: String) -> void:
	focus_queued=false
	for child: Node in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var heading:=Label.new()
	heading.text=title
	heading.add_theme_font_size_override("font_size",22)
	column.add_child(heading)

func note(text: String) -> void:
	var label:=Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=278
	column.add_child(label)

func button(text: String, action: Callable) -> void:
	var item:=Button.new()
	item.text=text
	item.custom_minimum_size.y=42
	column.add_child(item)
	item.pressed.connect(action)
	if not focus_queued:
		focus_queued=true
		call_deferred("focus_button",weakref(item))

func focus_button(reference: WeakRef) -> void:
	var item: Button=reference.get_ref()
	if is_instance_valid(item) and item.is_inside_tree() and item.get_parent()==column and opened:
		item.grab_focus()

func home() -> void:
	end_call()
	clear("VEYRA / PERSONAL")
	note("Adrian Vale\nIron Harbor • $%d"%game.memory.money)
	button("Messages",messages)
	button("Contacts",contacts)
	button("Camera • capture scene",capture_photo)
	button("Gallery (%d / 32)"%photos.size(),gallery)
	button("Close [%s]"%key_label(),close)

func messages() -> void:
	clear("DANTE CROSS")
	note("I'm at the garage. Come by when you're ready.\n\nThe Last Address is available. Accepting starts the story; exploring alone will not start it.")
	if not game.story_active:
		button("Accept • The Last Address",func() -> void: close(); game.start_story())
	else: note("The Last Address • accepted")
	button("Back",home)

func capture_photo() -> void:
	if taking_photo: return
	if photos.size()>=32:
		clear("CAMERA"); note("Gallery full. Existing photos are preserved."); button("Back",home); return
	if DisplayServer.get_name()=="headless": return
	taking_photo=true
	shell.hide()
	game.ui.gameplay.hide()
	await RenderingServer.frame_post_draw
	var image:=game.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://phone-gallery")
	var filename: String="photo_%d_%d.png"%[Time.get_unix_time_from_system(),Time.get_ticks_msec()]
	var result:=image.save_png("user://phone-gallery/"+filename)
	game.ui.gameplay.visible=not opened and not game.paused
	taking_photo=false
	if result==OK: photos.append(filename)
	if opened:
		shell.show()
		clear("CAMERA")
		note("Photo saved. Save a checkpoint to retain the gallery index." if result==OK else "Unable to save photo.")
		button("Back",home)

func gallery() -> void:
	clear("GALLERY")
	if photos.is_empty(): note("No saved photos.")
	else:
		photo_index=clampi(photo_index,0,photos.size()-1) if photo_index>=0 else photos.size()-1
		var image:=Image.load_from_file("user://phone-gallery/"+photos[photo_index])
		if image:
			var preview:=TextureRect.new()
			preview.texture=ImageTexture.create_from_image(image)
			preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.custom_minimum_size=Vector2(278,180)
			column.add_child(preview)
			note("Photo %d / %d"%[photo_index+1,photos.size()])
		if photo_index>0: button("Previous",func() -> void: photo_index-=1; gallery())
		if photo_index<photos.size()-1: button("Next",func() -> void: photo_index+=1; gallery())
	button("Back",home)

func restore(value: Variant) -> void:
	photos.clear()
	if not value is Array: return
	for entry: Variant in value:
		if entry is String and entry.begins_with("photo_") and entry.ends_with(".png") and entry==entry.get_file() and not entry.contains("..") and FileAccess.file_exists("user://phone-gallery/"+entry) and photos.size()<32:
			photos.append(entry)
