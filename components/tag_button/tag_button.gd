class_name TagButton
extends GuardedButton
## A guarded button drawn as a nailed paper tag (D24, D37, D42): a small torn ParchmentFrame sheet
## (its bites seeded by the tag's words, so each tag tears its own way), the sheet's 1 px Wood 1
## drop shadow below and right, the text in ink, and a 5×5 pin head with its highlight and shadow
## nailing its top-left corner. One of a choice (the options' text speed) is nailed only while
## chosen, and then by the selected pin's ember. Hovered, the tag lifts 1 px off the desk (its
## shadow deepens to 2 px; not under reduce motion, where it stays put) and a 1 px Wood 3 line rims
## it; disabled, the sheet is Parchment 0 and its text Wood 3. The hit area never moves. The
## button keeps its `text` (tests and tools read it) but draws it itself, on the tag's own rows.

enum Pin { WOOD, NONE, CHOSEN }

## The tag's height: a 1 px edge, a row of ground, one text row (its ink, descenders included,
## in rows 3-11), the bottom edge and the 1 px shadow under it.
const HEIGHT := 14
## The text's left edge, past the pin head, and its baseline.
const TEXT_LEFT := 8
const BASELINE := 10
## Pixels right of the text: 3 of ground, so the torn edge never reads as a letter, then the
## deckle ring, the edge column and the shadow.
const TEXT_RIGHT := 6
## The 5×5 pin head's top-left, in the tag's top-left corner.
const PIN_AT := Vector2i(1, 1)
const PIN_SIZE := 5
## How far a hovered tag lifts.
const LIFT := 1
const THEME_TYPE := &"DeskPalette"
const CLEAR := Color(0, 0, 0, 0)

## The pin head: Wood 3, none, or the chosen ember.
@export var pin: Pin = Pin.WOOD:
	set(value):
		pin = value
		queue_redraw()
## The text centred on the tag rather than after the pin.
@export var center_text: bool = false:
	set(value):
		center_text = value
		queue_redraw()
## A darker face: Wood 4 paper with Wood 3 edges and fibres, the text still in ink, so a tag
## nailed over a parchment page (the day-book's) reads as its own object, not a patch of the page.
@export var dark: bool = false:
	set(value):
		dark = value
		_fit_frame()
## Reduce motion (D37): a hovered tag is rimmed but does not lift.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_fit_frame()

var _frame: ParchmentFrame = null
var _hovered: bool = false
## What the last `_draw` painted over the sheet, in order (tests).
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []


func _ready() -> void:
	super()
	focus_mode = Control.FOCUS_NONE
	for style: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: StringName in [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
		&"font_disabled_color",
		&"font_hover_pressed_color",
	]:
		add_theme_color_override(color, CLEAR)
	_frame = ParchmentFrame.new()
	_frame.name = "Sheet"
	_frame.show_behind_parent = true
	_frame.torn = true
	add_child(_frame)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	resized.connect(_fit_frame)
	if size.x < fit_width():
		size = Vector2(fit_width(), HEIGHT)
	size.y = HEIGHT
	_fit_frame()


## The narrowest tag that holds the text.
func fit_width() -> int:
	return TEXT_LEFT + text_width() + TEXT_RIGHT


func text_width() -> int:
	var font: Font = get_theme_default_font()
	if font == null:
		return 0
	return ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x)


## Places the tag at `at` (whole pixels), `width` wide or as narrow as its text allows.
func place(at: Vector2, width: int = 0) -> void:
	position = at.floor()
	size = Vector2(maxi(width, fit_width()), HEIGHT)


## The baseline-left of the text in the tag, at rest.
func text_origin() -> Vector2i:
	var left: int = TEXT_LEFT
	if center_text:
		left = maxi(TEXT_LEFT, floori((size.x - 1 - text_width()) / 2.0) + 2)
	return Vector2i(left, BASELINE)


func is_hovered_tag() -> bool:
	return _hovered


## How far the tag is drawn above its place now: LIFT while hovered, 0 otherwise.
func lift() -> int:
	return LIFT if _hovered and not disabled and not reduce_motion else 0


## Every rectangle the last draw painted over the sheet, in order (tests).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


func sheet() -> ParchmentFrame:
	return _frame


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		if _frame != null:
			_fit_frame()


func _set_hovered(on: bool) -> void:
	_hovered = on
	_fit_frame()


func _fit_frame() -> void:
	if _frame == null:
		return
	_frame.position = Vector2(0, -lift())
	_frame.size = size
	# Everything inside the 1 px edge is flat ground: the text never sits on an edge pixel.
	_frame.inner = Rect2(Vector2(1, 1), size - Vector2(3, 3))
	_fit_face()
	queue_redraw()


## The sheet's colours: the desk's parchment, or the darker Wood face. The sheet reads its
## palette as DeskPalette, so the overrides apply under that type.
func _fit_face() -> void:
	if not is_inside_tree():
		return
	var faces: Dictionary = {
		&"parchment": &"wood_light", &"parchment_edge": &"frame", &"parchment_light": &"wood_light"
	}
	_frame.theme_type_variation = THEME_TYPE if dark else &""
	for sheet_color: StringName in faces:
		if dark:
			_frame.add_theme_color_override(sheet_color, _color(faces[sheet_color]))
		else:
			_frame.remove_theme_color_override(sheet_color)


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	# Each tag tears its own way; the words can change after it is placed (On / Off).
	if _frame != null and _frame.seed != hash(text):
		_frame.seed = hash(text)
	var up := Vector2(0, -lift())
	if lift() > 0:
		# Lifted, the tag's shadow on the desk is a row deeper.
		_paint(Rect2(1, size.y - 1, size.x - 1, 1), _color(&"parchment_shadow"))
	# A disabled tag's ground is Parchment 0, laid over the sheet's flat inner ground.
	if disabled and _frame != null:
		_paint(Rect2(_frame.inner.position + up, _frame.inner.size), _color(&"parchment_edge"))
	var ink: Color = _color(&"ink_soft") if disabled else _color(&"ink")
	var font: Font = get_theme_default_font()
	if font != null:
		draw_string(
			font,
			Vector2(text_origin()) + up,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			PixelFont.SIZE,
			ink
		)
	if _hovered and not disabled:
		_draw_rim(Rect2(up, size - Vector2.ONE))
	match pin:
		Pin.WOOD:
			_draw_pin(up, _color(&"pin_head"), _color(&"parchment_shadow"))
		Pin.CHOSEN:
			_draw_pin(up, _color(&"pin_selected"), _color(&"pin_selected_shadow"))


## The hovered tag's 1 px Wood 3 rim around its sheet (the shadow column and row left out).
func _draw_rim(rim: Rect2) -> void:
	var wood: Color = _color(&"frame")
	_paint(Rect2(rim.position, Vector2(rim.size.x, 1)), wood)
	_paint(Rect2(rim.position + Vector2(0, rim.size.y - 1), Vector2(rim.size.x, 1)), wood)
	_paint(Rect2(rim.position, Vector2(1, rim.size.y)), wood)
	_paint(Rect2(rim.position + Vector2(rim.size.x - 1, 0), Vector2(1, rim.size.y)), wood)


## The 5×5 pin head nailing the top-left corner, as the desk's other pins (PinSelectable).
func _draw_pin(up: Vector2, head: Color, shadow: Color) -> void:
	PinSelectable.draw_pin_head(
		_paint, PIN_AT + Vector2i(up), head, _color(&"pin_highlight"), shadow
	)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	_rects.append(rect)
	_colors.append(color)


func _color(color_name: StringName) -> Color:
	return get_theme_color(color_name, THEME_TYPE)
