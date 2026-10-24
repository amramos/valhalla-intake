class_name ParchmentFrame
extends Control
## A parchment sheet drawn in code (D8): a flat Parchment 1 ground, a 1-2 px deckled edge in
## Parchment 0 with Parchment 2 fibres, bites out of the edge when `torn`, an optional faint rule
## row, and a 1 px Wood 1 shadow along the bottom and right. Everything is a whole-pixel
## `draw_rect` in palette colours, laid out by a generator seeded from `seed`, so a sheet looks
## the same on every frame and every run. `inner` (the text area and hit rectangles) is solid
## flat ground, even where it reaches into the edge band: no edge, bite, rule or shadow pixel is
## ever painted inside it. It never takes the mouse.

enum Code { NONE, EDGE, LIGHT, SHEET, SHADOW, RULE }

## Palette fallbacks (docs/art/palette.gpl) for a frame outside the desk theme.
const PARCHMENT_0 := Color8(211, 201, 171)
const PARCHMENT_1 := Color8(246, 224, 183)
const PARCHMENT_2 := Color8(246, 238, 210)
const WOOD_1 := Color8(48, 42, 44)
const THEME_TYPE := &"DeskPalette"
## Chance per edge pixel that a 2 px deckle run, a light fibre or a bite begins.
const DECKLE_CHANCE := 0.2
const FIBRE_CHANCE := 0.15
const BITE_CHANCE := 0.12
const MAX_RUN := 3

## Seeds the deckle; the same seed and size always draw the same sheet.
@warning_ignore("shadowed_global_identifier") @export var seed: int = 0:
	set(value):
		seed = value
		queue_redraw()
## The text area in local coordinates: nothing but the flat ground is painted inside it.
@export var inner: Rect2 = Rect2():
	set(value):
		inner = value
		queue_redraw()
## Bites taken out of the outer edge, as a torn sheet.
@export var torn: bool = false:
	set(value):
		torn = value
		queue_redraw()
## The local row of a faint rule across the sheet; -1 for none.
@export var rule_y: int = -1:
	set(value):
		rule_y = value
		queue_redraw()

var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Every rectangle the last `_draw` painted, in order; the first is the flat ground.
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


## The colour of each rectangle in `drawn_rects()`.
func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var width: int = int(size.x)
	var height: int = int(size.y)
	if width < 3 or height < 3:
		return
	# The sheet leaves its last column and row to the shadow.
	var sheet := Vector2i(width - 1, height - 1)
	var codes := PackedByteArray()
	codes.resize(width * height)
	var interior := Rect2i(Vector2i(2, 2), sheet - Vector2i(4, 4))
	if sheet.x < 6 or sheet.y < 6:
		interior = Rect2i(Vector2i.ZERO, sheet)
	else:
		_layout(codes, width, height, sheet)
	# One ground rect, grown to every pixel `inner` touches, so the text area is solid parchment
	# even where it reaches into the edge band.
	var ground: Rect2i = interior
	var touched: Rect2i = _inner_pixels(width, height)
	if touched.has_area():
		ground = ground.merge(touched)
	_paint(ground, _color(Code.SHEET))
	_ground_inner(codes, width, interior, ground)
	for y: int in range(height):
		_paint_row(codes, width, y)


## The edge band, the rule and the shadow as one code per pixel; the ground is not in it.
func _layout(codes: PackedByteArray, width: int, height: int, sheet: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var right: int = sheet.x - 1
	var bottom: int = sheet.y - 1
	_edge(codes, width, rng, Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), sheet.x, true)
	_edge(codes, width, rng, Vector2i(0, bottom), Vector2i(1, 0), Vector2i(0, -1), sheet.x, false)
	_edge(codes, width, rng, Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), sheet.y, true)
	_edge(codes, width, rng, Vector2i(right, 0), Vector2i(0, 1), Vector2i(-1, 0), sheet.y, false)
	if rule_y >= 2 and rule_y <= bottom - 2:
		for x: int in range(2, right - 1):
			codes[rule_y * width + x] = Code.RULE
	for x: int in range(1, width):
		if codes[bottom * width + mini(x, right)] != Code.NONE:
			codes[(height - 1) * width + x] = Code.SHADOW
	for y: int in range(1, height - 1):
		if codes[y * width + right] != Code.NONE:
			codes[y * width + width - 1] = Code.SHADOW


