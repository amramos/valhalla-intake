class_name DawnWrit
extends Control
## The dawn (D21): the screen falls to Night 0, "DAY I" in the carved capitals with the horn, for
## 1.5 s at most; then the dark lifts on Odin's writ, hanging by the doors: a sealed parchment
## with the day's lines (ScreenText.dawn_lines, D34) and "Begin" on a tab at its bottom. Taking
## the writ down (the tab) begins the day; it slides up and away in 0.2 s.
##
## Any press during the dark card skips to the writ and does nothing else (D27): through the
## presentation gate's DAWN consumer (its owner begins it on `card_started` with `finish_card`,
## and ends it on `card_finished`), or here when no gate takes the press first. The whole screen
## is a mouse stop while the dawn shows, so nothing under the writ is clickable. Its clock is its
## own `_process`, paused by `set_paused`. Reduce motion (D37): no fall, lift or slide; the card
## still shows for 1.5 s unless clicked.

## The tab was pressed: begin the day.
signal advanced
## The dark card appeared; it ends with `card_finished` (by time, a press, or being closed).
signal card_started
signal card_finished
## The horn sounds with the card.
signal horn_requested

enum Stage { HIDDEN, FALL, CARD, LIFT, WRIT, SLIDE }

## The dark card's whole length, its fall included, and each movement's.
const CARD_SECONDS := 1.5
const FALL_SECONDS := 0.2
const LIFT_SECONDS := 0.2
const SLIDE_SECONDS := 0.2
const SCREEN := Vector2(480, 270)
## The writ's sheet on the screen, and the tab hanging from its bottom edge.
const WRIT_RECT := Rect2(120, 20, 240, 130)
const TAB_HEIGHT := 15
const TAB_TOP := 129
const TAB_PADDING := 8
## The button sits this much above the tab it is drawn as, so its word is on the tab's middle rows.
const TAB_TEXT_LIFT := 2
## The card's title is drawn at twice the capitals' size (16×22 letters); the writ's text is 1:1.
const TITLE_SCALE := 2
## The seal on the writ's top edge: "#" wax (Ember 1), "o" its rim (Ember 0), "c" its pressed
## heart (Ember 2).
const SEAL: Array[String] = [".ooo.", "o###o", "o#c#o", "o###o", ".ooo."]
const THEME_TYPE := &"DeskPalette"
## Palette fallbacks (docs/art/palette.gpl) outside the desk theme.
const NIGHT_0 := Color8(11, 23, 34)
const PARCHMENT_2 := Color8(246, 238, 210)
const WOOD_3 := Color8(93, 71, 63)
const EMBER_0 := Color8(107, 47, 30)
const EMBER_1 := Color8(166, 98, 59)
const EMBER_2 := Color8(224, 138, 74)

## Decorative movement off (D37): the desk sets it from the options. Turning it on mid-dawn
## settles a movement in progress (`settle_motion`).
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if reduce_motion and is_node_ready():
			settle_motion()

var _stage: Stage = Stage.HIDDEN
## Seconds in the current stage, and since the card began.
var _elapsed: float = 0.0
var _card_elapsed: float = 0.0
var _paused: bool = false
var _day: int = 0
var _lines: Array[String] = []

@onready var _writ: Control = $Writ
@onready var _lines_box: Control = $Writ/Lines
@onready var _seal: Control = $Writ/Seal
@onready var _tab: ParchmentFrame = $Writ/Tab
@onready var _begin: GuardedButton = $Writ/Begin
@onready var _curtain: ColorRect = $Curtain


## "DAY " and the day in Roman numerals: the card's title.
static func day_title(day: int) -> String:
	return "DAY " + PixelCapitals.roman(day)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_curtain.color = _theme_color(&"ink", NIGHT_0)
	_curtain.gui_input.connect(_on_curtain_input)
	_curtain.draw.connect(_draw_title)
	_seal.draw.connect(_draw_seal)
	for style: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		_begin.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	var ink: Color = _theme_color(&"ink", NIGHT_0)
	for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		_begin.add_theme_color_override(color, ink)
	_begin.pressed.connect(_on_begin_pressed)
	visible = false


## Shows the dawn of `day`: the dark card, then the writ listing `lines` with `begin_label` on
## its tab. Showing the same dawn again (a redraw) changes nothing.
func show_dawn(day: int, lines: Array[String], begin_label: String) -> void:
	_begin.text = begin_label
	_fit_tab()
	if _stage != Stage.HIDDEN and _stage != Stage.SLIDE and day == _day and lines == _lines:
		return
	_end_card()
	_day = day
	_lines = lines.duplicate()
	WritLines.write(
		_lines_box, _lines, _theme_color(&"ink", NIGHT_0), _theme_color(&"ink_soft", WOOD_3)
	)
	_writ.position = WRIT_RECT.position
	_writ.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	_curtain.visible = true
	_set_stage(Stage.CARD if reduce_motion else Stage.FALL)
	_card_elapsed = 0.0
	_cover(SCREEN.y if reduce_motion else 0.0)
	card_started.emit()
	horn_requested.emit()


## The gate's DAWN consumer: a press skips the card to the writ.
func finish_card() -> void:
	if is_showing_card():
		_end_card()


func is_showing_card() -> bool:
	return _stage == Stage.FALL or _stage == Stage.CARD


## The day began some other way: the card ends at once, a writ on show slides away.
func close() -> void:
	match _stage:
		Stage.HIDDEN:
			visible = false
		Stage.FALL, Stage.CARD:
			_end_card()
			_hide()
		Stage.LIFT, Stage.WRIT:
			_take_down()


