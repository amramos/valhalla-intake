extends SceneTree
## Development only: plays the whole slice from the title through real mouse events and saves a
## 1:1 screenshot after each step. Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/desk_shots/desk_shots.gd -- <output-folder>
##
## Title (and its options) -> day 1 -> dusk -> day 2 (pause and its options, Hakon) -> Hel's offer
## -> day 3 (the ledger, returned Hakon) -> the ending (its tableau, then its last page) -> Play
## again. Each dawn opens on the dark "DAY N" card and then Odin's writ; each dusk is the day-book.
## Each step is a mouse move, click, drag or key pushed through the viewport, as a player's would
## be, and each step's outcome is checked; the run prints FAIL lines and exits 1 when one does not
## hold. Day 1 is played by hand; later souls go to their legal doors by door click and confirm.
##
## The whole slice is played at the "instant" text speed, handed in through `Desk.use_options`, so
## what is left is the time no player can skip. For the time budget (D30) the run prints one
## `FORCED <soul> <seconds>` line per soul: the presentation gate's gated seconds (written
## captions, the slam window) from the end of the previous soul's slam to the end of this soul's,
## so a soul's slam and the first moments of the next tale, which overlap, count once, for the soul
## stamped. An honest soul over `FORCED_BUDGET` fails the run. The dark dawn card is gated too (up
## to 1.5 s a day, D21): it gets its own `DAWN <day> <seconds>` line, and the count starts afresh
## after it, so FORCED stays per soul. Day 1's card is left to run out; days 2 and 3 are clicked
## through, a click that only ends the card (D27).
##
## After "Play again" a second pass plays days 1 and 2 again at the normal text speed, each tale
## let run to its end before anything is pressed (a press during it would only finish it, D27),
## and prints one `TELLING <soul> <seconds>` line per soul: the same count with the tellings in.
##
## The run plays as a player at the window would, whatever window has the OS focus: the desk stops
## every clock while the game is out of focus (D35), but this run's timers and pushed events go on,
## so a focus loss mid-run (another window or a console coming forward) would freeze a slam under
## its clicks. The run hands the focus straight back (`_notification`).

const TITLE_SCENE := "res://scenes/title/title.tscn"
## No tale takes longer than this; a longer wait is a failure, not a hang.
const MAX_TALE_SECONDS := 30.0
## Forced (unskippable) seconds an honest soul may cost at most (D30).
const FORCED_BUDGET := 2.0
## The centre of the screen: a click there during the dark dawn card lands on nothing but the card.
const SCREEN_CENTRE := Vector2(240, 135)

var _out: String = ""
var _desk: Desk = null
var _failures: int = 0
## The soul whose forced seconds the gate is counting; "" for none.
var _forced_soul: String = ""
## Whether that soul tells the truth: only an honest soul is held to the budget.
var _forced_honest: bool = false
## The pass's line label: FORCED at the instant speed, TELLING at the normal one.
var _label: String = "FORCED"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var title: Node = (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	_run.call_deferred()


## The engine has just told the scene a focus loss; tell it the focus came back, so the desk's
## clocks run on under the pushed events (the header).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and root != null:
		root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)


func _run() -> void:
	await _frames(3)
	await _shot("00_title")
	var title: TitleScreen = current_scene as TitleScreen
	await _wait(0.4)
	await _click_control(title.options_button())
	_expect(title.options_panel().is_open(), "Options opens the panel on the title")
	await _wait(0.4)
	await _shot("00b_title_options")
	await _click_control(title.options_panel().back_button())
	_expect(not title.options_panel().is_open(), "Back closes the options")
	await _wait(0.4)
	await _click_control(title.start_button())
	await _frames(4)
	_desk = current_scene as Desk
	_expect(_desk != null, "Start opens the desk")
	if _desk == null:
		_finish()
		return
	var instant := Options.new()
	instant.text_speed = Options.INSTANT
	_desk.use_options(instant)
	await _day_one()
	await _finish_day()
	_account("")
	await _dusk("16_dusk1")
	_expect(_desk.commands().day_number() == 2, "Next day opens day 2")
	await _begin("20_dawn2")
	await _escape_and_resume()
	await _finish_day("21_day2", &"hakon")
	_account("")
	await _dusk("22_dusk2")
	_expect(_desk.commands().promise_state() == RunState.PROMISE_OPEN, "Hel's offer is recorded")
	_expect(_desk.commands().day_number() == 3, "day 3 dawns")
	await _begin("26_dawn3")
	_account(_soul())
	await _await_tale()
	var tray: LedgerTray = _desk.system().ledger_tray
	await _click_control(tray)
	_expect(tray.shown_line() == _desk.commands().ledger_line(), "the tray shows the ledger")
	await _shot("27_ledger_tray")
	await _click_control(tray)
	await _finish_day("28_day3", &"hakon")
	_account("")
	await _dusk("30_dusk3")
	_expect(_desk.commands().phase() == RunState.ENDING, "day 3's dusk leads to the ending")
	await _wait(0.4)
	await _click_control(_desk.system().day_book.next_button())
	var restarted: bool = _desk.commands().day_number() == 1
	_expect(restarted and _desk.commands().phase() == RunState.DAWN, "Play again")
	await _wait(0.4)
	await _shot("35_play_again")
	await _telling_pass()
	_finish()


## Days 1 and 2 again at the normal text speed: TELLING lines, and a tale caught halfway.
func _telling_pass() -> void:
	_label = "TELLING"
	_desk.use_options(Options.new())
	await _begin()
	_account(_soul())
	await _wait(1.0)
	_expect(_desk.system().is_telling(), "at the normal speed the tale is told line by line (D4)")
	await _shot("40_ulf_telling")
	await _finish_day()
	_account("")
	await _dusk("", false)
	await _begin()
	await _finish_day()
	_account("")


func _finish() -> void:
	print("DESK SHOTS: %s" % ("PASS" if _failures == 0 else "%d FAILED" % _failures))
	quit(0 if _failures == 0 else 1)


func _day_one() -> void:
	var system: DeskSystem = _desk.system()
	var writ: DawnWrit = system.dawn_writ
	await _frames(3)
	_expect(writ.is_showing_card(), "day 1 dawns on the dark card")
	await _wait(0.5)
	await _shot("01_dawn_card")
	# Left alone, the card ends by itself and the dark lifts on Odin's writ.
	var start: int = Time.get_ticks_msec()
	while writ.is_showing_card() and Time.get_ticks_msec() - start < 3000:
		await process_frame
	_expect(not writ.is_showing_card(), "the dark card ends by itself (D21)")
	await _wait(0.4)
	await _shot("01b_dawn_writ")
	_dawn_done(1)
	# A double-click as the tab appears (rearmed here, as when the dark lifts) begins nothing: its
	# first press falls inside the arm time and its second is a double-click's (D9).
	writ.next_button().rearm()
	await _double_click_control(writ.next_button())
	_expect(_desk.commands().phase() == RunState.DAWN, "a double-click on Begin is ignored")
	await _wait(0.4)
	await _click_control(writ.next_button())
	_expect(_soul() == "Ulf", "Begin seats Ulf")
	_expect(system.body_chart.layers().size() == 5, "Ulf's chart is his own art stack")
	_account(_soul())
	await _wait(1.0)
	_expect(not system.is_telling(), "at the instant speed the tale shows at once (D37)")
	await _await_tale()
	await _shot("02_ulf")
	await _hover(system.body_chart.area("B2"))
	_expect(system.hover_label.shown_text() == "no wound, back", "an absence hovers its label")
	await _shot("03_hover_absence")
	await _click_control(system.claim_panel.area("C1"))
	_expect(system.claim_panel.area("C1").selected, "the first click selects")
	await _shot("04_selected_c1")
	await _click_control(system.law_panel.area("L1"))
	_expect(_desk.commands().threads().size() == 1, "the second click pins a thread")
	await _shot("05_law_thread")
	await _double_click_control(_door(&"valhalla"))
	var asked: String = system.stamp_flow.stamp_prompt.question()
	_expect(asked == "Valhalla?", "a door click raises the stamp")
	await _shot("06_stamp_prompt")
	await _double_click_control(system.stamp_flow.stamp_prompt.confirm_button())
	_expect(_soul() == "Ulf", "a double-click on the confirm stamps nothing")
	await _wait(0.4)
	await _click_control(system.stamp_flow.stamp_prompt.confirm_button())
	await _wait(0.7)
	_expect(_soul() == "Kolbeinn", "one deliberate click on the confirm stamps")
	_account(_soul())
	await _await_tale()
	await _shot("08_kolbeinn")
	await _click_control(system.body_chart.area("B1"))
	await _click_control(system.claim_panel.area("C1"))
	await _click_control(system.body_chart.area("B3"))
	await _click_control(system.law_panel.area("L3"))
	_expect(_desk.commands().threads().size() == 2, "two threads on Kolbeinn")
	await _shot("10_two_threads")
	await _click_control(system.claim_panel.area("C4"))
	await _click_control(system.law_panel.area("L1"))
	await _wait(3.1)
	await _shot("11_no_seam")
	await _hover(_door(&"folkvangr"))
	_expect(system.hover_label.shown_glyph() == &"boar", "the barred door hovers its glyph")
	await _shot("12_locked_door")
	await _drag(system.soul.figure(), _door(&"valhalla"), "12b_drag_preview")
	# Presses inside the slam window are ignored (D27); the held soul waits past it.
	await _wait(0.6)
	var held: bool = _desk.commands().awaiting_next()
	_expect(held, "the soul dropped on the door is stamped and held (D48)")
	var prompt: StampPrompt = system.stamp_flow.stamp_prompt
	_expect(system.feather.visible and prompt.is_held(), "the feather and the held writ (D15)")
	await _shot("13_warning_holds_soul")
	await _click_control(system.feather)
	await _wait(0.4)
	await _hover(prompt.writ())
	_expect(system.hover_label.shown_text() != "", "the held writ says what a click does")
	await _shot("13b_send_it_on")
	await _click_control(prompt.writ())
	_expect(_soul() == "Hallr", "a click on the held writ seats Hallr")
	await _wait(0.7)


## Stamps every soul left today at its legal door by door click and confirm; shoots each soul
## whose id starts with `soul`.
func _finish_day(shot_prefix: String = "", soul: StringName = &"") -> void:
	var commands: DeskCommands = _desk.commands()
	var system: DeskSystem = _desk.system()
	for _guard: int in range(12):
		if commands.phase() != RunState.DESK:
			return
		await _wait(0.4)
		if commands.awaiting_next():
			await _click_control(system.stamp_flow.stamp_prompt.writ())
			await _wait(0.7)
			continue
		_account(_soul())
		await _await_tale()
		var encounter: Encounter = commands.current_encounter()
		if shot_prefix != "" and String(encounter.id).begins_with(String(soul)):
			await _shot("%s_%s" % [shot_prefix, encounter.id])
		await _click_control(_door(encounter.legal_realm))
		await _wait(0.4)
		await _click_control(system.stamp_flow.stamp_prompt.confirm_button())
		await _wait(0.7)


## Shoots every spread of the day-book (and the ending's tableau and last page) unless `shoot` is
## off, pressing Next with real clicks once each page's ink is dry. The next dawn's count starts
## afresh as the book closes.
func _dusk(prefix: String, shoot: bool = true) -> void:
	var book: DayBook = _desk.system().day_book
	var day: int = _desk.commands().day_number()
	var play_again: String = _desk.commands().slice_rules().text.play_again
	for index: int in range(10):
		await _frames(2)
		if book.tableau() != &"":
			# The ending's tableau shows 1.5 s on the gate band, then the last page (D23).
			await _wait(0.4)
			if shoot:
				await _shot("%s_tableau" % prefix)
		await _await_ink(book)
		await _wait(0.4)
		if shoot:
			await _shot("%s_card%d" % [prefix, index + 1])
		if book.next_button().text == play_again:
			return
		await _click_control(book.next_button())
		if _desk.commands().phase() == RunState.DAWN and _desk.commands().day_number() > day:
			_desk.gate().reset_gated_seconds()
			return


## Waits for the day-book's ink (and the ending's tableau) to finish by itself.
func _await_ink(book: DayBook) -> void:
	var start: int = Time.get_ticks_msec()
	while book.is_writing() and Time.get_ticks_msec() - start < MAX_TALE_SECONDS * 1000.0:
		await process_frame
	_expect(not book.is_writing(), "the day-book's ink dries by itself")


## Begins the day: a click through the dark "DAY N" card, which only ends it, then the writ's tab.
## Shoots the card and the writ when `prefix` is given.
func _begin(prefix: String = "") -> void:
	var writ: DawnWrit = _desk.system().dawn_writ
	var day: int = _desk.commands().day_number()
	await _frames(2)
	_expect(writ.is_showing_card(), "day %d dawns on the dark card" % day)
	await _wait(0.4)
	if prefix != "":
		await _shot(prefix + "_card")
	await _hover_at(SCREEN_CENTRE)
	await _press(SCREEN_CENTRE, false)
	var only_card: bool = not writ.is_showing_card()
	_expect(only_card and _desk.commands().phase() == RunState.DAWN, "a click ends only the card")
	await _wait(0.4)
	if prefix != "":
		await _shot(prefix + "_writ")
	_dawn_done(day)
	await _click_control(writ.next_button())
	_expect(_desk.commands().phase() == RunState.DESK, "Begin opens the desk")
	# The writ slides away; a pause straight after would hold it mid-slide in the shots.
	await _wait(DawnWrit.SLIDE_SECONDS + 0.1)


