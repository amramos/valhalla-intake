extends GutTest
## The desk scene with the WP1 slice data (Ulf, then Kolbeinn), driven through its own controls:
## the pin gesture and its thread (D8), the separate stamp confirm (D9), hit areas (D5) and threads
## that never cross text (D21).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(SliceLoader.load_slice())
	# The tale shows at once, so lines can be pressed right after the dawn card (D37).
	_desk.use_options(Fixture.instant())
	add_child_autofree(_desk)
	_system = _desk.system()


func test_the_desk_opens_on_the_dawn_card_and_begins_the_day() -> void:
	assert_eq(_desk.commands().phase(), RunState.DAWN)
	assert_true(_system.phase_card.visible, "the dawn card shows")
	assert_string_contains(_system.phase_card.shown_text(), "Day 1.")
	_begin()
	assert_eq(_desk.commands().phase(), RunState.DESK)
	assert_false(_system.phase_card.visible)
	assert_eq(_system.soul.soul_name(), "Ulf")
	assert_eq(_system.hud.shown_time(), "untimed", "day 1 is untimed (D10)")


func test_one_pin_through_the_desk_draws_a_thread_and_its_caption() -> void:
	_begin()
	_system.claim_panel.area("C1").press()
	assert_true(_system.claim_panel.area("C1").selected, "the first click highlights (D8)")
	_system.law_panel.area("L1").press()
	assert_eq(_desk.commands().threads().size(), 1, "the pin reached DeskCommands")
	assert_false(_system.claim_panel.area("C1").selected, "the pin clears the selection")
	assert_eq(_threads().size(), 1, "one thread line is drawn")
	assert_eq(_threads()[0].kind, Seam.Kind.LAW)
	assert_eq(
		_system.caption_strip.shown_text(),
		'"Speared, in..." against decree I: the saga is true. Decree I sends him to Valhalla.',
		"D6: the pair by its words, never its ids"
	)


func test_clicking_the_selected_item_again_or_right_clicking_cancels() -> void:
	_begin()
	var c1: PinSelectable = _system.claim_panel.area("C1")
	c1.press()
	c1.press()
	assert_false(c1.selected, "a second click on the same item cancels")
	c1.press()
	c1._gui_input(_mouse(MOUSE_BUTTON_RIGHT, false))
	assert_false(c1.selected, "a right-click cancels")
	assert_eq(_desk.commands().threads().size(), 0, "no pin was made")


func test_a_no_seam_pin_says_so_and_draws_no_thread_of_the_souls() -> void:
	_begin()
	_system.claim_panel.area("C4").press()
	_system.law_panel.area("L3").press()
	assert_eq(_desk.commands().threads().size(), 0)
	assert_eq(_threads().size(), 1, "one line on the desk")
	assert_true(_threads()[0].is_slack(), "the slack thread, dropping off the desk (D36)")
	assert_eq(_system.caption_strip.shown_text(), "No seam between those two.")


func test_one_stamp_goes_through_the_door_and_the_separate_confirm() -> void:
	_begin()
	_door(&"valhalla").press()
	assert_eq(_system.stamp_flow.stamp_prompt.question(), "Valhalla?")
	assert_eq(_system.soul.soul_name(), "Ulf", "a door click alone never stamps (D9)")
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	confirm.pressed.emit()
	assert_eq(_system.soul.soul_name(), "Kolbeinn", "the confirm stamped Ulf; the next soul sits")
	assert_eq(_desk.commands().quota_progress(), Vector2i(1, 1))
	assert_false(_system.stamp_flow.stamp_prompt.is_asking())
	assert_eq(
		_system.stamp_flow.stamp_prompt.soul_name(), "Ulf", "the stamped writ keeps Ulf (D14)"
	)


func test_the_confirm_ignores_presses_before_it_is_armed() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	assert_false(confirm.is_armed(), "a press right after the prompt appears does not count")
	assert_true(confirm.blocks(_mouse(MOUSE_BUTTON_LEFT, false)))


