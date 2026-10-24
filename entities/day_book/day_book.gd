class_name DayBook
extends Control
## The clerk's day-book over the dimmed desk (D22, D23, D34): at dusk an open two-page spread
## written in ink, its corner dog-eared "Next", "Skip all" on a paper tag; at the end of the run
## a short tableau on the gate band, then the last spread: the outcome as a carved heading, one row
## per soul ruled across both pages, the standing under a wax seal and "Play again" on a tag.
## ScreenText composes every word; `shown_text()` is exactly what the text harness prints.
##
## The tableau and the ink are a presentation: a press finishes both and does nothing else (D27),
## through the presentation gate's WRITTEN consumer (its owner begins it on `writing_started` with
## `finish_writing` and ends it on `writing_finished`), or here when no gate takes the press first.
## The buttons hide until the ink is dry, so a press can only finish it; the whole screen is a
## mouse stop while the book shows. Its clocks are its own `_process`, stopped by `set_paused`.
## Reduce motion (D37): no dim fade and no turning leaf; the tableau's marchers stand where their
## march ends.

signal advanced
signal skipped
## The tableau or the ink began; it ends with `writing_finished`.
signal writing_started
signal writing_finished
## A dusk spread was turned to the next (the page sound).
signal page_turned
## The book appeared over the desk, and left it (the drone under the book).
signal opened
signal closed

enum Mode { CLOSED, SPREAD, TABLEAU, ENDING }

const TIDE := &"tide"
const HOLLOW := &"hollow"
const HOLDS := &"holds"
const SCREEN := Vector2i(480, 270)
const DIM_ALPHA := 0.6
const DIM_SECONDS := 0.2
const TURN_SECONDS := 0.15
const TABLEAU_SECONDS := 1.5
## The writing never takes longer than this (D43).
const MAX_WRITE_SECONDS := 1.0
## The gate band's bottom: the tableau shows above it, undimmed.
const BAND_BOTTOM := 96

## The ink's pace in characters a second (INF writes at once). A change while the ink runs (the
## options' text speed) reaches the running Teller without restarting it; INF finishes it.
@export var write_cps: float = 60.0:
	set(value):
		write_cps = value
		_apply_pace()
## The doors' sprites the tableau stands under, in screen pixels (the desk's own, 60×87).
@export var valhalla_door: Rect2 = Rect2(89, 9, 60, 87)
@export var hel_door: Rect2 = Rect2(196, 9, 60, 87)
## Reduce motion (D37); turned on while the book shows, its motion settles at once.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if value and is_node_ready():
			settle_motion()

var _mode: Mode = Mode.CLOSED
var _shown_key: String = ""
var _shown_text: String = ""
var _book: Rect2i = Rect2i()
var _writing: bool = false
var _paused: bool = false
var _dim_elapsed: float = DIM_SECONDS
var _turn_left: float = 0.0
var _tableau: StringName = &""
var _tableau_elapsed: float = 0.0
var _ending: DayBookEnding = null
## The characters the ink is writing now, for its one-second cap.
var _characters: int = 0
## Where the dog-ear's word is inked (ink top-left, screen pixels).
var _next_ink: Vector2i = Vector2i.ZERO

@onready var _dim: ColorRect = $Dim
@onready var _stage: Control = $Stage
@onready var _left: DayBookPage = $Left
@onready var _right: DayBookPage = $Right
@onready var _overlay: Control = $Overlay
@onready var _next: GuardedButton = $Next
@onready var _skip: TagButton = $Skip
@onready var _play: TagButton = $PlayAgain
@onready var _teller: Teller = $Teller


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.draw.connect(_draw_stage)
	_overlay.draw.connect(_draw_overlay)
	DayBookLayout.hide_button_face(_next)
	_next.mouse_entered.connect(_overlay.queue_redraw)
	_next.mouse_exited.connect(_overlay.queue_redraw)
	_next.pressed.connect(func() -> void: advanced.emit())
	_play.pressed.connect(func() -> void: advanced.emit())
	# The book's tags are nailed over its parchment: the darker face reads apart from the page.
	_play.dark = true
	_skip.dark = true
	_skip.pressed.connect(func() -> void: skipped.emit())
	_teller.finished.connect(_set_writing.bind(false))
	visible = false
	set_process(false)


## Opens the book on `spread` (D22), or turns to it from the spread on show (the page sound),
## and writes it in ink. Showing the same spread again (a redraw) changes nothing.
func show_spread(spread: DuskSpread, next_label: String, skip_label: String) -> void:
	var key: String = "\n".join([spread.text(), next_label, skip_label])
	if _mode == Mode.SPREAD and key == _shown_key:
		return
	var turning: bool = _mode == Mode.SPREAD
	_open(key, spread.text(), Mode.SPREAD)
	_next.text = next_label
	_skip.text = skip_label
	_book = DayBookLayout.spread(_left, _right, spread)
	if turning:
		_turn_left = 0.0 if reduce_motion else TURN_SECONDS
		page_turned.emit()
	_write()


