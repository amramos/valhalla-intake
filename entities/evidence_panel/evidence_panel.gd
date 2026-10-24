# gdlint: disable=max-public-methods
class_name EvidencePanel
extends Control
## A paper of evidence lines (D6-D9): a saga sheet (the claim or a witness) or the Law scroll.
## Every line is a pin hit area. The sheet is torn parchment headed by the speaker in full ink,
## each line opening with a straight quote mark; the scroll hangs between two knotwork rods, its
## decrees numbered in roman numerals right-aligned in their own column, and its parchment ends
## just below the last decree, so it grows with the decrees in force (D9). A new decree carries a
## wax seal left of its numeral (D33). Ids show only with `show_ids` (tools). Decrees wrap at word
## boundaries; testimony never wraps, so a line too long for the sheet shows as overflow.
##
## `tell` writes the lines out one by one through a Teller (D4); a line's hit area is hidden, and
## a click on it ignored, until its line begins to show.

signal item_clicked(item_id: String)
signal cancel_requested
signal item_hover_started(item_id: String, text: String, area: Rect2)
signal item_hover_ended(item_id: String)
## The telling started by `tell` has shown every line (by pace or by `finish_telling`).
signal telling_finished

## Pixels between text lines (font size 16, line_spacing −3; ADR-0008).
const LINE_PITCH := PaperLine.LINE_PITCH
## Inner margin between the paper's edge and the text.
const PADDING := 2
## The label's first ink row sits this far below its top; lines are shifted up to match.
const LABEL_TOP := PaperLine.LABEL_TOP
## The height of each knotwork rod of the scroll (D9).
const ROD_HEIGHT := ScrollRod.HEIGHT
## The scroll's parchment never shows shorter than this, rods excluded.
const MIN_SCROLL_BODY := 40
## The scroll's parchment ends this far below the last decree's ink, the bottom rod under it (D9),
## when the panel has the room; a full day-3 scroll keeps at least `MIN_SCROLL_TAIL`.
const SCROLL_TAIL := 6
## The least parchment under the last decree: the frame's 2 px edge and its shadow.
const MIN_SCROLL_TAIL := 3

@export var heading: String = ""
## Wrap long lines at word boundaries (decrees); testimony lines never wrap.
@export var wrap_lines: bool = false
## &"sheet" (claim, witness) or &"scroll" (the Law).
@export var style: StringName = &"sheet"
## Shows the authored ids ("C1 ", "L1") instead of quote marks and numerals (tools only).
@export var show_ids: bool = false

var _areas: Dictionary[String, PinSelectable] = {}
var _labels: Dictionary[String, Label] = {}
## Line ids in shown order (the telling's order).
var _order: Array[String] = []
var _heading_label: Label = null
var _note_label: Label = null
var _frame: ParchmentFrame = null
var _teller: Teller = null
var _content_bottom: int = 0
## Where the scroll's lower rod begins, in panel pixels (sheets: the panel's height).
var _body_end: int = 0
## A telling is under way and its end not yet announced.
var _awaiting_finish: bool = false
## Lines marked NEW (D34): each carries a wax seal left of its numeral (D9, D33).
var _new_ids: Array[String] = []
## The heading's hover label (the witness's full description, D52); "" for none.
var _heading_hover: String = ""


func _ready() -> void:
	clip_contents = false
	_frame = ParchmentFrame.new()
	_frame.name = "Paper"
	_frame.show_behind_parent = true
	_frame.torn = true
	_frame.seed = hash(String(name))
	add_child(_frame)
	_teller = Teller.new()
	_teller.name = "Teller"
	add_child(_teller)
	_teller.line_shown.connect(_on_line_shown)
	_teller.finished.connect(_on_teller_finished)
	_heading_label = PaperLine.make_label(get_theme_color(&"ink", &"DeskPalette"))
	_heading_label.name = "Heading"
	add_child(_heading_label)
	_heading_label.mouse_entered.connect(_on_heading_entered)
	_heading_label.mouse_exited.connect(func() -> void: item_hover_ended.emit(""))
	_note_label = PaperLine.make_label(get_theme_color(&"ink_soft", &"DeskPalette"))
	_note_label.name = "Note"
	add_child(_note_label)
	_layout([], "")


