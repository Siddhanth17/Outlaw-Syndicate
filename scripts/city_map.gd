class_name CityMap
extends Control
var game: Node3D
func _ready() -> void:custom_minimum_size=Vector2(370,250)
func map_point(at: Vector3) -> Vector2:return Vector2(185+at.x*.9,125-at.z*.45)
func area(a: Vector3,b: Vector3,color: Color) -> void:
	var p:=map_point(a);var q:=map_point(b);draw_rect(Rect2(Vector2(minf(p.x,q.x),minf(p.y,q.y)),Vector2(absf(q.x-p.x),absf(q.y-p.y))),color)
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,370,250),Color(.035,.055,.065))
	area(Vector3(-70,0,-180),Vector3(72,0,58),Color(.15,.18,.20))
	area(Vector3(-70,0,58),Vector3(72,0,218),Color(.21,.24,.25))
	area(Vector3(-140,0,58),Vector3(-70,0,218),Color(.12,.23,.28))
	area(Vector3(72,0,58),Vector3(142,0,218),Color(.29,.23,.14))
	for x: float in VeyraQuarter.XS:draw_line(map_point(Vector3(x,0,58)),map_point(Vector3(x,0,218)),Color(.65,.67,.62),4)
	for z: float in VeyraQuarter.ZS:draw_line(map_point(Vector3(-140,0,z)),map_point(Vector3(142,0,z)),Color(.65,.67,.62),4)
	for x: float in [-70,0,72]:draw_line(map_point(Vector3(x,0,-176)),map_point(Vector3(x,0,58)),Color(.48,.53,.55),3)
	for z: float in [-176,58]:draw_line(map_point(Vector3(-70,0,z)),map_point(Vector3(72,0,z)),Color(.48,.53,.55),3)
	for actor: CityNPC in game.people:draw_circle(map_point(actor.position),1.8,Color(.8,.78,.5))
	for car: VeyraCar in game.traffic.cars:
		if car.visible:draw_circle(map_point(car.position),2.4,Color(.9,.42,.22))
	if game.law.unit and game.law.unit.case_id>0 and game.law.unit.car.position.distance_to(game.player.position)<120:draw_circle(map_point(game.law.unit.car.position),3.5,Color(.2,.7,1))
	draw_rect(Rect2(map_point(VeyraStation.ADDRESS)-Vector2(3,3),Vector2(6,6)),Color(.5,.75,1))
	draw_circle(map_point(game.residence.global_position),5,Color(.9,.54,.7))
	draw_circle(map_point(game.player.position),4,Color(.35,1,.8))
