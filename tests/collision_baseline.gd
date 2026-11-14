extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
 for i in range(n): await physics_frame
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 game._set_pause(false);await frames(30)
 var q:=PhysicsRayQueryParameters3D.create(Vector3(-17,1,22),Vector3(-13,1,22))
 print("BASELINE fence ray solid=",not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty())
 q=PhysicsRayQueryParameters3D.create(Vector3(12,0.9,24),Vector3(14,0.9,24))
 print("BASELINE cargo ray solid=",not game.get_world_3d().direct_space_state.intersect_ray(q).is_empty())
 var old:float=game.player.yaw
 var event:=InputEventMouseMotion.new();event.relative=Vector2(120,40);event.screen_relative=event.relative;event.position=Vector2(640,360)
 Input.parse_input_event(event);await frames(2)
 print("BASELINE mouse yaw delta=",game.player.yaw-old)
 var img:=get_root().get_texture().get_image() if DisplayServer.get_name()!="headless" else null
 if img: img.save_png("res://tests/artifacts/collision-baseline.png")
 quit()
