class_name DoorCarving
extends RefCounted
## A door's carved glyph as its lit sprite paints it, for the glyph cue: the carving's pixels (the
## darkest colour inside the glyph's area), that colour, and the 1 px edge around the carving
## (its 4-neighbours outside it), which the lit glyph keeps so it reads on every door's light.

## The carving's pixels, in sprite pixels.
var pixels: Array[Vector2i] = []
## The pixels around the carving that keep its edge when it is lit.
var edge: Array[Vector2i] = []
## The carving's colour.
var ink := Color()


## Reads the carving inside `area` of `texture`; an empty carving when there is no image.
static func read(texture: Texture2D, area: Rect2i) -> DoorCarving:
	var carving := DoorCarving.new()
	var image: Image = texture.get_image() if texture != null else null
	if image == null:
		return carving
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	area = area.intersection(bounds)
	var darkest: float = INF
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var luminance: float = image.get_pixel(x, y).get_luminance()
			if luminance < darkest:
				darkest = luminance
				carving.ink = image.get_pixel(x, y)
	var carved: Dictionary[Vector2i, bool] = {}
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).is_equal_approx(carving.ink):
				carved[Vector2i(x, y)] = true
	carving.pixels.assign(carved.keys())
	var around: Dictionary[Vector2i, bool] = {}
	for at: Vector2i in carving.pixels:
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if bounds.has_point(next) and not carved.has(next):
				around[next] = true
	carving.edge.assign(around.keys())
	return carving
