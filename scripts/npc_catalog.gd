class_name NPCCatalog
extends RefCounted

static var definitions: Dictionary = {}

static func profile(id: String) -> Dictionary:
	if definitions.is_empty(): definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/npc_archetypes.json"))
	return definitions.get(id,definitions.security)

static func instantiate(id: String) -> Node3D:
	return load(profile(id).model).instantiate()
