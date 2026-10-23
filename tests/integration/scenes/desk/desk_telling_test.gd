extends GutTest
## The tale at the desk and the presentation gate (D4, D5, D7, D10, D12, D27, D28, D43): the
## timed day-3 fixture desk (desk_fixture.gd) at the normal text speed, driven by real clicks
## pushed through the desk's own SubViewport.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func _open(options: Options, commands: DeskCommands = Fixture.commands()) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_desk.use_options(options)
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_the_clock_waits_for_the_tale_and_runs_once_a_click_ends_it() -> void:
	_open(Fixture.normal())
	assert_true(_system.is_telling(), "the tale is being told")
	assert_true(_system.claim_panel.is_telling(), "the claim first")
	var before: float = _desk.commands().time_left()
	_system._process(5.0)
	assert_eq(_desk.commands().time_left(), before, "D5: the clock waits for the telling")
	_click(_system.claim_panel.area("C1").get_global_rect().get_center())
	assert_false(_system.is_telling(), "the click ended the tale")
	_system._process(5.0)
	assert_eq(_desk.commands().time_left(), before - 5.0, "and the clock runs from then on")


func test_one_click_finishes_claim_and_witness_and_does_nothing_else() -> void:
	_open(Fixture.normal())
	var hel: Door = _door(&"hel")
	_click(hel.get_global_rect().get_center())
	assert_false(_system.is_telling(), "D7: one click finishes both tellings")
	assert_false(_system.claim_panel.is_telling())
	assert_false(_system.witness_panel.is_telling())
	for id: String in ["C1", "C2", "C3"]:
		assert_true(_system.claim_panel.area(id).visible, "%s shows" % id)
	for id: String in ["W1", "W2", "W3"]:
		assert_true(_system.witness_panel.area(id).visible, "%s shows" % id)
	assert_false(hel.selected, "D27: the consumed click raised no stamp")
	assert_false(_system.selection.has_selection(), "and selected nothing")
	_click(_system.claim_panel.area("C1").get_global_rect().get_center())
	assert_true(_system.claim_panel.area("C1").selected, "the next click acts")


func test_the_stamp_cannot_be_raised_until_the_tale_is_told() -> void:
	_open(Fixture.normal())
	_system.stamp_flow.ask(&"hel")
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "D4: not while the tale is told")
	_system.finish_tellings()
	_system.stamp_flow.ask(&"hel")
	assert_true(_system.stamp_flow.stamp_prompt.is_asking(), "once it is told, the door asks")


func test_the_witness_is_told_after_the_claim() -> void:
	_open(Fixture.normal())
	assert_true(_system.claim_panel.is_telling())
	assert_false(_system.witness_panel.is_telling(), "the witness waits for the claim")
	assert_false(_system.witness_panel.has_item("W1"), "the witness's sheet waits blank")
	assert_eq(_system.witness_panel.heading_text(), "Orm", "under its speaker's name")
	_system.claim_panel.finish_telling()
	assert_true(_system.witness_panel.has_item("W1"), "then its lines come")
	assert_false(_system.witness_panel.area("W2").visible, "and are told one by one")
	assert_true(_system.witness_panel.is_telling(), "the claim told, the witness begins (D7)")
	assert_true(_system.is_telling(), "the tale is not over yet")
	assert_true(_system.gate.is_consuming(), "a click would still finish it")
	_system.witness_panel.finish_telling()
	assert_false(_system.is_telling())
	assert_false(_system.gate.is_consuming(), "nothing left for a click to finish")


func test_lines_are_told_at_the_normal_pace_with_a_pause_between_them() -> void:
	_open(Fixture.normal())
	var teller: Teller = _system.claim_panel.teller()
	var first: Label = PaperLine.text_label(_system.claim_panel.area("C1"))
	var length: int = first.text.length()
	teller._process(float(length) / Options.NORMAL_CPS)
	assert_eq(first.visible_characters, length, "the first line at 40 cps (D4)")
	assert_false(_system.claim_panel.area("C2").visible, "the next line waits for its pause")
	teller._process(DeskTelling.LINE_PAUSE)
	assert_true(_system.claim_panel.area("C2").visible, "then it begins")


