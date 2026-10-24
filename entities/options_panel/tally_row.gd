class_name TallyRow
extends Control
## The volume's row of tally marks on the options panel (D37): STEPS strokes on the parchment,
## those up to the chosen step filled in ink and the rest hollow, outlined in Wood 3, so the level
## counts at 1x. A click on a stroke (or the gap after it) chooses that step; the second press of a
## double-click chooses nothing new.

## A stroke's step was clicked.
signal step_chosen(step: int)

const STEPS := 6
## Each stroke: STROKE wide, MARK_HEIGHT tall, one every PITCH pixels, MARK_TOP below the top.
const STROKE := 3
const PITCH := 6
const MARK_TOP := 3
const MARK_HEIGHT := 9
const HEIGHT := 14
const THEME_TYPE := &"DeskPalette"

## The chosen step, 0 (the quietest) to STEPS - 1 (full).
var step: int = STEPS - 1:
	set(value):
		step = clampi(value, 0, STEPS - 1)
		queue_redraw()

var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(STEPS * PITCH, HEIGHT)


## The stroke of `index` in local pixels.
func mark_rect(index: int) -> Rect2:
	return Rect2(index * PITCH, MARK_TOP, STROKE, MARK_HEIGHT)


## The click area of `index`: its stroke and the gap after it, the row's full height.
func hit_rect(index: int) -> Rect2:
	return Rect2(index * PITCH, 0, PITCH, HEIGHT)


## The step under local point `at`; -1 outside the row.
func step_at(at: Vector2) -> int:
	for index: int in range(STEPS):
		if hit_rect(index).has_point(at):
			return index
	return -1


## Simulates the player's click on step `index` (tests and tools).
func press(index: int) -> void:
	step_chosen.emit(clampi(index, 0, STEPS - 1))


func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	var index: int = step_at(button.position)
	if index >= 0 and not button.double_click:
		step_chosen.emit(index)


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var ink: Color = get_theme_color(&"ink", THEME_TYPE)
	var hollow: Color = get_theme_color(&"ink_soft", THEME_TYPE)
	for index: int in range(STEPS):
		var rect: Rect2 = mark_rect(index)
		if index <= step:
			_paint(rect, ink)
			continue
		_paint(Rect2(rect.position, Vector2(rect.size.x, 1)), hollow)
		_paint(Rect2(rect.position + Vector2(0, rect.size.y - 1), Vector2(rect.size.x, 1)), hollow)
		_paint(Rect2(rect.position + Vector2(0, 1), Vector2(1, rect.size.y - 2)), hollow)
		_paint(
			Rect2(rect.position + Vector2(rect.size.x - 1, 1), Vector2(1, rect.size.y - 2)), hollow
		)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)
