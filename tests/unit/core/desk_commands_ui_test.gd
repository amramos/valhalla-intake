extends GutTest
## What the full desk reads from the command layer (WP3): the slice rules, Hel's tide at her door
## (D21, D23), and the mentor's comment on an unguided soul's stamp (D16).

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_slice_rules_are_the_run_rules() -> void:
	var rules: SliceRules = Fixture.rules()
	rules.tide_threshold = 4
	var desk: DeskCommands = Fixture.desk(rules)
	assert_same(desk.slice_rules(), rules)
	assert_eq(desk.slice_rules().tide_threshold, 4)


func test_hels_tide_counts_unworthy_souls_at_the_stamp_and_restart_clears_it() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	assert_eq(desk.hel_tide(), 0, "Kolbeinn deserved Hel")
	desk.stamp(Realm.HEL)
	assert_eq(desk.hel_tide(), 1, "Asa, worthy of Valhalla")
	desk.debug_jump(2, 3)
	assert_eq(desk.hel_tide(), 2, "and Hakon")
	desk.restart_run()
	assert_eq(desk.hel_tide(), 0)


func test_mercy_on_day_one_is_named_kind_with_the_warning() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_eq(
		result.mentor_line,
		"Kind. Nothing in hand, and decree III. From tomorrow, that costs feathers."
	)


func test_an_illegal_stamp_is_told_apart_from_mercy() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 2)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_eq(
		result.mentor_line,
		"No wound, front, and 'Danes axed my chest'. Wrong door. From tomorrow, that costs feathers."
	)


func test_mercy_after_citations_begin_names_its_cost() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 2)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_eq(result.mentor_line, "Kind. 'Left the fight' and decree IV. That cost you two.")


func test_from_day_two_an_illegal_stamp_says_whether_the_soul_lied() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	assert_eq(
		desk.stamp(Realm.VALHALLA).mentor_line,
		"Wet to the knee, and 'Never left the hill'. You let a liar through."
	)
	desk.debug_jump(2, 1)
	assert_eq(
		desk.stamp(Realm.HEL).mentor_line,
		"'Fell in battle. Ness' and decree I. Nothing in that saga was a lie."
	)


func test_keeping_hels_promise_has_its_own_comment() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 3)
	assert_eq(desk.stamp(Realm.HEL).mentor_line, "'I held the door' and decree V. Hel pays well.")


func test_no_comment_on_a_legal_stamp_or_uncertainty() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 1)
	assert_eq(desk.stamp(Realm.VALHALLA).mentor_line, "", "legal")
	desk.debug_jump(3, 4)
	assert_eq(desk.stamp(Realm.VALHALLA).mentor_line, "", "Ketil, unproven at the desk")


func test_a_guided_soul_gets_a_comment_after_a_wrong_stamp_too() -> void:
	# Matrix A2: comments from soul 4 on, and after a wrong stamp on souls 1-3.
	var queues: Array = Fixture.queues()
	queues[0][1].mentor_steps.assign([MentorStep.make("Read him.", MentorStep.Until.READ)])
	var guided := DeskCommands.new()
	guided.start_run(Fixture.days(), queues, Fixture.rules(), Fixture.variants())
	guided.debug_jump(1, 2)
	assert_string_contains(guided.stamp(Realm.VALHALLA).mentor_line, "Wrong door.")


func test_the_days_first_grey_thread_draws_her_comment_once() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	assert_eq(desk.pin("C1", "W1").mentor_line, "One of them lies. The body may say which.")
	desk.debug_jump(3, 4)
	assert_eq(desk.pin("C2", "W1").mentor_line, "Huginn answers that. Two a day.")
	var again: PinResult = desk.pin("C2", "W1")
	assert_eq(again.mentor_line, "", "a re-pin isn't a new thread")