## Prints the dawn's gated seconds (the dark card) on its own line in the instant pass, and starts
## the count afresh for the day's first soul.
func _dawn_done(day: int) -> void:
	var gate: PresentationGate = _desk.gate()
	if _label == "FORCED":
		print("DAWN %d %.2f" % [day, gate.gated_seconds()])
	gate.reset_gated_seconds()


func _escape_and_resume() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await _frames(3)
	_expect(_desk.pause_overlay().is_open() and _desk.commands().is_paused(), "Esc pauses")
	await _shot("21a_pause")
	await _wait(0.4)
	var pause: PauseOverlay = _desk.pause_overlay()
	await _click_control(pause.options_button())
	_expect(pause.options_panel().is_open(), "Options opens the panel over the pause")
	await _wait(0.4)
	await _shot("21b_pause_options")
	root.push_input(key)
	await _frames(3)
	var back: bool = not pause.options_panel().is_open() and pause.is_open()
	_expect(back and _desk.commands().is_paused(), "Esc closes the options first, still paused")
	await _wait(0.4)
	await _click_control(pause.resume_button())
	_expect(not _desk.commands().is_paused(), "Resume carries on")


## A real drag: press on `from`, move past the drag threshold and over `to`, release there.
func _drag(from: Control, to: Control, shot_name: String) -> void:
	var start: Vector2 = from.get_global_rect().get_center()
	var end: Vector2 = to.get_global_rect().get_center()
	await _hover(from)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	root.push_input(press)
	await _frames(1)
	for step: int in range(1, 9):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = start.lerp(end, step / 8.0)
		motion.global_position = motion.position
		motion.relative = (end - start) / 8.0
		root.push_input(motion)
		await _frames(1)
	await _frames(2)
	var raised: bool = _desk.system().stamp_flow.stamp_prompt.is_asking()
	_expect(raised, "dragging over an open door raises the stamp")
	await _shot(shot_name)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = end
	release.global_position = end
	root.push_input(release)
	await _frames(3)


## Waits for the soul's tale to end by itself, at the player's text speed.
func _await_tale() -> void:
	var system: DeskSystem = _desk.system()
	var start: int = Time.get_ticks_msec()
	while system.is_telling() and Time.get_ticks_msec() - start < MAX_TALE_SECONDS * 1000.0:
		await process_frame
	_expect(not system.is_telling(), "the tale ends by itself within %d s" % MAX_TALE_SECONDS)


## Prints the gated seconds of the soul counted so far (if it is not `soul`) and starts counting
## for `soul` ("" ends the count: the day is over). An honest soul's FORCED over the budget fails.
func _account(soul: String) -> void:
	if soul == _forced_soul:
		return
	var gate: PresentationGate = _desk.gate()
	if _forced_soul != "":
		var seconds: float = gate.gated_seconds()
		print("%s %s %.2f" % [_label, _forced_soul, seconds])
		if _label == "FORCED" and _forced_honest:
			var what: String = "honest %s forced %.2f s, over %.1f s (D30)"
			_expect(seconds <= FORCED_BUDGET, what % [_forced_soul, seconds, FORCED_BUDGET])
	gate.reset_gated_seconds()
	_forced_soul = soul
	var encounter: Encounter = _desk.commands().current_encounter()
	_forced_honest = soul != "" and encounter != null and not encounter.liar


func _expect(condition: bool, what: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: " + what)


func _soul() -> String:
	return _desk.system().soul.soul_name()


func _door(realm: StringName) -> Door:
	for door: Door in _desk.system().doors:
		if door.realm == realm:
			return door
	return null


func _hover(target: Control) -> void:
	await _hover_at(target.get_global_rect().get_center())


func _hover_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = motion.position
	root.push_input(motion)
	await _frames(2)


func _click_control(target: Control) -> void:
	await _hover(target)
	await _press(target.get_global_rect().get_center(), false)


func _double_click_control(target: Control) -> void:
	await _hover(target)
	await _press(target.get_global_rect().get_center(), false)
	await _press(target.get_global_rect().get_center(), true)


func _press(at: Vector2, double: bool) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		event.double_click = double and pressed
		root.push_input(event)
		await _frames(1)
	await _frames(2)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = _out.path_join(name + ".png")
	image.save_png(path)
	print("saved %s (%dx%d)" % [path, image.get_width(), image.get_height()])


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
