class_name CityNavigation
extends Node

var grid := AStarGrid2D.new()
var built: bool = false

func rebuild() -> void:
	grid.region=Rect2i(-60,-108,121,229)
	grid.cell_size=Vector2(2,2)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var query:=PhysicsShapeQueryParameters3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(1.5,1.4,1.5)
	query.shape=shape
	query.collision_mask=CollisionLayers.STATIC
	for x: int in range(-60,61):
		for z: int in range(-108,121):
			query.transform=Transform3D(Basis.IDENTITY,Vector3(x*2,1.1,z*2))
			grid.set_point_solid(Vector2i(x,z),not get_parent().get_world_3d().direct_space_state.intersect_shape(query,1).is_empty())
			grid.set_point_weight_scale(Vector2i(x,z),3.0 if abs(x*2)<8 else 1.0)
	built=true

func nearest(point: Vector2i) -> Vector2i:
	for radius: int in range(13):
		var best:=point
		var distance: float=INF
		for x: int in range(-radius,radius+1):
			for y: int in range(-radius,radius+1):
				var id:=point+Vector2i(x,y)
				if grid.is_in_boundsv(id) and not grid.is_point_solid(id) and Vector2(x,y).length_squared()<distance:
					best=id;distance=Vector2(x,y).length_squared()
		if distance<INF:return best
	return point

func path(from: Vector3, to: Vector3, dynamic_obstacles: bool=false) -> PackedVector3Array:
	var points:=PackedVector3Array()
	if not built: return points
	var blocked: Array[Vector2i]=[]
	if dynamic_obstacles:
		var query:=PhysicsShapeQueryParameters3D.new()
		var shape:=BoxShape3D.new()
		shape.size=Vector3(1.6,1.2,1.6)
		query.shape=shape
		query.collision_mask=CollisionLayers.PROP|CollisionLayers.VEHICLE
		var center:=Vector2i(roundi(from.x/2),roundi(from.z/2))
		for x: int in range(-5,6):
			for z: int in range(-5,6):
				var cell:=center+Vector2i(x,z)
				if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):continue
				query.transform=Transform3D(Basis.IDENTITY,Vector3(cell.x*2,from.y+1,cell.y*2))
				if not get_parent().get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
					grid.set_point_solid(cell,true);blocked.append(cell)
	var a:=nearest(Vector2i(roundi(from.x/2),roundi(from.z/2)))
	var b:=nearest(Vector2i(roundi(to.x/2),roundi(to.z/2)))
	if grid.is_in_boundsv(a) and grid.is_in_boundsv(b) and not grid.is_point_solid(a) and not grid.is_point_solid(b):
		for point: Vector2 in grid.get_point_path(a,b,true): points.append(Vector3(point.x,from.y,point.y))
	for cell: Vector2i in blocked:grid.set_point_solid(cell,false)
	return points
