class_name DeskHighlights
extends RefCounted
## What the desk lights on the body chart and the sheets (D8, D28, D48): the half-made pin's
## selected item, the pair a caption, a click or the feather lit, a held soul's cited pair (lit
## until it is sent on, whatever the note shows) and, when nothing else is lit, the highlight of
## the mentor's guided step. DeskSystem owns it and calls `apply()` after every change.

## An item became selected (the pin is half made) or the selection ended: the cursor carries a pin
## while `has` is true (D13).
signal selection_changed(has: bool)

var selection := PinSelection.new()
## The pair lit by the note's caption, a thread already made or the feather.
var lit: Array[String] = []
## The cited pair of a held soul: lit until it is sent on, whatever the note shows (D28, D48).
var held_pair: Array[String] = []
## Whether the last `selection_changed` said an item was selected.
var _had_selection: bool = false

var _commands: DeskCommands
var _chart: BodyChart
var _panels: Array[EvidencePanel] = []
## Returns the mentor's guided step (a MentorStep, or null while the tale is told).
var _guided_step: Callable


func _init(
	commands: DeskCommands, chart: BodyChart, panels: Array[EvidencePanel], guided_step: Callable
) -> void:
	_commands = commands
	_chart = chart
	_panels = panels
	_guided_step = guided_step


## Draws the selection and the lit pair: a held soul's pair wins, then the lit pair, then the
## mentor's highlight.
func apply() -> void:
	var chosen: String = selection.selected_id
	var shown: Array[String] = lit
	if _commands.awaiting_next() and not held_pair.is_empty():
		shown = held_pair
	var step: MentorStep = _guided_step.call()
	if shown.is_empty() and step != null:
		shown = step.highlight
	_chart.set_selected(chosen)
	_chart.set_lit(shown)
	for panel: EvidencePanel in _panels:
		panel.set_selected(chosen)
		panel.set_lit(shown)
	_announce_selection()


## Lights a pair (a caption's, a held citation's, the feather's) in place of the last one.
func light(pair: Array[String]) -> void:
	lit = pair
	apply()


## Keeps a held citation's pair lit until the soul is sent on (D28, D48); `light()` shows it.
func hold(pair: Array[String]) -> void:
	held_pair = pair.duplicate()


## The caption that quoted `pair` gave way to one that quotes nothing: its pair goes dark, but a
## pair lit by something else since (a held citation, a click) stays (D28).
func drop(pair: Array[String]) -> void:
	if lit == pair:
		light([] as Array[String])


## A click on an item: the lit pair goes dark and the selection takes the click. Returns the
## completed pair, or [] while the pin is still open.
func click(item_id: String) -> Array[String]:
	lit.clear()
	return selection.click(item_id)


## Drops the half-made pin and redraws.
func cancel() -> void:
	selection.cancel()
	apply()


## A new soul: no selection, nothing lit, no held pair.
func forget() -> void:
	selection.cancel()
	lit.clear()
	held_pair.clear()
	_announce_selection()


## Says when the selection was made or ended since the last time it was said.
func _announce_selection() -> void:
	if selection.has_selection() != _had_selection:
		_had_selection = selection.has_selection()
		selection_changed.emit(_had_selection)