func test_the_mentors_guided_step_waits_for_the_tale() -> void:
	_open(Fixture.normal(), SliceLoader.load_slice())
	var step: MentorStep = _desk.commands().mentor_step()
	assert_not_null(step, "Ulf is guided")
	assert_eq(_system.mentor_bubble.shown_text(), "", "D5: no guidance while the tale is told")
	_system.finish_tellings()
	assert_eq(_system.mentor_bubble.shown_text(), step.text, "the step shows once it is told")


func test_at_instant_the_tale_shows_at_once_and_no_click_is_consumed() -> void:
	_open(Fixture.instant())
	assert_false(_system.is_telling(), "D37: told at once")
	assert_false(_system.gate.is_consuming())
	_click(_system.claim_panel.area("C1").get_global_rect().get_center())
	assert_true(_system.claim_panel.area("C1").selected, "the first click already acts")


func test_a_written_caption_holds_after_its_writing_and_a_click_finishes_it() -> void:
	_open(Fixture.normal())
	_system.finish_tellings()
	var strip: CaptionStrip = _system.caption_strip
	strip.clear()
	var comment: String = "Too quick, clerk. Look at the hand before you stamp."
	strip.post_caption(Caption.make(comment, CaptionStrip.Priority.MENTOR, &"mentor", [], true))
	strip.post("queued", CaptionStrip.Priority.HUGINN)
	assert_true(strip.is_writing(), "D43: the mentor's comment is written out")
	assert_true(_system.gate.is_consuming(), "a click would finish the writing")
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), comment, "no hold runs while the quill writes")
	_click(_system.claim_panel.area("C1").get_global_rect().get_center())
	assert_false(strip.is_writing(), "the click wrote the rest at once")
	assert_false(_system.gate.is_consuming())
	assert_false(_system.claim_panel.area("C1").selected, "D27: and did nothing else")
	strip._process(strip.hold_seconds - 0.5)
	assert_eq(strip.shown_text(), comment, "the 3 s hold starts when the writing ends")
	strip._process(0.5)
	assert_eq(strip.shown_text(), "queued", "then the next message shows")


func test_the_note_lights_the_pair_its_caption_quotes_until_the_next_caption() -> void:
	_open(Fixture.instant())
	_system.claim_panel.area("C2").press()
	_system.law_panel.area("L5").press()
	var caption: Caption = _system.caption_strip.shown_caption()
	assert_eq(caption.mark, &"pin_law", "D10: the pin in the law thread's colour")
	assert_eq(caption.pair, ["C2", "L5"] as Array[String])
	assert_true(_system.claim_panel.area("C2").lit, "D28: the quoted pair lights")
	assert_true(_system.law_panel.area("L5").lit)
	_system.caption_strip.take_over("No seam between those two.")
	assert_false(_system.claim_panel.area("C2").lit, "the next caption puts it out")
	assert_false(_system.law_panel.area("L5").lit)


func test_a_grey_threads_caption_names_both_speakers_by_their_words() -> void:
	_open(Fixture.instant())
	_system.claim_panel.area("C1").press()
	_system.witness_panel.area("W1").press()
	var shown: String = _system.caption_strip.shown_text()
	assert_eq(shown, 'Asgaut\'s "Held the..." against Orm\'s "He ran at...": one of them lies.')
	assert_eq(_system.caption_strip.shown_caption().mark, &"pin_grey")


func test_only_the_new_thread_is_drawn_in() -> void:
	_open(Fixture.instant())
	_system.claim_panel.area("C1").press()
	_system.witness_panel.area("W1").press()
	assert_true(_line(0).is_drawing_in(), "D12: the new thread is drawn taut")
	_system.claim_panel.area("C2").press()
	_system.law_panel.area("L5").press()
	assert_false(_line(0).is_drawing_in(), "the old thread is redrawn whole")
	assert_true(_line(1).is_drawing_in(), "only the new one draws in")


