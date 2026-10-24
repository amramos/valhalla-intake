class_name HudMarks
extends RefCounted
## The HUD's objects drawn pixel by pixel (art direction: small marks are placed in code): the
## candle with its flame, the tally slate's chalk marks and the ledger's closed book. Each drawer
## paints through `paint(rect: Rect2, color: Color)` so the HUD can record what it drew.

const CANDLE_WIDTH := 6
const CANDLE_HEIGHT := 14
const FLAME_HEIGHT := 3
## The flame's frames, 2×3, "#" is Ember 2: steady, then the two frames of a gutter (D36).
const FLAMES: Array = [
	[".#", "##", "##"],
	["#.", "##", "##"],
	["..", ".#", "##"],
]
const STEADY := 0
## No flame: the unlit candle of an untimed day, or a burnt-out one.
const UNLIT := -1

const SLATE_SIZE := Vector2i(12, 9)
## Inside the frame, two rows of one group of five each: four strokes and the fifth struck across.
const TALLY_CAPACITY := 10
const TALLY_GROUP := 5

const BOOK_SIZE := 8
## The closed book: d spine, l cover, f the title plate and clasp strap, p the pages' edge.
const BOOK: Array[String] = [
	"dllllll.",
	"dllllllp",
	"dlfffllp",
	"dllllllp",
	"dllllfff",
	"dllllllp",
	"dllllllp",
	"dllllll.",
]
## The wax dot sealing the clasp while a promise is open, 3×3 in Ember 2.
const WAX_DOT := Rect2i(5, 3, 3, 3)


## The wax's height in pixels: round(14 × time left / the day's clock), clamped to the candle.
static func wax_height(time_left: float, clock_seconds: float) -> int:
	if clock_seconds <= 0.0 or is_inf(time_left) or is_nan(time_left):
		return CANDLE_HEIGHT
	return clampi(roundi(CANDLE_HEIGHT * time_left / clock_seconds), 0, CANDLE_HEIGHT)


## The candle standing in a 6×17 box at `at` (wax from the bottom, the flame on the wax).
## `ramp` is the Parchment ramp from light to dark; `wick` the unlit wick's colour.
static func candle(
	paint: Callable,
	at: Vector2i,
	wax: int,
	flame: int,
	ramp: Array[Color],
	wick: Color,
	ember: Color,
) -> Array[Rect2]:
	var bottom: int = at.y + FLAME_HEIGHT + CANDLE_HEIGHT
	var top: int = bottom - wax
	if wax > 0:
		paint.call(Rect2(at.x, top, CANDLE_WIDTH, wax), ramp[1])
		paint.call(Rect2(at.x, top, 1, wax), ramp[0])
		paint.call(Rect2(at.x + 4, top, 2, wax), ramp[2])
		# The melted pool on top reads as the candle's lit end.
		paint.call(Rect2(at.x + 1, top, 4, 1), ramp[0])
	var flame_rects: Array[Rect2] = []
	if flame == UNLIT:
		if wax > 0:
			paint.call(Rect2(at.x + 3, top - 2, 1, 2), wick)
		return flame_rects
	var rows: Array = FLAMES[flame]
	for y: int in range(FLAME_HEIGHT):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] == "#":
				var cell := Rect2(at.x + 2 + x, top - FLAME_HEIGHT + y, 1, 1)
				paint.call(cell, ember)
				flame_rects.append(cell)
	return flame_rects


## The chalk strokes for `count` marks, relative to the slate's corner, in drawing order.
static func tally_rects(count: int) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	for index: int in range(mini(count, TALLY_CAPACITY)):
		var top: int = 1 + (index / TALLY_GROUP) * 4
		var stroke: int = index % TALLY_GROUP
		if stroke < TALLY_GROUP - 1:
			out.append(Rect2i(3 + 2 * stroke, top, 1, 3))
		else:
			out.append(Rect2i(2, top + 1, 9, 1))
	return out


## The slate at `at` in its 1 px wooden frame: faint target marks up to the quota, chalk over them
## for each soul admitted. `colors`: the slate, the chalk, the faint marks, the frame.
static func slate(
	paint: Callable, at: Vector2i, admitted: int, quota: int, colors: Array[Color]
) -> void:
	paint.call(Rect2(Vector2(at), Vector2(SLATE_SIZE)), colors[3])
	paint.call(Rect2(Vector2(at + Vector2i.ONE), Vector2(SLATE_SIZE - 2 * Vector2i.ONE)), colors[0])
	for mark: Rect2i in tally_rects(quota):
		paint.call(Rect2(mark.position + at, mark.size), colors[2])
	for mark: Rect2i in tally_rects(admitted):
		paint.call(Rect2(mark.position + at, mark.size), colors[1])


## The closed book at `at`; `colors` maps the pattern's letters. Returns the wax dot's rect, or an
## empty one when no promise is open.
static func book(
	paint: Callable, at: Vector2i, colors: Dictionary[String, Color], sealed: bool, ember: Color
) -> Rect2:
	for y: int in range(BOOK_SIZE):
		var row: String = BOOK[y]
		for x: int in range(BOOK_SIZE):
			if colors.has(row[x]):
				paint.call(Rect2(at.x + x, at.y + y, 1, 1), colors[row[x]])
	if not sealed:
		return Rect2()
	var dot := Rect2(Vector2(at + WAX_DOT.position), Vector2(WAX_DOT.size))
	paint.call(dot, ember)
	return dot


## A PixelGlyph painted cell by cell, so the HUD records each cell.
static func glyph(paint: Callable, id: StringName, at: Vector2i, color: Color) -> void:
	var rows: Array = PixelGlyph.GLYPHS.get(id, [])
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] == "#":
				paint.call(Rect2(at.x + x, at.y + y, 1, 1), color)
