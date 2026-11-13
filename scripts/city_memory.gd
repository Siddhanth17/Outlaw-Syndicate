class_name CityMemory
extends RefCounted

var events: Dictionary = {}
var money: int = 150
var stage: int = 0
var heat: float = 0.0

func remember(id: String, consequence: Dictionary) -> bool:
	if events.has(id):
		return false
	events[id] = consequence.duplicate(true)
	money += int(consequence.get("reward", 0))
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "events": events, "money": money, "stage": stage, "heat": heat}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.get("events") is Dictionary:
		return false
	if not data.get("stage") is float and not data.get("stage") is int:
		return false
	var next_stage: int = int(data.stage)
	if next_stage < 0 or next_stage > 5:
		return false
	events = data.events.duplicate(true)
	money = maxi(0, int(data.get("money", 0)))
	stage = next_stage
	heat = clampf(float(data.get("heat", 0)), 0, 100)
	return true
