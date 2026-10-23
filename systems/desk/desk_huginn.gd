class_name DeskHuginn
extends RefCounted
## The threads' knots and Huginn at the desk (D29, D30, D33). A click on a knot or bead shows its
## thread's caption again, or Huginn's answer once given; a grey knot also selects its thread for
## him (a second click lets it go). "Ask Huginn" asks about the selected thread (HuginnAsk) and
## its hover names the price. Nothing is selected or asked under a pending stamp (D9, D48).

## A grey knot was selected or let go: the desk redraws its threads.
signal thread_selected

## The grey thread whose knot is selected for Huginn; -1 for none.
var thread: int = -1

var _commands: DeskCommands
var _note: DeskNote
var _strip: CaptionStrip
var _button: Button
var _raven: Control
var _hover: HoverLabel
## True while input is held: a stamped soul waits or the stamp is raised.
var _held: Callable


func _init(
	commands: DeskCommands,
	note: DeskNote,
	strip: CaptionStrip,
	button: Button,
	raven: Control,
	hover: HoverLabel,
	held: Callable
) -> void:
	_commands = commands
	_note = note
	_strip = strip
	_button = button
	_raven = raven
	_hover = hover
	_held = held


## Wires a rebuilt thread's knot: its click and its hover.
func watch(line: ThreadLine) -> void:
	line.knot_clicked.connect(knot_clicked)
	line.knot_hover_started.connect(_hover.show_for)
	line.knot_hover_ended.connect(_hover.hide_label)


## A click on a knot or bead shows its thread's caption again (D33); a grey knot also selects the
## thread for Huginn, and shows his answer once given.
func knot_clicked(thread_index: int) -> void:
	if _held.call():
		return
	var threads: Array[Seam] = _commands.threads()
	if thread_index < 0 or thread_index >= threads.size():
		return
	var seam: Seam = threads[thread_index]
	var answer: String = _commands.thread_answer(thread_index)
	if answer != "":
		_strip.take_over_caption(_note.raven(answer, seam))
	else:
		_strip.take_over_caption(
			_note.thread(seam, _commands.current_encounter(), _commands.visible_items())
		)
	if seam.kind == Seam.Kind.GREY:
		thread = -1 if thread == thread_index else thread_index
		thread_selected.emit()


## "Ask Huginn": his answer on the selected thread goes to the note.
func ask() -> void:
	if _held.call() or thread < 0:
		return
	var answer: String = HuginnAsk.ask(_commands, thread)
	# An answer whose cost ended the day is not queued over the horn's announcement.
	if answer != "" and _commands.phase() == RunState.DESK:
		_strip.post_caption(_note.raven(answer, _commands.threads()[thread]))


## The button's hover: what asking needs, or costs.
func hovered() -> void:
	_hover.show_for(HuginnAsk.hover_text(_commands, thread), _button.get_global_rect())


## Shows the raven and his button on the days he is at the desk; the button waits for a thread.
func show(huginn_on: bool) -> void:
	_button.visible = huginn_on and _commands.phase() == RunState.DESK
	_button.disabled = thread < 0
	_raven.visible = huginn_on


## A new soul: no thread is selected.
func forget() -> void:
	thread = -1