## Shows the lines; `note` stands in for an empty panel ("No witness came back.", D46).
## `heading_hover` is the heading's hover label ("" for none). Stops a telling in progress
## without announcing its end.
func show_lines(
	items: Array[EvidenceItem],
	title: String = heading,
	note: String = "",
	heading_hover: String = ""
) -> void:
	heading = title
	_heading_hover = heading_hover
	_heading_label.mouse_filter = (
		Control.MOUSE_FILTER_STOP if heading_hover != "" else Control.MOUSE_FILTER_IGNORE
	)
	_teller.stop()
	_awaiting_finish = false
	_layout(items, note)


## Writes the shown lines out one at a time at `cps` characters a second with `line_pause`
## seconds between lines (D4); `voice` is `hash(soul_name)`. `telling_finished` follows once
## every line shows; an empty panel finishes on the next frame.
func tell(voice: int, cps: float, line_pause: float) -> void:
	var labels: Array[Label] = []
	for id: String in _order:
		_areas[id].visible = false
		labels.append(_labels[id])
	_awaiting_finish = true
	_teller.start_labels(labels, cps, line_pause, voice)


## Shows every line now and announces the end of the telling (a consumed click, D27).
func finish_telling() -> void:
	_teller.finish()


func is_telling() -> bool:
	return _teller.is_telling()


## The panel's Teller, for the presentation gate (pause) and the voice blips.
func teller() -> Teller:
	return _teller


## Marks lines NEW until the day's first stamp (D34): each shows its wax seal (D9, D33); an
## empty list clears the marks. The heading stays the heading alone.
func set_new(item_ids: Array[String]) -> void:
	if item_ids == _new_ids:
		return
	_new_ids = item_ids.duplicate()
	queue_redraw()


func is_new(item_id: String) -> bool:
	return _new_ids.has(item_id) and _areas.has(item_id)


## Where a new decree's wax seal is drawn, in panel pixels; an empty rect when it has none.
func seal_rect(item_id: String) -> Rect2:
	if not is_new(item_id) or not _areas[item_id].has_node(^"Numeral"):
		return Rect2()
	var line: PinSelectable = _areas[item_id]
	var numeral: Label = line.get_node(^"Numeral") as Label
	return Rect2(WaxSeal.place(line.position, int(numeral.position.x)), WaxSeal.SIZE_VECTOR)


## The heading's hover area (tests and tools).
func heading_hover_area() -> Control:
	return _heading_label


## The heading's whole row in global coordinates, whatever name it shows: a hover tag keeps clear
## of it (D20).
func heading_rect() -> Rect2:
	var top: int = ROD_HEIGHT if style == &"scroll" else 0
	return Rect2(global_position + Vector2(0, top), Vector2(size.x, PADDING + LINE_PITCH))


func heading_text() -> String:
	return _heading_label.text if _heading_label.visible else ""


func has_item(item_id: String) -> bool:
	return _areas.has(item_id)


## The line's hit area in global coordinates; an empty rect when absent.
func anchor_rect(item_id: String) -> Rect2:
	return _areas[item_id].get_global_rect() if _areas.has(item_id) else Rect2()


## Every hit area's rectangle in global coordinates (a knot must not cover one), shown or not.
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
	return PaperLine.width_of(self, _labels[item_id].text) if _labels.has(item_id) else 0


## Where the last line's ink ends, in panel pixels.
func content_bottom() -> int:
	return _content_bottom


## Where the parchment ends, in panel pixels: on the scroll the bottom rod starts here, so the area
## below it shows the desk (D9); a sheet's paper fills the panel.
func paper_bottom() -> int:
	return _body_end


