class_name MotionAudit
extends Node
var game: Node3D
var origins: Dictionary={}
var samples: Array=[]
func run() -> void:
	for i: int in range(6):await get_tree().physics_frame
	game._menu_action("New game")
	game.player.position=Vector3(0,.2,92)
	game.player.yaw=PI
	game.player.pitch=-.12
	game.player.camera.current=true
	game.quarter.minutes=600
	game.quarter.apply_clock()
	game.living.refresh(0)
	for actor: CityNPC in game.people:origins[actor.npc_id]=actor.position
	DirAccess.make_dir_recursive_absolute("user://motion-audit")
	for second: int in range(31):
		var rows: Array=[]
		for actor: CityNPC in game.people:
			var row: Dictionary={"id":actor.npc_id,"position":[actor.position.x,actor.position.y,actor.position.z],"distance":actor.position.distance_to(origins[actor.npc_id]),"active":not actor.abstracted,"speed":Vector2(actor.velocity.x,actor.velocity.z).length(),"schedule":actor.schedule_period,"path_size":actor.path_points.size(),"path_index":actor.path_index,"collisions":actor.get_slide_collision_count()}
			if actor.has_method("diagnostic"):row.merge(actor.diagnostic())
			rows.append(row)
		samples.append({"second":second,"citizens":rows})
		if second in [0,10,20,30] and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://motion-audit/gameplay-%02d.png"%second)
		if second<30:
			for i: int in range(60):await get_tree().physics_frame
	FileAccess.open("user://motion-audit/samples.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	for row: Dictionary in samples.back().citizens:print("MOTION ",JSON.stringify(row))
	get_tree().quit()
