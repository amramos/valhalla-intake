extends GutTest
## The full desk UI on the timed fixture desks (desk_fixture.gd): Hel's tide, NEW marks, the clock
## warning, Huginn's extra answer, thread styles, the caption strip's re-show, the thud and its
## sounds, dragging the soul onto a door, the plates, and the mentor's comments.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## pixelforge.toml's reserved ramps (Ember, Bile, Blood): never a thread's colour.
const RESERVED: Array[String] = [
	"6b2f1e", "a6623b", "e08a4a", "4f5a2c", "8b9361", "bbc983", "4a1418", "8e2a2a"
]

var _desk: Desk = null
var _system: DeskSystem = null


func _open(commands: DeskCommands) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_hels_tide_shows_its_figures_and_empty_slots_up_to_the_threshold() -> void:
	_open(Fixture.commands())
	var hel: Door = _door(&"hel")
	var threshold: int = _desk.commands().slice_rules().tide_threshold
	assert_eq(hel.tide, Vector2i(0, threshold), "empty slots up to the threshold (D21)")
	assert_eq(_door(&"valhalla").tide, Vector2i.ZERO, "only Hel's door has a tide")
	_stamp(&"hel")
	_system.stamp_flow.next_soul_button.pressed.emit()
	_stamp(&"hel")
	assert_eq(_desk.commands().hel_tide(), 1, "the returned soul was worthy of Valhalla")
	assert_eq(hel.tide, Vector2i(1, threshold), "one figure drawn")
	assert_eq(hel.tide_rect().size.y, 6.0, "6 px figures")


func test_new_marks_show_until_the_days_first_stamp() -> void:
	_open(Fixture.commands())
	assert_true(_system.law_panel.is_new("L5"), "the new decree is marked (D34)")
	assert_string_contains(_system.law_panel.heading_text(), "NEW: L5")
	assert_false(_system.law_panel.is_new("L4"))
	assert_true(_door(&"folkvangr").is_new, "the newly opened door is marked")
	_stamp(&"hel")
	assert_false(_system.law_panel.is_new("L5"), "the first stamp clears the marks")
	assert_false(_door(&"folkvangr").is_new)


func test_a_barred_door_says_when_it_opens_and_shows_its_locked_sprite() -> void:
	_open(Fixture.two_days())
	var folkvangr: Door = _door(&"folkvangr")
	assert_false(folkvangr.is_open)
	assert_eq(folkvangr.hover_text(), "Fólkvangr: Closed until day 3")
	assert_eq(folkvangr.shown_texture(), folkvangr.locked_texture)


func test_the_clock_warning_turns_the_clock_over() -> void:
	_open(Fixture.commands())
	assert_false(_system.hud.is_warning())
	_system._process(Fixture.CLOCK_SECONDS - 29.0)
	assert_true(_system.hud.is_warning(), "30 s left shows on the HUD (D22)")


func test_the_extra_answer_note_shows_once_todays_answers_are_spent() -> void:
	_open(Fixture.commands())
	_pin("C1", "W1")
	_pin("C3", "W3")
	_pin("C3", "W2")
	assert_eq(_system.hud.extra_note(), "", "no note while answers remain")
	for thread: int in [0, 1]:
		_knot(thread).press()
		_system.ask_huginn.pressed.emit()
	assert_eq(_desk.commands().huginn_left(), 0)
	assert_eq(_system.hud.extra_note(), "extra answer:\n2 feathers", "D29, D30")
	var before: int = _desk.commands().feathers()
	_knot(2).press()
	var text: DeskText = _desk.commands().slice_rules().text
	_system._on_ask_huginn_hovered()
	assert_eq(_system.hover_label.shown_text(), text.huginn_extra_hover, "A4: an unanswered one")
	_system.ask_huginn.pressed.emit()
	assert_ne(_desk.commands().thread_answer(2), "", "the third answer is bought and given")
	assert_eq(_desk.commands().feathers(), before - 2)
	var bought: String = text.huginn_bought_format % _desk.commands().thread_answer(2)
	_system.caption_strip._process(_system.caption_strip.hold_seconds)
	assert_eq(_system.caption_strip.shown_text(), bought, "A4: the bought answer says its price")


## The review's case: re-asking about an answered thread is free, so its hover names no price.
func test_the_extra_answer_hover_is_silent_on_an_already_answered_thread() -> void:
	_open(Fixture.commands())
	_pin("C1", "W1")
	_pin("C3", "W3")
	for thread: int in [0, 1]:
		_knot(thread).press()
		_system.ask_huginn.pressed.emit()
	assert_eq(_desk.commands().huginn_left(), 0, "today's answers are spent")
	assert_eq(_system.huginn_thread, 1, "the answered thread 1 is still selected")
	var before: int = _desk.commands().feathers()
	_system._on_ask_huginn_hovered()
	assert_eq(_system.hover_label.shown_text(), "", "no price on a thread already answered")
	_system.ask_huginn.pressed.emit()
	assert_eq(_desk.commands().feathers(), before, "and asking again costs nothing")


