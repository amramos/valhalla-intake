class_name NoteMarks
extends RefCounted
## The clerk's note's speaker marks (D10), each at most 7×7 and placed pixel by pixel: a pin in
## its thread's colour, Huginn's raven, the mentor's face, the black feather of a citation.

## A mark's box.
const SIZE := 7
## "#" is ink, "o" the mark's second colour, "." nothing.
const RAVEN: Array[String] = [
	"..###..",
	".#o###.",
	"##.####",
	"...####",
	"...####",
	"....##.",
	"...#.#.",
]
const MENTOR: Array[String] = [
	"..###..",
	".#####.",
	"##ooo##",
	"#o#o#o#",
	"#ooooo#",
	".#ooo#.",
	"..###..",
]
const FEATHER: Array[String] = [
	".....##",
	"....###",
	"...###.",
	"..###..",
	".###...",
	".o.....",
	"o......",
]
## A pin: an ink ring around a 5×5 head, so a pale pin still reads on parchment.
const PIN_RING: Array[String] = [
	".#####.",
	"#.....#",
	"#.....#",
	"#.....#",
	"#.....#",
	"#.....#",
	".#####.",
]


## Paints `mark` with its top-left at `at` through `paint` (a `(Rect2, Color)` callable).
## `colors` maps the names this needs: "ink", "second" (the raven's eye, the mentor's face, the
## feather's quill), "highlight", and the pin's "pin_red", "pin_grey" or "pin_law" head colour.
static func draw(
	paint: Callable, mark: StringName, at: Vector2i, colors: Dictionary[StringName, Color]
) -> void:
	match mark:
		&"raven":
			_bitmap(paint, RAVEN, at, colors)
		&"mentor":
			_bitmap(paint, MENTOR, at, colors)
		&"feather":
			_bitmap(paint, FEATHER, at, colors)
		&"pin_red", &"pin_grey", &"pin_law":
			_bitmap(paint, PIN_RING, at, colors)
			PinSelectable.draw_pin_head(
				paint,
				at + Vector2i.ONE,
				colors.get(mark, Color.WHITE),
				colors.get(&"highlight", Color.WHITE),
				colors.get(&"ink", Color.BLACK)
			)


## The pixels a mark covers, relative to its top-left (tests).
static func pixels(mark: StringName) -> Array[Vector2i]:
	var rows: Array[String] = []
	match mark:
		&"raven":
			rows = RAVEN
		&"mentor":
			rows = MENTOR
		&"feather":
			rows = FEATHER
		&"pin_red", &"pin_grey", &"pin_law":
			rows = PIN_RING
	var out: Array[Vector2i] = []
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			if rows[y][x] != ".":
				out.append(Vector2i(x, y))
	if rows == PIN_RING:
		for y: int in range(1, SIZE - 1):
			for x: int in range(1, SIZE - 1):
				out.append(Vector2i(x, y))
	return out


static func _bitmap(
	paint: Callable, rows: Array[String], at: Vector2i, colors: Dictionary[StringName, Color]
) -> void:
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			var code: String = rows[y][x]
			if code == ".":
				continue
			var color: Color = colors.get(&"ink" if code == "#" else &"second", Color.BLACK)
			paint.call(Rect2(Vector2(at + Vector2i(x, y)), Vector2.ONE), color)
