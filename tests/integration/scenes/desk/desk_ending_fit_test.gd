extends GutTest
## The day-book's two-page fit (D23, D34, D47): every spread the slice can write lies inside its
## pages, measured on the book itself (its Labels, the desk theme's m5x7, wrapping included).
## The ending's worst case is the review's: 12 rows, each with the widest name a soul can have
## ("Hakon (returned)") and two marks (the record mark and the black feather), every column at
## its widest (the widest stamped word, "never judged", the widest truth, the widest citation
## word), the outcome naming twelve of the widest names, the widest ledger line and standing. The
## played run's own ending is measured too, so every section the real ending carries is there.
## Dusk: every dusk of three played runs, and the heaviest widened with the widest citation and
## recap lines and every feather change a day can add.

const BOOK_SCENE := preload("res://entities/day_book/day_book.tscn")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const SLICE_PATH := "res://data/slice.tres"
const REALMS: Array[StringName] = [Realm.VALHALLA, Realm.FOLKVANGR, Realm.HEL, Realm.RAN]
const CITED: Array[StringName] = [VerdictRecord.IGNORED, VerdictRecord.MISSED]
const PROMISES: Array[StringName] = [
	RunState.PROMISE_OPEN, RunState.PROMISE_KEPT, RunState.PROMISE_BROKEN, RunState.PROMISE_LAPSED
]
## More feathers than a slice run can hold: a wider number than any real standing.
const MOST_FEATHERS := 999
const SCREEN := Rect2i(0, 0, 480, 270)

var _book: DayBook = null
var _rules: SliceRules = null
var _heading: String = ""


func before_each() -> void:
	var host := Control.new()
	host.theme = THEME
	host.size = Vector2(480, 270)
	add_child_autofree(host)
	_book = BOOK_SCENE.instantiate() as DayBook
	_book.write_cps = INF
	host.add_child(_book)
	_rules = SliceLoader.load_slice().slice_rules()


func test_the_played_ending_and_the_worst_ending_fit_the_last_spread() -> void:
	var played: DeskCommands = _played_run()
	assert_eq(played.phase(), RunState.ENDING, "the debug jump played the run to its ending")
	assert_eq(played.ending().entries.size(), 12, "the slice judges twelve encounters")
	_show(played.ending(), played.ending().outcome)
	_assert_fits("the ending as played")
	for outcome: StringName in [EndingReport.TIDE, EndingReport.HOLLOW, EndingReport.HALL_HOLDS]:
		var worst: EndingReport = _worst_ending(played, outcome)
		_show(worst, outcome)
		_assert_fits("the worst %s ending" % outcome)
		gut.p("worst %s: book %s" % [outcome, _book.book_rect()])


## The rows' columns: the widest name, two marks, every column at its widest, on one page each.
func test_the_worst_rows_carry_two_marks_and_the_widest_words() -> void:
	var worst: EndingReport = _worst_ending(_played_run(), EndingReport.TIDE)
	_show(worst, EndingReport.TIDE)
	var rows: Array[EndingRow] = ScreenText.ending_rows(worst, _rules)
	var two_marks: int = 0
	for row: EndingRow in rows:
		assert_eq(row.name, "Hakon (returned)", "the widest name on every row")
		if row.cited != &"" and row.mark in [EndingRow.FROST, EndingRow.HOLLOW]:
			two_marks += 1
	assert_gt(two_marks, 0, "rows with the record mark and the black feather (D47)")
	assert_eq(_book.right_page().mark_positions(&"feather").size(), _count_cited(rows))
	assert_true(_book.fits())


func test_every_played_dusk_and_the_heaviest_widened_fit_their_spreads() -> void:
	var heaviest: DuskReport = null
	var citations: Array[String] = []
	var recaps: Array[String] = []
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
					var report: DuskReport = desk.dusk_report()
					_assert_dusk_fits(report, "day %d, run %d" % [report.day, strategy])
					citations.append_array(report.citations)
					recaps.append_array(report.recap)
					if heaviest == null or _weight(report) > _weight(heaviest):
						heaviest = report
					if desk.phase() == RunState.ENDING:
						break
					desk.next_day()
	assert_gt(heaviest.citations.size(), 2, "a heavy day was played")
	_assert_dusk_fits(_widened(heaviest, citations, recaps), "the heaviest dusk, widened")


