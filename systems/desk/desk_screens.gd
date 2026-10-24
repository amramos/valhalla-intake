class_name DeskScreens
extends RefCounted
## The desk's screens between souls (D21, D22, D23): Odin's writ at dawn and the day-book at dusk
## and at the end of the run, drawn by PhaseFlow, which keeps the place in the sequence. This
## wires them to the presentation gate and the sounds: the dark "DAY N" card and the book's
## tableau and ink are consumed presentations (a press finishes them and nothing else, D27); the
## horn sounds with the card, a page turns with its sound, and the drone plays while the book is
## open (it loops by the loop points in its file), or from the moment it is unmuted while the book
## is open. The wind blows between days (D25): from the dawn card until the tab begins the day, and
## while the book is open, over the drone; inspection is quiet. The clerk's note stays through the
## dusk, dimmed under the book (the horn's line included, D33), and is cleared as the next dawn's
## card falls: neither the horn's line nor the last soul's comment shows under the writ. The tab,
## "Next", "Skip all" and "Play again" turn into commands.

var flow := PhaseFlow.new()
## The clerk's note, cleared as a dawn's card falls; the desk system sets it (null: left alone).
var caption_strip: CaptionStrip = null

var _commands: DeskCommands = null
var _writ: DawnWrit = null
var _book: DayBook = null
var _gate: PresentationGate = null
var _sounds: DeskSounds = null
## The gate's tokens for the dark card and the book's writing; -1 when none is open.
var _dawn_token: int = -1
var _book_token: int = -1


## `on_restart`: what "Play again" does (the desk system's full restart).
func _init(
	commands: DeskCommands,
	writ: DawnWrit,
	book: DayBook,
	gate: PresentationGate,
	sounds: DeskSounds,
	on_restart: Callable
) -> void:
	_commands = commands
	_writ = writ
	_book = book
	_gate = gate
	_sounds = sounds
	flow.on_restart = on_restart
	writ.advanced.connect(_on_advanced)
	writ.horn_requested.connect(_sounds.play.bind(&"horn", 1.0))
	writ.card_started.connect(_on_card_started)
	# The tab begins the day: inspection is quiet (D25).
	writ.advanced.connect(_stop_wind)
	writ.card_finished.connect(_on_card_finished)
	book.advanced.connect(_on_advanced)
	book.skipped.connect(_on_skipped)
	book.writing_started.connect(_on_writing_started)
	book.writing_finished.connect(_on_writing_finished)
	book.page_turned.connect(_sounds.play.bind(&"page_turn", 1.0))
	book.opened.connect(_on_book_opened)
	book.closed.connect(_sounds.stop.bind(&"drone"))
	book.closed.connect(_on_book_closed)
	gate.register_teller(book.teller())
	gate.pause_changed.connect(writ.set_paused)
	gate.pause_changed.connect(book.set_paused)
	gate.pause_changed.connect(_on_pause_changed)


## Draws the commands' phase: the writ at dawn, the book at dusk and the ending, neither while a
## soul is at the desk.
func show() -> void:
	flow.show_screens(_writ, _book, _commands)


## The writ's and the book's motion, and the book's ink at the quill's pace (D37, D43).
func use_options(options: Options) -> void:
	_writ.reduce_motion = options.reduce_motion
	_book.reduce_motion = options.reduce_motion
	_book.write_cps = options.cps() * DeskNote.WRITE_PACE
	# Unmuted while the book is open: the drone it could not start begins now.
	_start_drone()
	_start_wind()


## A restarted run (D31): the sequence is forgotten and both screens stop and hide at once.
func restart() -> void:
	flow.reset()
	_stop_wind()
	_writ.cancel()
	_book.cancel()
	_dawn_token = -1
	_book_token = -1


## A dusk spread turned without a desk change (no refresh follows), so the screens are drawn here.
func _on_advanced() -> void:
	flow.advance(_commands)
	show()


func _on_skipped() -> void:
	flow.skip(_commands)
	show()


func _on_book_opened() -> void:
	_sounds.play(&"drone")
	_start_wind()


## Starts the drone under an open book when it is not already sounding or held by the pause;
## DeskSounds plays nothing while muted. Under the pause it waits for the resume.
func _start_drone() -> void:
	var drone: AudioStreamPlayer = _sounds.player(&"drone")
	if drone == null or not _book.is_open() or _gate.is_paused():
		return
	if drone.playing or drone.stream_paused:
		return
	_sounds.play(&"drone")


func _on_pause_changed(paused: bool) -> void:
	if not paused:
		_start_drone()
		_start_wind()


## The wind blows while the dawn shows (the card and the writ) or the book is open.
func _wind_wanted() -> bool:
	return _commands.phase() == RunState.DAWN or _book.is_open()


## Starts the wind between days when it is not already sounding or held by the pause; DeskSounds
## plays nothing while muted, and an unmute or a resume starts it then.
func _start_wind() -> void:
	var wind: AudioStreamPlayer = _sounds.player(&"wind")
	if wind == null or _gate.is_paused() or not _wind_wanted():
		return
	if wind.playing or wind.stream_paused:
		return
	_sounds.play(&"wind")


func _stop_wind() -> void:
	var wind: AudioStreamPlayer = _sounds.player(&"wind")
	if wind != null and (wind.playing or wind.stream_paused):
		_sounds.stop(&"wind")


## The book closing into the next dawn keeps the wind blowing; any other close stills it.
func _on_book_closed() -> void:
	if _commands.phase() != RunState.DAWN:
		_stop_wind()


func _on_card_started() -> void:
	if caption_strip != null:
		caption_strip.clear()
	_dawn_token = _gate.begin(PresentationGate.DAWN, _writ.finish_card)
	_start_wind()


func _on_card_finished() -> void:
	_gate.end(_dawn_token)
	_dawn_token = -1


func _on_writing_started() -> void:
	_book_token = _gate.begin(PresentationGate.WRITTEN, _book.finish_writing)


func _on_writing_finished() -> void:
	_gate.end(_book_token)
	_book_token = -1
