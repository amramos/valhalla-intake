class_name Hud
extends Control
## The HUD in the gate band's top-right corner, as objects on the stone (D11, D33): a candle that
## burns down with the clock beside its m:ss, a quill with the feather count, a tally slate for the
## quota, Huginn's answers on day 3 and the ledger as a closed book with a wax dot while a promise
## is open. Each object has its own small Night 1 plate (2 px padding) so its number reads on
## every day's band (D39); there is no frame around the whole. Only the flame and the wax dot are
## ember (UI accents). Rank is never shown here.
##
## A no-seam pin that charged time is shown by the desk system calling `gutter(seconds)` at the
## pin (D36); the readout carries no field for it, so a refresh never replays the gutter. Its
## "-0:10" shows on the stone left of the candle, never over a number (D11): the node reaches
## 32 px left of the objects for it and starts at the screen's top edge. The gate's pause holds
## the gutter and the blink (`set_paused`); a restart clears the gutter (`clear_gutter`).

## Padding inside every plate, and the stone left between two plates.
const PAD := 2
const GAP := 2
const ICON_TEXT_GAP := 1
## The font's cap height at PixelFont.SIZE; a text row's plate is PAD + CAP + PAD tall.
const CAP := 7
const ROW_HEIGHT := CAP + 2 * PAD
## The objects' top-left corner and width (screen x 384–478 from y 2); the stone left of them
## holds the gutter's label.
const ORIGIN := Vector2i(32, 2)
const OBJECTS_WIDTH := 94
const FIRST_ROW_Y := 2
const SECOND_ROW_Y := FIRST_ROW_Y + ROW_HEIGHT + 1
## The candle's plate spans both rows at the left; the other objects start right of it.
const CANDLE_PLATE := Rect2i(32, 3, 10, 21)
const OBJECTS_X := 44
## The book sits inside the LedgerTray's click area (screen x 467–477, y 11–21: here 115–125).
const BOOK_AT := Vector2i(116, 12)
## The gutter's label plate: screen x 359–385, y 0–8, with 1 px around the caps. It sits above the
## Fólkvangr door (from y 9) and right of that door's NEW tag (to x 358); its last two columns
## share the candle plate's empty left padding, which is the same Night 1.
const GUTTER_AT := Vector2i(7, 0)
const GUTTER_PAD := Vector2i(1, 1)

## "extra answer: N feathers" is drawn under the Ask Huginn button, inside the HUD's column.
const EXTRA_NOTE_TOP := 42.0
const EXTRA_NOTE_FORMAT := "extra answer:\n%d feathers"
## The warning clock blinks at this rate (seconds per phase).
const BLINK_SECONDS := 0.5

## Palette values the theme does not name yet: Night 2 (the slate), Fog 2 (chalk) and Fog 1 (the
## faint target marks: Fog 0 vanishes on Night 2 at 1:1). The theme's `slate`, `chalk` and
## `chalk_faint` win when they exist.
const SLATE_FALLBACK := Color8(22, 48, 59)
const CHALK_FALLBACK := Color8(163, 174, 176)
const CHALK_FAINT_FALLBACK := Color8(122, 126, 123)

## Reduce motion (D37): the gutter's flame holds still; its label is the same either way.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_gutter.reduce_motion = value
var _gutter := HudGutter.new()
var _shown := HudReadout.new()
var _time_text: String = "--:--"
var _time_left: float = INF
var _clock_seconds: float = 0.0
var _warning: bool = false
var _blink: float = 0.0
var _rects: Array[Rect2] = []
var _colors: Array[Color] = []
var _texts: Array[String] = []
var _ember_rects: Array[Rect2] = []
var _gutter_plate := Rect2()
var _paused: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(readout: HudReadout) -> void:
	_shown = readout
	set_clock(readout.time_left, readout.clock_seconds, readout.warning)
	if not readout.clock_shown:
		_time_text = ""


## The candle and its numeral: `clock_seconds` is the day's full clock (0 on an untimed day).
func set_clock(time_left: float, clock_seconds: float, warning: bool) -> void:
	_time_left = time_left
	_clock_seconds = clock_seconds
	_warning = warning
	_time_text = format_time(time_left) if is_timed() else format_time(INF)
	queue_redraw()


## The flame gutters and "-m:ss" floats off it (D36); called when a no-seam pin charged time.
func gutter(seconds_lost: int) -> void:
	if seconds_lost <= 0:
		return
	_gutter.start("-" + format_time(seconds_lost))
	queue_redraw()


