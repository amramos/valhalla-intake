class_name HangingSheet
extends Control
## A parchment hung on the wall by two 3×3 Wood 3 pin heads at its top corners, its heading in the
## carved capitals centred near its top (the pause, the options panel: D37, D42). The sheet is a
## ParchmentFrame drawn behind; the pins and the heading are whole-pixel rects over it, in palette
## colours. It never takes the mouse.

## The heading's top below the sheet's, and the pin heads' inset from its top corners.
const HEADING_TOP := 8
const PIN_INSET := Vector2i(3, 3)
const PIN_SIZE := 3
const THEME_TYPE := &"DeskPalette"

## The heading, drawn in capitals.
@export var heading: String = "":
	set(value):
		heading = value
		queue_redraw()
## Seeds the deckle of the sheet.
@warning_ignore("shadowed_global_identifier") @export var seed: int = 0:
	set(value):
		seed = value
		if _frame != null:
			_frame.seed = value

var _frame: ParchmentFrame = null
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = ParchmentFrame.new()
	_frame.name = "Parchment"
	_frame.show_behind_parent = true
	_frame.seed = seed
	add_child(_frame)
	resized.connect(_fit)
	_fit()


## The heading's rect in local pixels (its outline and shadow included).
func heading_rect() -> Rect2:
	var width: int = PixelCapitals.width(heading)
	return Rect2(floorf((size.x - width) / 2.0), HEADING_TOP, width, PixelCapitals.HEIGHT)


## The two pin heads' rects in local pixels.
func pin_rects() -> Array[Rect2]:
	var right: int = int(size.x) - PIN_INSET.x - PIN_SIZE - 1
	var pins: Array[Rect2] = []
	for x: int in [PIN_INSET.x, right]:
		pins.append(Rect2(x, PIN_INSET.y, PIN_SIZE, PIN_SIZE))
	return pins


## Every rectangle the last draw painted over the parchment, in order (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _fit() -> void:
	if _frame != null:
		_frame.size = size
	queue_redraw()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	if heading != "":
		PixelCapitals.paint_runs(
			heading,
			Vector2i(heading_rect().position),
			_paint,
			_color(&"parchment_light"),
			_color(&"ink"),
			_color(&"night")
		)
	for pin: Rect2 in pin_rects():
		_paint(pin, _color(&"pin_head"))
		_paint(Rect2(pin.position, Vector2.ONE), _color(&"pin_highlight"))
		_paint(Rect2(pin.end - Vector2.ONE, Vector2.ONE), _color(&"parchment_shadow"))


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)


func _color(color_name: StringName) -> Color:
	return get_theme_color(color_name, THEME_TYPE)
