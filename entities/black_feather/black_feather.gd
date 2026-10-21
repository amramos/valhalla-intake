class_name BlackFeather
extends Control
## The black feather a citation leaves on the desk (D14, D33, D48). It stays until the next soul;
## clicking it shows its citation again and lights the cited pair.

signal clicked
signal hover_started(text: String, area: Rect2)
signal hover_ended

const HOVER_TEXT := "black feather: a citation"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hover_started.emit(HOVER_TEXT, get_global_rect()))
	mouse_exited.connect(func() -> void: hover_ended.emit())
	visible = false


## Simulates the player's click (tests and tools).
func press() -> void:
	clicked.emit()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
		accept_event()


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"parchment_dim", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
	var at: Vector2 = ((size - Vector2.ONE * PixelGlyph.SIZE) / 2.0).floor()
	PixelGlyph.draw(self, &"feather", at, get_theme_color(&"ink", &"DeskPalette"))
