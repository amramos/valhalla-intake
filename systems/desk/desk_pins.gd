class_name DeskPins
extends RefCounted
## The pin gesture and its outcome on the desk (D8, D12, D36, D51). A click selects an item, a
## click on another completes the pair, and core judges it: a new thread is drawn taut from its
## first end with the seam's sound and caption; a thread already made lights its pair and shows
## its caption again; a pair with no seam ticks, gutters the candle by the time it cost and drops
## a slack thread that takes no click and that the next press ends (D51). Owns the drawn thread
## lines, rebuilt on every refresh.

## A new thread is drawn taut in this long (D12).
const DRAW_IN_SECONDS := 0.15

## Reduce motion (D37): threads show whole at once and no slack thread drops.
var options: Options = Options.new()

var _commands: DeskCommands
var _board: ThreadBoard
var _highlights: DeskHighlights
var _huginn: DeskHuginn
var _strip: CaptionStrip
var _note: DeskNote
var _sounds: DeskSounds
var _hud: Hud
var _gate: PresentationGate
## True while input is held: a stamped soul waits or the stamp is raised.
var _held: Callable
## The drawn thread lines, from the last rebuild.
var _lines: Array[ThreadLine] = []
## Slack threads still falling; the next press frees them (D51).
var _strands: Array[ThreadLine] = []


func _init(
	commands: DeskCommands,
	board: ThreadBoard,
	highlights: DeskHighlights,
	huginn: DeskHuginn,
	strip: CaptionStrip,
	note: DeskNote,
	sounds: DeskSounds,
	hud: Hud,
	gate: PresentationGate,
	held: Callable
) -> void:
	_commands = commands
	_board = board
	_highlights = highlights
	_huginn = huginn
	_strip = strip
	_note = note
	_sounds = sounds
	_hud = hud
	_gate = gate
	_held = held
	_gate.add_press_hook(end_slack)


## Redraws the soul's threads; Huginn's selected knot stays selected.
func rebuild() -> void:
	var answers: Array[String] = []
	for index: int in range(_commands.threads().size()):
		answers.append(_commands.thread_answer(index))
	_lines = _board.rebuild(_commands.threads(), _commands.visible_items(), answers, _huginn.thread)
	for line: ThreadLine in _lines:
		_huginn.watch(line)


## A click on an item: the pin gesture's next step (D8), never under a pending stamp.
func click(item_id: String) -> void:
	if _held.call():
		return
	var pair: Array[String] = _highlights.click(item_id)
	if _highlights.selection.has_selection():
		_sounds.play(&"tack")
	_highlights.apply()
	if pair.size() == 2:
		pin(pair[0], pair[1])


func pin(a: String, b: String) -> void:
	var before: int = _commands.threads().size()
	var result: PinResult = _commands.pin(a, b)
	# The candle gutters by the time the pin cost (D36), even when that cost ended the day.
	if result.kind == PinResult.Kind.NO_SEAM and result.seconds_lost > 0.0:
		_hud.gutter(roundi(result.seconds_lost))
	if _commands.phase() != RunState.DESK:
		# The pin's cost ended the day: the horn's announcement stands.
		_highlights.apply()
		return
	match result.kind:
		PinResult.Kind.THREAD:
			_strip.post_caption(_caption(result.seam))
			_sounds.play(&"seam")
			_sounds.play(&"pull")
			if _commands.threads().size() > before:
				_draw_in(before)
		PinResult.Kind.ALREADY:
			_highlights.lit = [a, b] as Array[String]
			_strip.take_over_caption(_caption(result.seam))
		PinResult.Kind.NO_SEAM:
			var text: DeskText = _commands.slice_rules().text
			var line: String = text.no_seam_line
			if result.seconds_lost > 0.0:
				line = text.no_seam_timed_format % roundi(result.seconds_lost)
			_strip.take_over_caption(Caption.make(line, CaptionStrip.Priority.THREAD))
			_sounds.play(&"tick")
			_drop_slack(a, b)
	_highlights.apply()


## A pin with no seam (D36, D51): a slack thread between the pair drops off the desk. Purely
## cosmetic: it takes no click and blocks no pin, and the next rebuild frees it. Reduce motion
## draws none (D37).
func _drop_slack(a: String, b: String) -> void:
	if options.reduce_motion:
		return
	var items: Array[EvidenceItem] = _commands.visible_items()
	var line: ThreadLine = _board.make_slack(
		ThreadBoard.find_item(items, a), ThreadBoard.find_item(items, b)
	)
	if line != null:
		_gate.watch_tween(line.slacken_and_drop(ThreadLine.SLACK_SECONDS))
		_strands.append(line)


## Any press ends every slack thread still falling, at once, and nothing else (D51): the gate
## calls this before it decides the press, which goes on as it would have.
func end_slack() -> void:
	for index: int in range(_strands.size()):
		if is_instance_valid(_strands[index]) and not _strands[index].is_queued_for_deletion():
			_strands[index].queue_free()
	_strands.clear()


## Slack threads still falling (tests).
func falling_slack() -> int:
	var count: int = 0
	for index: int in range(_strands.size()):
		if is_instance_valid(_strands[index]) and not _strands[index].is_queued_for_deletion():
			count += 1
	return count


## The new thread is drawn taut from its first end (D12); the others stay as they are.
func _draw_in(thread_index: int) -> void:
	for line: ThreadLine in _lines:
		if is_instance_valid(line) and line.thread_index == thread_index:
			# Reduce motion (D37): the thread and its knot show whole at once.
			var seconds: float = 0.0 if options.reduce_motion else DRAW_IN_SECONDS
			_gate.watch_tween(line.draw_in(seconds))


## A thread's caption on the note, quoting the pair it lights while it shows (D6, D28).
func _caption(seam: Seam) -> Caption:
	return _note.thread(seam, _commands.current_encounter(), _commands.visible_items())