## The run's ending (D23, D47): the tableau (TIDE, HOLLOW or HOLDS) on the gate band for
## TABLEAU_SECONDS, then the last spread. `outcome_lines` follow the carved heading; the ledger's
## line (or "") and the standing sit on the right page over the rows. Showing it again changes
## nothing.
func show_ending(
	tableau: StringName,
	rows: Array[EndingRow],
	heading: String,
	outcome_lines: Array[String],
	ledger_line: String,
	standing: String,
	play_again_label: String,
	headers: Array[String] = []
) -> void:
	var ending := DayBookEnding.make(rows, heading, outcome_lines, ledger_line, standing)
	ending.headers = headers.duplicate()
	var key: String = "\n".join([tableau, ending.text(), play_again_label])
	if (_mode == Mode.TABLEAU or _mode == Mode.ENDING) and key == _shown_key:
		return
	_open(key, ending.text(), Mode.TABLEAU)
	_ending = ending
	_play.text = play_again_label
	_skip.text = ""
	_tableau = tableau
	_tableau_elapsed = 0.0
	_left.clear()
	_right.clear()
	_set_pages_visible(false)
	_set_writing(true)


## The gate's WRITTEN consumer: a press ends the tableau and the ink at once, landing on the
## finished page.
func finish_writing() -> void:
	if _mode == Mode.TABLEAU:
		_end_tableau()
	if _writing:
		_teller.finish()


## The tableau shows or the ink is running: a press would only finish it.
func is_writing() -> bool:
	return _writing


## The phase moved on: the book closes, its writing unfinished.
func close() -> void:
	if _mode == Mode.CLOSED:
		return
	_teller.stop()
	_mode = Mode.CLOSED
	_shown_key = ""
	_shown_text = ""
	_tableau = &""
	_left.clear()
	_right.clear()
	visible = false
	set_process(false)
	_set_writing(false)
	closed.emit()


## A restart: everything stops and hides at once.
func cancel() -> void:
	close()


## Stops (true) or resumes (false) the book's clocks and its ink (the pause, focus loss).
func set_paused(paused: bool) -> void:
	_paused = paused
	_teller.set_paused(paused)


## The words on show, exactly as the harness prints them; "" when closed.
func shown_text() -> String:
	return _shown_text


## The tableau on show, or &"" (tests).
func tableau() -> StringName:
	return _tableau if _mode == Mode.TABLEAU else &""


func is_open() -> bool:
	return _mode != Mode.CLOSED


## Every motion in progress jumps to its end state: the turning leaf is gone, the dim is full,
## the tableau's marchers stand where their march ends (the tableau itself keeps its time).
func settle_motion() -> void:
	_turn_left = 0.0
	if _dim_elapsed < DIM_SECONDS:
		_dim_elapsed = DIM_SECONDS
		_fit_dim()
	_stage.queue_redraw()
	_overlay.queue_redraw()


## A leaf is turning over the spread (never under reduce motion).
func is_turning() -> bool:
	return _turn_left > 0.0


## The dim's colour now: Night 0 at DIM_ALPHA once faded in (tests).
func dim_color() -> Color:
	return _dim.color


## The dog-ear at dusk, the "Play again" tag at the ending.
func next_button() -> GuardedButton:
	return _play if _mode == Mode.TABLEAU or _mode == Mode.ENDING else _next


func skip_button() -> GuardedButton:
	return _skip


func teller() -> Teller:
	return _teller


func left_page() -> DayBookPage:
	return _left


func right_page() -> DayBookPage:
	return _right


## The open book on the screen (its pages and spine).
func book_rect() -> Rect2i:
	return _book


## Every line of the open spread sits inside its page's text area (the fit tests).
func fits() -> bool:
	return DayBookLayout.fits(_left, _right)


func _process(delta: float) -> void:
	if _paused:
		return
	if _dim_elapsed < DIM_SECONDS:
		_dim_elapsed = minf(DIM_SECONDS, _dim_elapsed + delta)
		_fit_dim()
	if _turn_left > 0.0:
		_turn_left = maxf(0.0, _turn_left - delta)
		_overlay.queue_redraw()
	if _mode == Mode.TABLEAU:
		_tableau_elapsed += delta
		_stage.queue_redraw()
		if _tableau_elapsed >= TABLEAU_SECONDS:
			_end_tableau()
	if _writing:
		# A line's marks show once its ink begins.
		_left.queue_redraw()
		_right.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null:
		return
	accept_event()
	if button.pressed and button.button_index == MOUSE_BUTTON_LEFT and _writing:
		finish_writing()


func _open(key: String, text: String, mode: Mode) -> void:
	var opening: bool = _mode == Mode.CLOSED
	_shown_key = key
	_shown_text = text
	_mode = mode
	_teller.stop()
	visible = true
	set_process(true)
	if opening:
		_dim_elapsed = DIM_SECONDS if reduce_motion else 0.0
		_turn_left = 0.0
		opened.emit()
	_fit_dim()


