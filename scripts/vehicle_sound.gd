class_name VehicleSound
extends Node3D
# Audible RPM is a presentation model, not a replacement for wheel physics.
var layers: Array[AudioStreamPlayer3D]=[]
var shift: AudioStreamPlayer3D
var rpm: float=800
var gear: int=1
var load_amount: float=0
var running: bool=false
var vehicle_kind: String="car"
var gains: Array[float]=[1,0,0,0,0]
var shifts: int=0
var rolling: AudioStreamPlayer3D
var skid: AudioStreamPlayer3D
var surface_name: String="asphalt"
var surface_timer: float=0
func setup(idle: AudioStreamPlayer3D,kind: String,road_voice: AudioStreamPlayer3D=null) -> void:
	vehicle_kind=kind
	for name: String in ["idle","mid","high","load","coast"]:
		var voice:=idle if name=="idle" else AudioStreamPlayer3D.new()
		if name!="idle":add_child(voice)
		var stream: AudioStreamWAV=load("res://assets/audio/veyra3/%s_%s.wav"%[kind,name]).duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_end=stream.data.size()/2
		voice.stream=stream
		voice.bus="Vehicles"
		voice.unit_size=5
		voice.max_distance=65
		voice.volume_db=-80
		layers.append(voice)
	shift=AudioStreamPlayer3D.new()
	shift.stream=load("res://assets/audio/veyra3/%s_shift.wav"%kind)
	shift.bus="Vehicles";shift.volume_db=-22;shift.max_distance=25
	add_child(shift)
	rolling=road_voice if road_voice else AudioStreamPlayer3D.new()
	if not road_voice:add_child(rolling)
	skid=AudioStreamPlayer3D.new();add_child(skid)
	for pair: Array in [[rolling,"road_roll"],[skid,"road_skid"]]:
		var voice: AudioStreamPlayer3D=pair[0]
		var stream: AudioStreamWAV=load("res://assets/audio/veyra3/%s.wav"%pair[1]).duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=stream.data.size()/2
		voice.stream=stream;voice.bus="Vehicles";voice.volume_db=-80;voice.unit_size=4;voice.max_distance=35
func update(delta: float,speed: float,throttle: float,braking: bool,condition: float,active: bool,lateral_slip: float=0) -> void:
	running=active and condition>0
	var next_gear: int=clampi(1+int(absf(speed)/9),1,5)
	if next_gear!=gear and absf(speed)>2:
		gear=next_gear;shifts+=1
		if DisplayServer.get_name()!="headless" and running:shift.play()
	load_amount=lerpf(load_amount,absf(throttle),1-exp(-delta*5))
	var target: float=800+fposmod(absf(speed),9)*240+load_amount*1300
	if vehicle_kind=="bike":target*=1.5
	rpm=lerpf(rpm,target,1-exp(-delta*4))
	var normalized: float=clampf((rpm-(1200 if vehicle_kind=="bike" else 800))/3500,0,1)
	gains=[clampf(1-normalized*3,0,1),maxf(0,1-absf(normalized-.45)*2.7),clampf((normalized-.45)*2,0,1),load_amount*.45,(1-load_amount)*clampf(absf(speed)/10,0,1)*.3]
	if braking:gains[4]*=1.4
	gains[3]+=clampf(1-condition/100,0,1)*.2
	for i: int in range(layers.size()):
		var voice:=layers[i]
		voice.pitch_scale=lerpf(voice.pitch_scale,clampf(rpm/([1200,2700,4500,2700,1500][i] if vehicle_kind=="bike" else [800,2100,3300,2100,1000][i]),.65,1.75),1-exp(-delta*5))
		voice.volume_db=linear_to_db(maxf(gains[i],.0001))+(-18 if i<3 else -24)+(2 if condition<35 else 0) if running else -80
		if DisplayServer.get_name()!="headless":
			if running and not voice.playing:voice.play()
			elif not running and voice.playing:voice.stop()
	surface_timer-=delta
	if surface_timer<=0:
		surface_timer=.25
		var body: PhysicsBody3D=get_parent()
		var query:=PhysicsRayQueryParameters3D.create(body.global_position+Vector3.UP*.5,body.global_position-Vector3.UP*1.5,CollisionLayers.STATIC|MovementAudio.SURFACE_LAYER)
		query.exclude=[body.get_rid()];query.collide_with_areas=true
		var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():surface_name=hit.collider.get_meta("foot_surface","concrete")
	rolling.volume_db=(-33+minf(10,absf(speed)*.35)+(3 if surface_name in ["concrete","warehouse"] else (-4 if surface_name in ["wood","interior"] else 0))) if running and absf(speed)>1 else -80
	rolling.pitch_scale=clampf(.8+absf(speed)*.025,.8,1.6)
	var slip: float=lateral_slip
	skid.volume_db=clampf(-38+slip*4,-38,-21) if running and slip>.8 and absf(speed)>4 else -80
	for voice: AudioStreamPlayer3D in [rolling,skid]:
		if DisplayServer.get_name()!="headless":
			if voice.volume_db>-70 and not voice.playing:voice.play()
			elif voice.volume_db<=-70 and voice.playing:voice.stop()
