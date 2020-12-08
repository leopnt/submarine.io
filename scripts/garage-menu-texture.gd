extends TextureRect

export(Global.smTypes) var smType = Global.smTypes.std


func _draw():
	var radius = 20
	var offset = rect_size/2
	
	if smType == Global.smTypes.std:
		draw_arc(offset, radius, 0, 2*PI, 32, Color(0, 1, 0), 1.3, true)
	
	if smType == Global.smTypes.fst:
		var vLeft = offset + 1.2*radius*Vector2.UP.normalized().rotated(-3*PI/4)
		var vLeftOff = offset + 0.4*radius*Vector2.UP.normalized().rotated(-PI/2)
		var vUp = offset + 1.2*radius*Vector2.UP.normalized()
		var vRightOff = offset + 0.4*radius*Vector2.UP.normalized().rotated(PI/2)
		var vRight = offset + 1.2*radius*Vector2.UP.normalized().rotated(3*PI/4)
		var tab = [vLeft, vLeftOff, vUp, vRightOff, vRight, vLeft] #vLeft is added for polyline to close the shape
		var vertexs = PoolVector2Array(tab)
		draw_polyline(vertexs, Color(0, 1, 0, 1), 1.3, true)
	
	if smType == Global.smTypes.slw:
		draw_rect(Rect2(offset + Vector2(-radius, -radius), 2*Vector2(radius, radius)), Color(0, 1, 0), false, 1.3, true)

				
