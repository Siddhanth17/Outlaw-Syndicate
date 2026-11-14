class_name ActingValidation
extends Node

var game: Node3D
var passes: int = 0
var failures: int = 0

func check(ok: bool, text: String) -> void:
	print(("PASS " if ok else "FAIL ")+text)
	if ok: passes+=1
	else: failures+=1

func run() -> void:
	var director: DialogueDirector=game.dialogue_director
	check(director.face_meshes.size()==2 and not director.face_meshes[0].is_empty() and not director.face_meshes[1].is_empty(),"both actors expose authored facial morph controls")
	game.car.occupied=false
	director.start(false)
	await get_tree().process_frame
	check(director.active and game.cinematic_active and not game.player.camera_input_enabled,"conversation owns camera and gameplay input")
	var capture_time: float=0
	var frame: int=0
	var speakers_seen: Dictionary={}
	var played_speakers: Dictionary={}
	var dante_jaw: float=0
	var duration: float=float(director.lines[0].duration)+0.55+maxf(0.5,float(director.lines[1].duration)-0.35)
	for i: int in range(ceili(duration*60)):
		await get_tree().physics_frame
		if director.active:
			speakers_seen[director.lines[director.index].speaker]=director.audio.stream.resource_path
			if director.audio.playing: played_speakers[director.lines[director.index].speaker]=true
			if director.speaker==1: dante_jaw=maxf(dante_jaw,director.jaw)
		if director.active and director.index>=2: break
		if DisplayServer.get_name()!="headless" and director.elapsed>=capture_time and frame<72:
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://physics-verification/acting-%02d.png"%frame)
			capture_time+=0.12
			frame+=1
	check(speakers_seen.has("Adrian") and speakers_seen.has("Dante") and speakers_seen.Adrian!=speakers_seen.Dante,"both story speakers select different actual audio streams")
	check(dante_jaw>0.1,"Dante speech also drives his speaking facial overlay")
	check(director.max_jaw>0.1,"audio-envelope playback visibly drives jaw morph")
	check(director.saw_blink,"conversation produces timed lid closure")
	check(director.saw_gesture and game.player.dynamics.conversation_active,"tagged upper body gestures layered over idle")
	if DisplayServer.get_name()!="headless": check(played_speakers.has("Adrian") and played_speakers.has("Dante"),"real dialogue audio streams play for both speakers")
	else: print("NOT RUN physical audio output in headless mode")
	if DisplayServer.get_name()!="headless" and not director.audio.playing:
		director._next()
		await get_tree().process_frame
	game._set_pause(true)
	await get_tree().process_frame
	var position: float=director.line_time
	var jaw: float=director.jaw
	for i: int in range(10): await get_tree().physics_frame
	check((DisplayServer.get_name()=="headless" or director.audio.stream_paused) and is_equal_approx(position,director.line_time) and is_equal_approx(jaw,director.jaw),"pause freezes dialogue audio timeline and mouth")
	game._set_pause(false)
	var stage: int=game.memory.stage
	director.stop()
	check(not director.active and not director.audio.playing and not game.cinematic_active and game.player.camera_input_enabled and game.memory.stage==stage,"conversation skip restores control without changing completed objectives")
	var neutral: bool=true
	for meshes: Array in director.face_meshes:
		for mesh: MeshInstance3D in meshes:
			neutral = neutral and is_zero_approx(mesh.get_blend_shape_value(mesh.find_blend_shape_by_name("JawOpen")))
	check(neutral and not game.player.dynamics.conversation_active,"conversation exit resets facial and gesture overlays")
