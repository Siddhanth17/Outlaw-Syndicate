class_name ArrestPose
extends RiderIK
var restrained_player: ValePlayer
var enabled: bool=false
var elapsed: float=0
var hand_error: float=INF
func _process_modification_with_delta(_delta: float) -> void:
	if not enabled:return
	var skeleton:=get_skeleton()
	var facing: Basis=restrained_player.visual.global_basis.orthonormalized()
	hand_error=0
	for side: String in ["Left","Right"]:
		var sign_x: float=1 if side=="Left" else -1
		var end: int=skeleton.find_bone(side+"Hand")
		if end<0:hand_error=INF;return
		var wanted: Vector3=restrained_player.position+Vector3.UP*.92-facing.z*.22+facing.x*sign_x*.07
		var start: Vector3=skeleton.to_global(skeleton.get_bone_global_pose(end).origin)
		_solve(skeleton,side+"Arm",side+"ForeArm",side+"Hand",start.lerp(wanted,clampf(elapsed/.7,0,1)),restrained_player.position+Vector3.UP*1.05+facing.x*sign_x*.45-facing.z*.1)
		hand_error=maxf(hand_error,skeleton.to_global(skeleton.get_bone_global_pose(end).origin).distance_to(wanted))
