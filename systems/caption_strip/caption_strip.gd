class_name CaptionStrip
extends Control
## The clerk's note along the bottom of the desk (D10, D33): the bottom edge of a parchment page,
## a speaker mark at its left, the message in ink on up to two lines. Messages rank: a citation,
## then the newest thread caption, then Huginn's answer, then the mentor's comments. Each message
## holds at least `hold_seconds`; what arrives meanwhile waits, the most urgent first. A deliberate
## click (a thread, the mentor, the feather) takes the note over at once.
##
## A thread's caption and Huginn's answer show at once; a `written` caption (the mentor, a
## citation) is written out by a quill at `write_cps`, never longer than `MAX_WRITE_SECONDS`, and
## its hold starts when the writing ends (D43).

## A message reached the note (posted, taken over, or out of the queue).
signal text_shown(text: String)
## The same moment, with the whole caption (its mark and its quoted pair, D28).
signal caption_shown(caption: Caption)
## A written caption has been written out (by pace or by `finish_writing`).
signal writing_finished

## Lower is more urgent.
enum Priority { CITATION, THREAD, HUGINN, MENTOR }

## The text's top-left inside the note; the mark column and its rule sit left of it.
const TEXT_LEFT := 11
const TEXT_TOP := 2
const TEXT_RIGHT := 3
const LABEL_TOP := 3
## The speaker mark's top-left.
const MARK_AT := Vector2i(1, 2)
## The rule between the mark column and the text.
const RULE_X := 9
## The quill writes at least this fast: no written caption takes longer (D43).
const MAX_WRITE_SECONDS := 1.0
## The page runs on below the note, past the screen's bottom edge, so only its top is torn.
const PAGE_OVERHANG := 6

@export var hold_seconds: float = 3.0
## The quill's pace in characters a second (60 at normal text speed; INF writes at once).
@export var write_cps: float = 60.0

var _label: Label = null
var _frame: ParchmentFrame = null
var _teller: Teller = null
var _held: float = 0.0
var _writing: bool = false
## The pause holds the shown message where it is (the gate's pause_changed).
var _paused: bool = false
var _current: Caption = null
## Waiting messages, newest last.
var _pending: Array[Caption] = []


func _ready() -> void:
	_frame = ParchmentFrame.new()
	_frame.name = "Page"
	_frame.show_behind_parent = true
	_frame.torn = true
	_frame.seed = hash(String(name))
	_frame.size = size + Vector2(0, PAGE_OVERHANG)
	_frame.inner = Rect2(TEXT_LEFT, TEXT_TOP, size.x - TEXT_LEFT - TEXT_RIGHT, size.y - TEXT_TOP)
	add_child(_frame)
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.position = Vector2(TEXT_LEFT, TEXT_TOP - LABEL_TOP)
	_label.size.x = size.x - TEXT_LEFT - TEXT_RIGHT
	_label.add_theme_color_override(&"font_color", get_theme_color(&"ink", &"DeskPalette"))
	add_child(_label)
	_teller = Teller.new()
	_teller.name = "Quill"
	add_child(_teller)
	_teller.finished.connect(_on_written)
	_held = hold_seconds


func post(text: String, priority: Priority) -> void:
	post_caption(Caption.make(text, priority))


func post_caption(caption: Caption) -> void:
	if caption.text == "":
		return
	if _label.text == "" or (not _writing and _held >= hold_seconds):
		_show(caption)
		return
	_pending.append(caption)


## A deliberate click shows its text at once (D33).
func take_over(text: String) -> void:
	take_over_caption(Caption.make(text, Priority.THREAD))


func take_over_caption(caption: Caption) -> void:
	_pending.clear()
	_show(caption)


func clear() -> void:
	_pending.clear()
	_stop_writing()
	_label.text = ""
	_current = null
	_held = hold_seconds
	queue_redraw()


func shown_text() -> String:
	return _label.text


## The caption shown now; null when the note is empty.
func shown_caption() -> Caption:
	return _current


## How many lines the shown text takes.
func line_count() -> int:
	return _label.get_line_count() if _label.text != "" else 0


func is_writing() -> bool:
	return _writing


## Writes the rest of the caption at once (a consumed click, D27); its hold starts now.
func finish_writing() -> void:
	if _writing:
		_teller.finish()


## The quill's Teller, for the presentation gate (pause).
func teller() -> Teller:
	return _teller


## A paused note neither counts its hold nor shows the next message (the pause, focus loss).
func set_paused(paused: bool) -> void:
	_paused = paused


func is_paused() -> bool:
	return _paused


func _process(delta: float) -> void:
	if _writing or _paused:
		return
	_held += delta
	if _held >= hold_seconds and not _pending.is_empty():
		_show(_take_most_urgent())


func _take_most_urgent() -> Caption:
	var best: int = 0
	for index: int in range(_pending.size()):
		# Ties go to the newest message (the newest thread caption, D33).
		if _pending[index].priority <= _pending[best].priority:
			best = index
	var caption: Caption = _pending[best]
	_pending.remove_at(best)
	return caption


func _show(caption: Caption) -> void:
	_stop_writing()
	_current = caption
	_label.text = caption.text
	_held = 0.0
	if caption.written and not is_inf(write_cps) and write_cps > 0.0:
		_writing = true
		var cps: float = maxf(write_cps, caption.text.length() / MAX_WRITE_SECONDS)
		_teller.start(_label, caption.text, cps, 0.0, 0)
	queue_redraw()
	text_shown.emit(caption.text)
	caption_shown.emit(caption)


func _stop_writing() -> void:
	_teller.stop()
	_writing = false
	_label.visible_characters = -1


func _on_written() -> void:
	if not _writing:
		return
	_writing = false
	_held = 0.0
	writing_finished.emit()


func _draw() -> void:
	var rule: Color = get_theme_color(&"rule", &"DeskPalette")
	draw_rect(Rect2(RULE_X, TEXT_TOP, 1, size.y - TEXT_TOP), rule)
	if _current == null:
		return
	var colors: Dictionary[StringName, Color] = {
		&"ink": get_theme_color(&"ink", &"DeskPalette"),
		&"second": get_theme_color(&"ink_soft", &"DeskPalette"),
		&"highlight": get_theme_color(&"pin_highlight", &"DeskPalette"),
		&"pin_red": get_theme_color(&"thread_red", &"DeskPalette"),
		&"pin_grey": get_theme_color(&"thread_grey", &"DeskPalette"),
		&"pin_law": get_theme_color(&"thread_law", &"DeskPalette"),
	}
	NoteMarks.draw(_paint, _current.mark, MARK_AT, colors)


func _paint(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
