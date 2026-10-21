class_name DragSource
extends Control
## Something the player can pick up and drop on a target (D9: the waiting soul onto a door). It
## draws its `layers` and hands Godot's drag-and-drop a payload {"kind": kind}; targets decide in
## their own _can_drop_data. While `enabled` is false it cannot be picked up.

signal drag_started

## What a target sees in the payload.
@export var kind: StringName = &""
var enabled: bool = true
## What it looks like, bottom to top; the drag preview draws the same.
var layers: Array[Texture2D] = []:
	set(value):
		layers = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


## The payload a drag of this source carries.
func payload() -> Dictionary:
	return {"kind": kind}


func _get_drag_data(_at: Vector2) -> Variant:
	if not enabled or layers.is_empty():
		return null
	var preview := DragSource.new()
	preview.layers = layers
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.7)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	drag_started.emit()
	return payload()


func _draw() -> void:
	for layer: Texture2D in layers:
		draw_texture(layer, Vector2.ZERO)
