class_name DamageInspector
extends CanvasLayer
var game: Node3D
var label: Label
func _ready() -> void:
	layer=40
	var panel:=PanelContainer.new();panel.position=Vector2(24,190);add_child(panel)
	label=Label.new();label.custom_minimum_size=Vector2(380,180);label.add_theme_font_size_override("font_size",16);panel.add_child(label)
func _process(_delta: float) -> void:
	label.text="DAMAGE INSPECTOR / developer only\n"
	if game.damage_events.is_empty():label.text+="No registered projectile hit";return
	var event: Dictionary=game.damage_events[-1]
	for key: String in ["npc_id","region","weapon","before","applied","after","protection","critical","protected_story","state","defeated"]:label.text+="%s: %s\n"%[key,str(event[key])]
