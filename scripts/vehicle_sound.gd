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
func setup(idle: AudioStreamPlayer3D,kind: String) -> void:
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
func update(delta: float,speed: float,throttle: float,braking: bool,condition: float,active: bool) -> void:
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
	for i: int in range(layers.size()):
		var voice:=layers[i]
		voice.pitch_scale=lerpf(voice.pitch_scale,clampf(rpm/([1200,2700,4500,2700,1500][i] if vehicle_kind=="bike" else [800,2100,3300,2100,1000][i]),.65,1.75),1-exp(-delta*5))
		voice.volume_db=linear_to_db(maxf(gains[i],.0001))-23+(2 if condition<35 else 0) if running else -80
		if DisplayServer.get_name()!="headless":
			if running and not voice.playing:voice.play()
			elif not running and voice.playing:voice.stop()