## A restart: everything stops and hides at once.
func cancel() -> void:
	_end_card()
	_hide()


## A fall, lift or slide in progress jumps to its end state (reduce motion turned on mid-dawn,
## D37); the card keeps the rest of its time.
func settle_motion() -> void:
	match _stage:
		Stage.FALL:
			_cover(SCREEN.y)
			_set_stage(Stage.CARD)
		Stage.LIFT:
			_curtain.visible = false
			_set_stage(Stage.WRIT)
		Stage.SLIDE:
			_hide()


## Stops (true) or resumes (false) the card's clock and every movement (the pause, focus loss).
func set_paused(paused: bool) -> void:
	_paused = paused


## The writ's lines, joined by "\n", while the dawn shows (the harness prints the same words).
func shown_text() -> String:
	if _stage == Stage.HIDDEN or _stage == Stage.SLIDE:
		return ""
	return "\n".join(_lines)


## The writ's line labels, in order, without Odin's mark (tests).
func line_labels() -> Array[Label]:
	return WritLines.labels(_lines_box)


## Where Odin's mark sits, in the writ's text pixels (tests).
func signature_rect() -> Rect2:
	return WritLines.signature_rect(_lines_box)


func next_button() -> GuardedButton:
	return _begin


## Where the title is drawn, in screen pixels (tests and tools).
func title_rect() -> Rect2:
	var title: String = day_title(_day)
	var size_px := Vector2i(
		PixelCapitals.width(title, TITLE_SCALE), PixelCapitals.HEIGHT * TITLE_SCALE
	)
	var at := Vector2i((Vector2i(SCREEN) - size_px) / 2)
	return Rect2(at, Vector2(size_px))


func _process(delta: float) -> void:
	if _paused or _stage == Stage.HIDDEN:
		return
	_elapsed += delta
	match _stage:
		Stage.FALL, Stage.CARD:
			_card_elapsed += delta
			if _stage == Stage.FALL:
				_cover(SCREEN.y * minf(_elapsed / FALL_SECONDS, 1.0))
				if _elapsed >= FALL_SECONDS:
					_set_stage(Stage.CARD)
			if _card_elapsed >= CARD_SECONDS:
				_end_card()
		Stage.LIFT:
			_cover(SCREEN.y * maxf(1.0 - _elapsed / LIFT_SECONDS, 0.0))
			if _elapsed >= LIFT_SECONDS:
				_curtain.visible = false
				_set_stage(Stage.WRIT)
		Stage.SLIDE:
			var rise: float = WRIT_RECT.end.y + TAB_HEIGHT
			var y: float = WRIT_RECT.position.y - rise * minf(_elapsed / SLIDE_SECONDS, 1.0)
			_writ.position = Vector2(WRIT_RECT.position.x, roundf(y))
			if _elapsed >= SLIDE_SECONDS:
				_hide()


## The card ends: the writ hangs under the dark, which lifts (at once under reduce motion).
func _end_card() -> void:
	if not is_showing_card():
		return
	_writ.visible = true
	_begin.rearm()
	if reduce_motion:
		_curtain.visible = false
		_set_stage(Stage.WRIT)
	else:
		_cover(SCREEN.y)
		_set_stage(Stage.LIFT)
	card_finished.emit()


## The tab: the day begins and the writ goes; nothing on the desk waits for the slide. A writ
## already going begins nothing more.
func _on_begin_pressed() -> void:
	if _stage == Stage.HIDDEN or _stage == Stage.SLIDE:
		return
	_end_card()
	_take_down()
	advanced.emit()


func _take_down() -> void:
	if reduce_motion:
		_hide()
		return
	_curtain.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_stage(Stage.SLIDE)


func _hide() -> void:
	_stage = Stage.HIDDEN
	_writ.position = WRIT_RECT.position
	visible = false


func _set_stage(stage: Stage) -> void:
	_stage = stage
	_elapsed = 0.0
	_curtain.queue_redraw()


## The dark covers the screen from the top down to `height` px.
func _cover(height: float) -> void:
	_curtain.size = Vector2(SCREEN.x, roundf(height))
	_curtain.queue_redraw()


func _on_curtain_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and is_showing_card():
		finish_card()
		accept_event()


## The tab fits its label, centred under the sheet.
func _fit_tab() -> void:
	_begin.size = Vector2.ZERO
	var width: int = int(_begin.get_minimum_size().x) + TAB_PADDING * 2
	var left: int = int((WRIT_RECT.size.x - width) / 2.0)
	var rect := Rect2(left, TAB_TOP, width, TAB_HEIGHT)
	_tab.position = rect.position
	_tab.size = rect.size
	_begin.position = rect.position - Vector2(0, TAB_TEXT_LIFT)
	_begin.size = rect.size


## The title shows once the dark has fallen, and until it lifts.
func _draw_title() -> void:
	if _stage != Stage.CARD:
		return
	var face: Color = _theme_color(&"text_light", PARCHMENT_2)
	PixelCapitals.draw(_curtain, day_title(_day), title_rect().position, face, TITLE_SCALE)


func _draw_seal() -> void:
	var colors: Dictionary[String, Color] = {
		"#": _theme_color(&"seal_wax", EMBER_1),
		"o": _theme_color(&"pin_selected_shadow", EMBER_0),
		"c": _theme_color(&"pin_selected", EMBER_2),
	}
	for y: int in range(SEAL.size()):
		for x: int in range(SEAL[y].length()):
			var code: String = SEAL[y][x]
			if colors.has(code):
				_seal.draw_rect(Rect2(x, y, 1, 1), colors[code])


func _theme_color(color_name: StringName, fallback: Color) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return fallback
