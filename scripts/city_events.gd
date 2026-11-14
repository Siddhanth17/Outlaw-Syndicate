class_name CityEvents
extends Node

signal incident(event: Dictionary)
var game: Node3D
var recent: Dictionary = {}
var published: int = 0

func publish(kind: String, at: Vector3, severity: float, source: String = "player") -> void:
	var now: float=game.elapsed
	var cell:=Vector2i(roundi(at.x/8),roundi(at.z/8))
	var key: String=kind+source+str(cell)
	if now-float(recent.get(key,-10))<0.7: return
	recent[key]=now
	published+=1
	var event: Dictionary={"kind":kind,"position":at,"severity":severity,"source":source,"sequence":published}
	incident.emit(event)
	if kind in ["vehicle_person","gunshot"]:
		var id: String="harbor_incident_"+kind+str(cell)
		game.memory.remember(id,{"kind":kind,"district":"iron_harbor","severity":clampf(severity,0,100)})
	# Keep transient dedup state bounded, independent of the checkpoint log.
	if recent.size()>64:
		for old: Variant in recent.keys():
			if now-float(recent[old])>8: recent.erase(old)
	while recent.size()>96: recent.erase(recent.keys()[0])
