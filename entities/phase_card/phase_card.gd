class_name PhaseCard
extends Control
## A plain card over the desk between souls' days: dawn, dusk and the slice's end. WP1's minimal
## stand-in for the full dawn and dusk cards (D15, D34); it shows text and one button, guarded so
## a double-click can't skip the next card.

signal advanced

@onready var _text: Label = $Text
@onready var _button: GuardedButton = $Next


func _ready() -> void:
	_button.pressed.connect(func() -> void: advanced.emit())
	visible = false


func show_card(text: String, button_text: String) -> void:
	_text.text = text
	_button.text = button_text
	visible = true
	# A new card, even one that replaces another, waits out a double-click (D9).
	_button.rearm()


func shown_text() -> String:
	return _text.text if visible else ""


func next_button() -> GuardedButton:
	return _button


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"night", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
