class_name PinSelectable
extends Control
## One clickable piece of evidence (D5, D8): a body fact, a testimony line, a decree or a thread's
## knot. A left click asks to select it; a right click asks to cancel the selection. It never
## decides anything itself: its owner reads the signals and sets `selected` and `lit`.

signal clicked(item_id: String)
signal cancel_requested
signal hover_started(item_id: String, text: String, area: Rect2)
signal hover_ended(item_id: String)

## The smallest hit area a fact may have (D5).
const MIN_SIZE := Vector2(8, 8)

@export var item_id: String = ""
## Shown by the owner's hover label; "" for none (a line whose text is already on screen).
@export var hover_text: String = ""
## Draws corner ticks so an area with nothing drawn in it (an absence) can still be found.
@export var show_corners: bool = false
## Draws the outline even when idle (the fit check shows every hit area).
@export var show_outline: bool = false
@export var outline_color: Color = Color(0.7608, 0.8039, 0.7882, 1)
@export var select_color: Color = Color(0.1137, 0.3529, 0.4275, 1)
@export var lit_color: Color = Color(0.4902, 0.3922, 0.3137, 1)

## The first item of a pin in progress (D8).
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## Part of a pair being pointed at (a re-pin, a citation).
var lit: bool = false:
	set(value):
		lit = value
		queue_redraw()

var _hovered: bool = false


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(MIN_SIZE)
	size = size.max(MIN_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Simulates the player's click; the integration tests and tools use it.
func press() -> void:
	clicked.emit(item_id)


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
	var area := Rect2(Vector2.ZERO, size)
	if selected:
		draw_rect(area.grow(-0.5), select_color, false, 1.0)
		draw_rect(area.grow(-1.5), select_color, false, 1.0)
	elif lit:
		draw_rect(area.grow(-0.5), lit_color, false, 1.0)
	elif show_outline or _hovered:
		draw_rect(area.grow(-0.5), outline_color, false, 1.0)
	elif show_corners:
		_draw_corners(area)


func _draw_corners(area: Rect2) -> void:
	var right: float = area.size.x - 1.0
	var bottom: float = area.size.y - 1.0
	for corner: Vector2 in [
		Vector2(0, 0), Vector2(right, 0), Vector2(0, bottom), Vector2(right, bottom)
	]:
		draw_rect(Rect2(corner, Vector2.ONE), outline_color)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	hover_started.emit(item_id, hover_text, get_global_rect())


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	hover_ended.emit(item_id)
