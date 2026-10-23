class_name MentorBubble
extends Control
## The mentor's speech bubble by her portrait (D16, D18, D33): guided step prompts only, never the
## clerk's note. A parchment bubble with its corners rounded off and a 3 px tail pointing left at
## her portrait; her words are written out at `write_cps` (never longer than a second, D43).
##
## A step the player only has to read waits for a click on the bubble: while one will advance it,
## a 3×5 arrow blinks at the bottom right. The first click finishes the writing; a later
## deliberate click (armed a moment after the writing ends, never the second press of a
## double-click) emits `acknowledged`. A step that waits for a pin or a stamp shows no arrow.

## A deliberate click on a READ step whose words are all written.
signal acknowledged
## Her words began to be written out (the system holds the presentation gate meanwhile).
signal reveal_started
## Her words are all written (by pace, by a click or by `finish_reveal`).
signal reveal_finished

## The tail's width, drawn left of the bubble's rect (toward her portrait).
const TAIL := 3
## The tail's top row, level with her face.
const TAIL_Y := 14
## The text's left edge and the label's top; the first ink row is 3 px under the bubble's top.
const TEXT_LEFT := 2
const TEXT_TOP := -1
## Pixels right of the text: one of ground, the edge, the shadow.
const TEXT_RIGHT := 2
## Pixels between text lines (ADR-0008).
const LINE_PITCH := 10
## The arrow: 3×5, pointing right, inside the bottom-right corner.
const ARROW: Array[String] = ["#..", "##.", "###", "##.", "#.."]
const ARROW_SIZE := Vector2i(3, 5)
## The arrow's offset from the bubble's bottom-right corner (shadow, edge and a gap of ground).
const ARROW_INSET := Vector2i(3, 3)
## The arrow shows for this long, then hides for as long.
const BLINK_SECONDS := 0.4
## The writing never takes longer than this (D43).
const MAX_WRITE_SECONDS := 1.0
## Clicks this soon after the writing ends are ignored (a double-click never advances, D18).
const ARM_SECONDS := 0.3

## Her pace in characters a second (60 at normal text speed; INF writes at once).
@export var write_cps: float = 60.0
## No blinking: the arrow shows steadily (D37).
var reduce_motion: bool = false

var _text: Label = null
var _teller: Teller = null
var _wants_ack: bool = false
var _revealing: bool = false
var _armed_at_msec: int = 0
var _blink: float = 0.0
## What the last `_draw` painted, in order (tests).
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_text = Label.new()
	_text.name = "Text"
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.add_theme_color_override(&"font_color", get_theme_color(&"ink", &"DeskPalette"))
	_text.position = Vector2(TEXT_LEFT, TEXT_TOP)
	add_child(_text)
	_text.size = Vector2(text_width_for(int(size.x)), 0)
	_teller = Teller.new()
	_teller.name = "Quill"
	add_child(_teller)
	_teller.finished.connect(_on_revealed)
	visible = false


## The text's width in a bubble `width` pixels wide (the authoring check measures with it).
static func text_width_for(width: int) -> int:
	return width - TEXT_LEFT - TEXT_RIGHT


## How many lines of text fit above the arrow in a bubble `height` pixels tall.
static func lines_for(height: int) -> int:
	var arrow_top: int = height - ARROW_INSET.y - ARROW_SIZE.y - 1
	# A line's ink, descenders included, runs from its top + 4 to its top + 12.
	return maxi(0, (arrow_top - (TEXT_TOP + 12)) / LINE_PITCH + 1)


## Shows one step; `wants_ack` makes it wait for a click (a step the player only reads). A new
## text is written out from the start; the same text again leaves the bubble as it is.
func show_step(text: String, wants_ack: bool) -> void:
	var changed: bool = text != _text.text or not visible
	_wants_ack = wants_ack
	visible = true
	if changed:
		_reveal(text)
	queue_redraw()


func hide_step() -> void:
	_teller.stop()
	var was_revealing: bool = _revealing
	_revealing = false
	_text.visible_characters = -1
	visible = false
	_text.text = ""
	_wants_ack = false
	if was_revealing:
		reveal_finished.emit()


func shown_text() -> String:
	return _text.text if visible else ""


## The bubble's Teller, for the presentation gate (pause).
func teller() -> Teller:
	return _teller


func is_revealing() -> bool:
	return _revealing


## Writes the rest at once (a consumed click, D27); the next click must still be deliberate.
func finish_reveal() -> void:
	if _revealing:
		_teller.finish()


## True when the shown step waits for a click on the bubble.
func wants_ack() -> bool:
	return visible and _wants_ack


## True while the arrow is in play: a READ step, written out (it may be in its dark blink).
func shows_arrow() -> bool:
	return wants_ack() and not _revealing


## True when a click now would advance the step.
func is_armed() -> bool:
	return shows_arrow() and Time.get_ticks_msec() >= _armed_at_msec


