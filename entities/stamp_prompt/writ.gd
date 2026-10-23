class_name Writ
extends Control
## The soul's writ (D14, D15): a parchment slip under the doors with the soul's name, the slice's
## explicit recipient of the stamp (slice D9). The slam presses the stamp's own face into it: the
## realm's bold glyph (15×15, 3 px strokes) in Ink inside the 19×19 ink box (D55), never a
## reserved colour, with no frame round it but an uneven 1 px bleed and a few Wood 0 pixels of
## halo, the same for every stamp of a realm. Under the raised stamp lies its 1 px shadow; at the
## impact the slip flashes Parchment 2 and dents 1 px down (timed by the stamp). Nothing on it
## depends on anything but the name and the realm.
## While held (a citation or a day-1 warning, D15) a click on it sends the stamped soul on, and its
## hover says so.

## A left click on the held writ.
signal clicked
signal hover_started(text: String, area: Rect2)
signal hover_ended

## The impression's pixels: the glyph and its bleed in Ink, the halo in Wood 0.
enum Mark { INK, HALO }

const SIZE := Vector2i(90, 20)
## The area the slam inks, in the writ's pixels: 19×19 round the 15×15 glyph (D55), unframed. It
## sits 7 px in from the right so the stamp over it leaves room for "Fólkvangr?" beside it.
const INK_BOX := Rect2i(63, 0, 19, 19)
## The glyph's place inside the box.
const GLYPH_IN_BOX := Vector2i(2, 2)
## The name's label offset (m5x7 at 16 draws its capitals 5 px under the label's top).
const NAME_AT := Vector2(4, 1)
## The widest name that never runs under the ink box.
const NAME_MAX_WIDTH := 58
const HELD_HOVER := "Send it on"
## The same deckle on every writ: it never varies with the soul (D14).
const PAPER_SEED := 14
## The bleed's and the halo's pixel counts, drawn per realm from a generator seeded by its glyph.
const BLEED_MIN := 3
const BLEED_MAX := 5
const HALO_MIN := 2
const HALO_MAX := 3
## How far the impact dents the slip into the desk.
const DENT_PX := 1
const THEME_TYPE := &"DeskPalette"
## Palette fallbacks (docs/art/palette.gpl): Ink (Night 0), Wood 0, Night 1, Parchment 2.
const INK_FALLBACK := Color8(11, 23, 34)
const WOOD_0 := Color8(39, 30, 33)
const NIGHT_1 := Color8(15, 37, 48)
const PARCHMENT_2 := Color8(246, 238, 210)
const ORTHOGONAL: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const AROUND: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

var _paper: ParchmentFrame = null
var _flash: ColorRect = null
var _name: Label = null
var _ink: Control = null
var _glyph: StringName = &""
## The raised stamp's shadow in the writ's pixels; empty when no stamp is raised.
var _shadow: Rect2i = Rect2i()
var _dented: bool = false
## Every pixel the last ink draw painted, with its colour (tests).
var _drawn: Dictionary[Vector2i, Color] = {}
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
	# The flash covers the sheet (its last column and row are the paper's shadow) under the name.
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.size = Vector2(SIZE - Vector2i.ONE)
	_flash.color = _theme(&"pin_highlight", PARCHMENT_2)
	_flash.visible = false
	add_child(_flash)
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


func halo_color() -> Color:
	return _theme(&"ink_halo", WOOD_0)


## Every pixel the ink layer last painted (shadow, underline, impression), with its colour.
func drawn_ink() -> Dictionary[Vector2i, Color]:
	return _drawn.duplicate()


## The raised stamp's 1 px shadow over `area` (the writ's pixels), cut to the sheet (its last
## column and row are the paper's own shadow); an empty rect clears it.
func set_shadow(area: Rect2i) -> void:
	_shadow = area.intersection(Rect2i(Vector2i.ZERO, SIZE - Vector2i.ONE))
	_ink.queue_redraw()


func shadow() -> Rect2i:
	return _shadow


## The impact's flash: the whole slip in Parchment 2, under the name and the ink.
func set_flash(on: bool) -> void:
	_flash.visible = on


func is_flashing() -> bool:
	return _flash.visible


## The colour of the slip's ground now: Parchment 2 in the flash, else Parchment 1.
func sheet_color() -> Color:
	return _flash.color if _flash.visible else _theme(&"parchment", ParchmentFrame.PARCHMENT_1)