func _assert_fits(what: String) -> void:
	var book: Rect2i = _book.book_rect()
	assert_true(SCREEN.encloses(book.grow(2)), "%s: the book and its board on the screen" % what)
	assert_true(_book.fits(), "%s: every line inside its page" % what)
	var play: Rect2 = _book.next_button().get_global_rect()
	assert_true(Rect2(book).encloses(play), "%s: Play again on the page" % what)
	var rows_top: int = _rows_top()
	assert_lte(int(play.end.y), book.position.y + rows_top, "%s: above the rows" % what)
	var heading_room: int = int(_book.left_page().size.x) - 2 * DayBookLayout.MARGIN_X
	assert_lte(PixelCapitals.width(_heading), heading_room, "%s: the carved heading" % what)


func _assert_dusk_fits(report: DuskReport, what: String) -> void:
	for spread: DuskSpread in ScreenText.dusk_spreads(report, _rules):
		_book.show_spread(spread, _rules.text.next_label, _rules.text.skip_all_label)
		var book: Rect2i = _book.book_rect()
		assert_true(_book.fits(), "%s: every line inside its page" % what)
		assert_true(SCREEN.encloses(book.grow(2)), "%s: on the screen" % what)
		var skip: Rect2 = _book.skip_button().get_global_rect()
		assert_true(Rect2(SCREEN).encloses(skip), "%s: the Skip all tag on the screen" % what)
		var next: Rect2 = _book.next_button().get_global_rect()
		assert_true(Rect2(book).encloses(next), "%s: the dog-ear on the page" % what)
	_book.close()


## The worst ending for `outcome`, from the played run's own report (every section it carries).
func _worst_ending(played: DeskCommands, outcome: StringName) -> EndingReport:
	var report: EndingReport = played.ending()
	report.outcome = outcome
	var rows: Array[EndingEntry] = _widest_rows()
	for index: int in range(report.entries.size()):
		_widen(report.entries[index], rows[index % rows.size()])
	report.promise_line = _widest_promise()
	report.feathers = MOST_FEATHERS
	report.rank_name = _widest(_rules.rank_names)
	return report


func _show(report: EndingReport, outcome: StringName) -> void:
	var lines: Array[String] = ScreenText.ending_lines(report, _rules)
	_heading = lines[0]
	var outcome_lines: Array[String] = [lines[1]]
	if outcome != EndingReport.HALL_HOLDS:
		# Every row's name in the outcome, as if all twelve tipped it.
		var names: Array[String] = []
		for entry: EndingEntry in report.entries:
			names.append(ScreenText.display_name(entry, _rules.text))
		var format: String = (
			_rules.text.tide_format if outcome == EndingReport.TIDE else _rules.text.hollow_format
		)
		outcome_lines = [format % ", ".join(names)]
	_book.close()
	_book.show_ending(
		PhaseFlow.tableau_for(outcome),
		ScreenText.ending_rows(report, _rules),
		lines[0],
		outcome_lines,
		report.promise_line,
		lines[-1],
		_rules.text.play_again,
		ScreenText.ending_headers(_rules)
	)
	_book.finish_writing()


## Rows that put every column at its widest, each with the widest name: the widest two-mark rows
## (a wrong door to Hel or Valhalla with a citation), the widest stamped word, "never judged".
func _widest_rows() -> Array[EndingEntry]:
	var candidates: Array[EndingEntry] = []
	for verdict: StringName in REALMS + ([&""] as Array[StringName]):
		for worthy: StringName in REALMS:
			for mark: StringName in CITED:
				if verdict == worthy:
					continue
				var entry := EndingEntry.new()
				entry.soul_name = "Hakon"
				entry.returned = true
				entry.verdict = verdict
				entry.worthy = worthy
				entry.mark = mark if verdict != &"" else VerdictRecord.NEVER
				candidates.append(entry)
	var rows: Array[EndingEntry] = []
	for field: StringName in [
		&"verdict_text", &"truth_text", &"record_text", &"cited_text", &"text"
	]:
		rows.append(_widest_by(candidates, field, false))
		rows.append(_widest_by(candidates, field, true))
	return rows


