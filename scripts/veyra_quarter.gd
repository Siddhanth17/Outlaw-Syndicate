class_name VeyraQuarter
extends Node3D

# Persistent gameplay/collisions stay resident. Only decorative GLB sectors stream.
const XS: Array[float]=[-140,-70,0,72,142]
const ZS: Array[float]=[58,138,218]
var game: Node3D
var centers: Array[Vector3]=[]
var sectors: Dictionary={}
var kits: Array[PackedScene]=[]
var check_time: float=0
var minutes: float=1080
var day: int=1
var clock_time: float=0
var lamps: Array[OmniLight3D]=[]
var signal_lights: Array[MeshInstance3D]=[]
var load_count: int=0
var unload_count: int=0

func frontage_yaw(dx: float, dz: float) -> float:
	if dz<0:return PI if dx<0 else PI/2
	return -PI/2 if dx<0 else 0.0

func _ready() -> void:
	for i: int in range(4): kits.append(load("res://assets/environment/urban_frontage_%d.glb"%i))
	var harbor: IronHarbor=game.harbor
	harbor.solid(Vector3(1,-0.55,144),Vector3(316,1,190))
	harbor.surface(Vector3(1,-0.045,144),Vector2(316,190),"concrete",Color(.5,.5,.48),3,.9)
	for x: float in XS:
		harbor.surface(Vector3(x,.06,140),Vector2(14,178),"asphalt",Color.WHITE,3,.7)
	for z: float in ZS:
		harbor.surface(Vector3(1,.061,z),Vector2(296,14),"asphalt",Color.WHITE,3,.7)
	for row: int in range(2):
		for col: int in range(4):
			var center:=Vector3([-35,36,-105,107][col],0,98+row*80)
			centers.append(center)
			for dx: float in [-24,24]: harbor.solid(center+Vector3(dx,2,0),Vector3(.32,4,.32))
			for dx: float in [-6,6]: harbor.solid(center+Vector3(dx,.42,0),Vector3(2,.6,.5))
			harbor.solid(center+Vector3.UP*.065,Vector3(56,.13,66))
			harbor.surface(center+Vector3.UP*.136,Vector2(56,66),"concrete",Color(.7,.69,.64),2,.85)
			for dx: float in [-14,14]:
				for dz: float in [-18,18]:
					if center.x==-105 and dx==-14 and dz==-18:continue # Vale residence has its own modeled shell/collisions.
					var pose:=Transform3D(Basis(Vector3.UP,frontage_yaw(dx,dz)),center+Vector3(dx,.14,dz))
					var floor_body:=harbor.solid(pose*Vector3(0,.1,0),Vector3(18,.2,18))
					floor_body.set_meta("foot_surface","interior")
					# The modeled upper floor must also be physical for camera clearance
					# and acoustic enclosure queries inside the ground-floor shop.
					harbor.solid(pose*Vector3(0,3.4,0),Vector3(18,.2,18))
					var shop_light:=OmniLight3D.new()
					shop_light.position=pose*Vector3(0,2.4,7)
					shop_light.light_color=Color(1,.73,.42)
					shop_light.omni_range=6
					shop_light.distance_fade_enabled=true
					shop_light.distance_fade_begin=30
					shop_light.distance_fade_length=15
					shop_light.set_meta("night_energy",1.8)
					add_child(shop_light)
					lamps.append(shop_light)
					# Wall proxies match modeled shop openings. No filled building hull.
					for wall: Array in [[Vector3(-8.8,5,0),Vector3(.4,10,18)],[Vector3(8.8,5,0),Vector3(.4,10,18)],[Vector3(0,5,-8.8),Vector3(18,10,.4)],[Vector3(0,1.6,4.5),Vector3(18,3.2,.25)],[Vector3(-5.8,1.6,8.9),Vector3(5.5,3.2,.25)],[Vector3(5.8,1.6,8.9),Vector3(5.5,3.2,.25)]]:
						var body:=harbor.solid(pose*wall[0],wall[1])
						body.basis=pose.basis
					MovementAudio.region(self,pose*Vector3(0,.04,6.5),Vector3(16,.02,4),"interior")
	# Crossings, center lines and parking bays are modeled paint, without collision.
	for x: float in XS:
		for z: float in ZS:
			for axis: int in range(2):
				for side: int in [-1,1]:
					for k: int in range(8):
						var offset:=Vector3(-5.25+k*1.5,0,side*10)
						if axis==1: offset=Vector3(offset.z,0,offset.x)
						paint(Vector3(x,.074,z)+offset,Vector2(.65,3.2) if axis==0 else Vector2(3.2,.65),Color(.73,.72,.65))
			for axis: int in range(1):
				var pole: Node3D=game.harbor.asset("environment/streetlamp",Vector3(x+9,.14,z+11))
				pole.set_meta("quarter_lamp",true)
				var lamp:=OmniLight3D.new()
				lamp.position=Vector3(x+8,6,z+9)
				lamp.light_color=Color(1,.67,.38)
				lamp.omni_range=17
				lamp.light_energy=5
				lamp.distance_fade_enabled=true
				lamp.distance_fade_begin=45
				lamp.distance_fade_length=15
				add_child(lamp)
				lamps.append(lamp)
	for x: float in XS:
		for z: int in range(74,208,8):
			if abs(z-138)<12: continue
			paint(Vector3(x,.075,z),Vector2(.12,3),Color(.75,.64,.39))
	for z: float in ZS:
		for x: int in range(-126,134,8):
			if abs(x)<12:continue
			paint(Vector3(x,.075,z),Vector2(3,.12),Color(.75,.64,.39))
	# Harbor terminus: visible physical safety barriers separate background scenery.
	for x: float in [-70,0,72]:
		for dx: float in [-4,0,4]:
			game.harbor.asset("environment/urban_barrier",Vector3(x+dx,0,-205),PI/2)
		game.harbor.solid(Vector3(x,.5,-205),Vector3(13,1,.76))
	# Explicit production boundaries: connected T-junctions remain traversable;
	# straight-ahead roadworks cannot lead a player off the physical city plate.
	for x: float in XS:
		for dx: float in [-4,0,4]:game.harbor.asset("environment/urban_barrier",Vector3(x+dx,.14,232))
		game.harbor.solid(Vector3(x,.64,232),Vector3(13,1,.76))
	for z: float in ZS:
		for x: float in [-154,156]:
			for dz: float in [-4,0,4]:game.harbor.asset("environment/urban_barrier",Vector3(x,.14,z+dz),PI/2)
			game.harbor.solid(Vector3(x,.64,z),Vector3(.76,1,13))
	var closure:=Label3D.new();closure.text="VEYRA CENTRAL / ROADWORKS";closure.position=Vector3(0,2,231);closure.rotation.y=PI;closure.font_size=36;closure.pixel_size=.009;add_child(closure)
	refresh(true)

