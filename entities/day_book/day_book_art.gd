class_name DayBookArt
extends RefCounted
## The day-book's objects drawn pixel by pixel in palette colours (art direction: small marks are
## placed in code): the candle on the dimmed desk, the book's board and Wood spine, the dog-eared
## corner, a leaf turning, and the ending's tableau on the gate band (D23):
## the tide's 6 px figures marching left from Hel's door, three empty benches under Valhalla's, or
## nothing but the doors for the Hall holds. Each drawer paints through `paint(rect, color)`;
## `colors` maps the DeskPalette names in COLOR_NAMES. The only ember here is the candle's flame,
## Ember 2 like the HUD's candle (one accent rule for candles); on the book, only its wax seal.

const THEME_TYPE := &"DeskPalette"
const COLOR_NAMES: Array[StringName] = [
	&"ink",
	&"ink_soft",
	&"text_light",
	&"parchment",
	&"parchment_light",
	&"parchment_dim",
	&"parchment_edge",
	&"wood_dark",
	&"wood_light",
	&"frame",
	&"glyph",
	&"select_light",
	&"night",
	&"pin_selected",
]
## The candle stands on the desk at the screen's bottom-left, in its dish.
const CANDLE_AT := Vector2i(10, 247)
const DISH := Rect2i(7, 264, 12, 2)
## The tide's figures: 3×6 (a head over a body), as on Hel's door; how far the leader walks
## across the band, and the head start each figure gives the next, in parts of the march.
const FIGURE := Vector2i(3, 6)
const MARCH_PX := 150
const MAX_STAGGER := 0.12
const MAX_MARCHERS := 12
## Above the door sprite's bottom: the threshold, where the figures walk and the benches stand.
const FIGURE_ABOVE_SILL := 8
const BENCH_ABOVE_SILL := 7
const BENCH := Vector2i(12, 4)
const BENCH_STEP := 18
const BENCH_INSET := 6


## The palette's colours the drawers use, by name, from `target`'s theme.
static func theme_colors(target: Control) -> Dictionary:
	var colors: Dictionary = {}
	for color_name: StringName in COLOR_NAMES:
		colors[color_name] = target.get_theme_color(color_name, THEME_TYPE)
	return colors


## `text` in the page's font with its ink's top-left at `ink_at` (a button's words).
static func words(canvas: Control, text: String, ink_at: Vector2i, color: Color) -> void:
	var font: Font = canvas.get_theme_default_font()
	if font == null:
		return
	var baseline: int = ceili(font.get_ascent(PixelFont.SIZE)) - DayBookPage.LABEL_TOP
	var at := Vector2(ink_at + Vector2i(0, baseline))
	canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, color)


## The candle (6×14 wax and its 2×3 flame in Ember 2, HudMarks' shape) in a Wood dish. Returns
## the flame's cells.
static func candle(paint: Callable, colors: Dictionary) -> Array[Rect2]:
	paint.call(Rect2(DISH), colors[&"frame"])
	paint.call(Rect2(DISH.position, Vector2i(DISH.size.x, 1)), colors[&"wood_light"])
	var ramp: Array[Color] = [
		colors[&"parchment_light"], colors[&"parchment"], colors[&"parchment_dim"]
	]
	return HudMarks.candle(
		paint,
		CANDLE_AT,
		HudMarks.CANDLE_HEIGHT,
		HudMarks.STEADY,
		ramp,
		colors[&"frame"],
		colors[&"pin_selected"]
	)


## The book's board, 2 px proud of the pages, and the Wood spine between them.
static func binding(paint: Callable, book: Rect2i, colors: Dictionary) -> void:
	paint.call(Rect2(book.grow(2)), colors[&"wood_dark"])
	paint.call(Rect2(book.grow(1)), colors[&"frame"])
	var page_width: int = int((book.size.x - DayBookLayout.SPINE) / 2.0)
	var spine := Rect2i(
		book.position.x + page_width, book.position.y - 1, DayBookLayout.SPINE, book.size.y + 2
	)
	paint.call(Rect2(spine), colors[&"frame"])
	paint.call(
		Rect2(spine.position + Vector2i(1, 0), Vector2i(2, spine.size.y)), colors[&"wood_dark"]
	)


