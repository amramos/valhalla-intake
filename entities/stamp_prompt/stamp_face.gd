class_name StampFace
extends Control
## The stamp itself, drawn pixel by pixel (D14, D54): a wooden handle 8 px tall (a knob on a
## neck) above a 28×28 wooden block carved with the realm's glyph at twice its size in bold 3 px
## strokes, its inked face along the bottom row. Squashed (the impact, timed by the stamp's slam),
## the block is 26 px tall with its face still on the paper. In the impact's flash every tone steps
## one band lighter (the outline Wood 3, the body Wood 4, its lit edges Parchment 0, the carving
## Parchment 2). It draws only; the stamp's click is the GuardedButton over it.

const SIZE := Vector2i(28, 36)
const HANDLE_HEIGHT := 8
const BLOCK_HEIGHT := 28
## The block's height while squashed (2 px down, then whole again).
const SQUASH_HEIGHT := 26
## The glyph is carved at this scale (7×7 becomes 14×14), each cell then thickened 1 px right and
## down so the strokes are 3 px and the carving THICK_SPAN square.
const GLYPH_SCALE := 2
const THICK_SPAN := 15
const THEME_TYPE := &"DeskPalette"
## Palette fallbacks (docs/art/palette.gpl) for a stamp drawn outside the desk theme.
const WOOD_2 := Color8(65, 49, 45)
const WOOD_3 := Color8(93, 71, 63)
const WOOD_4 := Color8(125, 100, 80)
const NIGHT_0 := Color8(11, 23, 34)
const PARCHMENT_0 := Color8(211, 201, 171)
const PARCHMENT_2 := Color8(246, 238, 210)

## The PixelGlyph id carved on the block; &"" carves nothing.
var glyph: StringName = &"":
	set(value):
		glyph = value
		queue_redraw()

var _rects: Array[Rect2] = []
var _colors: Array[Color] = []
var _squashed: bool = false
var _flash: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE)


## Squashes the block on the paper (true) or stands it at its full height (false).
func set_squashed(on: bool) -> void:
	_squashed = on
	queue_redraw()


## The impact's flash (true) or the stamp's own tones (false).
func set_flash(on: bool) -> void:
	_flash = on
	queue_redraw()


func is_flashing() -> bool:
	return _flash


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
	var carved: Color = _color(&"glyph", PARCHMENT_0)
	if _flash:
		dark = wood
		wood = light
		light = carved
		carved = _color(&"pin_highlight", PARCHMENT_2)
	var height: int = block_height()
	# The face stays on the paper: a squash lowers the block's top and the handle with it.
	var top: int = SIZE.y - height
	var handle: int = top - HANDLE_HEIGHT
	var mid: int = SIZE.x / 2
	# The knob: a lit top, a rounded body with a lit left side and a dark underside.
	_rect(Rect2i(mid - 3, handle, 6, 1), light)
	_rect(Rect2i(mid - 4, handle + 1, 8, 2), wood)
	_rect(Rect2i(mid - 4, handle + 1, 1, 2), light)
	_rect(Rect2i(mid - 3, handle + 3, 6, 1), dark)
	# The neck, lit on its left, and the collar where it meets the block.
	_rect(Rect2i(mid - 2, handle + 4, 4, 3), wood)
	_rect(Rect2i(mid - 2, handle + 4, 1, 3), light)
	_rect(Rect2i(mid - 5, handle + 7, 10, 1), dark)
	# The block: a dark outline, a wooden body lit along the top and left.
	var block := Rect2i(0, top, SIZE.x, height - 1)
	_rect(block, dark)
	_rect(block.grow(-1), wood)
	_rect(Rect2i(1, top + 1, SIZE.x - 2, 1), light)
	_rect(Rect2i(1, top + 1, 1, height - 3), light)
	if glyph != &"":
		var span: int = THICK_SPAN
		var at := Vector2i((SIZE.x - span) / 2, top + (height - 1 - span) / 2 + 1)
		carve(self, glyph, at, carved)
		_rects.append(Rect2(at, Vector2(span, span)))
		_colors.append(carved)
	# The inked face, the block's bottom row.
	_rect(Rect2i(1, SIZE.y - 1, SIZE.x - 2, 1), _color(&"ink", NIGHT_0))


## Draws `glyph_id` on `canvas` in bold with its top-left at `at` (thick_pixels). The stamp's
## carving and the writ's impression share it, so the mark on the writ is the stamp's own face
## (D55).
static func carve(canvas: CanvasItem, glyph_id: StringName, at: Vector2i, color: Color) -> void:
	for pixel: Vector2i in thick_pixels(glyph_id):
		canvas.draw_rect(Rect2(at + pixel, Vector2.ONE), color)


## The bold glyph's pixels from its top-left: each "#" of PixelGlyph's 7×7 rows at GLYPH_SCALE,
## grown 1 px right and down (a 3×3 square), so its strokes are 3 px and it spans THICK_SPAN.
static func thick_pixels(glyph_id: StringName) -> Array[Vector2i]:
	var seen: Dictionary[Vector2i, bool] = {}
	var rows: Array = PixelGlyph.GLYPHS.get(glyph_id, [])
	var side: int = GLYPH_SCALE + 1
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] != "#":
				continue
			for cell: int in range(side * side):
				seen[Vector2i(x, y) * GLYPH_SCALE + Vector2i(cell % side, cell / side)] = true
	var pixels: Array[Vector2i] = []
	pixels.assign(seen.keys())
	return pixels


func _rect(area: Rect2i, color: Color) -> void:
	draw_rect(Rect2(area), color)
	_rects.append(Rect2(area))
	_colors.append(color)


func _color(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback
