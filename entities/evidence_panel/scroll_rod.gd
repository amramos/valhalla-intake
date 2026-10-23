class_name ScrollRod
extends RefCounted
## The Law scroll's wooden rod (D9): a 4 px band of knotwork in the Wood ramp, a 2 px braid of
## light and mid wood between two dark rows, with dark end caps. Whole-pixel rects only.

const HEIGHT := 4
## The braid repeats every this many pixels: 2 px of light wood, then 2 px of mid.
const PERIOD := 4


## Paints one rod with its top-left at `at`, `width` pixels long, through `paint` (a
## `(Rect2, Color)` callable). `colors` holds the
## dark, mid and light wood (Wood 2, 3 and 4).
static func draw(paint: Callable, at: Vector2i, width: int, colors: Array[Color]) -> void:
	if width <= 0 or colors.size() < 3:
		return
	var dark: Color = colors[0]
	var mid: Color = colors[1]
	var light: Color = colors[2]
	var origin := Vector2(at)
	paint.call(Rect2(origin, Vector2(width, 1)), dark)
	paint.call(Rect2(origin + Vector2(0, HEIGHT - 1), Vector2(width, 1)), dark)
	for x: int in range(0, width, 2):
		var run: float = float(mini(2, width - x))
		var lit_top: bool = x % PERIOD < PERIOD / 2
		paint.call(Rect2(origin + Vector2(x, 1), Vector2(run, 1)), light if lit_top else mid)
		paint.call(Rect2(origin + Vector2(x, 2), Vector2(run, 1)), mid if lit_top else light)
	paint.call(Rect2(origin, Vector2(1, HEIGHT)), dark)
	paint.call(Rect2(origin + Vector2(width - 1, 0), Vector2(1, HEIGHT)), dark)


## The colour of rod pixel (x, y) (tests): 0 dark, 1 mid, 2 light.
static func shade_at(x: int, y: int, width: int) -> int:
	if y <= 0 or y >= HEIGHT - 1 or x <= 0 or x >= width - 1:
		return 0
	var lit_top: bool = x % PERIOD < PERIOD / 2
	if y == 1:
		return 2 if lit_top else 1
	return 1 if lit_top else 2
