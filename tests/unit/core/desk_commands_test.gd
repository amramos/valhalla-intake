extends GutTest
## The command layer end to end on the synthetic slice: the day flow, quotas, Huginn, Hel's
## promise (D3, D22, D29), the return arc (D2) and restarting the run (D31).

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func _stamp_rest_legally(desk: DeskCommands) -> void:
	while desk.phase() == &"desk":
		desk.next_soul()
		if desk.phase() == &"desk":
			desk.stamp(desk.current_encounter().legal_realm)


func test_a_day_runs_dawn_desk_dusk_and_the_last_day_ends_the_slice() -> void:
	var desk: DeskCommands = Fixture.desk()
	assert_eq([desk.phase(), desk.day_number()], [&"dawn", 1])
	assert_null(desk.current_encounter(), "nobody at the desk at dawn")
	desk.begin_day()
	assert_eq(desk.phase(), &"desk")
	assert_eq(desk.current_encounter().soul_name, "Ulf")
	assert_eq(desk.visible_items().size(), 6 + 3, "Ulf's items plus three decrees")
	_stamp_rest_legally(desk)
	assert_eq(desk.phase(), &"dusk")
	desk.next_day()
	assert_eq([desk.phase(), desk.day_number()], [&"dawn", 2])
	desk.begin_day()
	_stamp_rest_legally(desk)
	desk.next_day()
	desk.begin_day()
	_stamp_rest_legally(desk)
	assert_eq(desk.phase(), &"ending")
	assert_eq(desk.ending().entries.size(), 10)


func test_quota_met_pays_and_shortfall_costs_per_soul() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	assert_eq(desk.dusk_report().quota_delta, 2, "day 1: Ulf met the quota of 1")
	assert_eq(desk.feathers(), 12)
	desk.debug_jump(3, 1)
	for realm: StringName in [Realm.HEL, Realm.HEL, Realm.FOLKVANGR, Realm.HEL]:
		desk.stamp(realm)
		desk.next_soul()
	var report: DuskReport = desk.dusk_report()
	assert_eq([report.admitted, report.quota], [0, 2])
	assert_eq(report.quota_delta, -2, "two souls short")


func test_day_one_never_costs_feathers_for_a_wrong_stamp() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 2)
	watch_signals(desk)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_true(result.warning)
	assert_false(result.citation)
	assert_eq(desk.feathers(), 10)
	assert_signal_not_emitted(desk, "citation_given")


func test_a_citation_is_given_at_the_stamp_and_named_at_dusk() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	watch_signals(desk)
	var result: StampResult = desk.stamp(Realm.VALHALLA)
	assert_eq(result.feathers_delta, -2)
	assert_signal_emitted_with_parameters(
		desk, "citation_given", [result.citation_text, "B4", "C1"]
	)
	assert_eq(result.citation_loss, 2)
	desk.next_soul()
	assert_eq(desk.dusk_report().citations, [result.citation_text] as Array[String])


func test_a_closed_door_refuses_the_stamp() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.begin_day()
	var result: StampResult = desk.stamp(Realm.FOLKVANGR)
	assert_false(result.valid)
	assert_eq(desk.current_encounter().soul_name, "Ulf", "the soul is still at the desk")
	assert_eq(desk.door_open_day(Realm.FOLKVANGR), 3)


func test_new_marks_show_until_the_first_stamp() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 1)
	assert_true(desk.shows_new_marks())
	assert_eq(desk.day_rules().new_decree_ids, ["L5"] as Array[String])
	desk.stamp(Realm.VALHALLA)
	assert_false(desk.shows_new_marks())


func test_huginn_answers_only_grey_threads_within_his_budget() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	desk.pin("C1", "W1")
	assert_eq(desk.ask_huginn(0), "", "he isn't on the desk on day 2")
	desk.debug_jump(3, 4)
	desk.pin("C2", "W1")
	assert_eq(desk.huginn_left(), 2)
	var start: float = desk.time_left()
	assert_eq(desk.ask_huginn(0), "The claim lies.")
	assert_eq(desk.time_left(), start - 5.0, "an answer costs 5 s")
	assert_eq(desk.ask_huginn(0), "The claim lies.", "the answer stays on its thread")
	assert_eq(desk.huginn_left(), 1, "asking again is free")
	assert_eq(desk.thread_answer(0), "The claim lies.")
	assert_eq(desk.ask_huginn(1), "", "no such thread")


func test_an_extra_answer_costs_feathers_once_the_free_ones_are_spent() -> void:
	var days: Array[DayRules] = Fixture.days()
	days[2].huginn_answers = 1
	var desk := DeskCommands.new()
	desk.start_run(days, Fixture.queues(), Fixture.rules(), Fixture.variants())
	desk.debug_jump(3, 4)
	assert_false(desk.buy_huginn_answer(), "a free answer is left")
	var feathers: int = desk.feathers()
	desk.pin("C2", "W1")
	desk.ask_huginn(0)
	assert_eq(desk.huginn_left(), 0)
	assert_true(desk.buy_huginn_answer())
	assert_eq(desk.huginn_left(), 1)
	assert_eq(desk.feathers(), feathers - 2)
	assert_false(desk.buy_huginn_answer(), "the bought answer is still unspent")


func test_hels_offer_is_made_at_day_two_dusk_and_kept_pays_at_the_stamp() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 1)
	assert_eq(desk.promise_state(), &"open")
	var offer: String = desk.dusk_report().requests[0]
	assert_true(offer.contains("Ragna"), offer)
	desk.debug_jump(3, 3)
	var before: int = desk.feathers()
	var result: StampResult = desk.stamp(Realm.HEL)
	assert_true(result.citation, "keeping the promise breaks L5")
	assert_eq(result.reward, 4)
	assert_eq(desk.feathers(), before - 2 + 4)
	assert_eq(desk.promise_state(), &"kept")


func test_hels_promise_is_broken_by_another_door() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 3)
	var result: StampResult = desk.stamp(Realm.FOLKVANGR)
	assert_eq(result.reward, 0)
	assert_eq(desk.promise_state(), &"broken")


func test_hels_promise_lapses_when_the_soul_goes_unjudged() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 1)
	desk.advance_time(1000.0)
	assert_eq(desk.phase(), &"ending")
	assert_eq(desk.promise_state(), &"lapsed")
	assert_true(desk.ending().never_judged.has("Ragna"))


func test_hakon_damned_after_his_seam_was_pinned_returns_ignored() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 2)
	assert_eq(desk.pin("C3", "L4").kind, PinResult.Kind.THREAD)
	desk.stamp(Realm.HEL)
	_stamp_rest_legally(desk)
	assert_eq(desk.dusk_report().returned_line, "Hakon is back.")
	desk.next_day()
	desk.begin_day()
	desk.stamp(Realm.VALHALLA)
	var returned: Encounter = desk.current_encounter()
	assert_eq(returned.id, &"hakon_ignored")
	assert_true(returned.returned)


func test_hakon_damned_unpinned_returns_missed() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 2)
	assert_eq(desk.current_encounter().id, &"hakon_missed")
	assert_eq(desk.queue_position(), Vector2i(2, 4))


func test_hakon_spared_brings_the_fallback() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 2)
	desk.stamp(Realm.VALHALLA)
	_stamp_rest_legally(desk)
	assert_eq(desk.dusk_report().returned_line, "")
	desk.next_day()
	desk.begin_day()
	desk.stamp(Realm.VALHALLA)
	assert_eq(desk.current_encounter().id, &"egil")


func test_strict_obedience_reaches_hels_tide() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	var report: EndingReport = desk.ending()
	assert_eq(report.tide_names, ["Asa", "Hakon", "Hakon"] as Array[String])
	assert_eq(report.outcome, EndingReport.TIDE)
	assert_eq(report.hollow_names.size(), 0)


func test_restart_restores_the_whole_day_one_dawn() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 3)
	desk.stamp(Realm.HEL)
	desk.set_paused(true)
	desk.restart_run()
	assert_eq([desk.phase(), desk.day_number()], [&"dawn", 1])
	assert_eq([desk.feathers(), desk.rank(), desk.huginn_left()], [10, 0, 0])
	assert_eq(desk.promise_state(), &"none")
	assert_eq(desk.ending().entries.size(), 0, "no verdicts recorded")
	assert_eq(desk.dusk_report().day, 0, "no dusk yet")
	assert_eq(desk.time_left(), INF)
	assert_false(desk.is_paused())
	assert_eq(desk.quota_progress(), Vector2i(0, 1))
	desk.begin_day()
	assert_eq(desk.current_encounter().soul_name, "Ulf")
	assert_eq(desk.threads().size(), 0)


func test_the_recap_puts_wrong_verdicts_first_and_names_uncertainty() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	var day_one: DuskReport = desk.dusk_report()
	assert_eq(day_one.recap[0], "Asa: The truth about Asa.", "Asa went to Hel, worthy of Valhalla")
	assert_eq(day_one.recap.size(), 3)
	desk.debug_jump(3, 4)
	desk.pin("C2", "W1")
	desk.stamp(Realm.VALHALLA)
	var day_three: DuskReport = desk.dusk_report()
	assert_eq(
		day_three.recap[1],
		"Ketil: The truth about Ketil. Couldn't be proven at the desk.",
		"admitted on an unanswered grey thread (D37)"
	)


func test_day_two_dusk_carries_the_story_beat() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 1)
	assert_eq(desk.dusk_report().story, "Eyvind prays.")


func test_a_shortfall_that_demotes_reports_the_penalty_not_the_refill() -> void:
	# The review's case: a -1 shortfall at 1 feather read as +4 after the refill.
	var rules: SliceRules = Fixture.rules()
	rules.start_feathers = 1
	var desk: DeskCommands = Fixture.desk(rules)
	desk.begin_day()
	for _soul: int in 3:
		desk.stamp(Realm.HEL)
		desk.next_soul()
	var report: DuskReport = desk.dusk_report()
	assert_eq(report.quota_delta, -1)
	assert_true(report.demoted)
	assert_eq([report.feathers, report.rank], [5, 1])
