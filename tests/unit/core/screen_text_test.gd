extends GutTest
## The text of the flow screens (matrix A5, A6, A8), composed once for both the desk and the
## harness: the dawn card, the dusk cards and the slice ending.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")

var _rules: SliceRules = Fixture.rules()


func test_the_clock_reads_minutes_and_seconds_rounded_up() -> void:
	assert_eq(
		[ScreenText.clock_text(300.0), ScreenText.clock_text(65.2), ScreenText.clock_text(9.0)],
		["5:00", "1:06", "0:09"]
	)


func test_the_dawn_card_fills_in_the_clock() -> void:
	var day: DayRules = Fixture.days()[1]
	day.dawn_lines.assign(["Day 2.", "The clock: {clock}. It runs while a soul is at the desk."])
	assert_eq(
		ScreenText.dawn_lines(day),
		["Day 2.", "The clock: 5:00. It runs while a soul is at the desk."] as Array[String]
	)


func test_the_dusk_cards_run_citations_quota_and_feathers_recap_requests_story() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 3)
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	var report: DuskReport = desk.dusk_report()
	var cards: Array[String] = ScreenText.dusk_cards(report, _rules)
	assert_eq(cards.size(), 5)
	assert_eq(cards[0], "Citations today: 1.\n" + report.citations[0])
	assert_eq(
		cards[1],
		(
			"Odin wanted 1. Valhalla took 2. +2 feathers.\n"
			+ "Feathers: 12 at dawn, 12 now.\n"
			+ "Citation (Grim): -2.\nQuota: +2.\n"
			+ "Rank: Chooser of the Slain."
		)
	)
	assert_eq(cards[2], "\n".join(report.recap))
	assert_string_contains(cards[3], "Hel: send Ragna to Hel. 4 feathers.")
	assert_eq(cards[4], "Eyvind prays.\nHakon is back.")


func test_a_quiet_dusk_says_so_and_leaves_empty_cards_out() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	var cards: Array[String] = ScreenText.dusk_cards(desk.dusk_report(), _rules)
	assert_eq(cards[0], "No citations today.")
	assert_true(cards[1].begins_with("Odin wanted 1. Valhalla took 2. +2 feathers."))
	assert_eq(cards.size(), 3, "citations, quota, recap; no request or story on day 1")


func test_a_short_quota_names_the_feathers_lost() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 1)
	for _soul: int in 3:
		desk.stamp(Realm.HEL)
		desk.next_soul()
	assert_true(
		ScreenText.dusk_cards(desk.dusk_report(), _rules)[1].begins_with(
			"Odin wanted 1. Valhalla took 0. -1 feathers."
		)
	)


func test_strict_obedience_ends_on_hels_tide_naming_the_souls() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	var lines: Array[String] = ScreenText.ending_lines(desk.ending(), _rules)
	assert_eq(lines[0], "Hel's tide")
	assert_eq(
		lines[1],
		(
			"The worthy you damned march with Hel. At the first horn they break the line: "
			+ "Asa, Hakon, Hakon (returned)."
		)
	)
	assert_true(lines.has("Asa: Hel. Truth: Valhalla. Missed."))
	assert_true(lines.has("Hakon (returned): Hel. Truth: Valhalla. Missed."))
	assert_true(lines.has("Ulf: Valhalla. Truth: Valhalla."))
	assert_true(lines.has("Broken. Ragna went to Fólkvangr."))
	assert_eq(lines[-1], "Feathers: %d. Rank: Chooser of the Slain." % desk.feathers())


func test_the_ending_lists_the_never_judged_and_a_lapsed_promise() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 1)
	desk.advance_time(1000.0)
	var report: EndingReport = desk.ending()
	assert_eq(report.promise_line, "Lapsed. Ragna was never judged.")
	var lines: Array[String] = ScreenText.ending_lines(report, _rules)
	assert_true(lines.has("Ragna: never judged."))
	assert_true(lines.has("Lapsed. Ragna was never judged."))


func test_a_returned_soul_is_marked_on_its_ending_entry() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 3)
	var returned: Array[String] = []
	for entry: EndingEntry in desk.ending().entries:
		if entry.returned:
			returned.append("%s day %d" % [entry.soul_name, entry.day])
	assert_eq(returned, ["Hakon day 3"] as Array[String])


## Day 3's quota and feathers are told on its own dusk card, which shows before the ending; the
## ending does not repeat them (D53's ending section, withdrawn once the harness showed that card).
func test_day_threes_quota_and_feathers_are_on_its_dusk_card_not_the_ending() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	var quota: String = "Odin wanted 2. Valhalla took 1. -1 feathers."
	var dusk: Array[String] = ScreenText.dusk_cards(desk.dusk_report(), _rules)
	assert_true(dusk[1].begins_with(quota + "\n"), "day 3's dusk card names the quota")
	var lines: Array[String] = ScreenText.ending_lines(desk.ending(), _rules)
	assert_false(lines.has(quota), "the ending leaves it to the dusk card")
	assert_false(lines.has("Quota: -1."), "and the day's feather changes")


func test_the_ending_sections_group_its_lines() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	var report: EndingReport = desk.ending()
	var sections: Array[String] = ScreenText.ending_sections(report, _rules)
	assert_eq(sections.size(), 4, "outcome, rows, ledger, standing")
	assert_true(sections[0].begins_with("Hel's tide\n"))
	assert_eq(sections[1].split("\n").size(), report.entries.size())
	assert_eq(sections[2], "Broken. Ragna went to Fólkvangr.")
	assert_eq(sections[3], "Feathers: %d. Rank: %s." % [desk.feathers(), desk.rank_name()])
	assert_eq(
		"\n".join(sections).split("\n"), PackedStringArray(ScreenText.ending_lines(report, _rules))
	)
