class_name WaxSeal
extends RefCounted
## The wax seal on a new decree (D9, D33): an 8×9 blob of Ember 1 wax in an Ember 0 rim, a 3×3
## Ember 2 heart pressed into it and a 2 px drip running off its bottom right, set left of the
## decree's numeral. A pin head is 5×5, Ember 2 with a dark shadow; the seal is bigger, darker
## and lighter at its heart, so the two never read alike (an ember dot means "pinned"). Its heart
## is what a forged seal can change. Whole-pixel rects only, in palette colours.

const WIDTH := 8
const HEIGHT := 9
const SIZE_VECTOR := Vector2(WIDTH, HEIGHT)
## Pixels between the seal and the numeral's first ink column, when the column leaves room.
const GAP := 1
## The seal never leaves the paper: the law gutter, where threads run, starts left of it. Beside
## "II" and "IV" it fills the 8 px left of the numeral exactly.
const MOST_LEFT := 0
## "#" wax (Ember 1), "o" the rim (Ember 0), "c" the pressed heart (Ember 2), "." nothing.
const BLOB: Array[String] = [
	"..oooo..",
	".o####o.",
	"o#ccc##o",
	"o#ccc##o",
	"o#ccc##o",
	".o####o.",
	"..oo##o.",
	"....o#o.",
	".....o..",
]


## The seal's top-left in panel pixels for a decree line at `line_at` whose numeral label sits
## `numeral_x` pixels into the line: at the paper's left edge, or further left (at most to
## `MOST_LEFT`) when the numeral is too wide to leave room, so it never covers the numeral. It
## stays inside the line's 10 px row, so it never touches the decree above or below.
static func place(line_at: Vector2, numeral_x: int) -> Vector2:
	var numeral_left: int = int(line_at.x) + numeral_x
	var x: int = mini(int(line_at.x) - EvidencePanel.PADDING, numeral_left - GAP - WIDTH)
	return Vector2(maxi(x, MOST_LEFT), int(line_at.y))


## Paints the seal with its top-left at `at` through `paint` (a `(Rect2, Color)` callable).
static func draw(paint: Callable, at: Vector2i, wax: Color, rim: Color, heart: Color) -> void:
	for y: int in range(BLOB.size()):
		var row: String = BLOB[y]
		var x: int = 0
		while x < row.length():
			var code: String = row[x]
			var end: int = x + 1
			while end < row.length() and row[end] == code:
				end += 1
			if code != ".":
				var color: Color = wax if code == "#" else (heart if code == "c" else rim)
				paint.call(Rect2(Vector2(at + Vector2i(x, y)), Vector2(end - x, 1)), color)
			x = end


## The pixels the seal covers, relative to its top-left (tests).
static func pixels() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(BLOB.size()):
		for x: int in range(BLOB[y].length()):
			if BLOB[y][x] != ".":
				out.append(Vector2i(x, y))
	return out
