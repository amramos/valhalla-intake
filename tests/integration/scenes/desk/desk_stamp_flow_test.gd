extends GutTest
## The stamp's slam and aftermath (D14, D15, D27, D33), with real clicks pushed through the desk's
## own SubViewport and real time for the slam and the walk: one slam per stamp, the slam window
## that ignores every press, the window opening at the walk with the writ swept and the next soul
## walking in, a restart killing the slam, reduce motion keeping the ink and the flare but no
## movement, the held writ's "Send it on", the stamp put down by any other click, and the mentor's
## comments around a held stamp (the citation first, carried to the next soul, never behind the
## horn, forgotten by a new run).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## Real time is a little late under a loaded test runner.
const SLACK := 0.2

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null
var _options: Options = null
var _jolts: Array[int] = []


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_options = Options.new()
	_jolts.clear()


func test_a_stamp_slams_once_inks_the_writ_and_jolts_once() -> void:
	_open(Fixture.commands())
	var flow: StampFlow = _system.stamp_flow
	assert_eq(flow.stamp_prompt.soul_name(), "Asgaut", "the writ names the soul at the desk")
	watch_signals(_desk.commands())
	_stamp(&"hel")
	assert_true(flow.is_slamming(), "the slam window opens on the press")
	assert_true(_desk.gate().is_slamming(), "and the gate holds it")
	assert_false(flow.stamp_prompt.is_inked(), "the 70 ms hold comes before the ink")
	assert_eq(flow.stamp_prompt.soul_name(), "Asgaut", "the next soul is seated; the writ waits")
	await wait_seconds(StampFlow.HOLD_SECONDS + StampFlow.IMPACT_SECONDS / 2.0)
	assert_true(flow.stamp_prompt.is_inked(), "the impact inks the writ")
	assert_eq(flow.stamp_prompt.writ().inked_glyph(), &"serpent", "with Hel's glyph")
	assert_eq(_jolts, [StampFlow.JOLT_PX] as Array[int], "the desk band jolts once, 3 px")
	await wait_seconds(StampFlow.SLAM_SECONDS + StampFlow.WALK_SECONDS + SLACK)
	assert_signal_emit_count(_desk.commands(), "stamped", 1, "one stamp")
	assert_eq(_jolts.size(), 1, "one slam per stamp")
	assert_false(flow.is_slamming())
	assert_eq(flow.stamp_prompt.soul_name(), "Second", "the swept writ gave way to the next")
	assert_false(flow.stamp_prompt.is_inked())


func test_every_press_in_the_slam_window_is_ignored() -> void:
	_open(Fixture.commands())
	watch_signals(_desk.commands())
	_stamp(&"hel")
	var hel: Door = _door(&"hel")
	watch_signals(hel)
	_click(hel)
	assert_signal_not_emitted(hel, "door_clicked", "a door press in the window does nothing")
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "no stamp is raised again")
	hel.dropped.emit(&"hel")
	_system.stamp_flow.stamp_prompt.confirmed.emit(&"hel")
	assert_signal_emit_count(_desk.commands(), "stamped", 1, "nothing stamps twice in the window")
	assert_eq(_soul(), "Second", "the next soul still waits its turn")


func test_the_window_opens_at_the_walk_and_the_next_soul_walks_in() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	var figure: DragSource = _system.soul.figure()
	assert_lt(figure.get_global_rect().end.x, 0.0, "the next soul waits off-screen in the slam")
	assert_eq(_walkers().size(), 1, "the stamped soul still stands where it stood")
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.05)
	assert_false(_desk.gate().is_slamming(), "the window is open again at the walk")
	assert_eq(_walkers().size(), 1, "the stamped soul walks to its door")
	assert_true(_system.soul.is_arriving(), "the next soul walks in during the walk")
	await wait_seconds(WaitingSoul.ARRIVE_SECONDS + SLACK)
	assert_eq(figure.position, WaitingSoul.FIGURE_AT, "the next soul stands in its place")


func test_a_stamp_after_the_last_walk_ended_walks_its_soul_too() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	assert_eq(_soul(), "Second", "Asgaut's legal stamp holds nothing")
	await wait_seconds(StampFlow.SLAM_SECONDS + StampFlow.WALK_SECONDS + SLACK)
	assert_eq(_walkers().size(), 0, "the first walk ended and its figure is gone")
	_stamp(&"valhalla")
	assert_eq(_walkers().size(), 1, "the second soul walks through its door")


