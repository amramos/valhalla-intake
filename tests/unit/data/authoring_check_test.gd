extends GutTest
## The authoring check (plan §2.27) on the real slice: every encounter passes AuthoringChecker,
## fact coverage holds in both slot-10 branches (D6), only Ketil needs Huginn (D30), and scripted
## runs play the strict-obedience trace and every slot-10 branch to the ending (D2, D23).
## The checks themselves are proven by broken copies in authoring_check_broken_test.gd.

const Checker := preload("res://tests/unit/data/authoring_checker.gd")

var _slice: SliceData = load("res://data/slice.tres") as SliceData
var _checker: Checker = Checker.new()
var _rules: SliceRules = _slice.rules_to_core()


func _herrings() -> Dictionary:
	var herrings: Dictionary = {}
	for data: EncounterData in _all_data():
		herrings[data.id] = data.red_herrings
	return herrings


func _all_data() -> Array[EncounterData]:
	var all: Array[EncounterData] = []
	for day: DayData in _slice.days:
		all.append_array(day.encounters)
	all.append_array([_slice.returned_ignored, _slice.returned_missed, _slice.fallback])
	return all


## [Encounter, DayRules] for all 14 encounters; the slot-10 souls are judged on day 3.
func _judged() -> Array[Array]:
	var pairs: Array[Array] = []
	for day: DayData in _slice.days:
		var rules_of_day: DayRules = day.to_core()
		for data: EncounterData in day.encounters:
			pairs.append([data.to_core(), rules_of_day])
	for data: EncounterData in [_slice.returned_ignored, _slice.returned_missed, _slice.fallback]:
		pairs.append([data.to_core(), _slice.days[2].to_core()])
	return pairs


func _roster() -> Array[Encounter]:
	var souls: Array[Encounter] = []
	for day: DayData in _slice.days:
		for data: EncounterData in day.encounters:
			souls.append(data.to_core())
	return souls


func test_lines_are_measured_with_the_desk_theme_font() -> void:
	assert_true(_checker.font_loaded(), "scenes/desk/desk_theme.tres has its font")
	assert_eq(
		_checker.width_of("C1 Speared, in battle."), _checker.width_of("C1 Speared, in battle.")
	)
	assert_gt(_checker.width_of("C1 Speared, in battle."), 60)


func test_the_widest_testimony_line_fits_the_cap() -> void:
	var widest: int = 0
	var widest_line: String = ""
	for pair: Array in _judged():
		for item: EvidenceItem in (pair[0] as Encounter).items:
			if item.group != EvidenceItem.Group.BODY:
				var line: String = "%s %s" % [item.id, item.text]
				if _checker.width_of(line) > widest:
					widest = _checker.width_of(line)
					widest_line = line
	gut.p("widest testimony line: %d px (%s)" % [widest, widest_line])
	assert_lte(widest, Checker.LINE_CAP_PX)


func test_every_encounter_passes_the_authoring_check() -> void:
	var problems: Array[String] = []
	var herrings: Dictionary = _herrings()
	for pair: Array in _judged():
		var soul: Encounter = pair[0]
		var pairs: Array[String] = []
		pairs.assign(herrings[soul.id])
		problems.append_array(_checker.check_encounter(soul, pair[1], pairs, _rules))
	assert_eq(_judged().size(), 14)
	assert_eq(problems, [] as Array[String])


func test_every_fact_state_has_a_seam_and_a_red_herring_in_both_branches() -> void:
	var problems: Array[String] = []
	for branch: EncounterData in [_slice.returned_ignored, _slice.returned_missed, _slice.fallback]:
		var souls: Array[Encounter] = _roster()
		souls.append(branch.to_core())
		problems.append_array(_checker.check_coverage(souls, _roster(), _herrings()))
	assert_eq(problems, [] as Array[String])


func test_only_ketil_needs_huginn() -> void:
	var needing: Array[String] = []
	for pair: Array in _judged():
		if _checker.needs_huginn(pair[0], pair[1], _rules):
			needing.append("%s day %d" % [(pair[0] as Encounter).id, (pair[1] as DayRules).day])
	assert_eq(needing, ["ketil day 3"] as Array[String])


