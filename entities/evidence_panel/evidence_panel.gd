class_name EvidencePanel
extends Control
## A parchment panel of numbered lines: the claim, the witness or the Law (D7, D32). Every line is
## a pin hit area. Lines are drawn as authored, prefixed by their id ("C1 ", "L3 "); decrees wrap
## at word boundaries, testimony lines never wrap, so a line too long for the panel shows as
## overflow instead of silently breaking.

signal item_clicked(item_id: String)
signal cancel_requested
signal item_hover_started(item_id: String, text: String, area: Rect2)
signal item_hover_ended(item_id: String)

## Pixels between text lines (font size 16, line_spacing −3; ADR-0008).
const LINE_PITCH := 10
## Inner margin between the frame and the text.
const PADDING := 2
## The label's first ink row sits this far below its top; lines are shifted up to match.
const LABEL_TOP := 3

@export var heading: String = ""
## Wrap long lines at word boundaries (decrees); testimony lines never wrap.
@export var wrap_lines: bool = false

var _areas: Dictionary[String, PinSelectable] = {}
var _labels: Dictionary[String, Label] = {}
var _heading_label: Label = null
var _note_label: Label = null
var _content_bottom: int = 0


func _ready() -> void:
	clip_contents = false
	_heading_label = _make_label(get_theme_color(&"ink_soft", &"DeskPalette"))
	_heading_label.name = "Heading"
	add_child(_heading_label)
	_note_label = _make_label(get_theme_color(&"ink_soft", &"DeskPalette"))
	_note_label.name = "Note"
	add_child(_note_label)
	_layout([], "")


## Shows the lines; `note` stands in for an empty panel ("No witness came back.", D46).
func show_lines(items: Array[EvidenceItem], title: String = heading, note: String = "") -> void:
	heading = title
	_layout(items, note)


func has_item(item_id: String) -> bool:
	return _areas.has(item_id)


## The line's hit area in global coordinates; an empty rect when absent.
func anchor_rect(item_id: String) -> Rect2:
	return _areas[item_id].get_global_rect() if _areas.has(item_id) else Rect2()


## Every hit area's rectangle in global coordinates (a knot must not cover one).
func hit_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if not is_visible_in_tree():
		return rects
	for id: String in _areas:
		rects.append(_areas[id].get_global_rect())
	return rects


func set_selected(item_id: String) -> void:
	for id: String in _areas:
		_areas[id].selected = id == item_id


func set_lit(item_ids: Array[String]) -> void:
	for id: String in _areas:
		_areas[id].lit = item_ids.has(id)


func area(item_id: String) -> PinSelectable:
	return _areas.get(item_id, null)


## The text width available to a line.
func inner_width() -> int:
	return int(size.x) - PADDING * 2


## How many lines an item takes (decrees wrap).
func line_count(item_id: String) -> int:
	return _labels[item_id].get_line_count() if _labels.has(item_id) else 0


## The width the line's text needs on one line, in pixels.
func text_width(item_id: String) -> int:
	if not _labels.has(item_id):
		return 0
	var label: Label = _labels[item_id]
	var font: Font = label.get_theme_font(&"font")
	var font_size: int = label.get_theme_font_size(&"font_size")
	return int(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) - 1


## Where the last line's ink ends, in panel pixels.
func content_bottom() -> int:
	return _content_bottom


## True when text runs past the panel's frame (the fit check reports it).
func overflows() -> bool:
	if _content_bottom > int(size.y) - PADDING:
		return true
	if wrap_lines:
		return false
	for id: String in _labels:
		if text_width(id) > inner_width():
			return true
	return false


func _layout(items: Array[EvidenceItem], note: String) -> void:
	for id: String in _areas:
		_areas[id].queue_free()
	_areas.clear()
	_labels.clear()
	var y: int = PADDING
	_heading_label.visible = heading != ""
	if heading != "":
		_heading_label.text = heading
		_heading_label.position = Vector2(PADDING, y - LABEL_TOP)
		y += LINE_PITCH
	for item: EvidenceItem in items:
		y += _add_line(item, y)
	_note_label.visible = items.is_empty() and note != ""
	if _note_label.visible:
		_note_label.text = note
		_note_label.position = Vector2(PADDING, y - LABEL_TOP)
		y += LINE_PITCH
	_content_bottom = y
	queue_redraw()


func _add_line(item: EvidenceItem, y: int) -> int:
	var hit := PinSelectable.new()
	hit.name = "Line%s" % item.id
	hit.item_id = item.id
	hit.select_color = get_theme_color(&"select_light", &"DeskPalette")
	hit.lit_color = get_theme_color(&"lit", &"DeskPalette")
	hit.position = Vector2(PADDING, y)
	var label: Label = _make_label(get_theme_color(&"ink", &"DeskPalette"))
	label.text = "%s %s" % [item.id, item.text]
	label.position = Vector2(0, -LABEL_TOP)
	if wrap_lines:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hit.add_child(label)
	add_child(hit)
	if wrap_lines:
		label.size = Vector2(inner_width(), 0)
	var lines: int = maxi(1, label.get_line_count())
	hit.size = Vector2(inner_width(), lines * LINE_PITCH)
	hit.clicked.connect(func(id: String) -> void: item_clicked.emit(id))
	hit.cancel_requested.connect(func() -> void: cancel_requested.emit())
	hit.hover_started.connect(
		func(id: String, text: String, at: Rect2) -> void: item_hover_started.emit(id, text, at)
	)
	hit.hover_ended.connect(func(id: String) -> void: item_hover_ended.emit(id))
	_areas[item.id] = hit
	_labels[item.id] = label
	return lines * LINE_PITCH


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	return label


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"parchment", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