## True when text runs past the paper (the fit check reports it).
func overflows() -> bool:
	if style == &"scroll":
		if _content_bottom + MIN_SCROLL_TAIL + ROD_HEIGHT > int(size.y):
			return true
	elif _content_bottom > int(size.y) - PADDING:
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
	_order.clear()
	var top: int = ROD_HEIGHT if style == &"scroll" else 0
	var y: int = top + PADDING
	_heading_label.visible = heading != ""
	var rule_y: int = -1
	if heading != "":
		_heading_label.text = heading
		_heading_label.position = Vector2(PADDING, y - LABEL_TOP)
		_heading_label.size = Vector2(inner_width() if style == &"scroll" else 0, 0)
		_heading_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if style == &"scroll" else HORIZONTAL_ALIGNMENT_LEFT
		)
		y += LINE_PITCH
		rule_y = y - 1 - top
	var lines_top: int = y
	for item: EvidenceItem in items:
		y += _add_line(item, y)
	_note_label.visible = items.is_empty() and note != ""
	if _note_label.visible:
		_note_label.text = note
		_note_label.position = Vector2(PADDING, y - LABEL_TOP)
		y += LINE_PITCH
	_content_bottom = y
	_body_end = int(size.y)
	if style == &"scroll":
		_body_end = mini(maxi(y + SCROLL_TAIL, top + MIN_SCROLL_BODY), int(size.y) - ROD_HEIGHT)
	_frame.position = Vector2(0, top)
	_frame.size = Vector2(size.x, _body_end - top)
	_frame.rule_y = rule_y
	# The lines and their hit areas: nothing but plain parchment is drawn under them.
	_frame.inner = Rect2(PADDING, lines_top - top, inner_width(), maxi(y - lines_top, 0))
	queue_redraw()


func _add_line(item: EvidenceItem, y: int) -> int:
	var hit: PinSelectable = PaperLine.build(
		self, item, style == &"scroll", show_ids, inner_width(), wrap_lines
	)
	hit.position = Vector2(PADDING, y)
	hit.clicked.connect(_on_line_clicked.bind(hit))
	hit.cancel_requested.connect(func() -> void: cancel_requested.emit())
	hit.hover_started.connect(
		func(id: String, text: String, at: Rect2) -> void: item_hover_started.emit(id, text, at)
	)
	hit.hover_ended.connect(func(id: String) -> void: item_hover_ended.emit(id))
	_areas[item.id] = hit
	_labels[item.id] = PaperLine.text_label(hit)
	_order.append(item.id)
	return int(hit.size.y)


## A click on a line not yet told is ignored (D4: lines are pinnable as they appear).
func _on_line_clicked(id: String, hit: PinSelectable) -> void:
	if hit.visible:
		item_clicked.emit(id)


func _on_line_shown(index: int) -> void:
	if index < _order.size():
		_areas[_order[index]].visible = true


func _on_teller_finished() -> void:
	for id: String in _areas:
		_areas[id].visible = true
	if _awaiting_finish:
		_awaiting_finish = false
		telling_finished.emit()


func _on_heading_entered() -> void:
	if _heading_hover != "":
		item_hover_started.emit("", _heading_hover, _heading_label.get_global_rect())


func _draw() -> void:
	if style == &"scroll":
		var width: int = int(size.x)
		ScrollRod.draw(_paint, Vector2i(0, 0), width, _rod_colors())
		ScrollRod.draw(_paint, Vector2i(0, _body_end), width, _rod_colors())
	var wax: Color = get_theme_color(&"seal_wax", &"DeskPalette")
	var edge: Color = get_theme_color(&"pin_selected_shadow", &"DeskPalette")
	var heart: Color = get_theme_color(&"pin_selected", &"DeskPalette")
	for id: String in _new_ids:
		var seal: Rect2 = seal_rect(id)
		if seal.has_area():
			WaxSeal.draw(_paint, Vector2i(seal.position), wax, edge, heart)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)


## Wood 2, 3 and 4 for the rods' knotwork.
func _rod_colors() -> Array[Color]:
	return [
		get_theme_color(&"wood_dark", &"DeskPalette"),
		get_theme_color(&"frame", &"DeskPalette"),
		get_theme_color(&"wood_light", &"DeskPalette"),
	]
