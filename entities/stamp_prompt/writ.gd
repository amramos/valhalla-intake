class_name Writ
extends Control
## The soul's writ (D14, D15): a parchment slip under the doors with the soul's name, the slice's
## explicit recipient of the stamp (slice D9). The slam inks the realm's glyph in its box in Ink,
## never a reserved colour, and nothing on it depends on anything but the name and the realm.
## While held (a citation or a day-1 warning, D15) a click on it sends the stamped soul on, and its
## hover says so.

## A left click on the held writ.
signal clicked
signal hover_started(text: String, area: Rect2)
signal hover_ended

const SIZE := Vector2i(70, 16)
## The box the slam inks, in the writ's pixels: an 11×11 frame round the 7×7 glyph.
const INK_BOX := Rect2i(55, 2, 11, 11)
## The name's label offset (m5x7 at 16 draws its capitals 5 px under the label's top).
const NAME_AT := Vector2(4, -1)
## The widest name that never runs under the ink box.
const NAME_MAX_WIDTH := 49
const HELD_HOVER := "Send it on"
## The same deckle on every writ: it never varies with the soul (D14).
const PAPER_SEED := 14
const THEME_TYPE := &"DeskPalette"
const INK_FALLBACK := Color8(11, 23, 34)

var _paper: ParchmentFrame = null
var _name: Label = null
var _ink: Control = null
var _glyph: StringName = &""
var _held: bool = false
var _hovered: bool = false


func _ready() -> void:
	size = Vector2(SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = ParchmentFrame.new()
	_paper.name = "Paper"
	_paper.seed = PAPER_SEED
	_paper.size = Vector2(SIZE)
	_paper.inner = Rect2(2, 2, SIZE.x - 5, SIZE.y - 5)
	add_child(_paper)
	_name = Label.new()
	_name.name = "Name"
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.position = NAME_AT
	_name.add_theme_color_override(&"font_color", _ink_color())
	add_child(_name)
	_ink = Control.new()
	_ink.name = "Ink"
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.size = Vector2(SIZE)
	_ink.draw.connect(_draw_ink)
	add_child(_ink)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_soul_name(soul_name: String) -> void:
	_name.text = soul_name


func soul_name() -> String:
	return _name.text


## Inks `glyph` (a PixelGlyph id) in the box; &"" clears it.
func set_ink(glyph: StringName) -> void:
	_glyph = glyph
	_ink.queue_redraw()


func inked_glyph() -> StringName:
	return _glyph


## The colour the ink is drawn in (tests: always Ink, D14).
func ink_color() -> Color:
	return _ink_color()


func set_held(held: bool) -> void:
	if held == _held:
		return
	_held = held
	mouse_filter = Control.MOUSE_FILTER_STOP if held else Control.MOUSE_FILTER_IGNORE
	if not held and _hovered:
		_hovered = false
		hover_ended.emit()
	_ink.queue_redraw()


func is_held() -> bool:
	return _held


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if _held and not button.double_click:
		clicked.emit()


## The ink box with the glyph inside it, and while the held writ is hovered a 1 px underline under
## the name (the same mark a pinnable line shows on hover).
func _draw_ink() -> void:
	var ink: Color = _ink_color()
	if _held and _hovered:
		var width: int = mini(int(_name.get_minimum_size().x), NAME_MAX_WIDTH)
		_ink.draw_rect(Rect2(NAME_AT.x, 12, width, 1), ink)
	if _glyph == &"":
		return
	var box := Rect2(INK_BOX)
	_ink.draw_rect(Rect2(box.position, Vector2(box.size.x, 1)), ink)
	_ink.draw_rect(Rect2(box.position + Vector2(0, box.size.y - 1), Vector2(box.size.x, 1)), ink)
	_ink.draw_rect(Rect2(box.position, Vector2(1, box.size.y)), ink)
	_ink.draw_rect(Rect2(box.position + Vector2(box.size.x - 1, 0), Vector2(1, box.size.y)), ink)
	PixelGlyph.draw(_ink, _glyph, box.position + Vector2(2, 2), ink)


func _ink_color() -> Color:
	if has_theme_color(&"ink", THEME_TYPE):
		return get_theme_color(&"ink", THEME_TYPE)
	return INK_FALLBACK


func _on_mouse_entered() -> void:
	if not _held:
		return
	_hovered = true
	_ink.queue_redraw()
	hover_started.emit(HELD_HOVER, get_global_rect())


func _on_mouse_exited() -> void:
	if not _hovered:
		return
	_hovered = false
	_ink.queue_redraw()
	hover_ended.emit()