## Arms the bubble at once (tests and tools; players wait the arm time).
func arm_now() -> void:
	_armed_at_msec = 0


## A deliberate click on the bubble, as `_gui_input` takes it (tests and tools).
func press() -> void:
	if _revealing:
		finish_reveal()
	elif is_armed():
		acknowledged.emit()


## The arrow's rect in local pixels.
func arrow_rect() -> Rect2:
	var at := Vector2i(size) - ARROW_INSET - ARROW_SIZE
	return Rect2(Vector2(at), Vector2(ARROW_SIZE))


## The rows and columns the text's ink may use, in local pixels (tests): every line, from its
## first ink row to the last of its descenders.
func text_rect() -> Rect2:
	var lines: int = _text.get_line_count() if _text.text != "" else 0
	var height: int = maxi(lines * LINE_PITCH - 1, 0)
	return Rect2(TEXT_LEFT, TEXT_TOP + 4, _text.size.x, height)


func line_count() -> int:
	return _text.get_line_count() if _text.text != "" else 0


## Every rectangle the last draw painted, in order, in local pixels (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	# The second press of a double-click never advances (D18).
	if not button.double_click:
		press()


func _process(delta: float) -> void:
	if not shows_arrow() or reduce_motion:
		return
	var lit: bool = _arrow_lit()
	_blink = fmod(_blink + delta, BLINK_SECONDS * 2.0)
	if _arrow_lit() != lit:
		queue_redraw()


func _reveal(text: String) -> void:
	_teller.stop()
	_revealing = true
	_blink = 0.0
	_text.size = Vector2(text_width_for(int(size.x)), 0)
	var cps: float = write_cps
	if not is_inf(cps) and cps > 0.0:
		cps = maxf(cps, text.length() / MAX_WRITE_SECONDS)
	_teller.start(_text, text, cps, 0.0, 0)
	if _teller.is_telling():
		reveal_started.emit()
	else:
		# At once (instant speed or empty): finished now, not on the next frame.
		_teller.finish()


func _on_revealed() -> void:
	if not _revealing:
		return
	_revealing = false
	_blink = 0.0
	_armed_at_msec = Time.get_ticks_msec() + int(ARM_SECONDS * 1000.0)
	queue_redraw()
	reveal_finished.emit()


func _arrow_lit() -> bool:
	return reduce_motion or _blink < BLINK_SECONDS


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var shape: Dictionary[Vector2i, bool] = _shape()
	var ground: Color = get_theme_color(&"parchment", &"DeskPalette")
	var edge: Color = get_theme_color(&"parchment_edge", &"DeskPalette")
	var shadow: Color = get_theme_color(&"parchment_shadow", &"DeskPalette")
	var width: int = int(size.x)
	var height: int = int(size.y)
	for y: int in range(height):
		var x: int = -TAIL
		while x < width:
			var color: Color = _color_at(shape, Vector2i(x, y), ground, edge, shadow)
			var end: int = x + 1
			while end < width and _color_at(shape, Vector2i(end, y), ground, edge, shadow) == color:
				end += 1
			if color.a > 0.0:
				_paint(Rect2(x, y, end - x, 1), color)
			x = end
	if shows_arrow() and _arrow_lit():
		var ink: Color = get_theme_color(&"ink", &"DeskPalette")
		var at: Vector2 = arrow_rect().position
		for row: int in range(ARROW.size()):
			var run: int = ARROW[row].count("#")
			_paint(Rect2(at + Vector2(0, row), Vector2(run, 1)), ink)


## The bubble's pixels: its rect less the shadow's column and row and the four corner pixels,
## and the tail left of it.
func _shape() -> Dictionary[Vector2i, bool]:
	var shape: Dictionary[Vector2i, bool] = {}
	var right: int = int(size.x) - 2
	var bottom: int = int(size.y) - 2
	for y: int in range(bottom + 1):
		for x: int in range(right + 1):
			if not _is_corner(Vector2i(x, y)):
				shape[Vector2i(x, y)] = true
	for row: int in range(TAIL):
		for x: int in range(-row - 1, 0):
			shape[Vector2i(x, TAIL_Y + row)] = true
	return shape


## Ground inside, edge on the outline, shadow one pixel down and right of the shape.
func _color_at(
	shape: Dictionary[Vector2i, bool], at: Vector2i, ground: Color, edge: Color, shadow: Color
) -> Color:
	if shape.has(at):
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not shape.has(at + step):
				return edge
		return ground
	# The shadow falls down and right of the shape, but never fills a rounded-off corner.
	if shape.has(at - Vector2i.ONE) and not _is_corner(at):
		return shadow
	return Color(0, 0, 0, 0)


func _is_corner(at: Vector2i) -> bool:
	var right: int = int(size.x) - 2
	var bottom: int = int(size.y) - 2
	return (at.x == 0 or at.x == right) and (at.y == 0 or at.y == bottom)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)
