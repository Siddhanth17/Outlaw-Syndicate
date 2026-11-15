class_name LivingWorld
extends Node

# Persistent identities/relationships/economy; CityMemory remains sole cash owner.
# Clock, events, navigation, actors and rendering remain in their existing systems.
signal changed(kind: String, subject: String)
var game: Node3D
var identities: Dictionary={}
var relationships: Dictionary={}
var ledger: Array[Dictionary]=[]
var inventory: Dictionary={}
var bank: int=0
var next_transaction: int=1
var roster_ready: bool=false
var budget: int=28
var active_count: int=0
var abstract_count: int=0
var timer: float=0
var paths: Dictionary={}
var audio_catalog: Dictionary={}

func populate() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/living_roster.json"))
	for record: Dictionary in data.citizens:
		var actor:=CityNPC.new()
		actor.game=game
		actor.npc_id=record.id
		actor.citizen_name=record.name
		actor.appearance_id=record.appearance
		actor.schedule_config=record.duplicate(true)
		actor.position=point(record.work if record.id=="resident_00" else record.home)
		actor.daily_destinations={"home":point(record.home),"work":point(record.work),"break":point(record.rest)}
		actor.route=PackedVector3Array([actor.position,actor.position+Vector3(0,0,2)])
		game.add_child(actor)
		game.people.append(actor)
		identities[actor.npc_id]=record.duplicate(true)
	for actor: CityNPC in game.people:
		if identities.has(actor.npc_id):continue
		identities[actor.npc_id]={"id":actor.npc_id,"name":actor.citizen_name if not actor.citizen_name.is_empty() else actor.npc_id.replace("_"," ").capitalize(),"occupation":actor.profile.role,"appearance":actor.appearance_id,"recurring":true,"city_line":"The main avenue connects the harbor to Northline.","background":"Works in Veyra.","voice":"Nadia"}
	identities["dante_cross"]={"id":"dante_cross","name":"Dante Cross","occupation":"mechanic","recurring":true}
	if FileAccess.file_exists("res://data/living_voices.json"):
		audio_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/living_voices.json"))
	roster_ready=true
	refresh(0)

static func point(value: Array) -> Vector3:return Vector3(value[0],value[1],value[2])
static func valid_point(value: Variant) -> bool:
	return value is Array and value.size()==3 and value.all(func(v: Variant) -> bool:return (v is int or v is float) and is_finite(float(v)) and absf(float(v))<10000)

func actor_for(id: String) -> CityNPC:
	if id=="dante_cross":return game.dante
	for actor: CityNPC in game.people:
		if actor.npc_id==id:return actor
	return null

func interaction_target() -> CityNPC:
	if not roster_ready or game.player.driving or game.player.riding_bike:return null
	var nearest: CityNPC
	var distance: float=3.1
	for actor: CityNPC in game.people:
		if actor.abstracted or actor.health<=0 or actor.danger_time>0:continue
		var candidate: float=actor.position.distance_to(game.player.position)
		if candidate>=distance:continue
		var ray:=PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP*1.3,actor.position+Vector3.UP*1.3,CollisionLayers.STATIC|CollisionLayers.PROP)
		if not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
		nearest=actor
		distance=candidate
	return nearest

func relation(id: String) -> Dictionary:
	if not relationships.has(id):relationships[id]={"topics":[],"familiarity":0,"trust":0,"contact":false}
	return relationships[id]

func converse(id: String, topic: String) -> String:
	if not identities.has(id):return "No resident record is available."
	var actor:=actor_for(id)
	if not actor or actor.health<=0 or actor.danger_time>0 or actor.position.distance_to(game.player.position)>4:return "They cannot talk right now."
	var record: Dictionary=identities[id]
	var state:=relation(id)
	if topic=="number":
		if state.familiarity<2:return "Let's get to know each other first."
		state.contact=true
		changed.emit("contact",id)
		return "Number saved. You can find me in Contacts."
	if not topic in ["greet","job","city"]:return "I don't have anything to add."
	if not state.topics.has(topic):
		state.topics.append(topic)
		state.familiarity=mini(3,state.familiarity+1)
		state.trust=mini(3,state.trust+1)
	changed.emit("conversation",id)
	match topic:
		"greet":return "I'm %s. Good to meet you."%record.name
		"job":return "I work as a %s. %s"%[record.occupation,record.get("background","")]
	return record.get("city_line","Follow the avenue north to Northline, south to Iron Harbor.")

func transact(delta: int, category: String, subject: String) -> bool:
	if delta==0 or absi(delta)>1000000 or game.memory.money+delta<0:return false
	game.memory.money+=delta
	ledger.append({"id":next_transaction,"day":game.quarter.day,"minute":game.quarter.minutes,"amount":delta,"category":category,"subject":subject,"cash_after":game.memory.money,"bank_after":bank})
	next_transaction+=1
	if ledger.size()>128:ledger.pop_front()
	changed.emit("transaction",subject)
	return true

func transfer(amount: int, deposit: bool) -> bool:
	if amount<=0 or amount>1000000:return false
	if deposit:
		if game.memory.money<amount:return false
		bank+=amount
		return transact(-amount,"bank_deposit","account")
	if bank<amount:return false
	bank-=amount
	return transact(amount,"bank_withdrawal","account")

func cafe_available() -> bool:
	var staff:=actor_for("resident_00")
	return staff!=null and staff.health>0 and staff.danger_time<=0 and staff.schedule_period=="work" and staff.position.distance_to(point(identities.resident_00.work))<1.7

func buy_food(item: String) -> String:
	if not cafe_available():return "The counter is closed or unattended."
	if game.player.driving or game.player.riding_bike or game.player.position.distance_to(Vector3(-12.5,.34,80))>4:return "Visit the Lantern counter on foot."
	if not item in ["coffee","sandwich"]:return "That item is not on the menu."
	var cost: int=4 if item=="coffee" else 8
	if int(inventory.get(item,0))>=20:return "You cannot carry more of that item."
	if not transact(-cost,"cafe_purchase",item):return "Not enough cash. No charge made."
	inventory[item]=int(inventory.get(item,0))+1
	game.sound("living/register",game.player.position)
	return "Purchased %s for $%d. Use it from the phone inventory."%[item,cost]

func consume(item: String) -> bool:
	if not item in ["coffee","sandwich"] or int(inventory.get(item,0))<=0 or game.player.health>=100:return false
	inventory[item]-=1
	game.player.health=minf(100,game.player.health+(5 if item=="coffee" else 25))
	changed.emit("consume",item)
	return true

func set_active(actor: CityNPC, active: bool) -> void:
	actor.abstracted=not active
	actor.set_physics_process(active)
	if actor.animation:actor.animation.active=active
	if actor.dynamics:actor.dynamics.active=active
	actor.visual.visible=active and actor.health>0
	if actor.health>0:
		actor.collision_layer=CollisionLayers.NPC if active else 0
		actor.collision_mask=CollisionLayers.SOLIDS if active else 0

func abstract_step(actor: CityNPC, delta: float) -> void:
	actor.update_schedule()
	var id: String=actor.npc_id
	if not paths.has(id) or paths[id].period!=actor.schedule_period:
		paths[id]={"period":actor.schedule_period,"points":game.navigation.path(actor.position,actor.route[actor.route_index]),"index":0}
	var data: Dictionary=paths[id]
	var travel: float=float(actor.profile.pace)*delta
	while travel>0 and data.index<data.points.size():
		var target: Vector3=data.points[data.index]
		var distance: float=actor.position.distance_to(target)
		if distance<=travel:
			actor.position=target
			travel-=distance
			data.index+=1
		else:
			actor.position=actor.position.move_toward(target,travel)
			travel=0

func refresh(delta: float) -> void:
	if not roster_ready:return
	var ordered: Array[CityNPC]=game.people.duplicate()
	ordered.sort_custom(func(a: CityNPC,b: CityNPC) -> bool:return a.position.distance_squared_to(game.player.position)<b.position.distance_squared_to(game.player.position))
	active_count=0
	abstract_count=0
	for actor: CityNPC in ordered:
		var pinned: bool=actor.conversing or actor.danger_time>0 or (actor.ragdoll and actor.ragdoll.active) or actor.injury_time>0 or actor.suspicion>0
		if pinned: # Never truncate injury/physics, even if this exceeds the normal crowd budget.
			if actor.abstracted:set_active(actor,true)
			active_count+=1
			continue
		var active: bool=actor.health>0 and actor.position.distance_to(game.player.position)<115 and active_count<budget
		if actor.abstracted==active:set_active(actor,active)
		if active:active_count+=1
		elif actor.health>0:
			abstract_count+=1
			abstract_step(actor,delta)

func snapshot() -> Dictionary:
	var citizens: Dictionary={}
	for actor: CityNPC in game.people:
		citizens[actor.npc_id]={"position":[actor.position.x,actor.position.y,actor.position.z],"schedule":actor.schedule_period}
	return {"version":1,"relationships":relationships.duplicate(true),"ledger":ledger.duplicate(true),"bank":bank,"inventory":inventory.duplicate(),"next_transaction":next_transaction,"citizens":citizens}

func validate(value: Variant) -> bool:
	if value==null:return true # Legacy root version-1 checkpoints migrate to defaults.
	if not value is Dictionary or value.get("version")!=1:return false
	for key: String in ["relationships","inventory","citizens"]:
		if not value.get(key,{}) is Dictionary or value.get(key,{}).size()>128:return false
	if not value.get("ledger",[]) is Array or value.get("ledger",[]).size()>128:return false
	for key: String in ["bank","next_transaction"]:
		var number: Variant=value.get(key,0)
		if not (number is int or number is float) or not is_finite(float(number)) or float(number)<0 or float(number)>1000000000:return false
	for id: Variant in value.get("citizens",{}):
		var record: Variant=value.citizens[id]
		if not id is String or not record is Dictionary or not valid_point(record.get("position")):return false
	for id: Variant in value.get("relationships",{}):
		var record: Variant=value.relationships[id]
		if not id is String or not record is Dictionary or not record.get("topics",[]) is Array or record.get("topics",[]).size()>8:return false
	for key: Variant in value.get("inventory",{}):
		var count: Variant=value.inventory[key]
		if not key in ["coffee","sandwich"] or not (count is int or count is float) or not is_finite(float(count)) or float(count)<0 or float(count)>20:return false
	for record: Variant in value.get("ledger",[]):
		if not record is Dictionary or not record.get("category","") is String or not record.get("subject","") is String:return false
		var amount: Variant=record.get("amount",0)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or absf(float(amount))>1000000:return false
		if str(record.category).length()>64 or str(record.get("subject","")).length()>96:return false
	return true

func restore(value: Variant) -> bool:
	if not validate(value):return false
	relationships.clear();ledger.clear();inventory.clear();paths.clear()
	bank=0;next_transaction=1
	if value==null:
		refresh(0)
		return true
	bank=int(value.get("bank",0));next_transaction=maxi(1,int(value.get("next_transaction",1)))
	for id: String in value.get("relationships",{}):
		if not identities.has(id):continue
		var source: Dictionary=value.relationships[id]
		var topics: Array=[]
		for topic: Variant in source.get("topics",[]):
			if topic in ["greet","job","city"] and not topics.has(topic):topics.append(topic)
		relationships[id]={"topics":topics,"familiarity":topics.size(),"trust":topics.size(),"contact":bool(source.get("contact",false)) and topics.size()>=2}
	for record: Dictionary in value.get("ledger",[]):ledger.append(record.duplicate(true))
	for record: Dictionary in ledger:next_transaction=maxi(next_transaction,int(record.get("id",0))+1)
	for item: String in value.get("inventory",{}):inventory[item]=int(value.inventory[item])
	for id: String in value.get("citizens",{}):
		var actor:=actor_for(id)
		if actor and actor.health>0:
			actor.position=point(value.citizens[id].position)
			actor.velocity=Vector3.ZERO
			actor.schedule_period=""
			actor.update_schedule()
			actor.reset_physics_interpolation()
	refresh(0)
	return true

func _process(delta: float) -> void:
	if game.paused or game.cinematic_active:return
	timer+=delta
	if timer>=.5:
		refresh(timer)
		timer=0