## The review's case: a restart while a stamped soul is still walking to its door must take the
## walking figure with the old run, and its walk must not run on into the new one.
func test_a_restart_during_the_walk_ends_the_walk_and_its_figure() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.05)
	assert_eq(_walkers().size(), 1, "the stamped soul walks to its door")
	_restart()
	assert_eq(_desk.commands().phase(), RunState.DAWN, "the restart reached the new run's dawn")
	assert_eq(_walkers().size(), 0, "the old run's walking figure left with it")
	await wait_seconds(StampFlow.WALK_SECONDS + SLACK)
	assert_eq(_walkers().size(), 0, "past the old walk's time, nothing walks or reappears")
	assert_eq(_system.stamp_flow.walk_layer.get_child_count(), 0, "the walk layer is empty")


func test_a_restart_in_the_slam_window_kills_the_slam() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	_restart()
	var flow: StampFlow = _system.stamp_flow
	assert_false(flow.is_slamming(), "the restart ends the slam")
	assert_false(_desk.gate().is_slamming(), "and opens the gate")
	await wait_seconds(StampFlow.SLAM_SECONDS + StampFlow.WALK_SECONDS + SLACK)
	assert_eq(_jolts.size(), 0, "the killed slam never reached its impact")
	assert_false(flow.stamp_prompt.is_inked(), "the new run's writ is clean")
	assert_false(flow.stamp_prompt.is_held())
	assert_eq(_walkers().size(), 0)


func test_reduce_motion_keeps_the_ink_and_the_flare_without_movement() -> void:
	_options.reduce_motion = true
	_open(Fixture.commands())
	_stamp(&"hel")
	await wait_seconds(StampFlow.HOLD_SECONDS + StampFlow.IMPACT_SECONDS + 0.03)
	assert_true(_system.stamp_flow.stamp_prompt.is_inked(), "the ink stays (D37)")
	assert_true(_door(&"hel").is_flaring(), "the flare stays")
	assert_eq(_jolts.size(), 0, "no jolt")
	await wait_seconds(StampFlow.SLAM_SECONDS + SLACK)
	assert_eq(_walkers().size(), 0, "the walk is its end state: the soul is gone")
	assert_eq(_system.soul.figure().position, WaitingSoul.FIGURE_AT, "the next soul is in place")
	assert_false(_system.soul.is_arriving(), "with no walk-in")
	assert_eq(_system.stamp_flow.stamp_prompt.soul_name(), "Second", "the writ swapped at once")


func test_the_held_writ_says_send_it_on_and_its_click_sends_the_soul_on() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_true(_desk.commands().awaiting_next(), "the citation holds the soul")
	await wait_seconds(StampFlow.SLAM_SECONDS + SLACK)
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	assert_true(prompt.is_held(), "the inked writ stays, held (D15)")
	assert_eq(_soul(), "Asgaut", "and so does the soul")
	assert_eq(_walkers().size(), 0, "a held soul does not walk yet")
	watch_signals(prompt)
	_skip_presentations()
	_move_to(prompt.writ().get_global_rect().get_center())
	assert_signal_emitted_with_parameters(
		prompt, "hover_started", [Writ.HELD_HOVER, prompt.writ().get_global_rect()]
	)
	_click(prompt.writ())
	assert_eq(_soul(), "Second", "the click on the writ seated the next soul")
	assert_eq(_walkers().size(), 1, "the held soul walks through its door now")
	assert_false(prompt.is_held())
	await wait_seconds(StampPrompt.SWEEP_SECONDS + StampPrompt.COME_UP_SECONDS + SLACK)
	assert_eq(prompt.soul_name(), "Second", "its writ was swept for the next soul's")


func test_any_other_click_puts_the_raised_stamp_down_and_does_nothing_else() -> void:
	_open(Fixture.commands())
	_system.finish_tellings()
	_click(_door(&"hel"))
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	assert_true(prompt.is_asking())
	_click(_area("C1"))
	assert_false(prompt.is_asking(), "a click on a line puts the stamp down")
	assert_false(_area("C1").selected, "and pins nothing")
	assert_false(_door(&"hel").selected, "the door is no longer chosen")
	_click(_door(&"hel"))
	_click(_door(&"valhalla"))
	assert_eq(prompt.question(), "Valhalla?", "a click on another door moves the stamp there")
	_click_at(Vector2(440, 60), MOUSE_BUTTON_RIGHT)
	assert_false(prompt.is_asking(), "a right-click anywhere puts it down")
	assert_eq(_soul(), "Asgaut", "nothing was stamped")


