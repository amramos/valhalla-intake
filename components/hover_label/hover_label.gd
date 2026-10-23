class_name HoverLabel
extends Control
## A hovered thing's plain-language label (D8, D20): a small parchment tag pinned to the desk by a
## 3×3 pin head at its top-left, the text in ink. It goes above the hovered area if it can, else
## below, else beside it, always inside the screen and never over a "keep clear" rect (the sheets'
## headings and the clerk's note) while any spot is clear of them; among those spots it covers the
## least of its "avoid" rects (the sheets themselves). It never takes the mouse.

## The tag's border: 1 px of parchment edge, then 1 px of ground before the text.
const EDGE := 1
## The text's top-left inside the tag, past the pin head's column.
const TEXT_AT := Vector2(6, 1)
## Pixels right of the text's advance, before the shadow: the edge column and one of ground.
const TEXT_RIGHT := 2
## The tag's height: a 1 px edge, one text row (its ink, descenders included, in rows 2-10), the
## bottom edge and the 1 px shadow under it.
const HEIGHT := 13
## The pin head (3×3) inside the tag's top-left corner.
const PIN_AT := Vector2i(1, 1)
const PIN_SIZE := 3
## Pixels between the tag and the hovered area.
const GAP := 1.0
## The label's first ink row sits this far below its top (ADR-0008).
const LABEL_TOP := 3

var _label: Label = null
var _frame: ParchmentFrame = null
var _glyph: StringName = &""
var _keep_clear: Array[Rect2] = []
var _avoid: Array[Rect2] = []
## What the last `_draw` painted, in order (tests).
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 100
	_frame = ParchmentFrame.new()
	_frame.name = "Tag"
	_frame.show_behind_parent = true
	_frame.torn = false
	add_child(_frame)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override(&"font_color", get_theme_color(&"ink", &"DeskPalette"))
	add_child(_label)
	visible = false


## Global rects the tag must never cover (the sheets' headings and the note, D20), and rects it
## covers as little as it can once those are clear (the sheets, so a fact's tag stays on the chart).
func set_keep_clear(rects: Array[Rect2], avoid: Array[Rect2] = []) -> void:
	_keep_clear = rects.duplicate()
	_avoid = avoid.duplicate()


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
	_label.position = TEXT_AT + Vector2(indent, -LABEL_TOP)
	var text_width: float = _label.get_minimum_size().x
	size = Vector2(TEXT_AT.x + indent + text_width + TEXT_RIGHT, HEIGHT)
	_frame.size = size
	# Everything inside the 1 px edge is flat ground: the text never sits on an edge pixel.
	_frame.inner = Rect2(Vector2(EDGE, EDGE), size - Vector2(EDGE * 2 + 1, EDGE * 2 + 1))
	global_position = place(size, area, get_viewport_rect(), _keep_clear, _avoid)
	visible = true
	queue_redraw()


func hide_label() -> void:
	visible = false


func shown_text() -> String:
	return _label.text if visible else ""


func shown_glyph() -> StringName:
	return _glyph if visible else &""


## The tag's rect in global coordinates (tests).
func tag_rect() -> Rect2:
	return Rect2(global_position, size)


## Where a tag of `tag_size` goes for `area`: above, below, right of, then left of it (above and
## below, first from the area's left edge, then ending at its right edge), the first spot inside
## `bounds` that covers no `keep_clear` and no `avoid` rect. When none is free, the spot that covers
## the least of `keep_clear`, and among those the least of `avoid`. Whole pixels.
static func place(
	tag_size: Vector2,
	area: Rect2,
	bounds: Rect2,
	keep_clear: Array[Rect2],
	avoid: Array[Rect2] = []
) -> Vector2:
	var left: float = clampf(area.position.x, bounds.position.x, bounds.end.x - tag_size.x)
	var right: float = clampf(area.end.x - tag_size.x, bounds.position.x, bounds.end.x - tag_size.x)
	var beside_y: float = clampf(area.position.y, bounds.position.y, bounds.end.y - tag_size.y)
	var above: float = area.position.y - GAP - tag_size.y
	var below: float = area.end.y + GAP
	var spots: Array[Vector2] = [
		Vector2(left, above),
		Vector2(right, above),
		Vector2(left, below),
		Vector2(right, below),
		Vector2(area.end.x + GAP, beside_y),
		Vector2(area.position.x - GAP - tag_size.x, beside_y),
	]
	var best := Vector2(INF, INF)
	var best_cover := Vector2(INF, INF)
	for spot: Vector2 in spots:
		var tag := Rect2(spot.round(), tag_size)
		if not bounds.encloses(tag):
			continue
		# (keep-clear area covered, avoided area covered), compared in that order.
		var cover := Vector2(_covered(tag, keep_clear), _covered(tag, avoid))
		if cover == Vector2.ZERO:
			return tag.position
		if cover.x < best_cover.x or (cover.x == best_cover.x and cover.y < best_cover.y):
			best_cover = cover
			best = tag.position
	if best_cover.x < INF:
		return best
	# A tag wider or taller than the screen: clamped under the area, as before.
	return Vector2(left, clampf(below, bounds.position.y, bounds.end.y - tag_size.y)).round()


static func _covered(tag: Rect2, rects: Array[Rect2]) -> float:
	var cover: float = 0.0
	for rect: Rect2 in rects:
		cover += tag.intersection(rect).get_area()
	return cover


## Every rectangle the last draw painted, in order, in local pixels (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	# The pin head: one highlight pixel, Wood 3, and a shadow pixel at the bottom right.
	var head: Color = get_theme_color(&"pin_head", &"DeskPalette")
	var at := Vector2(PIN_AT)
	_paint(Rect2(at, Vector2(PIN_SIZE, PIN_SIZE)), head)
	_paint(Rect2(at, Vector2.ONE), get_theme_color(&"pin_highlight", &"DeskPalette"))
	_paint(
		Rect2(at + Vector2(PIN_SIZE - 1, PIN_SIZE - 1), Vector2.ONE),
		get_theme_color(&"parchment_shadow", &"DeskPalette")
	)
	if _glyph != &"":
		PixelGlyph.draw(self, _glyph, TEXT_AT, get_theme_color(&"ink", &"DeskPalette"))


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)
