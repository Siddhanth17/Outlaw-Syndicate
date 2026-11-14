class_name VehicleHitRegion
extends Area3D

var vehicle: VeyraCar
var kind: String = "body"
var index: int = -1

func receive_hit(at: Vector3, direction: Vector3, power: float) -> void:
	vehicle.receive_bullet(at,direction,power,kind,index)