func test_a_cited_soul_stays_with_its_pair_lit_until_its_writ_is_sent_on() -> void:
	_begin()
	_stamp(&"hel")
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.2)
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	assert_true(_desk.commands().awaiting_next(), "the day-1 warning holds the soul (D48)")
	assert_eq(_system.soul.soul_name(), "Ulf", "the stamped soul stays on the desk")
	assert_true(_system.feather.visible, "the black feather is on the desk")
	assert_true(prompt.is_held(), "its inked writ is held (D15)")
	assert_true(_system.claim_panel.area("C1").lit, "the cited pair is lit")
	assert_true(_system.law_panel.area("L1").lit)
	assert_ne(_system.caption_strip.shown_text(), "", "the warning is in the strip")
	_system.claim_panel.area("C2").press()
	assert_false(_system.claim_panel.area("C2").selected, "no new pins while the soul waits")
	prompt.send_on()
	assert_eq(_system.soul.soul_name(), "Kolbeinn")
	assert_false(_system.feather.visible, "the feather leaves with the soul")
	assert_false(prompt.is_held())


func test_a_closed_door_offers_no_stamp() -> void:
	_begin()
	var folkvangr: Door = _door(&"folkvangr")
	assert_false(folkvangr.is_open, "Fólkvangr is barred on day 1")
	folkvangr.press()
	assert_false(_system.stamp_flow.stamp_prompt.is_asking())
	assert_string_contains(folkvangr.hover_text(), "Closed")


func test_cancelling_the_prompt_stamps_nothing() -> void:
	_begin()
	_door(&"hel").press()
	_system.stamp_flow.stamp_prompt.withdraw()
	assert_false(_system.stamp_flow.stamp_prompt.is_asking())
	assert_eq(_system.soul.soul_name(), "Ulf")


func test_every_body_fact_is_a_hit_area_of_at_least_8_by_8_with_its_label() -> void:
	_begin()
	await _stamp_and_seat(&"valhalla")
	for item: EvidenceItem in _desk.commands().visible_items():
		if item.group != EvidenceItem.Group.BODY:
			continue
		var hit: PinSelectable = _system.body_chart.area(item.id)
		assert_not_null(hit, "%s (%s) has a hit area" % [item.id, item.text])
		assert_true(hit.size.x >= 8 and hit.size.y >= 8, "%s is at least 8x8" % item.id)
		assert_eq(hit.hover_text, item.text, "%s hovers its plain label" % item.id)


func test_threads_never_cross_a_panel_of_text() -> void:
	_begin()
	await _stamp_and_seat(&"valhalla")
	_pin("B1", "C1")
	_pin("B3", "L3")
	assert_eq(_threads().size(), 2)
	var panels: Array[Rect2] = []
	for panel: EvidencePanel in [_system.claim_panel, _system.law_panel]:
		panels.append(panel.get_global_rect())
	for line: ThreadLine in _threads():
		for pixel: Vector2i in line.pixels():
			for panel: Rect2 in panels:
				assert_false(
					panel.has_point(Vector2(pixel) + Vector2(0.5, 0.5)),
					"thread pixel %s lies inside a text panel" % pixel
				)


func test_the_caption_strip_holds_a_message_before_the_next() -> void:
	var strip: CaptionStrip = _system.caption_strip
	strip.clear()
	strip.post("first", CaptionStrip.Priority.MENTOR)
	strip.post("second", CaptionStrip.Priority.THREAD)
	strip.post("third", CaptionStrip.Priority.CITATION)
	assert_eq(strip.shown_text(), "first", "the shown message holds")
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), "third", "a citation comes first (D33)")
	strip.take_over("clicked")
	assert_eq(strip.shown_text(), "clicked", "a deliberate click takes the strip over")


func test_the_pin_gesture_completes_a_pair_on_the_second_item() -> void:
	var gesture := PinSelection.new()
	assert_eq(gesture.click("C1"), [] as Array[String])
	assert_eq(gesture.click("L1"), ["C1", "L1"] as Array[String])
	assert_false(gesture.has_selection())


func _begin() -> void:
	_system.phase_card.next_button().pressed.emit()


func _pin(a: String, b: String) -> void:
	_area(a).press()
	_area(b).press()


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _stamp(realm: StringName) -> void:
	_door(realm).press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


## Stamps, then waits out the slam: the next soul's evidence comes in when it releases (D14).
func _stamp_and_seat(realm: StringName) -> void:
	_stamp(realm)
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.1)


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _threads() -> Array[ThreadLine]:
	var lines: Array[ThreadLine] = []
	for child: Node in _system.thread_layer.get_children():
		if child is ThreadLine and not child.is_queued_for_deletion():
			lines.append(child as ThreadLine)
	return lines


func _mouse(button: MouseButton, double: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.double_click = double
	return event
