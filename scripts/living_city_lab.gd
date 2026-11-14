extends "res://scripts/crash_facility.gd"

var gallery: Array[CityNPC]=[]
var victim: CityNPC
var voice_player: AudioStreamPlayer
var voice_index: int=0

func _ready() -> void:
	super._ready()
	var ids: Array[String]=["industrial_worker","dock_supervisor","security","pedestrian","delivery_driver","mechanic","police","faction","shopkeeper"]
	for i: int in range(ids.size()):
		var actor:=CityNPC.new()
		actor.game=self
		actor.name="Gallery_"+ids[i]
		actor.npc_id=actor.name
		actor.appearance_id=ids[i]
		actor.position=Vector3(188+i*2.8,0.05,-24)
		actor.route=PackedVector3Array([actor.position])
		add_child(actor)
		actor._play("Idle")
		actor.visual.rotation.y=PI
		actor.set_physics_process(false)
		var caption:=Label3D.new()
		caption.text=ids[i]
		caption.position.y=2.15
		caption.font_size=30
		caption.pixel_size=0.01
		actor.add_child(caption)
		gallery.append(actor)
	player.position=Vector3(200,0.1,-30)
	player.yaw=PI
	voice_player=AudioStreamPlayer.new()
	voice_player.volume_db=-6
	add_child(voice_player)
	scenario="Living systems: gallery is an engineering inspection; population also lives in Iron Harbor."

func _input(event: InputEvent) -> void:
	super._input(event)
	if paused or cinematic_active or not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_6,KEY_7:
			if is_instance_valid(victim): victim.queue_free()
			victim=CityNPC.new()
			victim.game=self
			victim.name="ContactSubject"
			victim.appearance_id="pedestrian"
			victim.position=Vector3(200,0.05,-2)
			victim.route=PackedVector3Array([victim.position])
			add_child(victim)
			car.repair()
			car.occupied=true
			car.reset_pose(Transform3D(Basis.IDENTITY,Vector3(200,0.8,-8)),Vector3(0,0,4 if event.physical_keycode==KEY_6 else 14))
			scenario="Actual vehicle contact: 6 low speed / 7 knockdown. Walk over to inspect."
		KEY_F6:
			var profiles: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/voice_profiles.json")).profiles
			var names: Array=profiles.keys()
			var selected: String=names[voice_index%names.size()]
			voice_index+=1
			voice_player.stream=load(profiles[selected].sample_audio)
			voice_player.play()
			scenario="VOICE: "+selected+" / "+profiles[selected].sample_text
		KEY_F7:
			voice_player.stop()
			dialogue_director.start(false)

func _process(delta: float) -> void:
	super._process(delta)
	voice_player.stream_paused=paused
	voice_player.volume_db=dialogue_volume
	if is_instance_valid(lab_label) and not paused and not cinematic_active:
		ui.objective.text="LIVING CITY LABORATORY\nPause menu: controls and audio settings"
		lab_label.text+="\n6 low contact / 7 knockdown / F6 cycle eight voices / F7 real Adrian–Dante conversation\nUse normal aim/fire to test body, glass, lamps and tires on any car."
