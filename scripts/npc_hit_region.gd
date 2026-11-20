class_name NPCHitRegion
extends Area3D
const LAYER: int=2048
static var profiles: Dictionary={}
var actor: HarborGuard
var region: String

static func rules() -> Dictionary:
	if profiles.is_empty():profiles=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_profiles.json"))
	return profiles

static func install(owner_actor: HarborGuard,skeleton: Skeleton3D) -> Array[NPCHitRegion]:
	var regions: Array[NPCHitRegion]=[]
	var segments: Dictionary=NPCRagdoll.SEGMENTS.duplicate(true)
	segments["neck"]=["Head",.045,1]
	var unit: float=skeleton.global_basis.get_scale().x
	for bone: String in segments:
		var id: int=skeleton.find_bone(bone)
		var end: int=skeleton.find_bone(segments[bone][0])
		if id<0 or end<0:continue
		var label: String="upper_torso"
		if bone=="Head":label="head"
		elif bone=="neck":label="neck"
		elif bone=="Hips":label="lower_torso"
		elif bone.begins_with("Left"):label="left_leg" if bone.contains("Leg") else "left_arm"
		elif bone.begins_with("Right"):label="right_leg" if bone.contains("Leg") else "right_arm"
		var attachment:=BoneAttachment3D.new();attachment.bone_name=bone;skeleton.add_child(attachment)
		var area:=NPCHitRegion.new();area.actor=owner_actor;area.region=label
		area.collision_layer=LAYER;area.collision_mask=0;area.monitoring=false;area.monitorable=false
		attachment.add_child(area)
		var rest: Transform3D=skeleton.get_bone_global_rest(id)
		var vector: Vector3=rest.basis.inverse()*(skeleton.get_bone_global_rest(end).origin-rest.origin)
		var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
		capsule.radius=(.075 if label=="head" else float(segments[bone][1]))/unit
		capsule.height=maxf(capsule.radius*2,vector.length()*.85)
		if label in ["upper_torso","lower_torso"]:
			var box:=BoxShape3D.new()
			box.size=Vector3(capsule.radius*2,maxf(vector.length()*.98,.01),capsule.radius*2)
			shape.shape=box
		else:shape.shape=capsule
		shape.position=vector*.5
		if vector.length()>.001:shape.quaternion=Quaternion(Vector3.UP,vector.normalized())
		area.add_child(shape);regions.append(area)
	return regions

func receive_hit(at: Vector3,direction: Vector3) -> void:
	actor.receive_projectile(region,at,direction)
