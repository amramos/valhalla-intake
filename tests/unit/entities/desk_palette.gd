extends RefCounted
## Test helper: the palette's colours (docs/art/palette.gpl) by name, and a recorder that stands
## in for a canvas so a code-drawn mark can be checked rect by rect.

const PALETTE_PATH := "res://docs/art/palette.gpl"

## Rectangles painted through `paint`, in order, with their colours.
var rects: Array[Rect2] = []
var colors: Array[Color] = []


## Every palette colour by its name ("Night 4", "Ember 2"…).
static func by_name() -> Dictionary[String, Color]:
	var named: Dictionary[String, Color] = {}
	var file: FileAccess = FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		return named
	var entry := RegEx.create_from_string(r"^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+)$")
	while not file.eof_reached():
		var found: RegExMatch = entry.search(file.get_line())
		if found != null:
			named[found.get_string(4).strip_edges()] = Color8(
				int(found.get_string(1)), int(found.get_string(2)), int(found.get_string(3))
			)
	return named


## The colours in `colors_drawn` that are not palette colours, as hex strings.
static func strays(colors_drawn: Array[Color]) -> Array[String]:
	var palette: Array[int] = []
	for color: Color in by_name().values():
		palette.append(color.to_rgba32())
	var out: Array[String] = []
	for color: Color in colors_drawn:
		if not palette.has(color.to_rgba32()) and not out.has(color.to_html(false)):
			out.append(color.to_html(false))
	return out


## The bounding box of `rects_drawn`.
static func bounds(rects_drawn: Array[Rect2]) -> Rect2:
	if rects_drawn.is_empty():
		return Rect2()
	var box: Rect2 = rects_drawn[0]
	for rect: Rect2 in rects_drawn:
		box = box.merge(rect)
	return box


## The colour last painted over pixel `at`; transparent when nothing was.
static func color_at(rects_drawn: Array[Rect2], colors_drawn: Array[Color], at: Vector2i) -> Color:
	var found := Color(0, 0, 0, 0)
	for index: int in range(rects_drawn.size()):
		if rects_drawn[index].has_point(Vector2(at) + Vector2(0.5, 0.5)):
			found = colors_drawn[index]
	return found


func paint(rect: Rect2, color: Color) -> void:
	rects.append(rect)
	colors.append(color)
