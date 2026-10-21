class_name WaitingSoul
extends Control
## The soul waiting at the gate, with its name plate (D4, D21). The figure is identity only: it
## shows nothing the body chart doesn't, and it is never clickable. The plate carries Hel's mark
## (the serpent) with a hover label when Hel has named this soul. The figure is a texture slot;
## until the WP2 souls land, the style frame is loaded from disk as a placeholder.

signal plate_hover_started(text: String, area: Rect2)
signal plate_hover_ended

const PLATE_HEIGHT := 10

## The art slot.
@export var soul_texture: Texture2D = null
@export var placeholder_path: String = "res://docs/art/frames/soul.png"

var _figure: TextureRect = null
var _plate: Control = null
var _name: Label = null
var _plate_label: String = ""
var _marked: bool = false
var _returned: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure = TextureRect.new()
	_figure.name = "Figure"
	_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure.texture = soul_texture
	if _figure.texture == null:
		_figure.texture = PlaceholderArt.load_texture(placeholder_path)
	_figure.position = Vector2(4, -8)
	add_child(_figure)
	_plate = Control.new()
	_plate.name = "Plate"
	_plate.mouse_filter = Control.MOUSE_FILTER_STOP
	_plate.position = Vector2(0, size.y - PLATE_HEIGHT)
	_plate.size = Vector2(size.x, PLATE_HEIGHT)
	_plate.draw.connect(_draw_plate)
	_plate.mouse_entered.connect(_on_plate_entered)
	_plate.mouse_exited.connect(func() -> void: plate_hover_ended.emit())
	add_child(_plate)
	_name = Label.new()
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.position = Vector2(2, -3)
	_name.add_theme_color_override(&"font_color", get_theme_color(&"text_light", &"DeskPalette"))
	_plate.add_child(_name)
	show_soul(null)


## Shows the soul at the desk; null empties the gate.
func show_soul(encounter: Encounter) -> void:
	visible = encounter != null
	if encounter == null:
		return
	_name.text = encounter.soul_name
	_plate_label = encounter.plate_label
	_marked = encounter.hel_marked
	_returned = encounter.returned
	_plate.queue_redraw()


func soul_name() -> String:
	return _name.text if visible else ""


func _draw_plate() -> void:
	var area := Rect2(Vector2.ZERO, _plate.size)
	var border: StringName = &"text_muted" if _returned else &"frame"
	_plate.draw_rect(area, get_theme_color(&"plate", &"DeskPalette"))
	_plate.draw_rect(area.grow(-0.5), get_theme_color(border, &"DeskPalette"), false, 1.0)
	if _marked:
		var at := Vector2(_plate.size.x - PixelGlyph.SIZE - 2, 2)
		PixelGlyph.draw(_plate, &"serpent", at, get_theme_color(&"glyph", &"DeskPalette"))


func _on_plate_entered() -> void:
	plate_hover_started.emit(_plate_label, _plate.get_global_rect())
