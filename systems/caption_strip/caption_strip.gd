class_name CaptionStrip
extends Control
## The caption strip along the bottom of the desk (D33). Messages rank: a citation, then the
## newest thread caption, then Huginn's answer, then the mentor's comments. Each message holds at
## least `hold_seconds`; what arrives meanwhile waits, the most urgent first. A deliberate click
## (a thread, the mentor, the feather) takes the strip over at once.

## A message reached the strip (posted, taken over, or out of the queue).
signal text_shown(text: String)

## Lower is more urgent.
enum Priority { CITATION, THREAD, HUGINN, MENTOR }

const PADDING := Vector2(3, 1)
const LABEL_TOP := 3

@export var hold_seconds: float = 3.0

var _label: Label = null
var _held: float = 0.0
## Waiting messages, newest last: [text, priority] pairs.
var _pending: Array[Array] = []


func _ready() -> void:
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.position = PADDING - Vector2(0, LABEL_TOP)
	_label.size.x = size.x - PADDING.x * 2
	_label.add_theme_color_override(&"font_color", get_theme_color(&"text_light", &"DeskPalette"))
	add_child(_label)
	_held = hold_seconds


func post(text: String, priority: Priority) -> void:
	if text == "":
		return
	if _label.text == "" or _held >= hold_seconds:
		_show(text)
		return
	_pending.append([text, priority])


## A deliberate click shows its text at once (D33).
func take_over(text: String) -> void:
	_pending.clear()
	_show(text)


func clear() -> void:
	_pending.clear()
	_label.text = ""
	_held = hold_seconds


func shown_text() -> String:
	return _label.text


## How many lines the shown text takes.
func line_count() -> int:
	return _label.get_line_count() if _label.text != "" else 0


func _process(delta: float) -> void:
	_held += delta
	if _held >= hold_seconds and not _pending.is_empty():
		_show(_take_most_urgent())


func _take_most_urgent() -> String:
	var best: int = 0
	for index: int in range(_pending.size()):
		# Ties go to the newest message (the newest thread caption, D33).
		if int(_pending[index][1]) <= int(_pending[best][1]):
			best = index
	var text: String = _pending[best][0]
	_pending.remove_at(best)
	return text


func _show(text: String) -> void:
	_label.text = text
	_held = 0.0
	text_shown.emit(text)


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, get_theme_color(&"night", &"DeskPalette"))
	draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