func _end_tableau() -> void:
	_mode = Mode.ENDING
	_tableau_elapsed = TABLEAU_SECONDS
	_book = DayBookLayout.ending(_left, _right, _ending)
	_write()


## Writes the open spread's lines in order, at `write_cps` but never longer than a second.
func _write() -> void:
	_set_pages_visible(true)
	_fit_dim()
	# A new page re-arms its buttons even when they never hid (instant ink): a double-click's
	# second press never turns the next page too.
	_next.rearm()
	_skip.rearm()
	_play.rearm()
	var labels: Array[Label] = _ending.order if _mode == Mode.ENDING else _left.labels()
	if _mode != Mode.ENDING:
		labels.append_array(_right.labels())
	_characters = 0
	for label: Label in labels:
		_characters += label.text.length()
	var cps: float = write_cps
	var at_once: bool = is_inf(cps) or cps <= 0.0 or _characters == 0
	if not at_once:
		cps = _pace()
		_set_writing(true)
	_teller.start_labels(labels, cps, 0.0, 0)
	if not _teller.is_telling():
		# At once (instant speed or nothing to write): finished now, not on the next frame.
		_teller.finish()


## The ink's pace: `write_cps`, faster for a long page so it never takes more than a second.
func _pace() -> float:
	return maxf(write_cps, _characters / MAX_WRITE_SECONDS)


## Hands a new `write_cps` to the ink already running, keeping what is written; INF (instant)
## finishes it at once.
func _apply_pace() -> void:
	if _teller == null or not _teller.is_telling():
		return
	if is_inf(write_cps) or write_cps <= 0.0:
		_teller.finish()
	elif _teller.has_method(&"set_cps"):
		_teller.call(&"set_cps", _pace())


func _set_writing(on: bool) -> void:
	var was: bool = _writing
	_writing = on
	var shows_buttons: bool = not on and _mode != Mode.CLOSED
	var at_ending: bool = _mode == Mode.ENDING or _mode == Mode.TABLEAU
	_next.visible = shows_buttons and not at_ending
	_skip.visible = shows_buttons and not at_ending and _skip.text != ""
	_play.visible = shows_buttons and at_ending
	if _next.visible:
		_next_ink = DayBookLayout.place_dusk_buttons(_next, _skip, _book)
	if _play.visible:
		DayBookLayout.place_play_again(_play, _book, _ending.play_again_y)
	_left.queue_redraw()
	_right.queue_redraw()
	_overlay.queue_redraw()
	if on and not was:
		writing_started.emit()
	elif was and not on:
		writing_finished.emit()


func _set_pages_visible(on: bool) -> void:
	_left.visible = on
	_right.visible = on
	_stage.queue_redraw()
	_overlay.queue_redraw()


## The desk dims under the book, fading in over DIM_SECONDS unless reduce motion. Under the
## tableau the desk below the gate band is covered whole in Night 0 (its emptied sheets never
## show) and the band stays clear.
func _fit_dim() -> void:
	var tableau: bool = _mode == Mode.TABLEAU
	var top: int = BAND_BOTTOM if tableau else 0
	_dim.position = Vector2(0, top)
	_dim.size = Vector2(SCREEN.x, SCREEN.y - top)
	var color: Color = _color(&"ink")
	color.a = 1.0 if tableau else DIM_ALPHA * (_dim_elapsed / DIM_SECONDS)
	_dim.color = color


func _draw_stage() -> void:
	var paint: Callable = _stage.draw_rect.bind(true, -1.0, false)
	var colors: Dictionary = DayBookArt.theme_colors(self)
	DayBookArt.candle(paint, colors)
	if _mode == Mode.TABLEAU:
		var progress: float = 1.0 if reduce_motion else _tableau_elapsed / TABLEAU_SECONDS
		var marchers: int = _ending.count_mark(EndingRow.FROST)
		var doors: Array[Rect2] = [valhalla_door, hel_door]
		DayBookArt.tableau(paint, _tableau, progress, marchers, doors, colors)
	elif _mode != Mode.CLOSED:
		DayBookArt.binding(paint, _book, colors)


func _draw_overlay() -> void:
	if _mode == Mode.CLOSED or _mode == Mode.TABLEAU:
		return
	var paint: Callable = _overlay.draw_rect.bind(true, -1.0, false)
	var colors: Dictionary = DayBookArt.theme_colors(self)
	if _turn_left > 0.0:
		DayBookArt.turning_leaf(paint, _book, _turn_left / TURN_SECONDS, colors)
	if _mode == Mode.ENDING:
		return
	DayBookArt.dog_ear(paint, _book, _next.visible and _next.is_hovered(), colors)
	# The dog-ear's word is inked once the ink is dry, as the button shows.
	if _next.visible:
		DayBookArt.words(_overlay, _next.text, _next_ink, colors[&"ink"])


func _color(color_name: StringName) -> Color:
	return get_theme_color(color_name, DayBookArt.THEME_TYPE)
