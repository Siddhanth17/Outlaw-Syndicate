class_name NPCRagdoll
extends Node3D

# Meter-scale physical rig drives the preserved centimeter-scale visual rig.
# No imported meshes, bone rest data, animation clips or skin binds are rewritten.
const LAYER: int = 512
const SEGMENTS: Dictionary={
	"Hips":["Spine02",0.105,12.0],"Spine02":["Spine01",0.09,8.0],
	"Spine01":["Spine",0.09,8.0],"Spine":["neck",0.10,9.0],
	"Head":["head_end",0.075,5.0],
	"LeftArm":["LeftForeArm",0.045,2.2],"RightArm":["RightForeArm",0.045,2.2],
	"LeftForeArm":["LeftHand",0.037,1.6],"RightForeArm":["RightHand",0.037,1.6],
	"LeftUpLeg":["LeftLeg",0.063,6.0],"RightUpLeg":["RightLeg",0.063,6.0],
	"LeftLeg":["LeftFoot",0.049,4.5],"RightLeg":["RightFoot",0.049,4.5]}
var actor: HarborGuard
var visual_skeleton: Skeleton3D
var proxy: Skeleton3D
var simulator: PhysicalBoneSimulator3D
var bridge: RagdollPoseBridge
var bones: Dictionary={}
var cached: Array[Transform3D]=[]
var active: bool=false
var settled: bool=false
var age: float=0
var quiet_time: float=0
var unit_scale: float=0.01
var peak_joint_gap: float=0
var frozen: bool=false
var built: bool=false
var limit_diagnostic: String=""
var links: Array[Dictionary]=[]
var pause_velocities: Dictionary={}
var paused_physics: bool=false

func setup(owner_actor: HarborGuard, skeleton: Skeleton3D) -> void:
	actor=owner_actor
	visual_skeleton=skeleton
	unit_scale=skeleton.global_basis.get_scale().x

func _build() -> void:
	var skeleton: Skeleton3D=visual_skeleton
	built=true
	proxy=Skeleton3D.new()
	proxy.name="MeterScalePhysicalSkeleton"
	add_child(proxy)
	for i: int in range(skeleton.get_bone_count()):
		proxy.add_bone(skeleton.get_bone_name(i))
		proxy.set_bone_parent(i,skeleton.get_bone_parent(i))
		var rest:=skeleton.get_bone_rest(i)
		rest.origin*=unit_scale
		rest.basis=rest.basis.orthonormalized()
		proxy.set_bone_rest(i,rest)
	proxy.reset_bone_poses()
	simulator=PhysicalBoneSimulator3D.new()
	proxy.add_child(simulator)
	for bone_name: String in SEGMENTS:
		var id:=proxy.find_bone(bone_name)
		var child:=proxy.find_bone(SEGMENTS[bone_name][0])
		if id<0 or child<0:continue
		var rest:=proxy.get_bone_global_rest(id)
		var end:=proxy.get_bone_global_rest(child).origin
		var vector: Vector3=rest.basis.inverse()*(end-rest.origin)
		var body_offset:=Transform3D(Basis(Quaternion(Vector3.UP,vector.normalized())),vector*0.5)
		var body:=HarborPhysicalBone.new()
		body.driver=self
		body.name="Physical_"+bone_name
		body.bone_name=bone_name
		body.mass=SEGMENTS[bone_name][2]
		body.friction=0.85
		body.bounce=0
		body.linear_damp=0.35
		body.angular_damp=1.3
		body.can_sleep=true
		body.collision_layer=0
		body.collision_mask=0
		simulator.add_child(body)
		body.body_offset=body_offset
		body.joint_offset=body_offset.affine_inverse()
		if bone_name!="Hips":
			var hinge: bool=bone_name.ends_with("ForeArm") or (bone_name.ends_with("Leg") and not bone_name.ends_with("UpLeg"))
			var frame:=Transform3D(Basis(Quaternion(Vector3.RIGHT,(end-rest.origin).normalized())),rest.origin)
			if hinge:
				var axis:=Vector3.RIGHT
				if bone_name.ends_with("ForeArm"):
					var parent_id:=proxy.get_bone_parent(id)
					axis=(rest.origin-proxy.get_bone_global_rest(parent_id).origin).cross(end-rest.origin).normalized()
				var horizontal:=axis.cross(Vector3.UP).normalized()
				var vertical:=axis.cross(horizontal).normalized()
				frame=Transform3D(Basis(horizontal,vertical,axis),rest.origin)
			body.joint_offset=(rest*body_offset).affine_inverse()*frame
			# Godot reloads the native joint on type changes, not offset changes.
			# Establish the frame first, then create and configure the native joint.
			body.joint_type=PhysicalBone3D.JOINT_TYPE_HINGE if hinge else PhysicalBone3D.JOINT_TYPE_CONE
			if hinge:
				body.set("joint_constraints/angular_limit_enabled",true)
				body.set("joint_constraints/angular_limit_lower",-125.0 if bone_name.ends_with("Leg") else -5.0)
				body.set("joint_constraints/angular_limit_upper",5.0 if bone_name.ends_with("Leg") else 125.0)
			else:
				body.set("joint_constraints/swing_span",28.0 if bone_name.begins_with("Spine") else (35.0 if bone_name=="Head" else 65.0))
				body.set("joint_constraints/twist_span",15.0 if bone_name.begins_with("Spine") else 25.0)
		var collider:=CollisionShape3D.new()
		var capsule:=CapsuleShape3D.new()
		capsule.radius=SEGMENTS[bone_name][1]
		capsule.height=maxf(vector.length()*0.90,capsule.radius*2+0.01)
		collider.shape=capsule
		body.add_child(collider)
		if bone_name.ends_with("Leg") and not bone_name.ends_with("UpLeg"):
			var toe_id:=proxy.find_bone(bone_name.replace("Leg","ToeBase"))
			var foot_point:=proxy.get_bone_global_rest(child).origin
			var toe_point:=proxy.get_bone_global_rest(toe_id).origin
			var foot_shape:=CollisionShape3D.new()
			var foot_capsule:=CapsuleShape3D.new()
			foot_capsule.radius=0.045
			foot_capsule.height=foot_point.distance_to(toe_point)+0.06
			foot_shape.shape=foot_capsule
			var world_foot:=Transform3D(Basis(Quaternion(Vector3.UP,(toe_point-foot_point).normalized())),(foot_point+toe_point)*0.5)
			foot_shape.transform=(rest*body_offset).affine_inverse()*world_foot
			body.add_child(foot_shape)
		PhysicsServer3D.body_set_max_contacts_reported(body.get_rid(),4)
		PhysicsServer3D.body_set_enable_continuous_collision_detection(body.get_rid(),true)
		bones[bone_name]=body
	# Exclude joint neighbors, retaining non-adjacent body self-collision.
	for bone_name: String in bones:
		var parent:=proxy.get_bone_parent(proxy.find_bone(bone_name))
		while parent>=0 and not bones.has(proxy.get_bone_name(parent)):parent=proxy.get_bone_parent(parent)
		if parent>=0:
			var child_body: HarborPhysicalBone=bones[bone_name]
			var parent_body: HarborPhysicalBone=bones[proxy.get_bone_name(parent)]
			child_body.add_collision_exception_with(parent_body)
			parent_body.add_collision_exception_with(child_body)
	for bone_name: String in bones:
		var id:=proxy.find_bone(bone_name)
		var parent:=proxy.get_bone_parent(id)
		while parent>=0 and not bones.has(proxy.get_bone_name(parent)):parent=proxy.get_bone_parent(parent)
		if parent<0:continue
		var child: HarborPhysicalBone=bones[bone_name]
		var parent_body: HarborPhysicalBone=bones[proxy.get_bone_name(parent)]
		var parent_rest:=proxy.get_bone_global_rest(parent)*parent_body.body_offset
		var anchor:=proxy.get_bone_global_rest(id)*child.body_offset*child.joint_offset
		links.append({"child":child,"parent":parent_body,"anchor":parent_rest.affine_inverse()*anchor})
	simulator.physical_bones_stop_simulation()
	simulator.modification_processed.connect(_cache_pose)
	bridge=RagdollPoseBridge.new()
	bridge.driver=self
	skeleton.add_child(bridge)

