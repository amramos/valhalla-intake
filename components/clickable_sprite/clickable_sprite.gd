class_name ClickableSprite
extends Control
## A sprite the player can click and hover: the black feather, the mentor's portrait. It draws
## its texture at its own size and emits; its owner decides what a click means.

signal clicked
signal hover_started(text: String, area: Rect2)
signal hover_ended

@export var texture: Texture2D = null:
	set(value):
		texture = value
		queue_redraw()
@export var hover_text: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hover_started.emit(hover_text, get_global_rect()))
	mouse_exited.connect(func() -> void: hover_ended.emit())


## Simulates the player's click (tests and tools).
func press() -> void:
	clicked.emit()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if not button.double_click:
			clicked.emit()


func _draw() -> void:
	if texture != null:
		draw_texture(texture, Vector2.ZERO)