## The ground lies under every pixel `inner` touches, so those pixels paint nothing more. Where
## the ground reaches past the interior into the edge band, a bite outside `inner` would show the
## ground beyond the edge line, so it becomes edge instead.
func _ground_inner(codes: PackedByteArray, width: int, interior: Rect2i, ground: Rect2i) -> void:
	for y: int in range(ground.position.y, ground.end.y):
		for x: int in range(ground.position.x, ground.end.x):
			var index: int = y * width + x
			if inner.intersects(Rect2(x, y, 1, 1)):
				codes[index] = Code.NONE
			elif codes[index] == Code.NONE and not interior.has_point(Vector2i(x, y)):
				codes[index] = Code.EDGE


## The whole pixels `inner` touches, within the frame; empty when it touches none.
func _inner_pixels(width: int, height: int) -> Rect2i:
	if not inner.has_area():
		return Rect2i()
	var from := Vector2i(floori(inner.position.x), floori(inner.position.y))
	var to := Vector2i(ceili(inner.end.x), ceili(inner.end.y))
	return Rect2i(from, to - from).intersection(Rect2i(0, 0, width, height))


## One side of the sheet: `length` pixels from `origin` along `along`; `inward` points into the
## sheet. The outer ring is Parchment 0 (with light fibres on the lit top and left sides), the
## ring inside it is parchment with 2 px deckle runs; a bite empties the outer ring and moves the
## edge one pixel in.
func _edge(
	codes: PackedByteArray,
	width: int,
	rng: RandomNumberGenerator,
	origin: Vector2i,
	along: Vector2i,
	inward: Vector2i,
	length: int,
	lit: bool
) -> void:
	var deckle_left: int = 0
	var bite_left: int = 0
	for step: int in range(length):
		var outer: Vector2i = origin + along * step
		var ring: Vector2i = outer + inward
		var at_end: bool = step == 0 or step == length - 1
		if bite_left == 0 and torn and not at_end and rng.randf() < BITE_CHANCE:
			bite_left = rng.randi_range(1, MAX_RUN)
		if deckle_left == 0 and rng.randf() < DECKLE_CHANCE:
			deckle_left = rng.randi_range(1, MAX_RUN)
		var fibre: bool = lit and rng.randf() < FIBRE_CHANCE
		var outer_code: int = Code.LIGHT if fibre else Code.EDGE
		var ring_code: int = Code.EDGE if deckle_left > 0 else Code.SHEET
		if bite_left > 0:
			outer_code = Code.NONE
			ring_code = Code.EDGE
			bite_left -= 1
		elif torn and at_end:
			outer_code = Code.NONE
		if deckle_left > 0:
			deckle_left -= 1
		codes[outer.y * width + outer.x] = outer_code
		if not at_end:
			codes[ring.y * width + ring.x] = ring_code


## Paints row `y` of the code map as runs of one colour.
func _paint_row(codes: PackedByteArray, width: int, y: int) -> void:
	var x: int = 0
	while x < width:
		var code: int = codes[y * width + x]
		var end: int = x + 1
		while end < width and codes[y * width + end] == code:
			end += 1
		if code != Code.NONE:
			_paint(Rect2i(x, y, end - x, 1), _color(code))
		x = end


func _paint(area: Rect2i, color: Color) -> void:
	var rect := Rect2(area)
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)


func _color(code: int) -> Color:
	match code:
		Code.EDGE:
			return _theme_color(&"parchment_edge", PARCHMENT_0)
		Code.LIGHT:
			return _theme_color(&"parchment_light", PARCHMENT_2)
		Code.SHADOW:
			return _theme_color(&"parchment_shadow", WOOD_1)
		Code.RULE:
			return _theme_color(&"rule", PARCHMENT_0)
	return _theme_color(&"parchment", PARCHMENT_1)


func _theme_color(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback
