class_name RagdollPoseBridge
extends SkeletonModifier3D

var driver: NPCRagdoll

func _process_modification_with_delta(_delta: float) -> void:
	if not is_instance_valid(driver) or not driver.active:return
	var skeleton:=get_skeleton()
	for i: int in range(driver.cached.size()):
		var pose: Transform3D=driver.cached[i]
		skeleton.set_bone_pose_position(i,pose.origin)
		skeleton.set_bone_pose_rotation(i,pose.basis.get_rotation_quaternion())
