class_name CityLaw
extends Node

# Witness-report foundation. Existing combat/search AI remains independently active.
# This registry does not yet dispatch units, impose fines or implement pursuit.
const KINDS: Array[String]=["gunshot","vehicle_person","defeat"]
const LIMIT: int=64
var game: Node3D
var records: Array[Dictionary]=[]
var next_id: int=1

func _ready() -> void:
	game.events.incident.connect(observe)

func witness(id: String) -> CityNPC:
	for actor: CityNPC in game.people:
		if actor.npc_id==id:return actor
	return null

func eligible(actor: CityNPC) -> bool:
	return actor.health>0 and not actor.abstracted and actor.state not in [HarborGuard.State.DEFEATED,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER] and actor.injury_time<=0

func witnesses(at: Vector3) -> Array[String]:
	var ids: Array[String]=[]
	for actor: CityNPC in game.people:
		if not eligible(actor) or actor.position.distance_to(at)>28:continue
		var ray:=PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*1.4,at+Vector3.UP,CollisionLayers.STATIC|CollisionLayers.PROP|CollisionLayers.VEHICLE)
		ray.exclude=[actor.get_rid()]
		if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():ids.append(actor.npc_id)
	return ids

func observe(event: Dictionary) -> void:
	if event.get("source")!="player" or not event.get("kind") in KINDS:return
	var at: Vector3=event.position
	var ids: Array[String]=witnesses(at)
	records.append({"id":next_id,"kind":event.kind,"position":[at.x,at.y,at.z],"severity":clampf(float(event.severity),0,100),"witnesses":ids,"status":"pending" if not ids.is_empty() else "unreported","remaining":2.0})
	next_id+=1
	if records.size()>LIMIT:records.pop_front()

func _physics_process(delta: float) -> void:
	if game.paused or game.cinematic_active:return
	for record: Dictionary in records:
		if record.status!="pending":continue
		record.remaining=maxf(0,float(record.remaining)-delta)
		if record.remaining>0:continue
		var callers: Array[String]=[]
		for id: String in record.witnesses:
			var actor: CityNPC=witness(id)
			if actor and actor.health>0 and actor.injury_time<=0 and actor.state not in [HarborGuard.State.DEFEATED,HarborGuard.State.KNOCKED_DOWN,HarborGuard.State.RECOVER]:callers.append(id)
		record.status="reported" if not callers.is_empty() else "unreported"
		record.witnesses=callers

func reported_count() -> int:
	return records.filter(func(record: Dictionary) -> bool:return record.status=="reported").size()

func snapshot() -> Dictionary:return {"version":1,"next_id":next_id,"records":records.duplicate(true)}

func whole(value: Variant,low: int,high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high and float(value)==floor(float(value))

func validate(value: Variant) -> bool:
	if value==null:return true
	if not value is Dictionary or value.get("version")!=1 or not whole(value.get("next_id"),1,1000000000) or not value.get("records") is Array or value.records.size()>LIMIT:return false
	var previous: int=0
	for record: Variant in value.records:
		if not record is Dictionary or not whole(record.get("id"),previous+1,int(value.next_id)-1) or not record.get("kind") in KINDS or not LivingWorld.valid_point(record.get("position")):return false
		previous=int(record.id)
		if not record.get("status") in ["pending","reported","unreported"] or not record.get("witnesses") is Array or record.witnesses.size()>64:return false
		for id: Variant in record.witnesses:
			if not id is String or not witness(id) or record.witnesses.count(id)!=1:return false
		if record.status in ["pending","reported"] and record.witnesses.is_empty():return false
		for key: String in ["severity","remaining"]:
			var number: Variant=record.get(key)
			if not (number is float or number is int) or not is_finite(float(number)) or number<0 or number>(100 if key=="severity" else 2):return false
	return true

func restore(value: Variant) -> void:
	records.clear();next_id=1
	if value is Dictionary:
		next_id=int(value.next_id)
		for record: Dictionary in value.records:records.append(record.duplicate(true))
