extends SceneTree
## Development only: plays the whole slice from the title through real mouse events and saves a
## 1:1 screenshot after each step. Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/desk_shots/desk_shots.gd -- <output-folder>
##
## Title -> day 1 -> dusk -> day 2 (pause, Hakon) -> Hel's offer -> day 3 (the ledger, returned
## Hakon) -> the ending -> Play again. Each step is a mouse move, click, drag or key pushed through
## the viewport, as a player's would be, and each step's outcome is checked; the run prints FAIL
## lines and exits 1 when one does not hold. Day 1 is played by hand; later souls go to their
## legal doors by door click and confirm.
##
## Every soul's tale is let run to its end at the player's text speed before anything is pressed
## (a press during it would only finish it, D27). For the time budget (D42) the run prints one
## `FORCED <soul> <seconds>` line per soul: the presentation gate's gated seconds (tellings,
## written captions, the slam window) from the end of the previous soul's slam to the end of this
## soul's, so a soul's slam and the first moments of the next tale, which overlap, count once, for
## the soul stamped.

const TITLE_SCENE := "res://scenes/title/title.tscn"
## No tale takes longer than this; a longer wait is a failure, not a hang.
const MAX_TALE_SECONDS := 30.0

var _out: String = ""
var _desk: Desk = null
var _failures: int = 0
## The soul whose forced seconds the gate is counting; "" for none.
var _forced_soul: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var title: Node = (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	_run.call_deferred()


func _run() -> void:
	await _frames(3)
	await _shot("00_title")
	var title: TitleScreen = current_scene as TitleScreen
	await _wait(0.4)
	await _click_control(title.start_button())
	await _frames(4)
	_desk = current_scene as Desk
	_expect(_desk != null, "Start opens the desk")
	if _desk == null:
		_finish()
		return
	await _day_one()
	await _finish_day()
	_account("")
	await _dusk("16_dusk1")
	_expect(_desk.commands().day_number() == 2, "Next day opens day 2")
	await _shot("20_dawn2")
	await _begin()
	await _escape_and_resume()
	await _finish_day("21_day2", &"hakon")
	_account("")
	await _dusk("22_dusk2")
	_expect(_desk.commands().promise_state() == RunState.PROMISE_OPEN, "Hel's offer is recorded")
	_expect(_desk.commands().day_number() == 3, "day 3 dawns")
	await _shot("26_dawn3")
	await _begin()
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
	await _click_control(_desk.system().phase_card.next_button())
	var restarted: bool = _desk.commands().day_number() == 1
	_expect(restarted and _desk.commands().phase() == RunState.DAWN, "Play again")
	await _shot("35_play_again")
	_finish()


func _finish() -> void:
	print("DESK SHOTS: %s" % ("PASS" if _failures == 0 else "%d FAILED" % _failures))
	quit(0 if _failures == 0 else 1)


func _day_one() -> void:
	var system: DeskSystem = _desk.system()
	await _frames(3)
	await _shot("01_dawn")
	await _double_click_control(system.phase_card.next_button())
	_expect(_desk.commands().phase() == RunState.DAWN, "a double-click on Begin is ignored")
	await _wait(0.4)
	await _click_control(system.phase_card.next_button())
	_expect(_soul() == "Ulf", "Begin seats Ulf")
	_expect(system.body_chart.layers().size() == 5, "Ulf's chart is his own art stack")
	_account(_soul())
	await _wait(1.0)
	_expect(system.is_telling(), "Ulf tells his tale line by line (D4)")
	await _shot("02a_ulf_telling")
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


## Shoots every dusk card (and the ending), pressing Next with real clicks.
func _dusk(prefix: String) -> void:
	var card: PhaseCard = _desk.system().phase_card
	var day: int = _desk.commands().day_number()
	var play_again: String = _desk.commands().slice_rules().text.play_again
	for index: int in range(10):
		await _wait(0.4)
		await _shot("%s_card%d" % [prefix, index + 1])
		if card.next_button().text == play_again:
			return
		await _click_control(card.next_button())
		if _desk.commands().phase() == RunState.DAWN and _desk.commands().day_number() > day:
			return


func _begin() -> void:
	await _wait(0.4)
	await _click_control(_desk.system().phase_card.next_button())
	_expect(_desk.commands().phase() == RunState.DESK, "Begin opens the desk")


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
	await _click_control(_desk.pause_overlay().resume_button())
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


## Prints the forced seconds of the soul counted so far (if it is not `soul`) and starts counting
## for `soul` ("" ends the count: the day is over).
func _account(soul: String) -> void:
	if soul == _forced_soul:
		return
	var gate: PresentationGate = _desk.gate()
	if _forced_soul != "":
		print("FORCED %s %.2f" % [_forced_soul, gate.gated_seconds()])
	gate.reset_gated_seconds()
	_forced_soul = soul


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
	var motion := InputEventMouseMotion.new()
	motion.position = target.get_global_rect().get_center()
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
