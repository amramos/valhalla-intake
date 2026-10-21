class_name ThreadLine
extends Control
## One thread on the desk (D8): an axis-aligned route drawn pixel by pixel in its kind's colour
## and line pattern, so kinds differ by shape as well as colour. A grey thread carries an 8 px knot
## that selects it (for Huginn); an answered knot is filled.

signal knot_clicked(thread_index: int)
signal knot_hover_started(text: String, area: Rect2)
signal knot_hover_ended

const KNOT_SIZE := 8

## Seam.Kind: RED, GREY or LAW.
var kind: int = Seam.Kind.RED
var thread_index: int = -1
## The route, in global pixels.
var points: PackedVector2Array = PackedVector2Array()
## Where the thread meets its items (global): a 1 px wide cap is filled, a wider one outlined.
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
	if kind == Seam.Kind.GREY:
		_add_knot(KnotPlacer.place(pixels(), avoid, KNOT_SIZE), knot_hover)
	queue_redraw()


func has_knot() -> bool:
	return _knot != null


func knot() -> PinSelectable:
	return _knot


## True when pixel `at` (global) lies on the drawn route.
func covers(at: Vector2i) -> bool:
	for pixel: Vector2i in pixels():
		if pixel == at:
			return true
	return false


func _add_knot(corner: Vector2, hover: String) -> void:
	_knot = PinSelectable.new()
	_knot.name = "Knot"
	_knot.item_id = "knot:%d" % thread_index
	_knot.hover_text = hover
	_knot.select_color = get_theme_color(&"select_dark", &"DeskPalette")
	_knot.outline_color = get_theme_color(&"mark", &"DeskPalette")
	add_child(_knot)
	_knot.size = Vector2(KNOT_SIZE, KNOT_SIZE)
	_knot.global_position = corner
	_knot.clicked.connect(func(_id: String) -> void: knot_clicked.emit(thread_index))
	_knot.hover_started.connect(
		func(_id: String, text: String, at: Rect2) -> void: knot_hover_started.emit(text, at)
	)
	_knot.hover_ended.connect(func(_id: String) -> void: knot_hover_ended.emit())


func _draw() -> void:
	var color: Color = _color()
	var origin: Vector2 = global_position
	var step: int = 0
	for pixel: Vector2i in pixels():
		if _pattern_on(step):
			draw_rect(Rect2(Vector2(pixel) - origin, Vector2.ONE), color)
		step += 1
	for cap: Rect2 in caps:
		var local := Rect2(cap.position - origin, cap.size)
		if cap.size.x <= 1.0:
			draw_rect(local, color)
		else:
			draw_rect(local.grow(-0.5), color, false, 1.0)
	if _knot != null:
		_draw_knot(Rect2(_knot.global_position - origin, _knot.size), color)


func _draw_knot(area: Rect2, color: Color) -> void:
	var inner: Rect2 = area.grow(-1)
	draw_rect(inner, get_theme_color(&"desk", &"DeskPalette"))
	draw_rect(inner.grow(-0.5), color, false, 1.0)
	if answered:
		draw_rect(inner.grow(-2), color)
	else:
		draw_rect(Rect2(inner.get_center() - Vector2.ONE, Vector2(2, 2)), color)


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
