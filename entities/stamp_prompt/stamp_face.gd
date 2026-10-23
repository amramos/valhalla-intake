class_name StampFace
extends Control
## The stamp itself, a 16×16 prop drawn pixel by pixel (D14): a wooden knob and neck, a wooden
## block carved with the realm's glyph, and its inked face along the bottom row. It draws only;
## the stamp's click is the GuardedButton over it.

const SIZE := Vector2i(16, 16)
## The block that carries the carved glyph; the glyph sits 3 px in from its left and 1 px down.
const BLOCK := Rect2i(1, 5, 14, 10)
const THEME_TYPE := &"DeskPalette"
## Palette fallbacks (docs/art/palette.gpl) for a stamp drawn outside the desk theme.
const WOOD_2 := Color8(65, 49, 45)
const WOOD_3 := Color8(93, 71, 63)
const WOOD_4 := Color8(125, 100, 80)
const NIGHT_0 := Color8(11, 23, 34)
const PARCHMENT_0 := Color8(211, 201, 171)

## The PixelGlyph id carved on the block; &"" carves nothing.
var glyph: StringName = &"":
	set(value):
		glyph = value
		queue_redraw()

var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE)


## Every rectangle the last `_draw` painted (the glyph as its 7×7 box), and their colours (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	var dark: Color = _color(&"wood_dark", WOOD_2)
	var wood: Color = _color(&"frame", WOOD_3)
	var light: Color = _color(&"wood_light", WOOD_4)
	# The knob: a lit top, a rounded body and a dark underside.
	_rect(Rect2i(6, 0, 4, 1), light)
	_rect(Rect2i(5, 1, 6, 2), wood)
	_rect(Rect2i(5, 1, 1, 2), light)
	_rect(Rect2i(6, 3, 4, 1), dark)
	# The neck.
	_rect(Rect2i(7, 4, 2, 1), dark)
	# The block: a dark outline, a wooden body lit along the top and left.
	_rect(BLOCK, dark)
	_rect(BLOCK.grow(-1), wood)
	_rect(Rect2i(BLOCK.position + Vector2i(1, 1), Vector2i(BLOCK.size.x - 2, 1)), light)
	_rect(Rect2i(BLOCK.position + Vector2i(1, 1), Vector2i(1, BLOCK.size.y - 2)), light)
	if glyph != &"":
		var at := Vector2(BLOCK.position + Vector2i(4, 2))
		var carved: Color = _color(&"glyph", PARCHMENT_0)
		PixelGlyph.draw(self, glyph, at, carved)
		_rects.append(Rect2(at, Vector2(PixelGlyph.SIZE, PixelGlyph.SIZE)))
		_colors.append(carved)
	# The inked face, one row under the block.
	_rect(Rect2i(2, SIZE.y - 1, SIZE.x - 4, 1), _color(&"ink", NIGHT_0))


func _rect(area: Rect2i, color: Color) -> void:
	draw_rect(Rect2(area), color)
	_rects.append(Rect2(area))
	_colors.append(color)


func _color(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback
