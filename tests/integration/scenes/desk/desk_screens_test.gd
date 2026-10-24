extends GutTest
## The screens between souls wired into the real desk (D21, D22, D25, D27): the dark dawn card
## sounds the horn and holds the gate until a click ends it, and only it; the day-book's ink holds
## the gate the same way; the drone plays while the book is open and stops when it closes, a turned
## spread sounds the page, an unmute while the book is open starts the drone (after the pause, if
## paused), the note stays under the book and clears as the next dawn's card falls, and a restart
## closes everything with no click owed. Sounds are followed through DeskSounds' own signals, never
## `AudioStreamPlayer.playing` (the real audio clock).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## A point on the screen's middle, under the dark card or the open book.
const CENTRE := Vector2(240, 135)

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null
var _sounds: Array[String] = []


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.quit_closes_game = false
	_desk.use_commands(SliceLoader.load_slice())
	_desk.use_options(Fixture.normal())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_sounds.clear()
	var sounds: DeskSounds = _system._sounds
	sounds.played.connect(func(sound: StringName, _pitch: float) -> void: _sounds.append(sound))
	sounds.stopped.connect(func(sound: StringName) -> void: _sounds.append("stop " + sound))


func test_the_dawn_card_holds_the_gate_and_a_click_only_ends_it() -> void:
	var writ: DawnWrit = _system.dawn_writ
	assert_true(writ.is_showing_card(), "the desk opens on the dark card")
	assert_true(_system.gate.is_consuming(), "the card holds the gate")
	watch_signals(_system.gate)
	_click(CENTRE)
	assert_signal_emitted_with_parameters(_system.gate, "consumed", [PresentationGate.DAWN])
	assert_eq(
		[writ.is_showing_card(), _desk.commands().phase(), _system.gate.is_consuming()],
		[false, RunState.DAWN, false],
		"the click ended the card and did nothing else"
	)
	writ.next_button().pressed.emit()
	assert_eq(_desk.commands().phase(), RunState.DESK, "the tab begins the day")


func test_a_new_dawn_sounds_the_horn() -> void:
	_play_to_dusk(1)
	_sounds.clear()
	_system.day_book.next_button().pressed.emit()
	assert_eq(_desk.commands().day_number(), 2)
	assert_true(_system.dawn_writ.is_showing_card(), "day 2 dawns on the dark card")
	assert_true(_sounds.has("horn"), "the horn sounds with the card")


func test_the_drone_plays_while_the_book_is_open_and_a_turn_sounds_the_page() -> void:
	_play_to_dusk(1)
	_system.day_book.skip_button().pressed.emit()
	assert_true(_sounds.has("stop drone"), "day 1's book closed with its drone")
	_sounds.clear()
	_play_to_dusk(2)
	var book: DayBook = _system.day_book
	assert_true(book.is_open(), "day 2's dusk opens the book")
	assert_eq(_sounds.count("drone"), 1, "the drone starts with the book")
	book.finish_writing()
	book.next_button().pressed.emit()
	assert_eq(
		[_sounds.count("page_turn"), _sounds.count("drone"), _sounds.has("stop drone")],
		[1, 1, false],
		"a turned spread sounds the page; the drone plays on"
	)
	book.finish_writing()
	book.next_button().pressed.emit()
	assert_false(book.is_open(), "the last spread's Next closes the book")
	assert_true(_sounds.has("stop drone"), "the drone stops with it")
	var drone: AudioStreamWAV = _system._sounds.player(&"drone").stream as AudioStreamWAV
	assert_eq(drone.loop_mode, AudioStreamWAV.LOOP_FORWARD, "the drone loops by its file's loop")


func test_the_note_stays_under_the_book_and_clears_as_the_next_dawn_falls() -> void:
	_play_to_dusk(1)
	_system.caption_strip.take_over("The Law is kept.")
	assert_true(_system.day_book.is_open())
	_system.day_book.skip_button().pressed.emit()
	assert_true(_system.dawn_writ.is_showing_card(), "day 2 dawns")
	assert_eq(_system.caption_strip.shown_text(), "", "no comment of the day under the writ")


func test_an_unmute_under_the_open_book_starts_the_drone_after_the_pause() -> void:
	var muted: Options = Fixture.normal()
	muted.muted = true
	_desk.use_options(muted)
	_play_to_dusk(1)
	assert_true(_system.day_book.is_open())
	assert_false(_sounds.has("drone"), "muted, the drone does not start")
	_desk.toggle_pause()
	var unmuted: Options = Fixture.normal()
	_desk.use_options(unmuted)
	assert_false(_sounds.has("drone"), "under the pause it waits")
	_desk.pause_overlay().resume_button().pressed.emit()
	assert_eq(_sounds.count("drone"), 1, "the resume starts it under the open book")
	var level: float = _system._sounds.player(&"drone").volume_db
	assert_eq(level, DeskSounds.level_db(unmuted), "at the player's volume")


