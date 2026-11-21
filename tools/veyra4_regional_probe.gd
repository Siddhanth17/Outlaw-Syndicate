extends SceneTree
var passes: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game: Node3D=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	for i: int in range(10):await physics_frame
	game.test_mode=true;game._menu_action("New game")
	var actor: CityNPC=game.law.witness("worker_01")
	actor.receive_projectile("left_leg",actor.position+Vector3.UP*.5,Vector3.FORWARD)
	var expected: Dictionary=actor.region_injuries.duplicate()
	var speed: float=actor.mobility_factor()
	check(actor.health>0 and speed<1 and speed>=.55,"regional leg injury affects a surviving actor")
	game._save();actor.region_injuries.clear();game._load()
	check(actor.region_injuries.keys()==expected.keys() and is_equal_approx(float(actor.region_injuries.get("left_leg",-1)),expected.left_leg) and is_equal_approx(actor.mobility_factor(),speed),"real JSON load restores regional movement consequence within floating point precision")
	actor.restore_regions({"unknown":1,"left_leg":INF,"right_arm":.5})
	check(actor.region_injuries=={"right_arm":.5},"invalid regional values are rejected")
	actor.restore_outcome(actor.max_health)
	check(actor.region_injuries.is_empty() and actor.mobility_factor()==1,"full-health reset clears regional penalties")
	print("REGIONAL_PERSISTENCE %d passed %d failed"%[passes,failures]);quit(1 if failures else 0)