## The right page's corner folded over: the corner shows the board, the flap its paler back; the
## flap lifts (Parchment 2) while hovered.
static func dog_ear(paint: Callable, book: Rect2i, hovered: bool, colors: Dictionary) -> void:
	var ear: Rect2i = DayBookLayout.dog_ear(book)
	var flap: Color = colors[&"parchment_light"] if hovered else colors[&"parchment_dim"]
	var size: int = ear.size.x
	for row: int in range(size):
		var y: int = ear.position.y + row
		var flap_width: int = size - row
		paint.call(Rect2(ear.position.x, y, flap_width, 1), flap)
		paint.call(Rect2(ear.position.x + flap_width - 1, y, 1, 1), colors[&"ink_soft"])
		if row > 0:
			paint.call(Rect2(ear.position.x + flap_width, y, row, 1), colors[&"wood_dark"])
	# The fold's crease along the flap's top and left.
	paint.call(Rect2(ear.position, Vector2i(size, 1)), colors[&"parchment_edge"])
	paint.call(Rect2(ear.position, Vector2i(1, size)), colors[&"parchment_edge"])


## A leaf turning from the right page over the spine to the left, `left` (1 to 0) of the turn to
## go: plain parchment narrowing over the right page, then widening over the left.
static func turning_leaf(paint: Callable, book: Rect2i, left: float, colors: Dictionary) -> void:
	var page_width: int = int((book.size.x - DayBookLayout.SPINE) / 2.0)
	var done: float = 1.0 - clampf(left, 0.0, 1.0)
	var spine_left: int = book.position.x + page_width
	var spine_right: int = spine_left + DayBookLayout.SPINE
	var leaf := Rect2i()
	if done < 0.5:
		var width: int = roundi(page_width * (1.0 - 2.0 * done))
		leaf = Rect2i(spine_right, book.position.y, width, book.size.y)
	else:
		var width: int = roundi(page_width * (2.0 * done - 1.0))
		leaf = Rect2i(spine_left - width, book.position.y, width, book.size.y)
	if leaf.size.x <= 0:
		return
	paint.call(Rect2(leaf), colors[&"parchment_dim"])
	paint.call(Rect2(leaf.position, Vector2i(leaf.size.x, 1)), colors[&"parchment_edge"])
	var outer: int = leaf.end.x - 1 if done < 0.5 else leaf.position.x
	paint.call(Rect2(outer, leaf.position.y, 1, leaf.size.y), colors[&"ink_soft"])


## The ending's tableau at `progress` (0 to 1) of its time: `marchers` figures for the tide.
## `doors` holds Valhalla's and Hel's door sprites' rects, in that order.
static func tableau(
	paint: Callable,
	kind: StringName,
	progress: float,
	marchers: int,
	doors: Array[Rect2],
	colors: Dictionary
) -> void:
	match kind:
		DayBook.TIDE:
			for at: Vector2i in tide_figures(progress, marchers, doors[1]):
				paint.call(Rect2(at + Vector2i(1, 0), Vector2i.ONE), colors[&"glyph"])
				paint.call(
					Rect2(at + Vector2i(0, 2), Vector2i(FIGURE.x, FIGURE.y - 2)), colors[&"glyph"]
				)
		DayBook.HOLLOW:
			for bench: Rect2i in benches(doors[0]):
				paint.call(Rect2(bench.position, Vector2i(BENCH.x, 2)), colors[&"frame"])
				paint.call(Rect2(bench.position, Vector2i(BENCH.x, 1)), colors[&"wood_light"])
				var legs_y: int = bench.position.y + 2
				paint.call(Rect2(bench.position.x + 1, legs_y, 1, 2), colors[&"wood_dark"])
				paint.call(Rect2(bench.end.x - 2, legs_y, 1, 2), colors[&"wood_dark"])


## Where each tide figure stands at `progress`: each sets out from Hel's door a little after the one
## before and walks left; every third pixel of the walk lifts it a pixel (a step). At 1 (reduce
## motion's end state) they stand in a file across the band.
static func tide_figures(progress: float, marchers: int, hel_door: Rect2) -> Array[Vector2i]:
	var count: int = clampi(marchers, 1, MAX_MARCHERS)
	var stagger: float = minf(MAX_STAGGER, 0.7 / count)
	var start_x: int = int(hel_door.position.x + hel_door.size.x / 2.0) - 1
	var floor_y: int = int(hel_door.end.y) - FIGURE_ABOVE_SILL
	var out: Array[Vector2i] = []
	for index: int in range(count):
		var walked: float = progress - index * stagger
		if walked < 0.0:
			continue
		var distance: int = roundi(MARCH_PX * walked)
		var lift: int = 1 if (distance / 3) % 2 == 1 else 0
		out.append(Vector2i(start_x - distance, floor_y - lift))
	return out


## The three empty benches under Valhalla's door, 12×4 each.
static func benches(valhalla_door: Rect2) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var y: int = int(valhalla_door.end.y) - BENCH_ABOVE_SILL
	for index: int in range(3):
		var x: int = int(valhalla_door.position.x) + BENCH_INSET + index * BENCH_STEP
		out.append(Rect2i(Vector2i(x, y), BENCH))
	return out