func test_the_books_ink_holds_the_gate_and_a_click_finishes_it() -> void:
	_play_to_dusk(1)
	var book: DayBook = _system.day_book
	var shown: String = book.shown_text()
	assert_true(book.is_writing() and _system.gate.is_consuming(), "the ink holds the gate")
	watch_signals(_system.gate)
	_click(CENTRE)
	assert_signal_emitted_with_parameters(_system.gate, "consumed", [PresentationGate.WRITTEN])
	assert_eq(
		[book.is_writing(), book.shown_text(), _desk.commands().phase()],
		[false, shown, RunState.DUSK],
		"the click finished the ink and turned nothing"
	)
	assert_false(_system.gate.is_consuming())


func test_a_restart_from_the_book_closes_it_with_no_click_owed() -> void:
	_play_to_dusk(1)
	assert_true(_system.day_book.is_writing())
	_system.restart()
	assert_false(_system.day_book.is_open(), "the book closed")
	assert_true(_sounds.has("stop drone"), "and its drone stopped")
	assert_eq(_desk.commands().phase(), RunState.DAWN)
	assert_true(_system.dawn_writ.is_showing_card(), "the new run dawns on the dark card")
	watch_signals(_system.gate)
	_click(CENTRE)
	assert_signal_emitted_with_parameters(_system.gate, "consumed", [PresentationGate.DAWN])
	assert_false(_system.gate.is_consuming(), "nothing of the old book is owed a click")


## A new dawn rewrites the writ's lines: the old ones are freed at once, never left orphaned until
## the frame ends (a restart's dawn did that, and the suite reported it).
func test_a_new_dawn_frees_the_old_writs_lines_at_once() -> void:
	var writ: DawnWrit = _system.dawn_writ
	var before: float = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var lines: Array[String] = ["Day 9.", "A short line."]
	writ.show_dawn(9, lines, "Begin")
	var after: float = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	assert_eq([writ.line_labels().size(), after], [2, before], "two lines, no orphan left")


func test_the_wind_blows_between_days_and_never_at_the_desk() -> void:
	var wind: AudioStreamPlayer = _system._sounds.player(&"wind")
	assert_not_null(wind, "the desk has the wind")
	assert_true(wind.playing, "the first dawn card brings the wind")
	_system.dawn_writ.next_button().pressed.emit()
	var at_the_desk: Array = [_winds(), wind.playing]
	_sounds.clear()
	_play_to_dusk(1)
	var at_dusk: Array[String] = _winds()
	_sounds.clear()
	_system.day_book.skip_button().pressed.emit()
	var into_dawn: Array = [_winds(), wind.playing, _system.dawn_writ.is_showing_card()]
	_system.dawn_writ.next_button().pressed.emit()
	assert_eq(at_the_desk, [["stop wind"], false], "the tab begins a quiet day")
	assert_eq(at_dusk, ["wind"] as Array[String], "the book's opening brings it back")
	assert_eq(into_dawn, [[], true, true], "it blows on from the book into the next dawn")
	assert_eq(_winds(), ["stop wind"] as Array[String])


func test_the_pause_holds_the_wind_and_the_volume_reaches_it() -> void:
	var wind: AudioStreamPlayer = _system._sounds.player(&"wind")
	_desk.toggle_pause()
	var held: bool = wind.stream_paused
	_desk.pause_overlay().resume_button().pressed.emit()
	assert_eq([held, wind.stream_paused], [true, false])
	var muted: Options = Fixture.normal()
	muted.muted = true
	_desk.use_options(muted)
	assert_eq(wind.volume_db, DeskSounds.MUTED_DB)


## The wind's starts and stops among the sounds followed so far.
func _winds() -> Array[String]:
	var found: Array[String] = []
	for sound: String in _sounds:
		if sound.ends_with("wind"):
			found.append(sound)
	return found


## Plays every soul to its legal door until the dusk of `day` (0: the first soul is seated).
func _play_to_dusk(day: int) -> void:
	var commands: DeskCommands = _desk.commands()
	for _step: int in range(200):
		match commands.phase():
			RunState.DAWN:
				_system.dawn_writ.next_button().pressed.emit()
			RunState.DESK:
				if day == 0:
					return
				if commands.awaiting_next():
					commands.next_soul()
				else:
					commands.stamp(commands.current_encounter().legal_realm)
			RunState.DUSK:
				if commands.dusk_report().day >= day:
					return
				_system.day_book.skip_button().pressed.emit()
			RunState.ENDING:
				return


## A move, a press and a release at `at`, pushed through the desk's viewport.
func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		_viewport.push_input(event)
