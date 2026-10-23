class_name ThreadLine
extends Control
## One thread on the desk (D8, D12): an axis-aligned route pinned at both ends, drawn pixel by
## pixel 3 px wide (an ink halo, a core in its kind's colour and a lighter edge) in its kind's line
## pattern, so kinds differ by shape as well as colour (red bold and unbroken, grey dotted, law
## dashed; no reserved colour). A 5×5 wooden pin head holds each end. A grey thread carries an
## 8 px tied knot that selects it for Huginn (filled once answered); every other thread carries a
## 6 px bead. A click on either shows the thread's caption again (D33).

signal knot_clicked(thread_index: int)
signal knot_hover_started(text: String, area: Rect2)
signal knot_hover_ended

const KNOT_SIZE := 8
const BEAD_SIZE := 6
const PIN_SIZE := PinSelectable.PIN_SIZE
## How far the slack thread falls when a pin finds no seam (D36).
const DROP_PIXELS := 20
## The tied knot: "#" is thread, "o" the loop filled once Huginn has answered.
const KNOT: Array[String] = [
	"..####..",
	".#oooo#.",
	"#oo##oo#",
	"#o#oo#o#",
	".#o##o#.",
	"..#..#..",
	".#....#.",
	"#......#",
]
## The bead: "#" ink, "c" thread, "h" the thread's lighter edge.
const BEAD: Array[String] = [
	".####.",
	"#cccc#",
	"#chcc#",
	"#cccc#",
	"#cccc#",
	".####.",
]

## Seam.Kind: RED, GREY or LAW.
var kind: int = Seam.Kind.RED
var thread_index: int = -1
## The route, in global pixels.
var points: PackedVector2Array = PackedVector2Array()
## Where the thread meets its items (global): the router's caps, kept for tools.
var caps: Array[Rect2] = []
var answered: bool = false:
	set(value):
		answered = value
		queue_redraw()
var selected: bool = false:
	set(value):
		selected = value
		if _knot != null:
			_knot.selected = value
		queue_redraw()

var _knot: PinSelectable = null
## How many route pixels show while the thread is drawn taut; -1 for all.
var _reveal: int = -1
## How far the thread has fallen, in pixels.
var _drop: int = 0
## What the last `_draw` painted, in order, in local pixels (tests).
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sets the route; a grey thread gets its knot near the middle of the route, clear of every rect
## in `avoid` (the desk's other hit areas).
func setup(
	p_kind: int,
	p_index: int,
	p_points: PackedVector2Array,
	p_caps: Array[Rect2],
	knot_hover: String,
	avoid: Array[Rect2] = []
) -> void:
	kind = p_kind
	thread_index = p_index
	points = p_points
	caps = p_caps
	var knot_size: int = knot_size_for(kind)
	_add_knot(KnotPlacer.place(pixels(), avoid, knot_size), knot_size, knot_hover)
	queue_redraw()


## The knot of a grey thread is 8 px (D8); other threads carry a 6 px bead.
static func knot_size_for(p_kind: int) -> int:
	return KNOT_SIZE if p_kind == Seam.Kind.GREY else BEAD_SIZE


func has_knot() -> bool:
	return _knot != null


func knot() -> PinSelectable:
	return _knot


## Draws the thread taut from its first end to its second over `seconds` (D12); the knot shows
## once the thread is whole. Returns the tween (null when drawn at once: no tree or no time).
func draw_in(seconds: float = 0.15) -> Tween:
	var total: int = pixels().size()
	if seconds <= 0.0 or total == 0 or not is_inside_tree():
		_set_reveal(-1)
		return null
	_set_reveal(1)
	var tween: Tween = create_tween()
	tween.tween_method(_reveal_fraction.bind(total), 0.0, 1.0, seconds)
	tween.tween_callback(_set_reveal.bind(-1))
	return tween


## True while the thread is still being drawn.
func is_drawing_in() -> bool:
	return _reveal >= 0


## A pin with no seam (D36, D51): the thread goes slack and falls `DROP_PIXELS`, then is freed.
## Purely cosmetic: its knot stops taking the mouse at once. Returns the tween (null when freed at
## once).
func slacken_and_drop(seconds: float = 0.4) -> Tween:
	if _knot != null:
		_knot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if seconds <= 0.0 or not is_inside_tree():
		queue_free()
		return null
	var tween: Tween = create_tween()
	tween.tween_method(_set_drop, 0.0, float(DROP_PIXELS), seconds)
	tween.tween_callback(queue_free)
	return tween


## True when pixel `at` (global) lies on the drawn route.
func covers(at: Vector2i) -> bool:
	for pixel: Vector2i in pixels():
		if pixel == at:
			return true
	return false


## The two pin heads' rectangles in global pixels, first end first (tests and the fit check).
func pin_head_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var route: Array[Vector2i] = pixels()
	if route.is_empty():
		return rects
	for end: Vector2i in [route[0], route[route.size() - 1]]:
		rects.append(Rect2(Vector2(end - Vector2i(2, 2)), Vector2(PIN_SIZE, PIN_SIZE)))
	return rects


## Every rectangle the last draw painted, in order (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


