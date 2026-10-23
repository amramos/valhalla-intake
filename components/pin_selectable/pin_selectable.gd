class_name PinSelectable
extends Control
## One clickable piece of evidence (D5, D8): a body fact, a testimony line, a decree or a thread's
## knot. A left click asks to select it; a right click asks to cancel the selection. It never
## decides anything itself: its owner reads the signals and sets `selected` and `lit`.
##
## Its marks are drawn pixel by pixel and never cross its text (D12): a hovered line is underlined
## in ink on its last row, a hovered fact shows corner brackets, and the selected item carries a
## stuck pin head beside it instead of a filled box. A fact (corner marks) never shows a
## rectangular outline: lit, its brackets take the lit colour; selected, it keeps its corner marks
## under the pin.

signal clicked(item_id: String)
signal cancel_requested
signal hover_started(item_id: String, text: String, area: Rect2)
signal hover_ended(item_id: String)

## How a hovered area is marked.
enum HoverMark { UNDERLINE, CORNERS, OUTLINE }

## The smallest hit area a fact may have (D5).
const MIN_SIZE := Vector2(8, 8)
## A pin head is 5×5 (D12).
const PIN_SIZE := 5
## Arm length of a hovered fact's corner brackets.
const BRACKET := 3

@export var item_id: String = ""
## Shown by the owner's hover label; "" for none (a line whose text is already on screen).
@export var hover_text: String = ""
## Draws corner ticks so an area with nothing drawn in it (an absence) can still be found.
@export var show_corners: bool = false
## Draws the outline even when idle (the fit check shows every hit area).
@export var show_outline: bool = false
@export var hover_mark: HoverMark = HoverMark.OUTLINE
## The underline's length from the left edge; -1 underlines the whole width.
@export var underline_width: int = -1
## True: the stuck pin sits inside the area's top-left corner (a fact on the chart). False: it
## hangs just left of the area, centred on its first text row, so it never covers a letter.
@export var pin_inside: bool = false
@export var outline_color: Color = Color(0.7608, 0.8039, 0.7882, 1)
@export var underline_color: Color = Color(0.0431, 0.0902, 0.1333, 1)
@export var select_color: Color = Color(0.1137, 0.3529, 0.4275, 1)
@export var lit_color: Color = Color(0.4902, 0.3922, 0.3137, 1)
## The stuck pin's head, its 1 px highlight and its shadow (Ember 2, Parchment 2, Ember 0).
@export var pin_color: Color = Color(0.8784, 0.5412, 0.2902, 1)
@export var pin_highlight: Color = Color(0.9647, 0.9333, 0.8235, 1)
@export var pin_shadow: Color = Color(0.4196, 0.1843, 0.1176, 1)

## The first item of a pin in progress (D8).
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## Part of a pair being pointed at (a re-pin, a citation, a caption's quoted pair).
var lit: bool = false:
	set(value):
		lit = value
		queue_redraw()

var _hovered: bool = false
## What the last `_draw` painted, in order (tests).
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


## Paints a 5×5 pin head with its top-left at `corner` through `paint` (a `(Rect2, Color)`
## callable): a round head with one highlight pixel and a shadow along its bottom and right
## (D12). Shared by the stuck pin, the threads' pins and the note's marks.
static func draw_pin_head(
	paint: Callable, corner: Vector2i, head: Color, highlight: Color, shadow: Color
) -> void:
	var at := Vector2(corner)
	paint.call(Rect2(at + Vector2(1, 0), Vector2(3, 1)), head)
	paint.call(Rect2(at + Vector2(0, 1), Vector2(4, 3)), head)
	paint.call(Rect2(at + Vector2(1, 1), Vector2(1, 1)), highlight)
	paint.call(Rect2(at + Vector2(4, 1), Vector2(1, 3)), shadow)
	paint.call(Rect2(at + Vector2(1, 4), Vector2(3, 1)), shadow)


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(MIN_SIZE)
	size = size.max(MIN_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Simulates the player's click; the integration tests and tools use it.
func press() -> void:
	clicked.emit(item_id)


func is_hovered() -> bool:
	return _hovered


## Every rectangle the last draw painted, in order, in local pixels (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


## The colour of each rectangle in `drawn_rects()`.
func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


## Where the stuck pin's head is drawn, in local pixels (tests and the fit check).
func pin_rect() -> Rect2:
	if pin_inside:
		return Rect2(Vector2.ONE, Vector2(PIN_SIZE, PIN_SIZE))
	return Rect2(Vector2(-PIN_SIZE, 1), Vector2(PIN_SIZE, PIN_SIZE))


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_LEFT:
		# The second press of a double-click would cancel the first; one deliberate click counts.
		if not button.double_click:
			clicked.emit(item_id)
		accept_event()
	elif button.button_index == MOUSE_BUTTON_RIGHT:
		cancel_requested.emit()
		accept_event()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var area := Rect2(Vector2.ZERO, size)
	if lit and hover_mark == HoverMark.CORNERS:
		_draw_corners(area, BRACKET, lit_color)
	elif lit:
		_outline(area, lit_color)
	elif show_outline:
		_outline(area, outline_color)
	elif _hovered:
		_draw_hover(area)
	elif show_corners or (selected and hover_mark == HoverMark.CORNERS):
		_draw_corners(area, 1, outline_color)
	if selected:
		var pin: Rect2 = pin_rect()
		draw_pin_head(_paint, Vector2i(pin.position), pin_color, pin_highlight, pin_shadow)


func _draw_hover(area: Rect2) -> void:
	match hover_mark:
		HoverMark.UNDERLINE:
			var width: float = area.size.x if underline_width < 0 else float(underline_width)
			_paint(Rect2(0, area.size.y - 1, width, 1), underline_color)
		HoverMark.CORNERS:
			_draw_corners(area, BRACKET, outline_color)
		_:
			_outline(area, outline_color)


## A 1 px outline just inside the area, as four whole-pixel rects.
func _outline(area: Rect2, color: Color) -> void:
	var w: float = area.size.x
	var h: float = area.size.y
	_paint(Rect2(0, 0, w, 1), color)
	_paint(Rect2(0, h - 1, w, 1), color)
	_paint(Rect2(0, 1, 1, h - 2), color)
	_paint(Rect2(w - 1, 1, 1, h - 2), color)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)


## Corner marks: single pixels when idle, `arm`-long brackets when hovered or lit.
func _draw_corners(area: Rect2, arm: int, color: Color) -> void:
	var right: float = area.size.x - 1.0
	var bottom: float = area.size.y - 1.0
	var reach: float = float(arm - 1)
	for corner: Vector2 in [
		Vector2(0, 0), Vector2(right, 0), Vector2(0, bottom), Vector2(right, bottom)
	]:
		var dx: float = reach if corner.x == 0.0 else -reach
		var dy: float = reach if corner.y == 0.0 else -reach
		_paint(Rect2(minf(corner.x, corner.x + dx), corner.y, arm, 1), color)
		_paint(Rect2(corner.x, minf(corner.y, corner.y + dy), 1, arm), color)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	hover_started.emit(item_id, hover_text, get_global_rect())


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	hover_ended.emit(item_id)
