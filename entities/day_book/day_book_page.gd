class_name DayBookPage
extends Control
## One page of the clerk's day-book (D22, D23): a worn parchment sheet (ParchmentFrame, torn at
## the edges) with its lines in ink and its small marks beside them. The lines are engine-rendered
## Labels, written out by the book's Teller; a mark, a carved heading or a rule belongs to a line
## and shows once that line has begun, so the marks come with the ink. Every mark is placed pixel by
## pixel in palette colours; the page never takes the mouse.

## The m5x7 line pitch, and how far below a Label's top its first line's ink begins.
const LINE_PITCH := 10
const LABEL_TOP := 3
## The marks, "#" in the mark's colour: the record marks (D23, D47) are 7×7 and differ by shape,
## the black feather is a 5×5 silhouette. The wax seal (7×7) is "o" rim, "#" wax and "c" heart.
const PATTERNS: Dictionary = {
	&"tick": ["......#", ".....##", "#...##.", "##.##..", ".###...", "..#....", "......."],
	&"frost": ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"],
	&"hollow": ["..###..", ".#...#.", "#.....#", "#.....#", "#.....#", ".#...#.", "..###.."],
	&"feather": ["...##", "..###", ".###.", ".##..", "#...."],
	&"seal": [".ooooo.", "o#####o", "o##c##o", "o#ccc#o", "o##c##o", "o#####o", ".ooooo."],
}
## The colour each mark is inked in (DeskPalette names); glyphs and the rest are Ink.
const MARK_COLORS: Dictionary = {&"frost": &"select_light", &"rule": &"ink_soft"}
const THEME_TYPE := &"DeskPalette"
## The sheet's worn edge and shadow keep this many columns clear at its right.
const INNER_RIGHT := 4

## Seeds the sheet's worn edge; each page of the book has its own.
@warning_ignore("shadowed_global_identifier") @export var seed: int = 0:
	set(value):
		seed = value
		if _frame != null:
			_frame.seed = value

## The lowest row (page pixels) the ink may reach; the layout sets it.
var text_bottom: int = 0

var _frame: ParchmentFrame = null
var _labels: Array[Label] = []
## Marks, carved headings and rules in drawing order: what, where, and the line they belong to
## (null: always shown).
var _kinds: Array[StringName] = []
var _rects: Array[Rect2i] = []
var _texts: Array[String] = []
var _owners: Array[Label] = []
## What the last `_draw` painted, in order (tests).
var _painted: Array[Rect2] = []
var _painted_colors: Array[Color] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = ParchmentFrame.new()
	_frame.name = "Sheet"
	_frame.show_behind_parent = true
	_frame.torn = true
	_frame.seed = seed
	add_child(_frame)
	resized.connect(_fit_frame)
	_fit_frame()


## Takes every line and mark off the page.
func clear() -> void:
	# Freed now, not queued: the owner stops its Teller before a page is cleared.
	for label: Label in _labels:
		label.free()
	_labels.clear()
	_kinds.clear()
	_rects.clear()
	_texts.clear()
	_owners.clear()
	queue_redraw()


## Writes `text` with its first line's ink at `at`, wrapped at `width` px (0: one line).
func write(text: String, at: Vector2i, width: int = 0) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	label.text = text
	label.position = Vector2(at.x, at.y - LABEL_TOP)
	# Sized once its text and wrap are set: earlier, the one-line width would hold it wide.
	label.size = Vector2(width, 0)
	label.size = Vector2(width, lines_of(label) * LINE_PITCH + LABEL_TOP)
	_labels.append(label)
	return label


## Takes the last line written (and the marks it carries) off the page.
func drop_last() -> void:
	if _labels.is_empty():
		return
	var label: Label = _labels.pop_back()
	for index: int in range(_owners.size() - 1, -1, -1):
		if _owners[index] == label:
			_kinds.remove_at(index)
			_rects.remove_at(index)
			_texts.remove_at(index)
			_owners.remove_at(index)
	label.free()
	queue_redraw()


## The lines `label` takes once wrapped.
func lines_of(label: Label) -> int:
	return maxi(1, label.get_line_count())


## The pixels `text` takes on one line in the page's font.
func text_width(text: String) -> int:
	var font: Font = get_theme_default_font()
	if font == null:
		return 0
	return ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x)


## A mark (PATTERNS, or a PixelGlyph realm glyph) with its top-left at `at`, shown with `owner`.
func mark(kind: StringName, at: Vector2i, owner: Label = null) -> void:
	_add(kind, Rect2i(at, Vector2i.ZERO), "", owner)


