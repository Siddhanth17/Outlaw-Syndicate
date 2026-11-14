class_name RiderIK
extends SkeletonModifier3D

# Targets come from the original motorcycle mesh's authored contact points.
# Solve in skeleton space, preserving the imported centimeter rig and limb lengths.
var bike: HarborMotorcycle
var errors: Dictionary = {}

func _process_modification_with_delta(_delta: float) -> void:
	if not is_instance_valid(bike) or not bike.rider or not bike.rider.riding_bike: return
	var sk := get_skeleton()
	var hips := sk.find_bone("Hips")
	if hips < 0: return
	var wanted := sk.to_local(bike.contact_point("seat"))
	var shift := wanted - sk.get_bone_global_pose(hips).origin
	var parent := sk.get_bone_parent(hips)
	var parent_basis := sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	sk.set_bone_pose_position(hips, sk.get_bone_pose_position(hips) + parent_basis.inverse() * shift)
	# Lean the torso from the lowest spine joint, rather than stretching arms.
	var spine: int=-1
	for i: int in range(sk.get_bone_count()):
		if sk.get_bone_parent(i)==hips and sk.get_bone_name(i).begins_with("Spine"): spine=i
	if spine>=0:
		var forward:=sk.global_basis.inverse()*bike.model.global_basis.z
		var up:=sk.global_basis.inverse()*bike.model.global_basis.y
		_rotate(sk,spine,up,up.rotated(up.cross(forward).normalized(),0.55))
	var head:=sk.find_bone("Head")
	if head>=0:
		_rotate(sk,head,sk.get_bone_global_pose(head).basis.y,sk.global_basis.inverse()*bike.model.global_basis.y)
	for side: String in ["Left", "Right"]:
		var sign_x: float = 1 if side == "Left" else -1
		_solve(sk, side+"Arm", side+"ForeArm", side+"Hand", bike.contact_point(side+"Hand"), bike.model.to_global(Vector3(sign_x*0.48,0.98,0.1)))
		_solve(sk, side+"UpLeg", side+"Leg", side+"Foot", bike.contact_point(side+"Foot"), bike.model.to_global(Vector3(sign_x*0.42,0.5,0.15)))
		var foot:=sk.find_bone(side+"Foot")
		var toe:=sk.find_bone(side+"ToeBase")
		if foot>=0 and toe>=0:
			_rotate(sk,foot,sk.get_bone_global_pose(toe).origin-sk.get_bone_global_pose(foot).origin,sk.global_basis.inverse()*(bike.model.global_basis.z-bike.model.global_basis.y*0.08))

func _rotate(sk: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	if from.length_squared() < 0.000001 or to.length_squared() < 0.000001: return
	var pose := sk.get_bone_global_pose(bone)
	var rotation := Quaternion(from.normalized(), to.normalized()) * pose.basis.orthonormalized().get_rotation_quaternion()
	var parent := sk.get_bone_parent(bone)
	var parent_rotation := sk.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
	sk.set_bone_pose_rotation(bone, parent_rotation.inverse() * rotation)

func _solve(sk: Skeleton3D, upper_name: String, lower_name: String, end_name: String, target_world: Vector3, pole_world: Vector3) -> void:
	var a := sk.find_bone(upper_name)
	var b := sk.find_bone(lower_name)
	var c := sk.find_bone(end_name)
	if mini(a,mini(b,c)) < 0: return
	var root := sk.get_bone_global_pose(a).origin
	var middle := sk.get_bone_global_pose(b).origin
	var end := sk.get_bone_global_pose(c).origin
	var target := sk.to_local(target_world)
	var l1 := root.distance_to(middle)
	var l2 := middle.distance_to(end)
	var distance := clampf(root.distance_to(target),absf(l1-l2)+0.01,l1+l2-0.01)
	var axis := root.direction_to(target)
	var pole := sk.to_local(pole_world)-root
	var bend := (pole-axis*pole.dot(axis)).normalized()
	if bend.length_squared()<0.1: bend=axis.cross(Vector3.RIGHT).normalized()
	var along := (l1*l1-l2*l2+distance*distance)/(2*distance)
	var elbow := root+axis*along+bend*sqrt(maxf(0,l1*l1-along*along))
	_rotate(sk,a,middle-root,elbow-root)
	middle=sk.get_bone_global_pose(b).origin
	end=sk.get_bone_global_pose(c).origin
	_rotate(sk,b,end-middle,target-middle)
	errors[end_name]=sk.to_global(sk.get_bone_global_pose(c).origin).distance_to(target_world)
