class_name DeskMentor
extends RefCounted
## The mentor at the desk (D5, D33): her guided step, once the soul's tale is told (her bubble and
## the door she points at; DeskHighlights lights the step's pair), her last comment shown again on
## a click on her, and the bubble's click to advance, never under a pending stamp (D9, D48). While
## her words are being written the presentation gate holds: a click finishes the writing and
## nothing else (D18, D27, D43).

## The presentation gate her writing holds (D27); null leaves the bubble to take its own first
## click. Setting it registers the bubble's Teller, so the pause stops her writing too.
var gate: PresentationGate = null:
	set(value):
		gate = value
		if gate != null:
			gate.register_teller(_bubble.teller())

var _commands: DeskCommands
var _bubble: MentorBubble
var _doors: Array[Door] = []
var _strip: CaptionStrip
var _note: DeskNote
var _stamp_flow: StampFlow
## True while the guided step must wait: the soul's tale is told, or its evidence is not yet on
## the desk (a slam under way).
var _telling: Callable
## True while input is held: a stamped soul waits or the stamp is raised.
var _held: Callable
## The gate's token for the writing in progress; -1 for none.
var _written_token: int = -1


func _init(
	commands: DeskCommands,
	bubble: MentorBubble,
	doors: Array[Door],
	strip: CaptionStrip,
	note: DeskNote,
	stamp_flow: StampFlow,
	telling: Callable,
	held: Callable
) -> void:
	_commands = commands
	_bubble = bubble
	_doors = doors
	_strip = strip
	_note = note
	_stamp_flow = stamp_flow
	_telling = telling
	_held = held
	_bubble.reveal_started.connect(_on_reveal_started)
	_bubble.reveal_finished.connect(_end_written)


## Her pace follows the text speed, as the clerk's note does (D37, D43); reduce motion steadies
## the arrow.
func use_options(options: Options) -> void:
	_bubble.write_cps = options.cps() * DeskNote.WRITE_PACE
	_bubble.reduce_motion = options.reduce_motion


## Writes the rest of her words at once (tests and tools, after `finish_tellings`).
func finish_reveal() -> void:
	_bubble.finish_reveal()


## The mentor's guided step, once the tale is told (D5) and the soul's evidence is on the desk;
## null before.
func guided_step() -> MentorStep:
	return null if _telling.call() else _commands.mentor_step()


## Shows the guided step in her bubble and points at its door; hides both off the desk.
func show_step() -> void:
	var step: MentorStep = guided_step()
	if step == null or _commands.phase() != RunState.DESK:
		_bubble.hide_step()
	else:
		_bubble.show_step(step.text, step.until == MentorStep.Until.READ)
	for door: Door in _doors:
		door.pointed = step != null and step.door == door.realm


func clicked() -> void:
	# A deliberate click on her shows her last comment again (D33), but only at the desk: never
	# over the horn's announcement or under a card.
	if _commands.phase() != RunState.DESK:
		return
	if _stamp_flow.mentor_line() != "":
		_strip.take_over_caption(_note.mentor(_stamp_flow.mentor_line()))


## A click on the bubble finishes a READ step, but never under a pending stamp (D9, D48).
func acknowledged() -> void:
	if _held.call():
		return
	_commands.mentor_ack()


func _on_reveal_started() -> void:
	_end_written()
	if gate != null:
		_written_token = gate.begin(PresentationGate.WRITTEN, _bubble.finish_reveal)


func _end_written() -> void:
	if _written_token >= 0 and gate != null:
		gate.end(_written_token)
	_written_token = -1
