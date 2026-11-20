class_name VeyraRoadNetwork
extends RefCounted

# Stable junction IDs, directed left-hand lanes and explicit closure-aware routing.
var nodes: Array[Vector3]=[]
var links: Dictionary={}
var closed: Dictionary={}
var reservations: Dictionary={}

func _init() -> void:
	for x: float in [-70,0,72]:
		for z: float in [58,138,218]:nodes.append(Vector3(x,0,z))
	# Keep the original nine junction IDs stable when adding west/east links.
	for x: float in [-140,142]:
		for z: float in [58,138,218]:nodes.append(Vector3(x,0,z))
	for a: int in range(nodes.size()):
		links[a]=[]
		for b: int in range(nodes.size()):
			var delta:=nodes[a]-nodes[b]
			if (is_zero_approx(delta.x) and is_equal_approx(absf(delta.z),80)) or (is_zero_approx(delta.z) and absf(delta.x)>=69 and absf(delta.x)<=73):links[a].append(b)

func key(a: int,b: int) -> String:return "%d>%d"%[a,b]
func connected(a: int,b: int) -> bool:return links.has(a) and links[a].has(b) and not closed.has(key(a,b))
func close_lane(a: int,b: int,value: bool) -> bool:
	if not links.has(a) or not links[a].has(b):return false
	if value:closed[key(a,b)]=true
	else:closed.erase(key(a,b))
	return true

func route(a: int,b: int) -> PackedInt32Array:
	if not links.has(a) or not links.has(b):return PackedInt32Array()
	var queue: Array[int]=[a]
	var previous: Dictionary={a:-1}
	while not queue.is_empty():
		var current: int=queue.pop_front()
		if current==b:break
		for next: int in links[current]:
			if connected(current,next) and not previous.has(next):previous[next]=current;queue.append(next)
	if not previous.has(b):return PackedInt32Array()
	var result:=PackedInt32Array([b])
	var at: int=b
	while at!=a:
		at=previous[at]
		result.insert(0,at)
	return result

func next_junction(a: int,b: int,choice: int) -> int:
	var options: Array[int]=[]
	for c: int in links[b]:
		if c!=a and connected(b,c):options.append(c)
	return options[posmod(choice,options.size())] if not options.is_empty() else -1

func direction(a: int,b: int) -> Vector3:return nodes[a].direction_to(nodes[b])
func lane_offset(a: int,b: int) -> Vector3:return Vector3.UP.cross(direction(a,b))*3

func movement(a: int,b: int,c: int) -> PackedVector3Array:
	var incoming:=direction(a,b)
	var outgoing:=direction(b,c)
	var start:=nodes[b]-incoming*12+lane_offset(a,b)
	var end:=nodes[b]+outgoing*12+lane_offset(b,c)
	var control:=nodes[b]+lane_offset(a,b)+lane_offset(b,c) if absf(incoming.dot(outgoing))<.5 else (start+end)*.5
	var points:=PackedVector3Array([start])
	for i: int in range(1,7):
		var t: float=i/6.0
		points.append(start.lerp(control,t).lerp(control.lerp(end,t),t))
	return points

func reserve(node: int,id: String) -> bool:
	if reservations.has(node) and reservations[node]!=id:return false
	reservations[node]=id
	return true

func release(node: int,id: String) -> void:
	if reservations.get(node,"")==id:reservations.erase(node)
