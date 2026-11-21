class_name TransitionValidation
extends Node
var game: Node3D
var passes: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	print(("PASS " if ok else "FAIL ")+message)
	if ok:passes+=1
	else:failures+=1
func frames(n: int) -> void:
	for i: int in range(n):await get_tree().physics_frame
func run() -> void:
	game.test_mode=true;await frames(10);game._menu_action("New game")
	var damage: VehicleDamage=game.car.damage
	game.car.repair()
	var count: int=damage.geometry_rebuild_count
	for i: int in range(8):game.car.restore_damage({})
	check(damage.geometry_rebuild_count==count,"eight pristine restores perform no vertex rebuild or normal regeneration")
	check(damage.parts.all(func(part: Dictionary) -> bool:return part.node.mesh==part.rest),"pristine vehicles reuse their exact immutable authored meshes")
	check(damage.mark_pool.is_empty(),"restoring an unshot vehicle does not allocate a bullet decal pool")
	damage.impact(Vector3(0,0,2),Vector3.BACK,15,false)
	check(damage.geometry_rebuild_count>count and damage.max_displacement>.01,"real dent impacts still deform actual vehicle geometry")
	var saved: Dictionary=game.car.damage_snapshot()
	game.car.repair();game.car.restore_damage(saved)
	check(damage.max_displacement>.01 and damage.hits.size()==saved.hits.size(),"damaged-state restoration keeps localized mesh deformation")
	game.car.restore_damage({})
	check(damage.max_displacement==0 and damage.parts.all(func(part: Dictionary) -> bool:return part.node.mesh==part.rest),"repairing a deformed car restores every original surface")
	game.car.restore_damage({"windows":[80,0,0,0,0,0],"tires":[85,0,0,0],"lights":[80,0,0,0]})
	check(damage.glass[0].state==3 and not damage.glass[0].node.visible and damage.tires[0]==85 and damage.light_damage[0]==80,"pristine mesh optimization preserves independent glass, tire and lamp damage")
	game.car.repair();game._save();game._load()
	check(game.car.damage.max_displacement==0 and game.law.stage=="free","real checkpoint load preserves the pristine vehicle and normal free roam")
	print("TRANSITION_VALIDATION %d passed %d failed"%[passes,failures]);get_tree().quit(1 if failures else 0)
