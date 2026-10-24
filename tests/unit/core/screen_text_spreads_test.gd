extends GutTest
## The day-book's text (D22, D23, D34, D44, D47): ScreenText's dusk spreads and ending rows say
## exactly the words the dusk cards and the ending lines said, so the desk and the text harness
## still print the same words, and the rows carry the record mark and the citation's feather.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")
const REALMS: Array[StringName] = [Realm.VALHALLA, Realm.FOLKVANGR, Realm.HEL, Realm.RAN]
const MARKS: Array[StringName] = [
	&"", VerdictRecord.IGNORED, VerdictRecord.MISSED, VerdictRecord.UNCERTAIN
]

var _rules: SliceRules = Fixture.rules()


func test_the_first_spread_holds_citations_and_quota_left_and_the_recap_right() -> void:
	var report: DuskReport = _dusk(2, Realm.VALHALLA)
	var spreads: Array[DuskSpread] = ScreenText.dusk_spreads(report, _rules)
	assert_eq(spreads.size(), 2, "requests and a story beat on day 2: a second spread")
	var title: String = "Dusk, day 2."
	assert_eq(spreads[0].title, title)
	assert_eq(spreads[0].left[0], title, "the title heads the left page")
	assert_eq(spreads[0].left[1], "Citations today: 1.")
	assert_eq(spreads[0].left[2], report.citations[0])
	assert_eq(spreads[0].left[3], "Odin wanted 1. Valhalla took 2. +2 feathers.")
	assert_eq(spreads[0].left[-1], "Rank: Chooser of the Slain.")
	assert_eq(spreads[0].right, report.recap, "the recap on the right page")
	assert_eq(spreads[1].left, [title] + report.requests, "requests on the next spread's left")
	assert_eq(spreads[1].right, ["Eyvind prays.", "Hakon is back."] as Array[String])


func test_a_quiet_day_has_one_spread_and_no_citations_never_stands_alone() -> void:
	var report: DuskReport = _dusk(1, Realm.VALHALLA)
	var spreads: Array[DuskSpread] = ScreenText.dusk_spreads(report, _rules)
	assert_eq(spreads.size(), 1, "no requests or story on day 1: no second spread")
	var left: Array[String] = spreads[0].left
	assert_eq(left[1], _rules.text.dusk_no_citations)
	assert_gt(left.size(), 3, "the quota shares its page")


## Every dusk of three played runs: "No citations today." never alone on a page, and the
## flattened spreads say the old five cards' words in the old order.
func test_the_flattened_spreads_say_the_old_cards_words_on_every_played_dusk() -> void:
	var checked: int = 0
	for strategy: int in range(3):
		var desk: DeskCommands = SliceLoader.load_slice()
		for _step: int in range(400):
			match desk.phase():
				RunState.DAWN:
					desk.begin_day()
				RunState.DESK:
					if desk.awaiting_next():
						desk.next_soul()
					else:
						desk.stamp(_choice(desk.current_encounter(), strategy))
				_:
					_check_dusk(desk.dusk_report(), desk.slice_rules())
					checked += 1
					if desk.phase() == RunState.ENDING:
						break
					desk.next_day()
	assert_eq(checked, 9, "three dusks in each of three runs")


func test_a_cards_text_is_its_spreads_title_over_its_body() -> void:
	var report: DuskReport = _dusk(2, Realm.HEL)
	var spreads: Array[DuskSpread] = ScreenText.dusk_spreads(report, _rules)
	var cards: Array[String] = ScreenText.dusk_cards(report, _rules)
	assert_eq(cards.size(), spreads.size())
	for index: int in range(spreads.size()):
		assert_eq(cards[index], spreads[index].body())
		assert_eq(spreads[index].title + "\n" + cards[index], spreads[index].text())