## A heading in the carved capitals with its top-left at `at`, shown with `owner`.
func heading(text: String, at: Vector2i, owner: Label = null) -> void:
	_add(&"heading", Rect2i(at, Vector2i.ZERO), text, owner)


## A 1 px rule (an underline), shown with `owner`.
func rule(area: Rect2i, owner: Label = null) -> void:
	_add(&"rule", area, "", owner)


func labels() -> Array[Label]:
	return _labels.duplicate()


## The lowest ink row any line reaches, in page pixels (the fit tests).
func ink_bottom() -> int:
	var bottom: int = 0
	for label: Label in _labels:
		var top: int = int(label.position.y) + LABEL_TOP
		bottom = maxi(bottom, top + lines_of(label) * LINE_PITCH)
	return bottom


## Every line ends above `text_bottom` and inside the sheet's flat ground, wrapped or not.
func fits() -> bool:
	if ink_bottom() > text_bottom:
		return false
	for label: Label in _labels:
		var width: int = int(label.size.x)
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
			width = text_width(label.text)
		if int(label.position.x) + width > int(size.x) - INNER_RIGHT:
			return false
	return true


## The marks shown now, by kind, in drawing order ("heading" and "rule" included).
func shown_marks() -> Array[StringName]:
	var shown: Array[StringName] = []
	for index: int in range(_kinds.size()):
		if _is_shown(_owners[index]):
			shown.append(_kinds[index])
	return shown


## Where each mark of `kind` is, in page pixels, shown or not (tests).
func mark_positions(kind: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for index: int in range(_kinds.size()):
		if _kinds[index] == kind:
			out.append(_rects[index].position)
	return out


func drawn_rects() -> Array[Rect2]:
	return _painted.duplicate()


func drawn_colors() -> Array[Color]:
	return _painted_colors.duplicate()


func _add(kind: StringName, area: Rect2i, text: String, owner: Label) -> void:
	_kinds.append(kind)
	_rects.append(area)
	_texts.append(text)
	_owners.append(owner)
	queue_redraw()


## A line has begun once the Teller shows any of it (-1 is all of it).
func _is_shown(owner: Label) -> bool:
	return owner == null or not is_instance_valid(owner) or owner.visible_characters != 0


func _fit_frame() -> void:
	if _frame == null:
		return
	_frame.position = Vector2.ZERO
	_frame.size = size
	# The text area is flat ground: no worn edge pixel ever lies under the ink.
	_frame.inner = Rect2(Vector2(4, 3), size - Vector2(4 + INNER_RIGHT, 6))


func _draw() -> void:
	_painted.clear()
	_painted_colors.clear()
	for index: int in range(_kinds.size()):
		if not _is_shown(_owners[index]):
			continue
		var kind: StringName = _kinds[index]
		var at: Vector2i = _rects[index].position
		match kind:
			&"heading":
				PixelCapitals.draw(self, _texts[index], Vector2(at), _color(&"parchment_light"))
			&"rule":
				_paint(Rect2(_rects[index]), _color(MARK_COLORS[&"rule"]))
			&"seal":
				_paint_pattern(PATTERNS[kind], at, _seal_colors())
			_:
				var rows: Array = PATTERNS.get(kind, PixelGlyph.GLYPHS.get(kind, []))
				var ink: Color = _color(MARK_COLORS.get(kind, &"ink"))
				_paint_pattern(rows, at, {"#": ink})


func _seal_colors() -> Dictionary:
	return {
		"o": _color(&"pin_selected_shadow"),
		"#": _color(&"seal_wax"),
		"c": _color(&"pin_selected"),
	}


## Paints a pattern row by row in runs of one code; codes missing from `colors` stay clear.
func _paint_pattern(rows: Array, at: Vector2i, colors: Dictionary) -> void:
	for y: int in range(rows.size()):
		var row: String = rows[y]
		var x: int = 0
		while x < row.length():
			var code: String = row[x]
			var end: int = x + 1
			while end < row.length() and row[end] == code:
				end += 1
			if colors.has(code):
				_paint(Rect2(at.x + x, at.y + y, end - x, 1), colors[code])
			x = end


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_painted.append(rect)
	_painted_colors.append(color)


func _color(color_name: StringName) -> Color:
	return get_theme_color(color_name, THEME_TYPE)
