class_name MentorBubble
extends Control
## The mentor's speech bubble by her portrait (D16, D33): guided step prompts only, never the
## caption strip. A step the player only has to read carries a "Next" button; a step that waits for
## a pin or a stamp has none.

signal acknowledged

const PADDING := 3
const LABEL_TOP := 3

var _text: Label = null
var _next: GuardedButton = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_text = Label.new()
	_text.name = "Text"
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.position = Vector2(PADDING + 2, PADDING - LABEL_TOP)
	add_child(_text)
	_text.size = Vector2(size.x - PADDING * 2 - 2, 0)
	_next = GuardedButton.new()
	_next.name = "Next"
	_next.text = "Next"
	_next.focus_mode = Control.FOCUS_NONE
	add_child(_next)
	_next.position = Vector2(size.x - 28 - PADDING, size.y - 14 - PADDING + 1)
	_next.size = Vector2(28, 14)
	_next.pressed.connect(func() -> void: acknowledged.emit())
	visible = false


## Shows one step; `wants_ack` adds the "Next" button (a step the player only reads).
func show_step(text: String, wants_ack: bool) -> void:
	var changed: bool = text != _text.text or not visible
	_text.text = text
	_next.visible = wants_ack
	visible = true
	if changed and wants_ack:
		_next.rearm()
	queue_redraw()


func hide_step() -> void:
	visible = false
	_text.text = ""


func shown_text() -> String:
	return _text.text if visible else ""


func next_button() -> GuardedButton:
	return _next


func _draw() -> void:
	var area := Rect2(Vector2(2, 0), size - Vector2(2, 0))
	draw_rect(area, get_theme_color(&"parchment", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
	# The tail points left, at her portrait.
	var ink: Color = get_theme_color(&"frame", &"DeskPalette")
	draw_rect(Rect2(0, 8, 2, 1), ink)
	draw_rect(Rect2(1, 7, 1, 3), get_theme_color(&"parchment", &"DeskPalette"))
	draw_rect(Rect2(0, 6, 1, 1), ink)
	draw_rect(Rect2(0, 10, 1, 1), ink)