## Plays the run to the ending. choose(soul) picks the door; thread(soul) says whether to thread
## the seams the Law needs (Huginn's answer included) before the stamp.
func _play(desk: DeskCommands, choose: Callable, thread: Callable) -> void:
	for _step: int in range(200):
		match desk.phase():
			&"dawn":
				desk.begin_day()
			&"dusk":
				desk.next_day()
			&"desk":
				if desk.awaiting_next():
					desk.next_soul()
					continue
				var soul: Encounter = desk.current_encounter()
				if thread.call(soul):
					_thread_the_law(desk, soul)
				desk.stamp(choose.call(soul))
			_:
				return


func _thread_the_law(desk: DeskCommands, soul: Encounter) -> void:
	for seam: Seam in soul.seams:
		var result: PinResult = desk.pin(seam.a, seam.b)
		if result.kind == PinResult.Kind.THREAD and seam.kind == Seam.Kind.GREY:
			if desk.day_rules().huginn_answers > 0:
				desk.ask_huginn(desk.threads().size() - 1)


func _legal(soul: Encounter) -> StringName:
	return soul.legal_realm


func _always(_soul: Encounter) -> bool:
	return true


func _never(_soul: Encounter) -> bool:
	return false


func test_strict_obedience_reaches_hels_tide_with_the_hollow_hall_empty() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	_play(desk, _legal, _always)
	var report: EndingReport = desk.ending()
	assert_eq(report.tide_names, ["Asa", "Hakon", "Hakon"] as Array[String])
	assert_eq(report.outcome, EndingReport.TIDE)
	assert_eq(report.hollow_names.size(), 0)
	assert_eq(report.entries.size(), 12)
	assert_eq(
		report.entries[9].truth, _slice.returned_ignored.truth, "the threaded Hakon came back"
	)
	assert_eq(desk.feathers(), 13, "10, 12, 14, then one short on day 3")
	assert_eq(desk.huginn_left(), 1, "one answer, on Ketil")
	assert_eq(desk.promise_state(), &"broken")


func test_keeping_hels_promise_makes_the_tide_four() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	var keep: Callable = func(soul: Encounter) -> StringName:
		return Realm.HEL if soul.hel_marked else soul.legal_realm
	_play(desk, keep, _always)
	var report: EndingReport = desk.ending()
	assert_eq(report.tide_names, ["Asa", "Hakon", "Hakon", "Ragna"] as Array[String])
	assert_eq(desk.feathers(), 15, "13, minus the citation, plus Hel's 4")
	assert_eq(desk.promise_state(), &"kept")
	assert_eq(desk.ledger_line(), "Kept. Ragna went to Hel. Hel paid 4 feathers.")


func test_hakon_damned_unthreaded_returns_missed() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	var thread_all_but_hakon: Callable = func(soul: Encounter) -> bool: return soul.id != &"hakon"
	_play(desk, _legal, thread_all_but_hakon)
	var report: EndingReport = desk.ending()
	assert_eq(report.entries[9].soul_name, "Hakon")
	assert_eq(report.entries[9].truth, _slice.returned_missed.truth)
	assert_eq(report.entries[5].mark, VerdictRecord.MISSED)


func test_mercy_on_hakon_brings_egil_to_slot_ten() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	var spare_hakon: Callable = func(soul: Encounter) -> StringName:
		return Realm.VALHALLA if soul.id == &"hakon" else soul.legal_realm
	_play(desk, spare_hakon, _never)
	var report: EndingReport = desk.ending()
	assert_eq(report.entries[9].soul_name, "Egil")
	assert_eq(report.tide_names, ["Asa", "Egil"] as Array[String])
	assert_eq(report.outcome, EndingReport.HALL_HOLDS)


func test_every_guided_step_fits_the_mentors_bubble() -> void:
	var problems: Array[String] = []
	var guided: Array[String] = []
	for pair: Array in _judged():
		var soul: Encounter = pair[0]
		problems.append_array(_checker.check_mentor(soul, pair[1]))
		if not soul.mentor_steps.is_empty():
			guided.append(String(soul.id))
		for step: MentorStep in soul.mentor_steps:
			gut.p(
				(
					"%s: '%s' %d of %d lines"
					% [
						soul.id,
						step.text,
						_checker.bubble_lines(step.text),
						_checker.bubble_room(step)
					]
				)
			)
	assert_eq(guided, ["ulf", "kolbeinn", "hallr"] as Array[String], "D16: three guided souls")
	assert_eq(problems, [] as Array[String])
