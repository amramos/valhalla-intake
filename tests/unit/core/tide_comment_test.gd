extends GutTest
## D53: the mentor explains Hel's tide on the stamp that adds its first figure (0 to 1), guided
## souls included, and never again.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_the_first_figure_at_hels_door_draws_her_explanation() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 2)
	assert_eq(desk.stamp(Realm.HEL).mentor_line, "", "Kolbeinn deserved Hel: no figure")
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_eq(desk.hel_tide(), 1)
	assert_eq(result.mentor_line, "The Law is kept. Hel's tide grows by one.")
	desk.debug_jump(2, 2)
	assert_eq(desk.stamp(Realm.HEL).mentor_line, "", "the second figure goes unremarked")


func test_a_first_figure_from_a_broken_law_adds_the_tide_to_her_comment() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 3, true)
	assert_eq(desk.hel_tide(), 0, "mercy so far")
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_eq(
		result.mentor_line,
		"'I held the door' and decree V. Hel pays well. Hel's tide grows by one."
	)


func test_a_guided_soul_gets_the_tide_comment_too() -> void:
	var queues: Array = Fixture.queues()
	queues[0][2].mentor_steps.assign([MentorStep.make("Read her.", MentorStep.Until.READ)])
	var desk := DeskCommands.new()
	desk.start_run(Fixture.days(), queues, Fixture.rules(), Fixture.variants())
	desk.debug_jump(1, 3)
	assert_eq(desk.stamp(Realm.HEL).mentor_line, "The Law is kept. Hel's tide grows by one.")


func test_a_first_figure_from_an_unseen_broken_law_never_says_the_law_is_kept() -> void:
	# A wrong stamp no visible seam shows draws no comment of its own (D37), so the tide's
	# explanation must not open by praising obedience.
	var queues: Array = Fixture.queues()
	var soul: Encounter = queues[0][0]
	soul.seams.clear()
	soul.legal_realm = Realm.VALHALLA
	soul.worthy_realm = Realm.VALHALLA
	var desk := DeskCommands.new()
	desk.start_run(Fixture.days(), queues, Fixture.rules(), Fixture.variants())
	desk.begin_day()
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_false(result.correct, "Hel broke the Law, unseen")
	assert_eq(desk.hel_tide(), 1)
	assert_eq(result.mentor_line, "Hel's tide grows by one.")
