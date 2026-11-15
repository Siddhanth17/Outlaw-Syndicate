class_name CityDiagnostics
extends CanvasLayer
# Developer-only overlay: enabled explicitly with --city-debug, absent from release HUD.
var game: Node3D
var label: Label
var timer: float=0
func _ready() -> void:
	label=Label.new()
	label.position=Vector2(16,175)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color(1,.9,.5))
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_outline_size",4)
	add_child(label)
func _process(delta: float) -> void:
	timer-=delta
	if timer>0 or not game.living.roster_ready:return
	timer=.3
	var actors: Array[CityNPC]=game.people.duplicate()
	actors.sort_custom(func(a: CityNPC,b: CityNPC) -> bool:return a.position.distance_squared_to(game.player.position)<b.position.distance_squared_to(game.player.position))
	var lines: Array[String]=["DEVELOPER / motion diagnostics","Active %d / budget %d; abstract %d"%[game.living.active_count,game.living.budget,game.living.abstract_count]]
	for actor: CityNPC in actors.slice(0,6):
		var d:=actor.diagnostic()
		lines.append("%s / %s | %s / %s | v %.2f | stuck %.1fs | %s"%[actor.npc_id,actor.citizen_name,d.state,d.navigation,actor.get_real_velocity().length(),d.stuck_seconds,str(d.destination)])
	for i: int in range(mini(2,game.traffic.cars.size())):lines.append("car%d %.2fm/s / %s"%[i,game.traffic.cars[i].linear_velocity.length(),game.traffic.reasons[i]])
	label.text="\n".join(lines)