## Every row of a played ending says ScreenText.row's words, split for the page's columns.
func test_the_ending_rows_say_the_old_lines_words() -> void:
	for verdict: StringName in [Realm.HEL, Realm.VALHALLA]:
		var desk: DeskCommands = Fixture.desk()
		desk.debug_jump(3, 4)
		desk.stamp(verdict)
		var report: EndingReport = desk.ending()
		var rows: Array[EndingRow] = ScreenText.ending_rows(report, _rules)
		var lines: Array[String] = ScreenText.ending_lines(report, _rules)
		assert_eq(rows.size(), report.entries.size())
		for index: int in range(rows.size()):
			assert_eq(rows[index].text, lines[2 + index], "the row is the old line")
			assert_eq(" ".join(rows[index].segments()), rows[index].text, "split, not reworded")


## Every name, door, truth and mark the slice can put on a row, the returned name included.
func test_every_possible_row_splits_into_its_columns_without_losing_a_word() -> void:
	var count: int = 0
	for returned: bool in [false, true]:
		for verdict: StringName in REALMS + ([&""] as Array[StringName]):
			for worthy: StringName in REALMS:
				for mark: StringName in MARKS:
					var entry: EndingEntry = _entry("Hakon", returned, verdict, worthy, mark)
					var row: EndingRow = ScreenText.ending_row(entry, _rules.text)
					assert_eq(row.text, ScreenText.row(entry, _rules.text))
					assert_eq(" ".join(row.segments()), row.text)
					count += 1
	assert_eq(count, 2 * 5 * 4 * 4)


func test_a_row_splits_into_name_stamp_truth_and_the_feathers_word() -> void:
	var entry: EndingEntry = _entry("Hakon", true, Realm.HEL, Realm.VALHALLA, VerdictRecord.MISSED)
	var row: EndingRow = ScreenText.ending_row(entry, _rules.text)
	assert_eq(
		[
			row.name_text,
			row.verdict_text,
			row.truth_label,
			row.truth_text,
			row.record_text,
			row.cited_text
		],
		["Hakon (returned):", "Hel.", "Truth:", "Valhalla.", "Worthy, damned.", "Missed."]
	)
	var never: EndingRow = ScreenText.ending_row(
		_entry("Ragna", false, &"", Realm.FOLKVANGR, VerdictRecord.NEVER), _rules.text
	)
	assert_eq([never.name_text, never.verdict_text], ["Ragna:", "never judged."])
	assert_eq(
		[never.truth_label, never.truth_text, never.record_text, never.cited_text], ["", "", "", ""]
	)


## The record's word follows the truth (D23, D47; the critic could not read the marks alone), the
## citation's word after it; a wrong door that tips no ending has no record word.
func test_the_row_says_its_records_word_after_the_truth() -> void:
	var cases: Array = [
		[Realm.VALHALLA, Realm.VALHALLA, &"", "Ulf: Valhalla. Truth: Valhalla. Matched."],
		[
			Realm.HEL,
			Realm.VALHALLA,
			VerdictRecord.IGNORED,
			"Ulf: Hel. Truth: Valhalla. Worthy, damned. Ignored."
		],
		[
			Realm.VALHALLA,
			Realm.HEL,
			VerdictRecord.MISSED,
			"Ulf: Valhalla. Truth: Hel. Liar, admitted. Missed."
		],
		[
			Realm.FOLKVANGR,
			Realm.VALHALLA,
			VerdictRecord.MISSED,
			"Ulf: Fólkvangr. Truth: Valhalla. Missed."
		],
		[&"", Realm.HEL, VerdictRecord.NEVER, "Ulf: never judged."],
	]
	for case: Array in cases:
		var entry: EndingEntry = _entry("Ulf", false, case[0], case[1], case[2])
		assert_eq(ScreenText.row(entry, _rules.text), case[3])
		assert_eq(ScreenText.ending_row(entry, _rules.text).text, case[3])


## The record mark first (tick, frost, hollow ring; "never judged"), then the citation's feather
## (D23, D47); a wrong door that tips no ending carries no record mark.
func test_each_row_carries_its_record_mark_and_its_citation() -> void:
	var cases: Array = [
		[Realm.VALHALLA, Realm.VALHALLA, &"", EndingRow.TICK, &""],
		[Realm.HEL, Realm.VALHALLA, VerdictRecord.IGNORED, EndingRow.FROST, EndingRow.IGNORED],
		[Realm.VALHALLA, Realm.HEL, VerdictRecord.MISSED, EndingRow.HOLLOW, EndingRow.MISSED],
		[Realm.VALHALLA, Realm.FOLKVANGR, VerdictRecord.UNCERTAIN, EndingRow.HOLLOW, &""],
		[Realm.FOLKVANGR, Realm.VALHALLA, VerdictRecord.MISSED, &"", EndingRow.MISSED],
		[&"", Realm.HEL, VerdictRecord.NEVER, EndingRow.NEVER, &""],
	]
	for case: Array in cases:
		var entry: EndingEntry = _entry("Ulf", false, case[0], case[1], case[2])
		var row: EndingRow = ScreenText.ending_row(entry, _rules.text)
		assert_eq([row.mark, row.cited], [case[3], case[4]], "%s for %s" % [case[0], case[1]])


func test_the_frost_and_hollow_rows_are_the_souls_the_ending_counts() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	var report: EndingReport = desk.ending()
	var frost: int = 0
	for row: EndingRow in ScreenText.ending_rows(report, _rules):
		if row.mark == EndingRow.FROST:
			frost += 1
	assert_eq(frost, report.tide_names.size(), "one frost per soul in Hel's tide")


func _check_dusk(report: DuskReport, rules: SliceRules) -> void:
	var spreads: Array[DuskSpread] = ScreenText.dusk_spreads(report, rules)
	var words: Array[String] = []
	for spread: DuskSpread in spreads:
		for page: Array[String] in [spread.left, spread.right]:
			var lines: Array[String] = page.filter(
				func(line: String) -> bool: return line != spread.title
			)
			if lines.has(rules.text.dusk_no_citations):
				assert_gt(lines.size(), 1, "never alone on a page (day %d)" % report.day)
		words.append(spread.body())
	assert_eq("\n".join(words), "\n".join(_old_cards(report, rules)), "day %d" % report.day)


## The dusk cards as they were before the day-book: one card per block, an empty block left out.
func _old_cards(report: DuskReport, rules: SliceRules) -> Array[String]:
	var text: DeskText = rules.text
	var citations: Array[String] = [text.dusk_no_citations]
	if not report.citations.is_empty():
		citations = [text.dusk_citations_format % report.citations.size()]
		citations.append_array(report.citations)
	var quota: Array[String] = []
	if report.quota_delta >= 0:
		quota.append(text.quota_met_format % [report.quota, report.admitted, report.quota_delta])
	else:
		quota.append(text.quota_short_format % [report.quota, report.admitted, -report.quota_delta])
	quota.append(text.feathers_dawn_format % [report.feathers_at_dawn, report.feathers])
	quota.append_array(report.feather_lines)
	quota.append(text.rank_format % report.rank_name)
	var story: Array[String] = []
	for line: String in [report.story, report.returned_line]:
		if line != "":
			story.append(line)
	var cards: Array[String] = ["\n".join(citations), "\n".join(quota)]
	for block: Array[String] in [report.recap, report.requests, story]:
		if not block.is_empty():
			cards.append("\n".join(block))
	return cards


## Legal doors, the wrong door for every soul, or the worthy door.
func _choice(soul: Encounter, strategy: int) -> StringName:
	match strategy:
		1:
			return Realm.HEL if soul.legal_realm != Realm.HEL else Realm.VALHALLA
		2:
			return soul.worthy_realm
	return soul.legal_realm


func _dusk(day: int, last: StringName) -> DuskReport:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(day, 3)
	desk.stamp(last)
	desk.next_soul()
	return desk.dusk_report()


func _entry(
	soul_name: String, returned: bool, verdict: StringName, worthy: StringName, mark: StringName
) -> EndingEntry:
	var entry := EndingEntry.new()
	entry.soul_name = soul_name
	entry.returned = returned
	entry.verdict = verdict
	entry.worthy = worthy
	entry.mark = mark
	return entry