func paint(at: Vector3, size: Vector2, color: Color) -> void:
	var mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=size
	mesh.mesh=plane
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=.85
	mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position=at
	add_child(mesh)

func refresh(all_now: bool=false) -> void:
	var began: int=Time.get_ticks_usec()
	_refresh_impl(all_now)
	game.profile_step("stream.sector",began)

func _refresh_impl(all_now: bool=false) -> void:
	var at: Vector3=game.player.position
	for i: int in range(centers.size()):
		var distance: float=Vector2(at.x-centers[i].x,at.z-centers[i].z).length()
		if not sectors.has(i) and distance<155:
			var sector:=Node3D.new()
			add_child(sector)
			sector.position=centers[i]
			for a: int in range(4):
				if centers[i].x==-105 and a==0:continue
				var model: Node3D=kits[(i+a)%4].instantiate()
				sector.add_child(model)
				model.position=Vector3(-14 if a%2==0 else 14,.14,-18 if a<2 else 18)
				model.rotation.y=frontage_yaw(model.position.x,model.position.z)
				for part: Node in model.find_children("*","MeshInstance3D",true,false):
					for surface: int in range(part.mesh.get_surface_count()):
						var original: Material=part.get_active_material(surface)
						if not original is StandardMaterial3D: continue
						if original.resource_name.contains("Brick") or original.resource_name.contains("stucco") or original.resource_name.contains("limestone"):
							var finish: StandardMaterial3D=original.duplicate()
							finish.albedo_color=Color(.72,.68,.57) if original.resource_name.contains("limestone") else ([Color(.48,.18,.10),Color(.58,.62,.48),Color(.35,.22,.16),Color(.70,.57,.36)][(i+a)%4])
							part.set_surface_override_material(surface,finish)
			for dx: float in [-6,6]:
				var bench: Node3D=load("res://assets/environment/urban_bench.glb").instantiate()
				sector.add_child(bench)
				bench.position=Vector3(dx,.14,0)
			for dx: float in [-24,24]:
				var tree: Node3D=load("res://assets/environment/urban_tree.glb").instantiate()
				sector.add_child(tree)
				tree.position=Vector3(dx,.14,0)
			sectors[i]=sector
			load_count+=1
			if not all_now: break # At most one visual sector instantiated per update.
		elif sectors.has(i) and distance>190:
			sectors[i].queue_free()
			sectors.erase(i)
			unload_count+=1

func daylight() -> float:
	return smoothstep(-.1,.25,sin((minutes/1440.0-.25)*TAU))

func apply_clock() -> void:
	var day:=daylight()
	var env: Environment=game.harbor.environment.environment
	env.ambient_light_color=Color(.22,.35,.55).lerp(Color(.62,.71,.85),day)
	env.ambient_light_energy=lerpf(.36,.45,day)
	env.tonemap_exposure=lerpf(1.25,.9,day)
	env.fog_light_color=Color(.09,.16,.24).lerp(Color(.58,.68,.77),day)
	env.fog_density=lerpf(.004,.0007,day)
	var sky_material: ShaderMaterial=env.sky.sky_material
	sky_material.set_shader_parameter("daylight",day)
	game.harbor.celestial.light_energy=lerpf(.65,1.2,day)
	game.harbor.celestial.light_color=Color(.34,.49,.72).lerp(Color(1,.9,.73),day)
	game.harbor.celestial.rotation.x=deg_to_rad(-20-day*36)
	for light: OmniLight3D in lamps: light.light_energy=float(light.get_meta("night_energy",5))*(1-day)
	for light: Light3D in game.harbor.local_lights: light.light_energy=(7 if light is OmniLight3D else 8)*(1-day)

func _process(delta: float) -> void:
	if game.paused or game.cinematic_active:return
	var advanced: float=minutes+delta*.5
	day+=int(advanced/1440)
	minutes=fposmod(advanced,1440)
	check_time-=delta
	clock_time-=delta
	if check_time<=0:
		refresh()
		check_time=.2
	if clock_time<=0:
		apply_clock()
		clock_time=1
