class_name HeroValidation
extends Node

var observed_long_hair:=Quaternion.IDENTITY
var long_peak: float=0
var game: Node3D
var passes: int=0
var failures: int=0

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok: passes+=1
	else: failures+=1

func frames(count: int) -> void:
	for i: int in range(count): await get_tree().physics_frame

func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://living-verification/"+name+".png")

func run() -> void:
	var player: ValePlayer=game.player
	game._leave_car(true)
	game._set_pause(false)
	player.position=Vector3(0,0.05,15)
	player.velocity=Vector3.ZERO
	player.yaw=0
	player.visual.rotation.y=PI
	player.action_time=0
	player.injuries.restore([])
	var skeleton: Skeleton3D=player.visual.find_children("*","Skeleton3D",true,false)[0]
	check(player.visual.scene_file_path.ends_with("adrian_reference.glb"),"signature hero asset integrated without overwriting base human")
	for name: String in ["LongHairBackL","LongHairBackR","LongHairSideL","LongHairSideR"]:
		check(skeleton.find_bone(name)>=0 and skeleton.find_bone(name+"Tip")>=0,"weighted long-hair spring chain: "+name)
	check(player.visual.find_children("*","MeshInstance3D",true,false).size()<=12,"signature garment and hair attachments have bounded draw meshes")
	game.cine_camera.current=true
	game.cine_camera.position=player.position+Vector3(0.65,1.65,-1.2)
	game.cine_camera.look_at(player.position+Vector3.UP*1.5)
	game.cine_camera.fov=40
	await frames(30)
	await capture("adrian-signature-close")
	game.cine_camera.position=player.position+Vector3(-0.7,1.7,1.2)
	game.cine_camera.look_at(player.position+Vector3.UP*1.6)
	await capture("adrian-half-tied-rear")
	Input.action_press("forward")
	Input.action_press("aim")
	await frames(30)
	var leg: int=skeleton.find_bone("LeftLeg")
	var before: Quaternion=skeleton.get_bone_pose_rotation(leg)
	await frames(8)
	check(player.current_animation=="AimWalk" and not before.is_equal_approx(skeleton.get_bone_pose_rotation(leg)),"aiming locomotion retains moving leg animation instead of fixed aim legs")
	Input.action_release("forward")
	var shots: int=player.recoil_impulses
	game.cooldown=0
	game.ammunition=12
	game._fire()
	check(player.recoil_impulses==shots+1 and player.recoil_offset.x<0,"actual weapon fire adds bounded camera and body recoil")
	await frames(40)
	check(player.recoil_offset.length()<0.001,"procedural recoil returns to aim without drift")
	Input.action_release("aim")
	Input.action_press("forward")
	Input.action_press("sprint")
	var chain: int=skeleton.find_bone("LongHairBackL")
	var rest: Quaternion=skeleton.get_bone_rest(chain).basis.get_rotation_quaternion()
	player.dynamics.modification_processed.connect(func() -> void:
		observed_long_hair=skeleton.get_bone_pose_rotation(chain)
		long_peak=maxf(long_peak,observed_long_hair.angle_to(rest)))
	for i: int in range(36):
		await frames(3)
		game.cine_camera.current=true
		game.cine_camera.position=player.position+Vector3(2,1.7,-3)
		game.cine_camera.look_at(player.position+Vector3.UP*1.1)
		game.cine_camera.fov=50
		if OS.get_cmdline_user_args().has("--record-living"): await capture("signature-run-%03d"%i)
	check(long_peak>0.001,"long-hair weighted chain responds during real sprint movement")
	Input.action_release("forward")
	Input.action_release("sprint")
	await frames(90)
	check(player.velocity.length()<0.2 and player.dynamics.hair_angle.length()<=0.161 and player.dynamics.hem_angle.length()<=0.251,"stop settles locomotion with bounded hair and garment springs")
	game.damage_player(6,Vector3.RIGHT)
	check(not player.injuries.marks.is_empty(),"gameplay damage creates restrained persistent injury mark")
	for i: int in range(8): player.injuries.hit(player.visual.to_global(Vector3(0,1.55,0.1)),10)
	check(player.injuries.marks.size()==4,"injury shader history is bounded")
	game._save()
	player.injuries.restore([])
	game._load()
	check(player.injuries.marks.size()==4,"checkpoint preserves player injury appearance")
	game.cine_camera.current=true
	game.cine_camera.position=player.position+Vector3(0.65,1.65,-1.2)
	game.cine_camera.look_at(player.position+Vector3.UP*1.5)
	game.cine_camera.fov=40
	await capture("injury-after-combat")
	var ground_query:=PhysicsRayQueryParameters3D.create(Vector3(206,2,0),Vector3(206,-3,0),CollisionLayers.STATIC)
	if game.get_world_3d().direct_space_state.intersect_ray(ground_query).is_empty(): game.harbor.solid(Vector3(206,-0.5,0),Vector3(20,1,20))
	var left:=HarborGuard.new()
	left.game=game
	left.position=Vector3(204,0.05,0)
	game.add_child(left)
	var right:=HarborGuard.new()
	right.game=game
	right.position=Vector3(208,0.05,0)
	game.add_child(right)
	await frames(15)
	left.receive_vehicle_contact(12,Vector3.LEFT,left.position+Vector3.UP)
	right.receive_vehicle_contact(12,Vector3.RIGHT,right.position+Vector3.UP)
	check(left.fall_axis.dot(right.fall_axis)<-0.9,"opposed impact directions select opposed knockdown axes")
	await frames(45)
	check(left.position.y>=-0.05 and right.position.y>=-0.05 and left.position.y<2 and right.position.y<2,"directional knockdown remains bounded over physical ground")
	game.cine_camera.fov=65
	game.cine_camera.position=Vector3(206,5,-9)
	game.cine_camera.look_at(Vector3(206,0.6,0))
	await capture("directional-knockdowns")
