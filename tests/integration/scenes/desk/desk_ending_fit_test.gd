extends GutTest
## The ending card's worst case, measured the way PhaseCard lays it out: its own Label, the desk
## theme's m5x7 font, ENDING_WIDTH, wrapping included. The report is the real one, from
## DeskCommands.ending() after a full run, so any section the ending really carries is measured
## (the review's case: a hand-built report missed one). Then every piece is widened to the widest
## the slice's data can make, composed by ScreenText: the outcome naming the widest name for every
## encounter, every row as wide as any row can be, the widest ledger line and the widest standing.
## The card must fit PhaseCard's height clamp with its button row.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const SLICE_PATH := "res://data/slice.tres"
const REALMS: Array[StringName] = [Realm.VALHALLA, Realm.FOLKVANGR, Realm.HEL, Realm.RAN]
const MARKS: Array[StringName] = [&"", VerdictRecord.IGNORED, VerdictRecord.MISSED]
const PROMISES: Array[StringName] = [
	RunState.PROMISE_OPEN, RunState.PROMISE_KEPT, RunState.PROMISE_BROKEN, RunState.PROMISE_LAPSED
]
## More feathers than a slice run can hold: a wider number than any real standing.
const MOST_FEATHERS := 999
## PhaseFlow.ending_text's blank line between sections.
const SECTION_GAP := "\n\n"

var _desk: Desk = null
var _card: PhaseCard = null
var _label: Label = null
var _rules: SliceRules = null


func before_each() -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	add_child_autofree(_desk)
	_card = _desk.system().phase_card
	_label = _card.get_node("Text") as Label
	_rules = _desk.commands().slice_rules()


func test_the_longest_possible_ending_fits_the_card_with_its_button_row() -> void:
	var played: DeskCommands = _played_run()
	assert_eq(played.phase(), RunState.ENDING, "the debug jump played the run to its ending")
	var slots: int = played.ending().entries.size()
	assert_eq(slots, 12, "the slice judges twelve encounters")
	var limit: float = PhaseCard.SCREEN.y - 4.0
	var as_played: float = _card_height(PhaseFlow.ending_text(played.ending(), _rules))
	assert_lte(as_played, limit, "the ending as played fits the card's height clamp")
	var worst: String = ""
	var worst_height: float = 0.0
	for outcome: StringName in [EndingReport.TIDE, EndingReport.HOLLOW, EndingReport.HALL_HOLDS]:
		var text: String = _worst_ending(played, outcome)
		var height: float = _card_height(text)
		if height > worst_height:
			worst = text
			worst_height = height
	gut.p("worst-case ending: %d lines, %.0f px of %.0f" % [_lines(worst), worst_height, limit])
	_card.show_card(worst, _rules.text.play_again, "", PhaseFlow.ENDING_WIDTH)
	assert_eq(_card.size.y, worst_height, "measured as PhaseCard sizes itself")
	assert_lte(worst_height, limit, "the worst-case ending fits the card's height clamp")
	var pitch: int = _label.get_line_height() + _label.get_theme_constant(&"line_spacing")
	assert_eq(pitch, PhaseCard.LINE_PITCH, "the label's real line pitch is PhaseCard's")
	var lines: int = _lines(worst)
	var button_top: float = _card.next_button().position.y
	var text_bottom: float = PhaseCard.PADDING + lines * PhaseCard.LINE_PITCH
	assert_lte(text_bottom, button_top, "the text ends above the button row")


## A full run played to its ending: every soul stamped to its legal realm.
func _played_run() -> DeskCommands:
	var desk: DeskCommands = SliceLoader.load_slice()
	desk.debug_jump(3, 99)
	return desk


## The full card text for `outcome`, composed by ScreenText from the played run's own ending reports
## (so every section the real ending carries is measured), each widened to its worst case.
func _worst_ending(played: DeskCommands, outcome: StringName) -> String:
	var name_owner: Encounter = _widest_name_owner()
	var named: EndingReport = played.ending()
	named.outcome = outcome
	for entry: EndingEntry in named.entries:
		if outcome == EndingReport.HOLLOW:
			_widen(entry, _entry(name_owner, Realm.VALHALLA, Realm.HEL, &""))
		else:
			_widen(entry, _entry(name_owner, Realm.HEL, Realm.VALHALLA, &""))
	var rows: EndingReport = played.ending()
	var widest_row: EndingEntry = _widest_row()
	for entry: EndingEntry in rows.entries:
		_widen(entry, widest_row)
	rows.promise_line = _widest_promise()
	rows.feathers = MOST_FEATHERS
	rows.rank_name = _widest(_rules.rank_names)
	var sections: Array[String] = ScreenText.ending_sections(rows, _rules)
	assert_eq(sections.size(), 4, "outcome, rows, ledger, standing")
	assert_eq(PhaseFlow.ending_text(rows, _rules), SECTION_GAP.join(sections), "PhaseFlow's join")
	sections[0] = ScreenText.ending_sections(named, _rules)[0]
	return SECTION_GAP.join(sections)


## Gives a real report's `entry` the name, verdict, truth and mark of `widest`; the rest stays.
func _widen(entry: EndingEntry, widest: EndingEntry) -> void:
	entry.soul_name = widest.soul_name
	entry.returned = widest.returned
	entry.verdict = widest.verdict
	entry.worthy = widest.worthy
	entry.mark = widest.mark


## The card's height as PhaseCard computes it, before its clamp.
func _card_height(text: String) -> float:
	return (
		PhaseCard.PADDING
		+ _lines(text) * PhaseCard.LINE_PITCH
		+ PhaseCard.GAP
		+ PhaseCard.BUTTON_HEIGHT
		+ PhaseCard.PADDING
	)


func _lines(text: String) -> int:
	_card.show_card(text, _rules.text.play_again, "", PhaseFlow.ENDING_WIDTH)
	return maxi(1, _label.get_line_count())


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


func _entry(
	encounter: Encounter, verdict: StringName, worthy: StringName, mark: StringName
) -> EndingEntry:
	var entry := EndingEntry.new()
	entry.soul_name = encounter.soul_name
	entry.returned = encounter.returned
	entry.verdict = verdict
	entry.worthy = worthy
	entry.mark = mark
	return entry


## The encounter whose name, as the ending shows it ("Hakon (returned)"), is widest.
func _widest_name_owner() -> Encounter:
	var best: Encounter = null
	var best_width: float = -1.0
	for encounter: Encounter in _encounters():
		var entry: EndingEntry = _entry(encounter, &"", &"", &"")
		var width: float = _width(ScreenText.display_name(entry, _rules.text))
		if width > best_width:
			best = encounter
			best_width = width
	return best


## The widest row any encounter can have: every verdict (or none), worthy realm and mark.
func _widest_row() -> EndingEntry:
	var best: EndingEntry = null
	var best_width: float = -1.0
	for encounter: Encounter in _encounters():
		for verdict: StringName in REALMS + ([&""] as Array[StringName]):
			for worthy: StringName in REALMS:
				for mark: StringName in MARKS:
					var entry: EndingEntry = _entry(encounter, verdict, worthy, mark)
					var width: float = _width(ScreenText.row(entry, _rules.text))
					if width > best_width:
						best = entry
						best_width = width
	return best


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
	var font: Font = _label.get_theme_font(&"font")
	var size: int = _label.get_theme_font_size(&"font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