## The note under Ask Huginn, or "" when hidden.
func extra_note() -> String:
	if not _shown.huginn_on or _shown.huginn_left > 0 or _shown.extra_cost <= 0:
		return ""
	return EXTRA_NOTE_FORMAT % _shown.extra_cost


func is_warning() -> bool:
	return _warning


func is_timed() -> bool:
	return _clock_seconds > 0.0 and is_finite(_time_left)


## The candle's wax height in pixels (0–14).
func wax_height() -> int:
	return HudMarks.wax_height(_time_left, _clock_seconds)


func is_lit() -> bool:
	return is_timed() and _shown.clock_shown and wax_height() > 0


## The gutter's label while it shows ("-0:10"), else "".
func gutter_label() -> String:
	return _gutter.label()


## The gutter label's plate as last drawn; empty when no label showed.
func gutter_plate() -> Rect2:
	return _gutter_plate


## The presentation gate's pause holds the gutter and the warning blink where they are.
func set_paused(paused: bool) -> void:
	_paused = paused


## Ends a gutter at once (a restarted run leaves nothing of the old one on the desk).
func clear_gutter() -> void:
	_gutter.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _paused:
		return
	if _gutter.advance(delta):
		queue_redraw()
	if _warning:
		_blink = fmod(_blink + delta, BLINK_SECONDS * 2.0)
		queue_redraw()


## "m:ss", or "untimed" when there is no clock (day 1, D10).
static func format_time(seconds: float) -> String:
	if is_inf(seconds):
		return "untimed"
	var whole: int = maxi(0, ceili(seconds))
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]


func shown_time() -> String:
	return _time_text


## Every rectangle the last draw painted, in order (tests and tools).
func drawn_rects() -> Array[Rect2]:
	return _rects.duplicate()


## The colour of each rectangle in `drawn_rects()`.
func drawn_colors() -> Array[Color]:
	return _colors.duplicate()


## Every text the last draw wrote, in order.
func drawn_texts() -> Array[String]:
	return _texts.duplicate()


## The rectangles the last draw painted in ember: the flame and the wax dot only.
func ember_rects() -> Array[Rect2]:
	return _ember_rects.duplicate()


func _draw() -> void:
	_rects.clear()
	_colors.clear()
	_texts.clear()
	_ember_rects.clear()
	_gutter_plate = Rect2()
	_draw_candle()
	var right: int = _draw_clock()
	_draw_icon_object(Vector2i(right + GAP, FIRST_ROW_Y), &"quill", str(_shown.feathers))
	right = _draw_slate()
	if _shown.huginn_on:
		_draw_icon_object(Vector2i(right + GAP, SECOND_ROW_Y), &"raven", str(_shown.huginn_left))
	_draw_book()
	if _gutter.label() != "":
		_draw_gutter_label()
	_draw_extra_note()


func _draw_candle() -> void:
	_paint(_whole(CANDLE_PLATE), _color(&"night"))
	var flame: int = _gutter.flame_frame() if is_lit() else HudMarks.UNLIT
	var ramp: Array[Color] = [
		_color(&"parchment_light"), _color(&"parchment"), _color(&"parchment_dim")
	]
	var at: Vector2i = CANDLE_PLATE.position + Vector2i(PAD, PAD)
	var wick: Color = _color(&"frame")
	var flame_rects: Array[Rect2] = HudMarks.candle(
		_paint, at, wax_height(), flame, ramp, wick, _color(&"pin_selected")
	)
	_ember_rects.append_array(flame_rects)


## The m:ss (or "untimed") on its plate; turned over and blinking in the last 30 s (D22). Returns
## the plate's right edge.
func _draw_clock() -> int:
	if _time_text == "":
		return OBJECTS_X - GAP
	var plate := Rect2i(OBJECTS_X, FIRST_ROW_Y, _text_width(_time_text) + 2 * PAD, ROW_HEIGHT)
	var turned: bool = _warning and _blink < BLINK_SECONDS
	_paint(_whole(plate), _color(&"text_light" if turned else &"night"))
	var ink: Color = _color(&"ink" if turned else &"text_light")
	_text(plate.position + Vector2i(PAD, PAD), _time_text, ink)
	return plate.end.x


