class_name Hud
extends Control
## The HUD in the gate band's top-right corner (D21): the clock, feathers, the quota and Huginn's
## answers, each a code-drawn icon with a number, in parchment and grey only (never a reserved
## colour). The ledger icon shows a badge while a promise is open. Rank is never shown here.

const ROW_PITCH := 10
const ICON_TEXT_GAP := 2
## Where the right-hand column of cells starts; "untimed" fits the left one.
const RIGHT_COLUMN_X := 56.0

var _time_text: String = "--:--"
var _feathers: int = 0
var _quota := Vector2i.ZERO
var _huginn_on: bool = false
var _huginn_left: int = 0
var _promise_open: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(
	time_left: float,
	feathers: int,
	quota: Vector2i,
	huginn_on: bool,
	huginn_left: int,
	promise_open: bool
) -> void:
	_time_text = format_time(time_left)
	_feathers = feathers
	_quota = quota
	_huginn_on = huginn_on
	_huginn_left = huginn_left
	_promise_open = promise_open
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
	_cell(Vector2(3, 2), &"clock", _time_text)
	_cell(Vector2(RIGHT_COLUMN_X, 2), &"feather", str(_feathers))
	_cell(Vector2(3, 2 + ROW_PITCH), &"quota", "%d/%d" % [_quota.x, _quota.y])
	if _huginn_on:
		_cell(Vector2(RIGHT_COLUMN_X, 2 + ROW_PITCH), &"raven", str(_huginn_left))
	var ledger_at := Vector2(size.x - PixelGlyph.SIZE - 3, 2 + ROW_PITCH)
	PixelGlyph.draw(self, &"ledger", ledger_at, get_theme_color(&"glyph", &"DeskPalette"))
	if _promise_open:
		var badge := Rect2(ledger_at + Vector2(PixelGlyph.SIZE - 2, -1), Vector2(3, 3))
		draw_rect(badge, get_theme_color(&"text_light", &"DeskPalette"))


func _cell(at: Vector2, icon: StringName, text: String) -> void:
	PixelGlyph.draw(self, icon, at, get_theme_color(&"glyph", &"DeskPalette"))
	var font: Font = get_theme_default_font()
	var baseline := Vector2(at.x + PixelGlyph.SIZE + ICON_TEXT_GAP, at.y + PixelGlyph.SIZE)
	draw_string(
		font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		PixelFont.SIZE,
		get_theme_color(&"text_light", &"DeskPalette")
	)