func test_a_held_stamp_shows_its_citation_before_the_mentors_comment() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.hold_seconds = 0.3
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_true(stamp.citation, "the visible red seam cites the Valhalla stamp")
	assert_ne(stamp.mentor_line, "", "and the unguided soul draws her comment")
	assert_eq(strip.shown_text(), stamp.citation_text, "D33: the citation takes the strip first")
	await wait_seconds(strip.hold_seconds + 1.0 + SLACK)
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment follows once the hold is over")


func test_play_again_forgets_the_last_runs_mentor_comment() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	var old_line: String = _system.stamp_flow.mentor_line()
	assert_ne(old_line, "", "the illegal stamp drew her comment")
	await _send_on()
	await _await_window()
	# Her carried comment is written out and holds the gate (D10); finish it, as a click would.
	_system.caption_strip.finish_writing()
	_system.finish_tellings()
	_stamp(&"valhalla")
	assert_eq(_desk.commands().phase(), RunState.ENDING, "the run is over")
	await _await_window()
	# The last day's dusk cards, then the ending's Play again, reach the new run's dawn; then Begin.
	for _card: int in 10:
		if _desk.commands().phase() == RunState.DAWN:
			break
		_advance_card()
	assert_eq(_desk.commands().phase(), RunState.DAWN, "Play again reached the new run's dawn")
	_advance_card()
	assert_eq(_soul(), "Asgaut", "a new run seats its first soul")
	assert_eq(_system.stamp_flow.mentor_line(), "", "nothing she said last run is retained")
	_system.finish_tellings()
	_click(_system.mentor_portrait)
	assert_ne(_system.caption_strip.shown_text(), old_line, "a click on her replays nothing old")


func test_the_mentors_next_waits_while_the_stamp_is_raised() -> void:
	_open(SliceLoader.load_slice())
	var step: MentorStep = _desk.commands().mentor_step()
	assert_not_null(step, "Ulf is guided (D16)")
	assert_eq(step.until, MentorStep.Until.READ, "his first step is read")
	_system.finish_tellings()
	_click(_door(&"valhalla"))
	assert_true(_system.stamp_flow.stamp_prompt.is_asking(), "the stamp is raised")
	var bubble: MentorBubble = _system.mentor_bubble
	bubble.finish_reveal()
	bubble.arm_now()
	_click(bubble)
	assert_eq(_desk.commands().mentor_step(), step, "no guidance advances under a pending stamp")


func test_the_walking_soul_lets_a_click_through_to_the_door_under_it() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	var walkers: Array[DragSource] = _walkers()
	assert_eq(walkers.size(), 1)
	var walker: DragSource = walkers[0]
	assert_eq(walker.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the walker is decoration")
	var hel: Door = _door(&"hel")
	# The walk frees its figure when it ends: a walk that ends early fails here, never errors. The
	# wait holds a weak reference, since a lambda's captured node that is freed is itself an error.
	var walker_ref: WeakRef = weakref(walker)
	var over_door: Callable = func() -> bool:
		var walking: DragSource = walker_ref.get_ref() as DragSource
		if not is_instance_valid(walking):
			return false
		return walking.get_global_rect().intersection(hel.get_global_rect()).get_area() >= 16.0
	await wait_until(over_door, StampFlow.SLAM_SECONDS + StampFlow.WALK_SECONDS)
	if not is_instance_valid(walker_ref.get_ref()):
		fail_test("the walk ended before the walker reached Hel's door")
		return
	assert_false(_desk.gate().is_slamming(), "the walk is outside the slam window")
	var overlap: Rect2 = walker.get_global_rect().intersection(hel.get_global_rect())
	assert_true(overlap.has_area(), "the walker is over Hel's door")
	_system.finish_tellings()
	watch_signals(hel)
	_click_at(overlap.get_center())
	assert_signal_emitted(hel, "door_clicked", "the click under the walker reaches the door")


## The review's case: a stamp drew her comment, then the clock ran out; a click on her portrait
## must not replay the old comment over the horn's announcement.
func test_a_click_on_the_mentor_after_the_horn_keeps_the_horns_caption() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_ne(_system.stamp_flow.mentor_line(), "", "the illegal stamp drew her comment")
	await _send_on()
	_desk.commands().advance_time(Fixture.CLOCK_SECONDS)
	assert_ne(_desk.commands().phase(), RunState.DESK, "the clock ran out")
	var strip: CaptionStrip = _system.caption_strip
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "the horn's announcement shows")
	_click(_system.mentor_portrait)
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "a click on her never covers the horn")


