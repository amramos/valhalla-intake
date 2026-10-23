class_name StampFace
extends Control
## The stamp itself, drawn pixel by pixel (D14, D54): a wooden handle 8 px tall (a knob on a
## neck) above a 24×24 wooden block carved with the realm's glyph at twice its size, its inked
## face along the bottom row. Squashed (the impact, timed by the stamp's slam), the block is 22 px
## tall with its face still on the paper. It draws only; the stamp's click is the GuardedButton
## over it.

const SIZE := Vector2i(24, 32)
const HANDLE_HEIGHT := 8
const BLOCK_HEIGHT := 24
## The block's height while squashed (D54: 24×22, then 24×24 again).
const SQUASH_HEIGHT := 22
## The glyph is carved at this scale (7×7 becomes 14×14).
const GLYPH_SCALE := 2
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
var _squashed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE)


## Squashes the block on the paper (true) or stands it at its full height (false).
func set_squashed(on: bool) -> void:
	_squashed = on
	queue_redraw()


## The block's height as drawn now: 24, or 22 while squashed.
func block_height() -> int:
	return SQUASH_HEIGHT if _squashed else BLOCK_HEIGHT


## Every rectangle the last `_draw` painted (the glyph as its box), and their colours (tests).
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
	var height: int = block_height()
	# The face stays on the paper: a squash lowers the block's top and the handle with it.
	var top: int = SIZE.y - height
	var handle: int = top - HANDLE_HEIGHT
	# The knob: a lit top, a rounded body with a lit left side and a dark underside.
	_rect(Rect2i(9, handle, 6, 1), light)
	_rect(Rect2i(8, handle + 1, 8, 2), wood)
	_rect(Rect2i(8, handle + 1, 1, 2), light)
	_rect(Rect2i(9, handle + 3, 6, 1), dark)
	# The neck, lit on its left, and the collar where it meets the block.
	_rect(Rect2i(10, handle + 4, 4, 3), wood)
	_rect(Rect2i(10, handle + 4, 1, 3), light)
	_rect(Rect2i(7, handle + 7, 10, 1), dark)
	# The block: a dark outline, a wooden body lit along the top and left.
	var block := Rect2i(0, top, SIZE.x, height - 1)
	_rect(block, dark)
	_rect(block.grow(-1), wood)
	_rect(Rect2i(1, top + 1, SIZE.x - 2, 1), light)
	_rect(Rect2i(1, top + 1, 1, height - 3), light)
	if glyph != &"":
		var carved: Color = _color(&"glyph", PARCHMENT_0)
		var span: int = PixelGlyph.SIZE * GLYPH_SCALE
		var at := Vector2i((SIZE.x - span) / 2, top + (height - 1 - span) / 2 + 1)
		carve(self, glyph, at, carved)
		_rects.append(Rect2(at, Vector2(span, span)))
		_colors.append(carved)
	# The inked face, the block's bottom row.
	_rect(Rect2i(1, SIZE.y - 1, SIZE.x - 2, 1), _color(&"ink", NIGHT_0))


## Draws `glyph_id` on `canvas` at GLYPH_SCALE with its top-left at `at`: each "#" of PixelGlyph's
## 7×7 rows becomes a 2×2 square. The stamp's carving and the writ's impression share it, so the
## mark on the writ is the stamp's own face (D55).
static func carve(canvas: CanvasItem, glyph_id: StringName, at: Vector2i, color: Color) -> void:
	var rows: Array = PixelGlyph.GLYPHS.get(glyph_id, [])
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] == "#":
				var cell := Vector2i(x, y) * GLYPH_SCALE
				canvas.draw_rect(Rect2(at + cell, Vector2(GLYPH_SCALE, GLYPH_SCALE)), color)


func _rect(area: Rect2i, color: Color) -> void:
	draw_rect(Rect2(area), color)
	_rects.append(Rect2(area))
	_colors.append(color)


func _color(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback
