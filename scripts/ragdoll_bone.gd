class_name HarborPhysicalBone
extends PhysicalBone3D

var driver: NPCRagdoll
var self_contacts: int = 0
var contacts: int = 0
var peak_speed: float = 0

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.linear_velocity=state.linear_velocity.limit_length(8)
	state.angular_velocity=state.angular_velocity.limit_length(12)
	peak_speed=maxf(peak_speed,state.linear_velocity.length())
	contacts+=state.get_contact_count()
	for i: int in range(state.get_contact_count()):
		var other: Object=state.get_contact_collider_object(i)
		if other is HarborPhysicalBone and other.driver==driver:self_contacts+=1
