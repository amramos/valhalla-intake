class_name KnotPlacer
extends RefCounted
## Places a thread's knot (D8): an 8×8 box on the thread's route, as near the middle of the
## route's longest vertical run as it can be, overlapping no other hit area so it never steals a
## click meant for a fact or a line. Pure geometry over global pixel rectangles.


## The knot's top-left corner. `route` is every pixel of the thread in order; `avoid` holds the hit
## areas the knot must not cover. Falls back to the preferred spot when no free spot exists.
static func place(route: Array[Vector2i], avoid: Array[Rect2], knot_size: int) -> Vector2:
	if route.is_empty():
		return Vector2.ZERO
	var half: int = floori(knot_size / 2.0)
	var preferred: Vector2i = _preferred(route)
	var best := Vector2(preferred - Vector2i(half, half))
	var best_cost: int = -1
	for pixel: Vector2i in route:
		# The box may slide sideways off the line as long as the line still runs through it.
		for shift: int in range(-half, half):
			for vertical: bool in [false, true]:
				var offset := Vector2i(0, shift) if vertical else Vector2i(shift, 0)
				var corner: Vector2i = pixel + offset - Vector2i(half, half)
				var box := Rect2(Vector2(corner), Vector2(knot_size, knot_size))
				if _hits(box, avoid):
					continue
				var cost: int = absi(shift) * 4 + (pixel - preferred).length_squared()
				if best_cost < 0 or cost < best_cost:
					best_cost = cost
					best = Vector2(corner)
	return best


## The middle of the route's longest straight vertical run.
static func _preferred(route: Array[Vector2i]) -> Vector2i:
	var best_start: int = 0
	var best_length: int = 0
	var start: int = 0
	for index: int in range(1, route.size() + 1):
		var vertical: bool = index < route.size() and route[index].x == route[index - 1].x
		if vertical:
			continue
		if index - start > best_length:
			best_length = index - start
			best_start = start
		start = index
	return route[best_start + floori(best_length / 2.0)]


static func _hits(box: Rect2, avoid: Array[Rect2]) -> bool:
	for rect: Rect2 in avoid:
		if box.intersects(rect):
			return true
	return false
