class_name BodyChart
extends Control
## The body chart (D5): front and back views side by side, with every fact, absences included,
## as a hit area of at least 8×8 keyed by its place. The head and hair are never clickable.
## The art is a slot: set `chart_texture` to the final asset; until then the style frame is
## loaded from disk as a placeholder.

signal item_clicked(item_id: String)
signal cancel_requested
signal item_hover_started(item_id: String, text: String, area: Rect2)
signal item_hover_ended(item_id: String)

const CHART_SIZE := Vector2(128, 100)

## The art slot. Empty until the WP2 body bases land.
@export var chart_texture: Texture2D = null
## Development placeholder, read from disk only while `chart_texture` is empty.
@export var placeholder_path: String = "res://docs/art/frames/body-chart.png"
## Hit areas in chart pixels, by place (EvidenceItem.place). Front view on the left half, back
## view on the right; no two facts of one soul share a place.
@export var place_rects: Dictionary[StringName, Rect2] = {
	&"neck": Rect2(27, 22, 10, 8),
	&"torso_front": Rect2(21, 31, 22, 15),
	&"hand_right": Rect2(11, 51, 11, 11),
	&"hand_left": Rect2(42, 51, 11, 11),
	&"hem": Rect2(22, 60, 20, 33),
	&"legs": Rect2(21, 70, 22, 22),
	&"torso_back": Rect2(86, 30, 22, 16),
}
## Outlines every hit area (the fit check).
@export var outline_all: bool = false

var _areas: Dictionary[String, PinSelectable] = {}
var _art: TextureRect = null


func _ready() -> void:
	custom_minimum_size = CHART_SIZE
	_art = TextureRect.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.texture = chart_texture
	if _art.texture == null:
		_art.texture = PlaceholderArt.load_texture(placeholder_path)
	add_child(_art)


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
	hit.outline_color = get_theme_color(&"mark", &"DeskPalette")
	hit.select_color = get_theme_color(&"select_dark", &"DeskPalette")
	hit.lit_color = get_theme_color(&"parchment_dim", &"DeskPalette")
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


func _draw() -> void:
	# The chart's panel (D51: Night 3); the art sits on it.
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color(&"chart", &"DeskPalette"))