## The candidate whose row is widest in `field`; with `two_marks`, among rows with two marks.
func _widest_by(candidates: Array[EndingEntry], field: StringName, two_marks: bool) -> EndingEntry:
	var best: EndingEntry = null
	var best_width: float = -1.0
	for entry: EndingEntry in candidates:
		var row: EndingRow = ScreenText.ending_row(entry, _rules.text)
		if two_marks and not (row.cited != &"" and row.mark in [EndingRow.FROST, EndingRow.HOLLOW]):
			continue
		var width: float = _width(String(row.get(field)))
		if width > best_width:
			best = entry
			best_width = width
	return best


func _widen(entry: EndingEntry, widest: EndingEntry) -> void:
	entry.soul_name = widest.soul_name
	entry.returned = widest.returned
	entry.verdict = widest.verdict
	entry.worthy = widest.worthy
	entry.mark = widest.mark


## The heaviest dusk with its citations and recap lines as wide as any played, and every feather
## change a day can add on top of its own.
func _widened(report: DuskReport, citations: Array[String], recaps: Array[String]) -> DuskReport:
	var widest_citation: String = _widest(citations)
	for index: int in range(report.citations.size()):
		report.citations[index] = widest_citation
	var widest_recap: String = _widest(recaps)
	for index: int in range(report.recap.size()):
		report.recap[index] = widest_recap
	var text: DeskText = _rules.text
	report.feather_lines.append(text.feather_huginn_format % 2)
	report.feather_lines.append(text.feather_hel_format % 4)
	report.feather_lines.append(text.demoted_format % [_widest(_rules.rank_names), 10])
	return report


func _weight(report: DuskReport) -> int:
	return report.citations.size() * 10 + report.feather_lines.size()


func _rows_top() -> int:
	var tops: Array[Vector2i] = _book.right_page().mark_positions(&"feather")
	return tops[0].y - 1 if not tops.is_empty() else 0


func _count_cited(rows: Array[EndingRow]) -> int:
	var count: int = 0
	for row: EndingRow in rows:
		count += 1 if row.cited != &"" else 0
	return count


func _choice(soul: Encounter, strategy: int) -> StringName:
	match strategy:
		1:
			return Realm.HEL if soul.legal_realm != Realm.HEL else Realm.VALHALLA
		2:
			return soul.worthy_realm
	return soul.legal_realm


func _played_run() -> DeskCommands:
	var desk: DeskCommands = SliceLoader.load_slice()
	desk.debug_jump(3, 99)
	return desk


func _encounters() -> Array[Encounter]:
	var data: SliceData = load(SLICE_PATH) as SliceData
	var found: Array[Encounter] = []
	for day: DayData in data.days:
		for encounter: EncounterData in day.encounters:
			found.append(encounter.to_core())
	for variant: EncounterData in [data.returned_ignored, data.returned_missed, data.fallback]:
		if variant != null:
			found.append(variant.to_core())
	return found


## The widest ledger line Hel's promise can end on, for any soul and door.
func _widest_promise() -> String:
	var lines: Array[String] = []
	for encounter: Encounter in _encounters():
		for state: StringName in PROMISES:
			for realm: StringName in REALMS:
				lines.append(Ledger.line(state, encounter.soul_name, realm, _rules))
	return _widest(lines)


func _widest(texts: Array[String]) -> String:
	var best: String = ""
	for text: String in texts:
		if _width(text) > _width(best):
			best = text
	return best


func _width(text: String) -> float:
	var font: Font = _book.get_theme_default_font()
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