## The colour of each rectangle in `drawn_rects()`.
func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _add_knot(corner: Vector2, knot_size: int, hover: String) -> void:
	_knot = PinSelectable.new()
	_knot.name = "Knot"
	_knot.item_id = "knot:%d" % thread_index
	_knot.hover_text = hover
	_knot.hover_mark = PinSelectable.HoverMark.OUTLINE
	_knot.select_color = get_theme_color(&"select_dark", &"DeskPalette")
	_knot.outline_color = get_theme_color(&"mark", &"DeskPalette")
	_knot.pin_color = get_theme_color(&"pin_selected", &"DeskPalette")
	_knot.pin_shadow = get_theme_color(&"pin_selected_shadow", &"DeskPalette")
	_knot.pin_highlight = get_theme_color(&"pin_highlight", &"DeskPalette")
	add_child(_knot)
	_knot.size = Vector2(knot_size, knot_size)
	_knot.global_position = corner
	_knot.clicked.connect(func(_id: String) -> void: knot_clicked.emit(thread_index))
	_knot.hover_started.connect(
		func(_id: String, text: String, at: Rect2) -> void: knot_hover_started.emit(text, at)
	)
	_knot.hover_ended.connect(func(_id: String) -> void: knot_hover_ended.emit())


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var color: Color = _color()
	var edge: Color = _edge_color()
	var ink: Color = get_theme_color(&"ink", &"DeskPalette")
	var origin: Vector2 = global_position - Vector2(0, _drop)
	var route: Array[Vector2i] = pixels()
	var shown: int = route.size() if _reveal < 0 else mini(_reveal, route.size())
	for index: int in range(shown):
		_paint(Rect2(Vector2(route[index]) - origin - Vector2.ONE, Vector2(3, 3)), ink)
	for index: int in range(shown):
		if not _pattern_on(index):
			continue
		_paint(Rect2(Vector2(route[index]) - origin, Vector2.ONE), color)
		# The lighter edge runs beside the core on one side: 3 px in all with the halo (D12).
		var along: Vector2i = route[mini(index + 1, route.size() - 1)] - route[maxi(index - 1, 0)]
		var side := Vector2i(1, 0) if absi(along.y) >= absi(along.x) else Vector2i(0, 1)
		_paint(Rect2(Vector2(route[index] + side) - origin, Vector2.ONE), edge)
	if shown == 0:
		return
	_draw_pin(route[0], origin)
	if _reveal >= 0:
		return
	_draw_pin(route[route.size() - 1], origin)
	if _knot != null:
		var corner := Vector2i(_knot.global_position - origin)
		if kind == Seam.Kind.GREY:
			_draw_knot(corner, color, ink)
		else:
			_draw_bead(corner, color, edge, ink)


func _draw_pin(end: Vector2i, origin: Vector2) -> void:
	PinSelectable.draw_pin_head(
		_paint,
		end - Vector2i(2, 2) - Vector2i(origin),
		get_theme_color(&"pin_head", &"DeskPalette"),
		get_theme_color(&"pin_highlight", &"DeskPalette"),
		get_theme_color(&"ink", &"DeskPalette")
	)


## The tied knot on an ink backing that hugs its strands.
func _draw_knot(corner: Vector2i, color: Color, ink: Color) -> void:
	for y: int in range(KNOT_SIZE):
		for x: int in range(KNOT_SIZE):
			if _knot_backed(x, y):
				_paint(Rect2(Vector2(corner + Vector2i(x, y)), Vector2.ONE), ink)
	for y: int in range(KNOT_SIZE):
		for x: int in range(KNOT_SIZE):
			var code: String = KNOT[y][x]
			if code == "#" or (code == "o" and answered):
				_paint(Rect2(Vector2(corner + Vector2i(x, y)), Vector2.ONE), color)


func _knot_backed(x: int, y: int) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and ny >= 0 and nx < KNOT_SIZE and ny < KNOT_SIZE and KNOT[ny][nx] == "#":
				return true
	return false


func _draw_bead(corner: Vector2i, color: Color, edge: Color, ink: Color) -> void:
	for y: int in range(BEAD_SIZE):
		for x: int in range(BEAD_SIZE):
			var code: String = BEAD[y][x]
			if code == ".":
				continue
			var fill: Color = ink if code == "#" else (edge if code == "h" else color)
			_paint(Rect2(Vector2(corner + Vector2i(x, y)), Vector2.ONE), fill)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)


func _reveal_fraction(fraction: float, total: int) -> void:
	_set_reveal(clampi(ceili(fraction * total), 1, total))


func _set_reveal(count: int) -> void:
	_reveal = count
	if _knot != null:
		_knot.visible = count < 0
	queue_redraw()


func _set_drop(pixels_down: float) -> void:
	_drop = roundi(pixels_down)
	queue_redraw()


func _pattern_on(step: int) -> bool:
	match kind:
		Seam.Kind.GREY:
			return step % 2 == 0
		Seam.Kind.LAW:
			return step % 5 < 3
	return true


func _color() -> Color:
	match kind:
		Seam.Kind.GREY:
			return get_theme_color(&"thread_grey", &"DeskPalette")
		Seam.Kind.LAW:
			return get_theme_color(&"thread_law", &"DeskPalette")
	return get_theme_color(&"thread_red", &"DeskPalette")


## The core's lighter edge: Wood 4 beside the rust red, Parchment 2 beside grey and law.
func _edge_color() -> Color:
	if kind == Seam.Kind.RED:
		return get_theme_color(&"thread_red_light", &"DeskPalette")
	return get_theme_color(&"pin_highlight", &"DeskPalette")


## Every pixel of the route, in order, each corner once.
func pixels() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for index: int in range(points.size() - 1):
		var a := Vector2i(points[index])
		var b := Vector2i(points[index + 1])
		var delta: Vector2i = b - a
		var steps: int = maxi(absi(delta.x), absi(delta.y))
		var start: int = 0 if index == 0 else 1
		for s: int in range(start, steps + 1):
			var t: float = float(s) / float(maxi(steps, 1))
			out.append(Vector2i(Vector2(a).lerp(Vector2(b), t).round()))
	return out
