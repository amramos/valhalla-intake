class_name BodyChart
extends Control
## The body chart (D5): front and back views side by side, with every fact, absences included,
## as a hit area of at least 8×8 keyed by its place. The head and hair are never clickable.
## The art is the soul's layer stack (BodyStacks: base, left hand, fact overlays, head), drawn on
## the chart's Night 3 panel (D51). The panel is the top of a stone slab (D35): a Night 4 rim and a
## Night 1 shadow are drawn outside the chart's rectangle, so the node's rect, the chart's pixels,
## its hit areas and the thread routes that start from its edges stay exactly where they were.

signal item_clicked(item_id: String)
signal cancel_requested
signal item_hover_started(item_id: String, text: String, area: Rect2)
signal item_hover_ended(item_id: String)

const CHART_SIZE := Vector2(128, 100)
## The slab's rim around the chart and its shadow below and right, in pixels (D35).
const RIM := 2
const SHADOW := 2

## Which layers make each soul's body.
@export var stacks: BodyStacks = null
## Shown when an encounter has no stack (a development stand-in).
@export var placeholder_path: String = "res://docs/art/frames/body-chart.png"
## Hit areas in chart pixels, by place (EvidenceItem.place), fitted to the WP2 body base (front
## view centred on x 31.5, back on x 95.5). No two facts of one soul share a place.
@export var place_rects: Dictionary[StringName, Rect2] = {
	&"neck": Rect2(27, 24, 10, 8),
	&"torso_front": Rect2(20, 33, 24, 14),
	&"hand_right": Rect2(13, 56, 10, 10),
	&"hand_left": Rect2(41, 56, 10, 10),
	&"hem": Rect2(22, 68, 20, 28),
	&"legs": Rect2(21, 74, 22, 20),
	&"torso_back": Rect2(84, 30, 24, 18),
}
## Outlines every hit area (the fit check).
@export var outline_all: bool = false

var _areas: Dictionary[String, PinSelectable] = {}
var _layers: Array[Texture2D] = []
var _placeholder: Texture2D = null


func _ready() -> void:
	custom_minimum_size = CHART_SIZE


## Draws one soul's body from its layer stack; an unknown id shows the placeholder frame.
func show_body(encounter_id: StringName) -> void:
	_layers = stacks.chart_layers(encounter_id) if stacks != null else ([] as Array[Texture2D])
	if _layers.is_empty() and encounter_id != &"":
		if _placeholder == null:
			_placeholder = PlaceholderArt.load_texture(placeholder_path)
		if _placeholder != null:
			_layers = [_placeholder]
	queue_redraw()


## The layers drawn now, bottom to top (tests).
func layers() -> Array[Texture2D]:
	return _layers


## Rebuilds the hit areas for one soul's body facts; other items are ignored.
func show_facts(items: Array[EvidenceItem]) -> void:
	for area: PinSelectable in _areas.values():
		area.queue_free()
	_areas.clear()
	for item: EvidenceItem in items:
		if item.group != EvidenceItem.Group.BODY:
			continue
		if not place_rects.has(item.place):
			push_warning("BodyChart: no hit area for place '%s' (%s)" % [item.place, item.id])
			continue
		_add_area(item, place_rects[item.place])


func has_item(item_id: String) -> bool:
	return _areas.has(item_id)


## The hit area's rectangle in global coordinates; an empty rect when absent.
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


## The hit area for one fact (tests and tools).
func area(item_id: String) -> PinSelectable:
	return _areas.get(item_id, null)


func _add_area(item: EvidenceItem, rect: Rect2) -> void:
	var hit := PinSelectable.new()
	hit.name = "Fact%s" % item.id
	hit.item_id = item.id
	hit.hover_text = item.text
	hit.show_corners = true
	hit.show_outline = outline_all
	hit.hover_mark = PinSelectable.HoverMark.CORNERS
	hit.pin_inside = true
	hit.outline_color = get_theme_color(&"mark", &"DeskPalette")
	hit.select_color = get_theme_color(&"select_dark", &"DeskPalette")
	hit.lit_color = get_theme_color(&"parchment_dim", &"DeskPalette")
	hit.pin_color = get_theme_color(&"pin_selected", &"DeskPalette")
	hit.pin_shadow = get_theme_color(&"pin_selected_shadow", &"DeskPalette")
	hit.pin_highlight = get_theme_color(&"pin_highlight", &"DeskPalette")
	hit.position = rect.position
	hit.size = rect.size
	add_child(hit)
	hit.clicked.connect(func(id: String) -> void: item_clicked.emit(id))
	hit.cancel_requested.connect(func() -> void: cancel_requested.emit())
	hit.hover_started.connect(
		func(id: String, text: String, at: Rect2) -> void: item_hover_started.emit(id, text, at)
	)
	hit.hover_ended.connect(func(id: String) -> void: item_hover_ended.emit(id))
	_areas[item.id] = hit


## The slab's rim and shadow, in local pixels, all outside the chart's rectangle (tests).
func slab_rects() -> Array[Rect2]:
	var rim := Rect2(Vector2(-RIM, -RIM), size + Vector2(RIM, RIM) * 2)
	return [
		Rect2(rim.end.x, rim.position.y + SHADOW, SHADOW, rim.size.y),
		Rect2(rim.position.x + SHADOW, rim.end.y, rim.size.x - SHADOW, SHADOW),
		Rect2(rim.position, Vector2(rim.size.x, RIM)),
		Rect2(rim.position.x, rim.end.y - RIM, rim.size.x, RIM),
		Rect2(rim.position.x, 0, RIM, size.y),
		Rect2(size.x, 0, RIM, size.y),
	]


func _draw() -> void:
	var rects: Array[Rect2] = slab_rects()
	var shadow: Color = get_theme_color(&"slab_shadow", &"DeskPalette")
	var rim: Color = get_theme_color(&"slab_rim", &"DeskPalette")
	for index: int in range(rects.size()):
		draw_rect(rects[index], shadow if index < 2 else rim)
	# The chart's panel (D51: Night 3); the art sits on it, under the hit areas.
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color(&"chart", &"DeskPalette"))
	for layer: Texture2D in _layers:
		draw_texture(layer, Vector2.ZERO)