func start(direction: Vector3, point: Vector3, severity: float) -> void:
	if active:return
	if not built:_build()
	frozen=false
	peak_joint_gap=0
	age=0
	quiet_time=0
	settled=false
	proxy.global_transform=Transform3D(visual_skeleton.global_basis.orthonormalized(),visual_skeleton.global_position)
	for i: int in range(proxy.get_bone_count()):
		proxy.set_bone_pose_position(i,visual_skeleton.get_bone_pose_position(i)*unit_scale)
		proxy.set_bone_pose_rotation(i,visual_skeleton.get_bone_pose_rotation(i))
	proxy.force_update_all_bone_transforms()
	if actor.animation:actor.animation.pause()
	if actor.dynamics:actor.dynamics.active=false
	actor.collision_layer=0
	actor.collision_mask=0
	actor.body_collision.set_deferred("disabled",true)
	if actor.weapon:actor.weapon.hide()
	active=true
	for body: HarborPhysicalBone in bones.values():
		body.collision_layer=LAYER
		body.collision_mask=CollisionLayers.SOLIDS
	simulator.physical_bones_start_simulation()
	# Rebuild anchors from the captured animated pose, not the import rest pose.
	# Shoulder/neck helper bones can translate the child anchor during animation.
	links.clear()
	for bone_name: String in bones:
		var body: HarborPhysicalBone=bones[bone_name]
		var kind: int=body.joint_type
		if kind==PhysicalBone3D.JOINT_TYPE_NONE:continue
		var settings: Dictionary={}
		for property: String in (["angular_limit_enabled","angular_limit_lower","angular_limit_upper"] if kind==PhysicalBone3D.JOINT_TYPE_HINGE else ["swing_span","twist_span"]):settings[property]=body.get("joint_constraints/"+property)
		body.joint_type=PhysicalBone3D.JOINT_TYPE_NONE
		body.joint_type=kind
		for property: String in settings:body.set("joint_constraints/"+property,settings[property])
		var parent:=proxy.get_bone_parent(proxy.find_bone(bone_name))
		while parent>=0 and not bones.has(proxy.get_bone_name(parent)):parent=proxy.get_bone_parent(parent)
		if parent>=0:
			var parent_body: HarborPhysicalBone=bones[proxy.get_bone_name(parent)]
			links.append({"child":body,"parent":parent_body,"anchor":parent_body.global_transform.affine_inverse()*body.global_transform*body.joint_offset})
	var momentum: Vector3=(actor.velocity+direction.limit_length(1)*clampf(severity*0.04,0.6,2.0)).limit_length(6)
	for body: HarborPhysicalBone in bones.values():body.linear_velocity=momentum
	var nearest: HarborPhysicalBone=bones.Hips
	for body: HarborPhysicalBone in bones.values():
		if body.global_position.distance_to(point)<nearest.global_position.distance_to(point):nearest=body
	nearest.apply_central_impulse(direction.limit_length(1)*clampf(severity*0.06,0.6,3))
	_cache_pose()

func _cache_pose() -> void:
	if not active:return
	cached.clear()
	var globals: Array[Transform3D]=[]
	for i: int in range(proxy.get_bone_count()):
		var pose:=proxy.get_bone_global_pose(i)
		pose.origin/=unit_scale
		pose.basis=pose.basis.orthonormalized()
		globals.append(pose)
		var parent:=proxy.get_bone_parent(i)
		cached.append(globals[parent].affine_inverse()*pose if parent>=0 else pose)

func pelvis_position() -> Vector3:
	return bones.Hips.global_position if active else actor.global_position+Vector3.UP

func max_speed() -> float:
	var speed: float=0
	for body: HarborPhysicalBone in bones.values():speed=maxf(speed,body.linear_velocity.length())
	return speed

func joint_gap() -> float:
	var gap: float=0
	for link: Dictionary in links:
		gap=maxf(gap,(link.child.global_transform*link.child.joint_offset).origin.distance_to((link.parent.global_transform*link.anchor).origin))
	return gap

