class_name PhaseCard
extends Control
## A card over the desk between souls: a dawn card, one card of a dusk sequence, or the slice's
## ending (D15, D23, D34). It renders text it is given (ScreenText composes it), sized to fit and
## centred on the screen, with a primary button and an optional second one ("Skip all"). Both are
## guarded, so a double-click never skips the next card.

signal advanced
signal skipped

const PADDING := 6
const LINE_PITCH := 10
const LABEL_TOP := 3
const BUTTON_HEIGHT := 14
const GAP := 4
const SCREEN := Vector2(480, 270)

@onready var _text: Label = $Text
@onready var _next: GuardedButton = $Next
@onready var _skip: GuardedButton = $Skip


func _ready() -> void:
	_next.pressed.connect(func() -> void: advanced.emit())
	_skip.pressed.connect(func() -> void: skipped.emit())
	visible = false


## Shows `text` (lines joined by "\n") at `width` px, with `next_label` and, when given,
## `skip_label`. A new card re-arms its buttons even when it replaces another (D9).
func show_card(
	text: String, next_label: String, skip_label: String = "", width: float = 320.0
) -> void:
	var changed: bool = not visible or text != _text.text
	_text.text = text
	_text.position = Vector2(PADDING, PADDING - LABEL_TOP)
	_text.size = Vector2(width - PADDING * 2, 0)
	var lines: int = maxi(1, _text.get_line_count())
	var height: float = PADDING + lines * LINE_PITCH + GAP + BUTTON_HEIGHT + PADDING
	size = Vector2(width, minf(height, SCREEN.y - 4))
	position = ((SCREEN - size) / 2.0).floor()
	_next.text = next_label
	_next.size = Vector2.ZERO
	_next.position = Vector2(
		width - PADDING - _next.get_minimum_size().x, size.y - PADDING - BUTTON_HEIGHT
	)
	_skip.visible = skip_label != ""
	_skip.text = skip_label
	_skip.size = Vector2.ZERO
	_skip.position = Vector2(PADDING, _next.position.y)
	visible = true
	if changed:
		_next.rearm()
		_skip.rearm()
	queue_redraw()


func shown_text() -> String:
	return _text.text if visible else ""


func next_button() -> GuardedButton:
	return _next


func skip_button() -> GuardedButton:
	return _skip


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"night", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