## The impact dents the slip DENT_PX down and letting go springs it back. Only a dent undoes a
## dent, so a sweep's own movement is never overridden.
func set_dented(on: bool) -> void:
	if on == _dented:
		return
	_dented = on
	position.y = DENT_PX if on else 0


func is_dented() -> bool:
	return _dented


## The impression of `glyph` in the writ's pixels: the stamp's bold glyph, 3-5 pixels of bleed at
## its edges and 2-3 of halo beside the ink, all inside INK_BOX. The bleed and the halo come from
## a generator seeded by the glyph, so every stamp of a realm leaves the same mark (D14).
static func impression(glyph: StringName) -> Dictionary[Vector2i, Mark]:
	var marks: Dictionary[Vector2i, Mark] = {}
	var at: Vector2i = INK_BOX.position + GLYPH_IN_BOX
	for pixel: Vector2i in StampFace.thick_pixels(glyph):
		marks[at + pixel] = Mark.INK
	if marks.is_empty():
		return marks
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(glyph))
	var bleed: Array[Vector2i] = _beside(marks, ORTHOGONAL)
	for pixel: Vector2i in _pick(bleed, rng.randi_range(BLEED_MIN, BLEED_MAX), rng):
		marks[pixel] = Mark.INK
	var halo: Array[Vector2i] = _beside(marks, AROUND)
	for pixel: Vector2i in _pick(halo, rng.randi_range(HALO_MIN, HALO_MAX), rng):
		marks[pixel] = Mark.HALO
	return marks


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


## The raised stamp's shadow, the impression, and while the held writ is hovered a 1 px underline
## under the name (the same mark a pinnable line shows on hover).
func _draw_ink() -> void:
	_drawn.clear()
	var ink: Color = _ink_color()
	if _shadow.has_area():
		_paint(_shadow, _theme(&"night", NIGHT_1))
	if _held and _hovered:
		var width: int = mini(int(_name.get_minimum_size().x), NAME_MAX_WIDTH)
		_paint(Rect2i(int(NAME_AT.x), int(NAME_AT.y) + 13, width, 1), ink)
	if _glyph == &"":
		return
	var halo: Color = halo_color()
	var marks: Dictionary[Vector2i, Mark] = impression(_glyph)
	for pixel: Vector2i in marks:
		_paint(Rect2i(pixel, Vector2i.ONE), ink if marks[pixel] == Mark.INK else halo)


## Paints `area` on the ink layer and records its pixels.
func _paint(area: Rect2i, color: Color) -> void:
	_ink.draw_rect(Rect2(area), color)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			_drawn[Vector2i(x, y)] = color


## The pixels inside INK_BOX not in `marks` with a neighbour in it along `steps`, in reading order.
static func _beside(marks: Dictionary[Vector2i, Mark], steps: Array[Vector2i]) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y: int in range(INK_BOX.position.y, INK_BOX.end.y):
		for x: int in range(INK_BOX.position.x, INK_BOX.end.x):
			var pixel := Vector2i(x, y)
			if marks.has(pixel):
				continue
			for step: Vector2i in steps:
				if marks.has(pixel + step):
					found.append(pixel)
					break
	return found


## `count` of `pixels` (all of them if there are fewer), chosen by `rng`.
static func _pick(
	pixels: Array[Vector2i], count: int, rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var pool: Array[Vector2i] = pixels.duplicate()
	var chosen: Array[Vector2i] = []
	while chosen.size() < count and not pool.is_empty():
		chosen.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return chosen


## A 1 px outline of `area` on `canvas` (the prompt's shockwave).
static func frame(canvas: CanvasItem, area: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(area.position, Vector2(area.size.x, 1)), color)
	canvas.draw_rect(
		Rect2(area.position + Vector2(0, area.size.y - 1), Vector2(area.size.x, 1)), color
	)
	canvas.draw_rect(Rect2(area.position, Vector2(1, area.size.y)), color)
	canvas.draw_rect(
		Rect2(area.position + Vector2(area.size.x - 1, 0), Vector2(1, area.size.y)), color
	)


func _ink_color() -> Color:
	return _theme(&"ink", INK_FALLBACK)


func _theme(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback


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
