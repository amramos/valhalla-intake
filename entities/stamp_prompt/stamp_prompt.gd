class_name StampPrompt
extends Control
## The stamp preview by the doors (D9): "Stamp <name> to <realm>?" with a separate confirm button
## that ignores double-clicks. It says nothing about correctness. Cancel, or a right-click on the
## prompt, withdraws it. There is no undo after the confirm.

signal confirmed(realm: StringName)
signal cancelled

## Pixels between the question, the confirm and the cancel.
const GAP := 3

var realm: StringName = &""

@onready var _question: Label = $Question
@onready var _confirm: GuardedButton = $Confirm
@onready var _cancel: Button = $Cancel


func _ready() -> void:
	_confirm.pressed.connect(_on_confirm_pressed)
	_cancel.pressed.connect(withdraw)
	visible = false


## Shows the preview for one soul and one realm.
func ask(soul_name: String, p_realm: StringName) -> void:
	realm = p_realm
	_question.text = question_for(soul_name, p_realm)
	_arrange()
	visible = true
	# Asking again (another door) restarts the arm time, as a fresh prompt would.
	_confirm.rearm()


static func question_for(soul_name: String, p_realm: StringName) -> String:
	return "Stamp %s to %s?" % [soul_name, Realm.display_name(p_realm)]


func withdraw() -> void:
	if not visible:
		return
	visible = false
	realm = &""
	cancelled.emit()


func question() -> String:
	return _question.text if visible else ""


func confirm_button() -> GuardedButton:
	return _confirm


## Fits the prompt to its question: the confirm sits right after the text, the cancel after it.
func _arrange() -> void:
	_question.size = Vector2.ZERO
	var x: float = _question.position.x + _question.get_minimum_size().x + GAP
	_confirm.position.x = x
	_cancel.position.x = _confirm.position.x + _confirm.size.x + GAP
	size.x = _cancel.position.x + _cancel.size.x + 2
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
		withdraw()
		accept_event()


func _on_confirm_pressed() -> void:
	if not visible or realm == &"":
		return
	var chosen: StringName = realm
	visible = false
	realm = &""
	confirmed.emit(chosen)


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"night", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