func _physics_process(delta: float) -> void:
	if not active:return
	if actor.game.paused or actor.game.cinematic_active:
		if not paused_physics:
			paused_physics=true
			for body: HarborPhysicalBone in bones.values():
				pause_velocities[body.name]=[body.linear_velocity,body.angular_velocity]
				PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		return
	if paused_physics:
		paused_physics=false
		for body: HarborPhysicalBone in bones.values():
			PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_RIGID)
			if frozen:PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_SLEEPING,true)
			else:
				body.linear_velocity=pause_velocities[body.name][0]
				body.angular_velocity=pause_velocities[body.name][1]
		pause_velocities.clear()
	age+=delta
	if frozen and max_speed()>0.25:frozen=false
	peak_joint_gap=maxf(peak_joint_gap,joint_gap())
	if max_speed()<0.20:quiet_time+=delta
	else:quiet_time=0
	settled=quiet_time>0.8
	if settled and age>3 and not frozen and actor.state==HarborGuard.State.DEFEATED:
		frozen=true
		for body: HarborPhysicalBone in bones.values():
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_SLEEPING,true)

func stop() -> void:
	if not active:return
	active=false
	for body: HarborPhysicalBone in bones.values():PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_RIGID)
	frozen=false
	simulator.physical_bones_stop_simulation()
	for body: HarborPhysicalBone in bones.values():
		body.collision_layer=0
		body.collision_mask=0
	actor.body_collision.set_deferred("disabled",false)
	actor.collision_layer=CollisionLayers.NPC
	actor.collision_mask=CollisionLayers.SOLIDS
	visual_skeleton.reset_bone_poses()
	if actor.dynamics:
		actor.dynamics.active=true
		actor.dynamics.reset_state()

func nudge(body: HarborPhysicalBone, impulse: Vector3) -> void:
	if not active:return
	if frozen:
		frozen=false
		quiet_time=0
		for segment: HarborPhysicalBone in bones.values():PhysicsServer3D.body_set_state(segment.get_rid(),PhysicsServer3D.BODY_STATE_SLEEPING,false)
	body.apply_central_impulse(impulse.limit_length(3))

func limit_error_degrees() -> float:
	var worst: float=0
	for link: Dictionary in links:
		var parent_frame: Basis=(link.parent.global_transform*link.anchor).basis.orthonormalized()
		var child_frame: Basis=(link.child.global_transform*link.child.joint_offset).basis.orthonormalized()
		var relative: Basis=parent_frame.inverse()*child_frame
		if link.child.joint_type==PhysicalBone3D.JOINT_TYPE_HINGE:
			var angle: float=-rad_to_deg(relative.get_euler().z)
			var lower: float=link.child.get("joint_constraints/angular_limit_lower")
			var upper: float=link.child.get("joint_constraints/angular_limit_upper")
			var error: float=maxf(lower-angle,angle-upper)
			if error>worst:
				worst=error
				limit_diagnostic=str(link.child.name)+" hinge="+str(angle)
		else:
			var rotation:=relative.get_rotation_quaternion()
			var twist:=Quaternion(rotation.x,0,0,rotation.w).normalized()
			var swing:=rotation*twist.inverse()
			# Jolt uses a swing pyramid: each Y/Z angle has its own bound.
			var y: float=rad_to_deg(2*atan2(absf(swing.y),absf(swing.w)))
			var z: float=rad_to_deg(2*atan2(absf(swing.z),absf(swing.w)))
			var twist_angle: float=rad_to_deg(2*atan2(absf(twist.x),absf(twist.w)))
			if twist_angle>180:twist_angle=360-twist_angle
			var error: float=maxf(maxf(y,z)-float(link.child.get("joint_constraints/swing_span")),twist_angle-float(link.child.get("joint_constraints/twist_span")))
			if error>worst:
				worst=error
				limit_diagnostic=str(link.child.name)+" swing="+str(maxf(y,z))+" twist="+str(twist_angle)

	return maxf(0,worst)
