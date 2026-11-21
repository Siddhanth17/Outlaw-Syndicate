class_name LawProfile
extends Node
var game: Node3D
var active: bool=false
var previous: int=0
var started: int=0
var frames_ms: Array[float]=[]
var physics_ms: Array[float]=[]
var law_us: Array[float]=[]
var police_us: Array[float]=[]
var traffic_us: Array[float]=[]
var npc_us: Array[float]=[]
var effects_us: Array[float]=[]
var texture_bytes: float=0
var draw_calls: float=0
var slow_frames: Array[Dictionary]=[]
var pipeline_previous: Dictionary={}
var pipeline_total: Dictionary={}
const PIPELINES: Dictionary={"mesh":Performance.PIPELINE_COMPILATIONS_MESH,"surface":Performance.PIPELINE_COMPILATIONS_SURFACE,"draw":Performance.PIPELINE_COMPILATIONS_DRAW,"specialization":Performance.PIPELINE_COMPILATIONS_SPECIALIZATION}
func begin() -> void:
	active=true;started=Time.get_ticks_usec()
func _process(_delta: float) -> void:
	if not active:return
	var now: int=Time.get_ticks_usec()
	var compiled: Dictionary={}
	for key: String in PIPELINES:
		var count: int=int(Performance.get_monitor(PIPELINES[key]))
		compiled[key]=maxi(0,count-int(pipeline_previous.get(key,count)))
		pipeline_total[key]=int(pipeline_total.get(key,0))+int(compiled[key]);pipeline_previous[key]=count
	if previous>0 and now-previous>30000 and slow_frames.size()<128:
		slow_frames.append({"at_ms":now/1000.0,"frame_ms":(now-previous)/1000.0,"position":[game.player.position.x,game.player.position.y,game.player.position.z],"pipeline_delta":compiled,"recent_spans":game.profile_spans.slice(-12)})
	if previous>0:frames_ms.append((now-previous)/1000.0)
	previous=now
	physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
	texture_bytes=maxf(texture_bytes,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	draw_calls=maxf(draw_calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
func _physics_process(_delta: float) -> void:
	if not active:return
	law_us.append(game.law.simulation_us);police_us.append(game.law.unit.simulation_us)
	traffic_us.append(game.traffic.simulation_us);npc_us.append(game.living.npc_cost_us);effects_us.append(game.character_impacts.simulation_us)
func finish() -> void:
	active=false
	if frames_ms.is_empty():return
	var metrics:=ExpansionValidation.new();var stats: Dictionary=metrics.statistics(frames_ms)
	var worst: float=0;var count: int=maxi(1,int(ceil(frames_ms.size()*.01)))
	for i: int in range(frames_ms.size()-count,frames_ms.size()):worst+=frames_ms[i]
	var report: Dictionary={"transition_spans":game.profile_spans.duplicate(true),"seconds":(Time.get_ticks_usec()-started)/1000000.0,"frames":frames_ms.size(),"average_fps":1000/stats.mean,"one_percent_low_fps":1000/(worst/count),"frame_ms":stats,"all_physics_ms":metrics.statistics(physics_ms),"law_cpu_us_per_step":metrics.statistics(law_us),"police_cpu_us_per_step":metrics.statistics(police_us),"civilian_traffic_cpu_us_per_step":metrics.statistics(traffic_us),"npc_movement_cpu_us_per_step":metrics.statistics(npc_us),"effects_cpu_us_per_step":metrics.statistics(effects_us),"texture_buffer_bytes_peak":texture_bytes,"draw_calls_peak":draw_calls,"render_size":[1920,1080],"audio_dsp_cpu":"NOT MEASURED","ragdoll_cpu_isolation":"NOT MEASURED; included in aggregate physics","scope":"exported automated crime/response or pursuit lab, actual city traffic/navigation; screenshots disabled; checkpoint IO and camera/zone changes remain included; NPC timing excludes render-time animation"}
	report["slow_frames"]=slow_frames;report["pipeline_compilations_since_begin"]=pipeline_total
	DirAccess.make_dir_recursive_absolute("user://dispatch-lab")
	FileAccess.open("user://dispatch-lab/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	metrics.free();print("LAW_PERFORMANCE ",JSON.stringify(report))