## The review's case: her comment on a held stamp waits behind the citation's hold; "Send it on"
## clicked inside that hold carries it to the next soul instead of dropping it.
func test_her_comment_on_a_held_stamp_follows_a_send_on_clicked_inside_the_hold() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_eq(strip.shown_text(), stamp.citation_text, "the citation holds the strip")
	await _send_on()
	assert_eq(_soul(), "Second", "the next soul is seated inside the hold")
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment arrives with the next soul")


func test_her_comment_follows_the_next_soul_after_the_feather_retook_the_strip() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	await _await_window()
	_skip_presentations()
	_click(_system.stamp_flow.feather)
	assert_eq(_system.caption_strip.shown_text(), stamp.citation_text, "the feather re-shows it")
	await _send_on()
	assert_eq(_system.caption_strip.shown_text(), stamp.mentor_line, "her comment is not lost")


func test_her_comment_once_shown_is_not_repeated_on_the_next_soul() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.hold_seconds = 0.2
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	await wait_seconds(strip.hold_seconds + 1.0 + SLACK)
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment showed during the hold")
	await _send_on()
	assert_eq(strip.shown_text(), "", "the next soul starts on a clear strip")


func test_a_carried_comment_never_queues_behind_the_horn() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	# The held stamp runs the clock out; the horn waits for "Send it on" (D36, D48).
	_desk.commands().set_stamp_seconds(Fixture.CLOCK_SECONDS)
	_stamp(&"valhalla")
	assert_true(_desk.commands().awaiting_next())
	await _send_on()
	var strip: CaptionStrip = _system.caption_strip
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "the horn sounds on Send it on")
	strip._process(strip.hold_seconds + 1.0)
	strip._process(strip.hold_seconds + 1.0)
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "past the hold, the horn still stands")


func _open(commands: DeskCommands) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_desk.use_options(_options)
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.stamp_flow.jolt_callback = func(px: int, _seconds: float) -> void: _jolts.append(px)
	_advance_card()


func _advance_card() -> void:
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	_click(next)


func _restart() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	_viewport.push_input(key)
	var pause: PauseOverlay = _desk.pause_overlay()
	assert_true(pause.is_open(), "Esc opens the pause")
	for button: GuardedButton in [pause.restart_button(), pause.yes_button()]:
		button.arm_now()
		_click(button)


## Waits out the slam window, so the next press is the player's again.
func _await_window() -> void:
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.05)


## Clicks the held writ once the slam window is over.
func _send_on() -> void:
	await _await_window()
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	assert_true(prompt.is_held(), "the writ is held")
	_skip_presentations()
	_click(prompt.writ())


## A written caption (the citation) holds the gate until its quill is done; a click on the bare
## band finishes it, as a player's would, so the next click acts.
func _skip_presentations() -> void:
	for _press: int in range(4):
		if not _desk.gate().is_consuming():
			return
		_click_at(Vector2(440, 60))


func _soul() -> String:
	return _system.soul.soul_name()


func _walkers() -> Array[DragSource]:
	var found: Array[DragSource] = []
	for child: Node in _system.stamp_flow.walk_layer.get_children():
		if child is DragSource and not child.is_queued_for_deletion():
			found.append(child as DragSource)
	return found


func _pin(a: String, b: String) -> void:
	_system.finish_tellings()
	_click(_area(a))
	_click(_area(b))


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


## The tale told, a door clicked and its stamp pressed: the slam begins.
func _stamp(realm: StringName) -> void:
	_system.finish_tellings()
	_click(_door(realm))
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	_click(confirm)


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _click(target: Control) -> void:
	_click_at(target.get_global_rect().get_center())


func _move_to(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)


## A move, a press and a release at `at`, pushed through the desk's viewport.
func _click_at(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	_move_to(at)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.position = at
		event.global_position = at
		event.pressed = pressed
		_viewport.push_input(event)
