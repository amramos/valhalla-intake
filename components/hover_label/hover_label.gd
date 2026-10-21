class_name HoverLabel
extends Control
## A small parchment label shown under (or above) a hovered area, kept inside the screen (D8).
## It never takes the mouse.

const PADDING := Vector2(2, 1)
const GAP := 1.0

var _label: Label = null
var _glyph: StringName = &""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 100
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.position = PADDING + Vector2(0, -3)
	add_child(_label)
	visible = false


## Shows `text` next to `area` (global coordinates), led by a PixelGlyph when `glyph` names one
## (a door's carved mark); an empty text hides the label.
func show_for(text: String, area: Rect2, glyph: StringName = &"") -> void:
	if text == "":
		hide_label()
		return
	_glyph = glyph
	var indent: float = PixelGlyph.SIZE + 2.0 if glyph != &"" else 0.0
	_label.text = text
	_label.size = Vector2.ZERO
	_label.position = PADDING + Vector2(indent, -3)
	var text_size: Vector2 = _label.get_minimum_size()
	size = Vector2(text_size.x + indent, 9) + PADDING * 2
	var bounds: Rect2 = get_viewport_rect()
	var spot := Vector2(area.position.x, area.end.y + GAP)
	if spot.y + size.y > bounds.end.y:
		spot.y = area.position.y - GAP - size.y
	spot.x = clampf(spot.x, bounds.position.x, bounds.end.x - size.x)
	spot.y = clampf(spot.y, bounds.position.y, bounds.end.y - size.y)
	global_position = spot.round()
	visible = true
	queue_redraw()


func hide_label() -> void:
	visible = false


func shown_text() -> String:
	return _label.text if visible else ""


func shown_glyph() -> StringName:
	return _glyph if visible else &""


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"parchment", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"ink", &"DeskPalette"), false, 1.0)
	if _glyph != &"":
		PixelGlyph.draw(
			self, _glyph, PADDING + Vector2(0, 0), get_theme_color(&"ink", &"DeskPalette")
		)
