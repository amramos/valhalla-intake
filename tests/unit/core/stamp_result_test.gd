extends GutTest
## What a committed stamp carries for the slam (D38): the figures it added to Hel's tide, exactly
## once per stamp, and the id of the soul that left, even when the next soul is already seated.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_a_worthy_soul_sent_to_hel_adds_one_to_the_tide() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	var asa: Encounter = desk.current_encounter()
	assert_eq(asa.worthy_realm, Realm.VALHALLA, "the fixture's Asa is worthy of Valhalla")
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_eq([result.tide_delta, desk.hel_tide()], [1, 1])


func test_a_stamp_that_damns_no_worthy_soul_adds_nothing() -> void:
	# Kolbeinn is worthy of Hel; Asa, next, is sent to the Valhalla she is worthy of.
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 2)
	assert_eq(desk.current_encounter().worthy_realm, Realm.HEL)
	var kolbeinn: StampResult = desk.stamp(Realm.HEL)
	var asa: StampResult = desk.stamp(Realm.VALHALLA)
	assert_eq([kolbeinn.tide_delta, asa.tide_delta, desk.hel_tide()], [0, 0, 0])


func test_each_stamp_counts_only_its_own_figure() -> void:
	# Two worthy souls damned on two days: each stamp reports one, never the running total.
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	var deltas: Array[int] = [desk.stamp(Realm.HEL).tide_delta]
	desk.next_day()
	desk.begin_day()
	deltas.append(desk.stamp(Realm.VALHALLA).tide_delta)
	assert_eq(desk.current_encounter().soul_name, "Hakon")
	deltas.append(desk.stamp(Realm.HEL).tide_delta)
	assert_eq(deltas, [1, 0, 1] as Array[int])
	assert_eq(desk.hel_tide(), 2)


func test_the_departing_id_is_the_stamped_soul_not_the_next_one() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.begin_day()
	var stamped: StringName = desk.current_encounter().id
	var result: StampResult = desk.stamp(desk.current_encounter().legal_realm)
	assert_ne(desk.current_encounter().id, stamped, "the next soul is seated")
	assert_eq(result.departing_id, stamped)


func test_a_refused_stamp_names_no_departure() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.begin_day()
	var refused: StampResult = desk.stamp(Realm.RAN)
	assert_eq([refused.valid, refused.departing_id, refused.tide_delta], [false, &"", 0])