## A glyph and a number on one plate; returns the plate's right edge.
func _draw_icon_object(at: Vector2i, icon: StringName, text: String) -> int:
	var width: int = PixelGlyph.SIZE + ICON_TEXT_GAP + _text_width(text)
	var plate := Rect2i(at, Vector2i(width + 2 * PAD, ROW_HEIGHT))
	_paint(_whole(plate), _color(&"night"))
	HudMarks.glyph(_paint, icon, at + Vector2i(PAD, PAD), _color(&"glyph"))
	var text_at := at + Vector2i(PAD + PixelGlyph.SIZE + ICON_TEXT_GAP, PAD)
	_text(text_at, text, _color(&"text_light"))
	return plate.end.x


## The tally slate and "N/M" on one plate (the 9 px slate leaves 1 px above and below it).
func _draw_slate() -> int:
	var numeral: String = "%d/%d" % [_shown.quota.x, _shown.quota.y]
	var width: int = HudMarks.SLATE_SIZE.x + ICON_TEXT_GAP + 1 + _text_width(numeral)
	var plate := Rect2i(OBJECTS_X, SECOND_ROW_Y, width + 2 * PAD, ROW_HEIGHT)
	_paint(_whole(plate), _color(&"night"))
	var colors: Array[Color] = [
		_color(&"slate", SLATE_FALLBACK),
		_color(&"chalk", CHALK_FALLBACK),
		_color(&"chalk_faint", CHALK_FAINT_FALLBACK),
		_color(&"frame"),
	]
	var slate_at := plate.position + Vector2i(PAD, 1)
	HudMarks.slate(_paint, slate_at, _shown.quota.x, _shown.quota.y, colors)
	var text_at := Vector2i(
		slate_at.x + HudMarks.SLATE_SIZE.x + ICON_TEXT_GAP + 1, plate.position.y
	)
	_text(text_at + Vector2i(0, PAD), numeral, _color(&"text_light"))
	return plate.end.x


func _draw_book() -> void:
	_paint(Rect2(Vector2(BOOK_AT - Vector2i(PAD, PAD)), Vector2(12, 12)), _color(&"night"))
	var colors: Dictionary[String, Color] = {
		"d": _color(&"wood_dark"),
		"l": _color(&"wood_light"),
		"f": _color(&"frame"),
		"p": _color(&"parchment_dim"),
	}
	var dot: Rect2 = HudMarks.book(
		_paint, BOOK_AT, colors, _shown.promise_open, _color(&"pin_selected")
	)
	if dot.has_area():
		_ember_rects.append(dot)


## "-0:10" on its own plate on the stone left of the candle; it never moves and covers nothing.
func _draw_gutter_label() -> void:
	var text: String = _gutter.label()
	var plate := Rect2i(GUTTER_AT, Vector2i(_text_width(text), CAP) + 2 * GUTTER_PAD)
	_gutter_plate = _whole(plate)
	_paint(_gutter_plate, _color(&"night"))
	_text(GUTTER_AT + GUTTER_PAD, text, _color(_gutter.ink()))


## The Ask Huginn button's caption (D29, D30); it lives below this node until the raven replaces
## the button, so it is the one thing drawn outside the HUD's rect.
func _draw_extra_note() -> void:
	var note: String = extra_note()
	if note == "":
		return
	var plate := Rect2(ORIGIN.x, EXTRA_NOTE_TOP, OBJECTS_WIDTH, 2 * 10 + 2)
	draw_rect(plate, _color(&"night"))
	var row: float = EXTRA_NOTE_TOP + 1
	for line: String in note.split("\n"):
		_text(Vector2i(ORIGIN.x + 3, int(row)), line, _color(&"text_light"))
		row += 10


func _paint(rect: Rect2, color: Color) -> void:
	_rects.append(rect)
	_colors.append(color)
	draw_rect(rect, color)


## One line of text whose cap tops sit at `top`.
func _text(top: Vector2i, text: String, color: Color) -> void:
	_texts.append(text)
	draw_string(
		get_theme_default_font(),
		Vector2(top + Vector2i(0, CAP)),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		PixelFont.SIZE,
		color
	)


## The text's inked width: its advance less the trailing column of spacing.
func _text_width(text: String) -> int:
	var font: Font = get_theme_default_font()
	var advance: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
	return maxi(0, ceili(advance) - 1)


func _color(name: StringName, fallback: Color = Color.TRANSPARENT) -> Color:
	if fallback.a > 0.0 and not has_theme_color(name, &"DeskPalette"):
		return fallback
	return get_theme_color(name, &"DeskPalette")


static func _whole(rect: Rect2i) -> Rect2:
	return Rect2(Vector2(rect.position), Vector2(rect.size))
