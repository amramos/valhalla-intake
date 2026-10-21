extends GutTest
## The authoring check's own proof: each check fails on a copy of the real data with one
## deliberate fault (the checks run clean on the real slice in authoring_check_test.gd).

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


func _roster() -> Array[Encounter]:
	var souls: Array[Encounter] = []
	for day: DayData in _slice.days:
		for data: EncounterData in day.encounters:
			souls.append(data.to_core())
	return souls


func _broken(id: StringName) -> Encounter:
	for data: EncounterData in _all_data():
		if data.id == id:
			return data.to_core()
	return null


func _problems(soul: Encounter, day_index: int, herrings: Array[String] = []) -> String:
	var day: DayRules = _slice.days[day_index].to_core()
	return "\n".join(_checker.check_encounter(soul, day, herrings, _rules))


func test_a_wrong_stamp_without_a_visible_pair_fails() -> void:
	var grim: Encounter = _broken(&"grim")
	grim.seams.clear()
	assert_string_contains(_problems(grim, 1), "a stamp to valhalla has no visible pair to cite")


func test_a_closed_worthy_door_fails() -> void:
	assert_string_contains(_problems(_broken(&"egil"), 1), "the folkvangr door is closed")


func test_a_law_caption_naming_the_wrong_realm_fails() -> void:
	var ulf: Encounter = _broken(&"ulf")
	ulf.seams[0].destination = Realm.HEL
	ulf.seams[0].caption = "the saga is true. L1 sends him to Hel."
	var problems: String = _problems(ulf, 0)
	assert_string_contains(problems, "but L1 sends to valhalla (D44)")
	assert_string_contains(problems, "(R2, R3)")


func test_a_caption_stating_precedence_fails() -> void:
	var egil: Encounter = _broken(&"egil")
	egil.seams[2].caption = "L5 sends him to Fólkvangr, but L2 rules."
	assert_string_contains(_problems(egil, 2), "(R2, R3)")


func test_a_law_thread_from_a_lie_or_a_grey_line_fails() -> void:
	var kolbeinn: Encounter = _broken(&"kolbeinn")
	kolbeinn.seams.append(
		Seam.make(
			"C1", "L1", Seam.Kind.LAW, Seam.Liar.NONE, Realm.VALHALLA, "L1 sends him to Valhalla."
		)
	)
	assert_string_contains(_problems(kolbeinn, 0), "(R4)")
	var grim: Encounter = _broken(&"grim")
	grim.seams.append(
		Seam.make("W1", "L4", Seam.Kind.LAW, Seam.Liar.NONE, Realm.HEL, "L4 sends him to Hel.")
	)
	assert_string_contains(_problems(grim, 1), "(R5)")


func test_a_law_thread_on_a_grey_only_soul_fails() -> void:
	var ketil: Encounter = _broken(&"ketil")
	ketil.seams.append(
		Seam.make(
			"C1", "L1", Seam.Kind.LAW, Seam.Liar.NONE, Realm.VALHALLA, "L1 sends him to Valhalla."
		)
	)
	assert_string_contains(_problems(ketil, 2), "(R6)")


func test_an_unprefixed_law_thread_without_a_red_seam_fails() -> void:
	var asa: Encounter = _broken(&"asa")
	asa.liar = true
	asa.seams[0].caption = "L3 sends her to Hel."
	assert_string_contains(_problems(asa, 0), "(R7)")


func test_a_law_thread_on_evidence_that_cant_show_its_condition_fails() -> void:
	var ulf: Encounter = _broken(&"ulf")
	ulf.seams.append(
		Seam.make(
			"B3",
			"L3",
			Seam.Kind.LAW,
			Seam.Liar.NONE,
			Realm.HEL,
			"the saga is true. L3 sends him to Hel."
		)
	)
	assert_string_contains(_problems(ulf, 0), "(R1)")


func test_a_line_over_132_px_fails() -> void:
	var asa: Encounter = _broken(&"asa")
	asa.item("C4").text = "My girl has the farm and the goats."
	assert_string_contains(_problems(asa, 0), "C4 is")
	assert_string_contains(_problems(asa, 0), "over 132 (D50)")


func test_a_red_herring_that_is_a_seam_fails() -> void:
	var herrings: Array[String] = ["B1|C1"]
	assert_string_contains(
		_problems(_broken(&"kolbeinn"), 0, herrings), "is not a no-seam pin (D24)"
	)


func test_a_fact_state_without_a_red_herring_fails() -> void:
	var herrings: Dictionary = _herrings()
	herrings[&"ragna"] = ["B5|C2", "B1|C2", "B2|C2", "C4|L1"]
	var souls: Array[Encounter] = _roster()
	var problems: Array[String] = _checker.check_coverage(souls, souls, herrings)
	assert_eq(problems, ["fact state 'broken neck' has no red-herring use (D6)"] as Array[String])


func test_a_mentor_step_too_long_for_the_bubble_fails() -> void:
	var ulf: Encounter = _broken(&"ulf")
	ulf.mentor_steps[0].text = "Read the body first, every mark of it, front and back, then the claim."
	var problems: String = "\n".join(_checker.check_mentor(ulf, _slice.days[0].to_core()))
	assert_string_contains(problems, "the bubble holds")


func test_a_witness_heading_too_wide_for_its_panel_fails() -> void:
	var sigvaldi: Encounter = _broken(&"sigvaldi")
	sigvaldi.witness_name = "Bjornolfr Thorgrimsson Longbeard, his shield-brother"
	var problems: String = "\n".join(_checker.check_witness_heading(sigvaldi))
	assert_string_contains(
		problems, "the witness heading 'WITNESS Bjornolfr Thorgrimsson Longbeard'"
	)
