class_name WitnessPhone
extends RiderIK
var caller: CityNPC
var calling: bool=false
var elapsed: float=0
var hand_error: float=INF
var handset: Node3D
func _ready() -> void:
	var attachment:=BoneAttachment3D.new();attachment.bone_name="RightHand";get_skeleton().add_child(attachment)
	handset=load("res://assets/props/veyra_handset.glb").instantiate();attachment.add_child(handset)
	handset.top_level=true;handset.scale=Vector3.ONE;handset.hide()
func begin(progress: float=0) -> void:
	if calling:return
	calling=true;elapsed=progress;hand_error=INF
func finish() -> void:
	calling=false;elapsed=0;hand_error=INF
	if caller and caller.dynamics:caller.dynamics.has_head_target=false
	if handset:handset.hide()
func _process_modification_with_delta(_delta: float) -> void:
	if not calling or caller.health<=0:
		if handset:handset.hide()
		return
	var skeleton:=get_skeleton()
	var head: int=skeleton.find_bone("Head")
	var hand: int=skeleton.find_bone("RightHand")
	if head<0 or hand<0:return
	var crown: int=skeleton.find_bone("head_end")
	var head_center: Vector3=skeleton.get_bone_global_pose(head).origin
	if crown>=0:head_center=head_center.lerp(skeleton.get_bone_global_pose(crown).origin,.5)
	var ear: Vector3=skeleton.to_global(head_center)-caller.visual.global_basis.orthonormalized().x*.12-Vector3.UP*.055
	var start: Vector3=skeleton.to_global(skeleton.get_bone_global_pose(hand).origin)
	var wanted: Vector3=start.lerp(ear,clampf(elapsed/.4,0,1))
	_solve(skeleton,"RightArm","RightForeArm","RightHand",wanted,caller.position-caller.visual.global_basis.orthonormalized().x*.45+caller.visual.global_basis.orthonormalized().z*.25+Vector3.UP)
	hand_error=skeleton.to_global(skeleton.get_bone_global_pose(hand).origin).distance_to(ear)
	handset.global_basis=caller.visual.global_basis.orthonormalized()*Basis(Vector3.UP,-PI/2)
	handset.global_position=skeleton.to_global(skeleton.get_bone_global_pose(hand).origin)+Vector3.UP*.055
	handset.visible=elapsed>.2
