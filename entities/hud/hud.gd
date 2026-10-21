class_name Hud
extends Control
## The HUD in the gate band's top-right corner (D21): the clock, feathers, the quota and Huginn's
## answers, each a code-drawn icon with a number, in parchment and grey only (never a reserved
## colour). The ledger icon shows a badge while a promise is open. Rank is never shown here.

const ROW_PITCH := 10
const ICON_TEXT_GAP := 2
## Where the right-hand column of cells starts; "untimed" fits the left one.
const RIGHT_COLUMN_X := 56.0

## "extra answer: N feathers" is drawn under the Ask Huginn button, inside the HUD's column.
const EXTRA_NOTE_TOP := 40.0
const EXTRA_NOTE_FORMAT := "extra answer:\n%d feathers"
## The warning clock blinks at this rate (seconds per phase).
const BLINK_SECONDS := 0.5

var _time_text: String = "--:--"
var _shown := HudReadout.new()
var _blink: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(readout: HudReadout) -> void:
	_shown = readout
	_time_text = format_time(readout.time_left)
	queue_redraw()


## The note under Ask Huginn, or "" when hidden.
func extra_note() -> String:
	if not _shown.huginn_on or _shown.huginn_left > 0 or _shown.extra_cost <= 0:
		return ""
	return EXTRA_NOTE_FORMAT % _shown.extra_cost


func is_warning() -> bool:
	return _shown.warning


func _process(delta: float) -> void:
	if not _shown.warning:
		return
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), get_theme_color(&"night", &"DeskPalette"))
	draw_rect(
		Rect2(Vector2.ZERO, size).grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0
	)
	if _shown.warning and _blink < BLINK_SECONDS:
		# The last 30 s (D22): the clock cell turns over, parchment on ink, and blinks.
		draw_rect(
			Rect2(1, 1, RIGHT_COLUMN_X - 3, ROW_PITCH),
			get_theme_color(&"text_light", &"DeskPalette")
		)
		_cell(Vector2(3, 2), &"clock", _time_text, &"ink")
	else:
		_cell(Vector2(3, 2), &"clock", _time_text)
	_cell(Vector2(RIGHT_COLUMN_X, 2), &"feather", str(_shown.feathers))
	_cell(Vector2(3, 2 + ROW_PITCH), &"quota", "%d/%d" % [_shown.quota.x, _shown.quota.y])
	if _shown.huginn_on:
		_cell(Vector2(RIGHT_COLUMN_X, 2 + ROW_PITCH), &"raven", str(_shown.huginn_left))
	var ledger_at := Vector2(size.x - PixelGlyph.SIZE - 3, 2 + ROW_PITCH)
	PixelGlyph.draw(self, &"ledger", ledger_at, get_theme_color(&"glyph", &"DeskPalette"))
	if _shown.promise_open:
		var badge := Rect2(ledger_at + Vector2(PixelGlyph.SIZE - 2, -1), Vector2(3, 3))
		draw_rect(badge, get_theme_color(&"text_light", &"DeskPalette"))
	var note: String = extra_note()
	if note != "":
		var plate := Rect2(0, EXTRA_NOTE_TOP, size.x, 2 * ROW_PITCH + 2)
		draw_rect(plate, get_theme_color(&"night", &"DeskPalette"))
		var row: float = EXTRA_NOTE_TOP + 1
		for line: String in note.split("\n"):
			_text(Vector2(3, row), line, get_theme_color(&"text_light", &"DeskPalette"))
			row += ROW_PITCH


func _cell(at: Vector2, icon: StringName, text: String, ink: StringName = &"") -> void:
	var icon_color: Color = get_theme_color(&"glyph", &"DeskPalette")
	var text_color: Color = get_theme_color(&"text_light", &"DeskPalette")
	if ink != &"":
		icon_color = get_theme_color(ink, &"DeskPalette")
		text_color = icon_color
	PixelGlyph.draw(self, icon, at, icon_color)
	_text(Vector2(at.x + PixelGlyph.SIZE + ICON_TEXT_GAP, at.y), text, text_color)


## One line of text whose cap tops sit at `top`.
func _text(top: Vector2, text: String, color: Color) -> void:
	draw_string(
		get_theme_default_font(),
		top + Vector2(0, PixelGlyph.SIZE),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		PixelFont.SIZE,
		color
	)
