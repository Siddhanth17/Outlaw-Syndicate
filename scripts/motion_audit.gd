class_name MotionAudit
extends Node
var game: Node3D
var origins: Dictionary={}
var samples: Array=[]
func run() -> void:
	game.test_mode=true
	if DisplayServer.get_name()!="headless":
		get_window().content_scale_size=Vector2i(1920,1080)
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	for i: int in range(6):await get_tree().physics_frame
	game._menu_action("New game")
	game.player.position=Vector3(0,.2,92)
	game.player.yaw=PI
	if OS.get_cmdline_user_args().has("--audit-worker"):
		game.player.position=Vector3(-8,.2,85)
		game.player.yaw=0
	game.player.pitch=-.12
	game.player.camera.current=true
	game.quarter.minutes=600
	game.quarter.apply_clock()
	game.living.refresh(0)
	for actor: CityNPC in game.people:origins[actor.npc_id]=actor.position
	DirAccess.make_dir_recursive_absolute("user://motion-audit")
	var seconds: int=12 if OS.get_cmdline_user_args().has("--audit-worker") else 30
	if OS.get_cmdline_user_args().has("--probe-nav"):seconds=0
	for second: int in range(seconds+1):
		var rows: Array=[]
		for actor: CityNPC in game.people:
			var row: Dictionary={"id":actor.npc_id,"position":[actor.position.x,actor.position.y,actor.position.z],"distance":actor.position.distance_to(origins[actor.npc_id]),"active":not actor.abstracted,"speed":Vector2(actor.velocity.x,actor.velocity.z).length(),"schedule":actor.schedule_period,"path_size":actor.path_points.size(),"path_index":actor.path_index,"collisions":actor.get_slide_collision_count()}
			if actor.has_method("diagnostic"):row.merge(actor.diagnostic())
			rows.append(row)
		samples.append({"second":second,"citizens":rows})
		if second in [0,10,20,30] and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://motion-audit/gameplay-%02d.png"%second)
		if second<seconds:
			for i: int in range(60):await get_tree().physics_frame
	FileAccess.open("user://motion-audit/samples.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	if OS.get_cmdline_user_args().has("--audit-worker"):
		var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(1.5,1.4,1.5);query.shape=shape
		query.transform=Transform3D(Basis.IDENTITY,Vector3(-14,1.1,80));query.collision_mask=CollisionLayers.STATIC
		print("CAFE_CELL ",game.navigation.grid.is_point_solid(Vector2i(-7,40))," path=",game.navigation.path(Vector3(-10,.2,76),Vector3(-14.5,.36,80)))
		for hit: Dictionary in game.get_world_3d().direct_space_state.intersect_shape(query,8):print("CAFE_BLOCKER ",hit.collider," at=",hit.collider.global_position," basis=",hit.collider.global_basis)
		var ground:=PhysicsRayQueryParameters3D.create(Vector3(-14,2,80),Vector3(-14,-1,80),CollisionLayers.STATIC)
		print("CAFE_GROUND ",game.get_world_3d().direct_space_state.intersect_ray(ground))
		for z: int in [78,80,82]:
			query.transform.origin=Vector3(-12,1.1,z)
			var edge:=PhysicsRayQueryParameters3D.create(Vector3(-12,2,z),Vector3(-12,-1,z),CollisionLayers.STATIC)
			print("CAFE_DOOR ",z," grid_solid=",game.navigation.grid.is_point_solid(Vector2i(-6,z/2))," ground=",game.get_world_3d().direct_space_state.intersect_ray(edge)," hits=",game.get_world_3d().direct_space_state.intersect_shape(query,2))
	for row: Dictionary in samples.back().citizens:print("MOTION ",JSON.stringify(row))
	get_tree().quit()
