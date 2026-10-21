extends GutTest
## Ledger D48: a stamp that draws a citation (or a day-1 warning) holds the desk until
## next_soul(); the stamp's own time applies first, on every slot alike.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_a_cited_soul_holds_the_desk_until_next_soul() -> void:
	# D48: the black feather and the lit pair stay with the stamped soul.
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_true(result.citation)
	assert_true(desk.awaiting_next())
	assert_eq(desk.current_encounter().soul_name, "Sigvaldi")
	assert_eq(desk.queue_position(), Vector2i(1, 3))
	assert_same(desk.pending_stamp(), result)
	assert_eq([desk.pending_stamp().citation_a, desk.pending_stamp().citation_b], ["C1", "L1"])
	assert_eq(desk.threads().size(), 0, "the soul's own threads stay readable")
	assert_eq(desk.pin("B2", "C1").kind, PinResult.Kind.INVALID, "no pins while held")
	assert_false(desk.stamp(Realm.VALHALLA).valid, "no second stamp")
	var left: float = desk.time_left()
	desk.advance_time(60.0)
	assert_eq(desk.time_left(), left, "the clock stands while nobody is judged")
	desk.next_soul()
	assert_false(desk.awaiting_next())
	assert_null(desk.pending_stamp())
	assert_eq(desk.current_encounter().soul_name, "Hakon")


func test_a_day_one_warning_holds_the_desk_too() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 2)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_true(result.warning)
	assert_true(desk.awaiting_next())


func test_a_stamp_without_a_citation_seats_the_next_soul_at_once() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	desk.stamp(Realm.VALHALLA)
	assert_false(desk.awaiting_next())
	assert_eq(desk.current_encounter().soul_name, "Hakon")


func test_the_last_cited_soul_ends_the_day_only_on_next_soul() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	desk.stamp(Realm.VALHALLA)
	assert_eq(desk.phase(), &"desk")
	desk.next_soul()
	assert_eq(desk.phase(), &"dusk")


func test_stamp_time_applies_on_every_slot_then_the_horn() -> void:
	# The review's case: the stamp completes, then its time, then the next soul or the horn.
	var desk: DeskCommands = Fixture.desk()
	desk.set_stamp_seconds(20.0)
	desk.debug_jump(2, 2)
	assert_eq(desk.time_left(), 300.0, "a debug jump charges nothing")
	desk.advance_time(285.0)
	watch_signals(desk)
	desk.stamp(Realm.HEL)
	assert_signal_emitted(desk, "horn")
	assert_eq(desk.phase(), &"dusk")
	var hakon: EndingEntry = desk.ending().entries[4]
	assert_eq([hakon.soul_name, hakon.verdict], ["Hakon", Realm.HEL], "the stamp completed")
	assert_eq(desk.dusk_report().never_judged, ["Grim"] as Array[String])


## Stamps soul `slot` of `day` with 15 s left and 20 s of stamp time, so the stamp runs the clock
## out; returns the desk after the stamp.
func _stamp_out_the_clock(day: int, slot: int, realm: StringName) -> DeskCommands:
	var desk: DeskCommands = Fixture.desk()
	desk.set_stamp_seconds(20.0)
	desk.debug_jump(day, slot)
	desk.advance_time(desk.time_left() - 15.0)
	watch_signals(desk)
	var result: StampResult = desk.stamp(realm)
	assert_true(result.citation, "the stamp is cited")
	return desk


func test_a_cited_stamp_that_runs_the_clock_out_holds_until_next_soul_mid_queue() -> void:
	# The review's case: the clock running out must not clear the held citation (D36, D48).
	var desk: DeskCommands = _stamp_out_the_clock(2, 1, Realm.HEL)
	assert_true(desk.awaiting_next())
	assert_eq(desk.phase(), &"desk")
	assert_eq(desk.current_encounter().soul_name, "Sigvaldi")
	assert_signal_not_emitted(desk, "horn")
	desk.next_soul()
	assert_signal_emit_count(desk, "horn", 1)
	assert_eq(desk.phase(), &"dusk")
	assert_eq(desk.dusk_report().never_judged, ["Hakon", "Grim"] as Array[String])
	assert_eq(desk.dusk_report().citations.size(), 1)


func test_a_cited_last_stamp_that_runs_the_clock_out_settles_the_day_once() -> void:
	var desk: DeskCommands = _stamp_out_the_clock(2, 3, Realm.VALHALLA)
	assert_true(desk.awaiting_next())
	assert_eq(desk.current_encounter().soul_name, "Grim")
	var feathers: int = desk.feathers()
	desk.next_soul()
	assert_signal_emit_count(desk, "horn", 1)
	assert_eq(desk.phase(), &"dusk")
	assert_eq(desk.dusk_report().never_judged, [] as Array[String])
	assert_eq(desk.feathers(), feathers + 2, "the met quota pays once")
	desk.next_soul()
	assert_eq(desk.phase(), &"dusk", "a second release does nothing")


func test_a_cited_stamp_that_runs_the_last_clock_out_holds_before_the_ending() -> void:
	var desk: DeskCommands = _stamp_out_the_clock(3, 3, Realm.HEL)
	assert_true(desk.awaiting_next())
	assert_eq(desk.phase(), &"desk")
	desk.next_soul()
	assert_signal_emit_count(desk, "horn", 1)
	assert_eq(desk.phase(), &"ending")
	assert_eq(desk.ending().never_judged, ["Ketil"] as Array[String])
