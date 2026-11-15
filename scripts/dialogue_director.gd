class_name DialogueDirector
extends Node

signal completed
var game: Node3D
var audio: AudioStreamPlayer
var database: Dictionary
var lines: Array[Dictionary] = []
var index: int = -1
var active: bool = false
var elapsed: float = 0
var line_time: float = 0
var jaw: float = 0
var max_jaw: float = 0
var saw_blink: bool = false
var saw_gesture: bool = false
var face_meshes: Array[Array] = []
var speaker: int = 0

func _ready() -> void:
	database = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	audio = AudioStreamPlayer.new()
	audio.bus="Dialogue"
	audio.volume_db = -4
	add_child(audio)
	for visual: Node3D in [game.player.visual, game.dante]:
		var found: Array[MeshInstance3D] = []
		for mesh: Node in visual.find_children("*", "MeshInstance3D", true, false):
			if mesh.find_blend_shape_by_name("JawOpen") >= 0: found.append(mesh)
		face_meshes.append(found)

func start(closing: bool = false) -> void:
	lines.clear()
	var ids: Array = ["closing_dante", "closing_adrian"] if closing else ["greeting_adrian", "greeting_dante", "question_adrian", "warning_dante"]
	for id: String in ids:
		for line: Dictionary in database.lines:
			if line.id == id: lines.append(line)
	index = -1
	elapsed = 0
	max_jaw = 0
	saw_blink = false
	saw_gesture = false
	active = true
	game.cinematic_active = true
	game.player.camera_input_enabled = false
	game.player.set_physics_process(false)
	game.car.set_physics_process(false)
	game.car.freeze = true
	game.harbor.pause_props(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.player.position = Vector3(0.8,0.05,0.8)
	game.player.visual.rotation.y = atan2(game.dante.position.x-game.player.position.x, game.dante.position.z-game.player.position.z)
	game.player.perform("Idle", 0.1)
	game.dante.rotation.y = atan2(game.player.position.x-game.dante.position.x,game.player.position.z-game.dante.position.z)
	game.ui.crosshair.hide()
	game.ui.prompt.text=""
	game.ui.ammo.text=""
	game.ui.status.text=""
	game.ui.health.hide()
	game.cine_camera.current = true
	_next()

func _next() -> void:
	index += 1
	line_time = 0
	jaw = 0
	if index >= lines.size():
		stop()
		return
	var line: Dictionary = lines[index]
	speaker = 0 if line.speaker == "Adrian" else 1
	audio.stream = load(line.audio)
	if DisplayServer.get_name() != "headless": audio.play()
	game._say(line.speaker, line.line)
	game.ui.objective.text = "THE LAST ADDRESS / conversation\n[Enter / A] Skip"

func stop() -> void:
	audio.stop()
	active = false
	jaw = 0
	for group: Array in face_meshes:
		for mesh: MeshInstance3D in group:
			for name: String in ["JawOpen","BlinkLeft","BlinkRight","BrowConcern"]: _shape(mesh,name,0)
	for dynamics: HumanDynamics in [game.player.dynamics, game.dante_dynamics]:
		if dynamics:
			dynamics.gesture_amount = 0
			dynamics.conversation_active = false
	completed.emit()
	game._end_cinematic()
	game.harbor.pause_props(game.paused)

func _process(delta: float) -> void:
	if not active: return
	audio.stream_paused = game.paused
	if game.paused: return
	elapsed += delta
	line_time += delta
	var line: Dictionary = lines[index]
	var playback: float = audio.get_playback_position() if DisplayServer.get_name() != "headless" else line_time
	var envelope: Array = line.envelope
	var sample: int = clampi(int(playback*float(line.envelope_hz)),0,envelope.size()-1)
	var value: float = float(envelope[sample]) if (audio.playing or DisplayServer.get_name()=="headless") and line_time < float(line.duration) else 0.0
	jaw = move_toward(jaw,value,delta*14)
	max_jaw = maxf(max_jaw,jaw)
	for actor: int in range(2):
		var blink_phase: float = fmod(elapsed + actor*1.9,4.1)
		var blink: float = maxf(0,1-absf(blink_phase-0.14)/0.11)
		saw_blink = saw_blink or blink>0.7
		for mesh: MeshInstance3D in face_meshes[actor]:
			_shape(mesh,"JawOpen",jaw*0.95 if actor==speaker else 0)
			_shape(mesh,"BlinkLeft",blink)
			_shape(mesh,"BlinkRight",blink)
			_shape(mesh,"BrowConcern",0.5 if line.gesture in ["concern","warning"] else 0.12)
		var dynamics: HumanDynamics = game.player.dynamics if actor==0 else game.dante_dynamics
		if dynamics:
			dynamics.conversation_active = true
			dynamics.gesture_tag = str(line.gesture) if actor==speaker else "listen"
			dynamics.gesture_amount = sin(clampf(line_time/float(line.duration),0,1)*PI)*0.8
			dynamics.conversation_clock = line_time
			saw_gesture = saw_gesture or dynamics.gesture_amount>0.3
	# Fixed side of the line of action; establish, speaker reverse, listener reaction.
	var actor_at: Vector3 = game.player.position if speaker==0 else game.dante.position
	var listener_at: Vector3 = game.dante.position if speaker==0 else game.player.position
	var target: Vector3 = actor_at + Vector3.UP*1.5
	var camera_at: Vector3
	if elapsed<1.2:
		camera_at = Vector3(3,2.2,4)
		target = Vector3(-0.3,1.2,0)
	elif line_time>float(line.duration)*0.78:
		target=listener_at+Vector3.UP*1.5
		camera_at=listener_at+(actor_at-listener_at).normalized()*1.5+Vector3(0.65,0,-0.77)*1.1+Vector3.UP*1.65
	else:
		camera_at=actor_at+(listener_at-actor_at).normalized()*1.5+Vector3(0.65,0,-0.77)*1.1+Vector3.UP*1.65
	game.cine_camera.position = game.cine_camera.position.lerp(camera_at,1-exp(-delta*7)) if elapsed>0.1 else camera_at
	game.cine_camera.look_at(target)
	game.cine_camera.fov=38
	game.player.dynamics.has_head_target=true
	game.player.dynamics.head_target=game.dante.position+Vector3.UP*1.55
	game.dante_dynamics.has_head_target=true
	game.dante_dynamics.head_target=game.player.position+Vector3.UP*1.55
	if line_time>float(line.duration)+0.55: _next()

func _shape(mesh: MeshInstance3D, name: String, value: float) -> void:
	var shape: int=mesh.find_blend_shape_by_name(name)
	if shape>=0: mesh.set_blend_shape_value(shape,value)