func test_the_sheets_are_headed_by_their_speakers() -> void:
	_open(Fixture.instant())
	assert_eq(_system.claim_panel.heading_text(), "Asgaut", "D6: the soul's name")
	assert_eq(_system.witness_panel.heading_text(), "Orm", "the witness's name")
	assert_string_contains(_system.law_panel.heading_text(), "Odin's Law")
	assert_eq(_system.law_panel.style, &"scroll", "the Law is the scroll (D9)")


func test_the_jolt_drops_the_desk_band_and_reduce_motion_keeps_it_still() -> void:
	_open(Fixture.instant())
	var home: Vector2 = _system.claim_panel.position
	var chart: Vector2 = _system.body_chart.position
	_desk.jolt(2, 0.1)
	assert_eq(_system.claim_panel.position, home + Vector2(0, 2), "the band drops 2 px")
	assert_eq(_system.body_chart.position, chart + Vector2(0, 2))
	assert_eq(_door(&"hel").position.y, 9.0, "the gate band stays")
	await wait_seconds(0.2)
	assert_eq(_system.claim_panel.position, home, "and comes back")
	assert_false(_desk.is_jolting())
	_desk.options().reduce_motion = true
	_desk.jolt(2, 0.1)
	assert_eq(_system.claim_panel.position, home, "D37: reduce motion, no jolt")


func test_the_pause_stops_the_telling_and_resume_carries_it_on() -> void:
	_open(Fixture.normal())
	_desk.toggle_pause()
	assert_true(_system.claim_panel.teller().is_paused(), "the pause stops the telling")
	_desk.pause_overlay().resume_button().pressed.emit()
	assert_false(_system.claim_panel.teller().is_paused())
	assert_true(_system.is_telling(), "the tale goes on where it was")


## The review's case: each bob's tween was dropped, so the pause let a dipped soul spring back.
## The gate watches it now: the pause holds a bob mid-dip.
func test_the_pause_holds_the_speaking_soul_mid_bob() -> void:
	_open(Fixture.normal())
	var figure: DragSource = _system.soul.figure()
	var dipped: Callable = func() -> bool:
		return figure.position.y == WaitingSoul.FIGURE_AT.y + WaitingSoul.BOB_PX
	await wait_until(dipped, 2.0)
	assert_true(dipped.call(), "a voice blip dips the speaking soul")
	_desk.toggle_pause()
	await wait_seconds(WaitingSoul.BOB_SECONDS + 0.1)
	assert_true(dipped.call(), "the pause holds the bob where it was")
	_desk.pause_overlay().resume_button().pressed.emit()
	await wait_seconds(WaitingSoul.BOB_SECONDS + 0.05)
	_system.finish_tellings()
	assert_eq(figure.position.y, WaitingSoul.FIGURE_AT.y, "resumed and told, the soul stands")


func test_a_restart_during_the_tale_ends_it_unfinished() -> void:
	_open(Fixture.normal())
	_desk.toggle_pause()
	_desk.pause_overlay().restart_button().pressed.emit()
	_desk.pause_overlay().yes_button().pressed.emit()
	assert_false(_system.is_telling())
	assert_false(_system.gate.is_consuming(), "no click is owed to the old tale")
	_click(_system.phase_card.next_button().get_global_rect().get_center())
	assert_eq(_desk.commands().phase(), RunState.DAWN, "the dawn card's guard still holds")


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _line(thread_index: int) -> ThreadLine:
	for child: Node in _system.thread_layer.get_children():
		var line: ThreadLine = child as ThreadLine
		if line != null and not line.is_queued_for_deletion() and line.thread_index == thread_index:
			return line
	return null


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