func test_ask_huginn_is_greyed_until_a_grey_thread_is_selected() -> void:
	_open(Fixture.commands())
	_pin("C1", "W1")
	assert_true(_system.ask_huginn.disabled)
	_system._on_ask_huginn_hovered()
	var text: DeskText = _desk.commands().slice_rules().text
	assert_eq(_system.hover_label.shown_text(), text.huginn_select_hover, "A4")
	_knot(0).press()
	assert_false(_system.ask_huginn.disabled)


func test_the_three_thread_kinds_differ_by_colour_and_pattern_and_use_no_reserved_colour() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_pin("C1", "W1")
	_pin("C2", "L5")
	var colours: Dictionary = {}
	var patterns: Dictionary = {}
	for line: ThreadLine in _threads():
		var colour: Color = line._color()
		assert_false(RESERVED.has(colour.to_html(false)), "%s is reserved" % colour.to_html(false))
		colours[colour.to_html(false)] = true
		var pattern: String = ""
		for step: int in range(6):
			pattern += "1" if line._pattern_on(step) else "0"
		patterns[pattern] = true
	assert_eq(colours.size(), 3, "three colours")
	assert_eq(patterns.size(), 3, "three patterns")


func test_a_click_on_a_threads_bead_shows_its_caption_again() -> void:
	_open(Fixture.commands())
	_pin("C2", "L5")
	_system.caption_strip.take_over("something else")
	_knot(0).press()
	assert_eq(
		_system.caption_strip.shown_text(), "C2 against L5: L5 sends him to Fólkvangr.", "D33, A1"
	)


func test_a_seam_plays_its_sound_and_a_stamp_its_thud_flare_and_walk() -> void:
	_open(Fixture.commands())
	var seam: AudioStreamPlayer = _system.seam_player
	_pin("C2", "L5")
	assert_true(seam.playing, "seam found")
	_stamp(&"folkvangr")
	assert_true(_system.stamp_flow.thud_player.playing, "the stamp's thud")
	assert_true(_door(&"folkvangr").is_flaring(), "the door flares")
	assert_eq(_system.stamp_flow.walk_layer.get_child_count(), 1, "the soul walks through")


func test_dragging_the_soul_onto_an_open_door_previews_then_commits() -> void:
	_open(Fixture.commands())
	var payload: Dictionary = _system.soul.figure().payload()
	var hel: Door = _door(&"hel")
	assert_true(hel._can_drop_data(Vector2.ZERO, payload))
	assert_eq(_system.stamp_flow.stamp_prompt.question(), "Stamp Asgaut to Hel?", "the preview")
	assert_eq(_soul(), "Asgaut", "hovering commits nothing")
	_system.stamp_flow._notification(Node.NOTIFICATION_DRAG_END)
	assert_false(_system.stamp_flow.stamp_prompt.visible, "released elsewhere: cancelled")
	hel._can_drop_data(Vector2.ZERO, payload)
	hel._drop_data(Vector2.ZERO, payload)
	assert_eq(_soul(), "Second", "dropped on the door: stamped")


func test_a_barred_door_refuses_the_dragged_soul() -> void:
	_open(Fixture.two_days())
	assert_false(_door(&"folkvangr")._can_drop_data(Vector2.ZERO, _system.soul.figure().payload()))


func test_a_held_soul_cannot_be_dragged() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_true(_desk.commands().awaiting_next())
	assert_null(_system.soul.figure()._get_drag_data(Vector2.ZERO))


func test_plates_show_hels_mark_or_frost_with_their_hover_label() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	_system.stamp_flow.next_soul_button.pressed.emit()
	assert_eq(_soul(), "Second")
	assert_eq(_system.soul.plate_texture().resource_path, "res://assets/art/ui/nameplate-frost.png")
	watch_signals(_system.soul)
	_system.soul._on_plate_entered()
	assert_eq(_system.hover_label.shown_text(), "Back from Hel. His saga was true.")


func test_the_mentors_comment_on_a_stamp_shows_and_a_click_on_her_shows_it_again() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	var line: String = _desk.commands().pending_stamp().mentor_line
	assert_ne(line, "", "a wrong stamp on an unguided soul draws her comment")
	_system.caption_strip.take_over("something else")
	_system.mentor_portrait.press()
	assert_eq(_system.caption_strip.shown_text(), line, "D33: a click on the mentor")


func _soul() -> String:
	return _system.soul.soul_name()


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


func _knot(thread_index: int) -> PinSelectable:
	for line: ThreadLine in _threads():
		if line.thread_index == thread_index and line.has_knot():
			return line.knot()
	return null
