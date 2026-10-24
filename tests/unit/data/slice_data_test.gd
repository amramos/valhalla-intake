extends GutTest
## The slice's data as the evidence matrix and the ledger write it: tunables, the three days
## (D10, D28, D30, D34, D35), the decrees word for word (D32), the queues and the slot-10
## variants (D2, D22, D46), and the shared text of matrix section A.

const L1 := (
	"Valhalla takes only those slain by a weapon in battle. "
	+ "Death by sickness, age or accident goes to Hel."
)
const L2 := "Whoever lies to the Gate goes to Hel, whatever else the Law says."
const L3 := "Even so, a warrior without a weapon in hand goes to Hel."
const L4 := "Even so, those who fled the battle go to Hel."
## Any evidence id in displayed text. A raw string: in a plain one "\b" is a backspace.
const ID_PATTERN := r"\b[BCWL][0-9]+\b"
const L5 := "Those who fell defending hearth and kin go to Fólkvangr, whatever I, III and IV say."

var _slice: SliceData = load("res://data/slice.tres") as SliceData


func _days() -> Array[DayRules]:
	var days: Array[DayRules] = []
	for day: DayData in _slice.days:
		days.append(day.to_core())
	return days


func _soul(id: StringName) -> Encounter:
	for day: DayData in _slice.days:
		for encounter: EncounterData in day.encounters:
			if encounter.id == id:
				return encounter.to_core()
	return null


func _queue(day: DayData) -> Array[String]:
	var names: Array[String] = []
	for encounter: EncounterData in day.encounters:
		names.append(String(encounter.id))
	return names


func test_the_slice_holds_the_tunables() -> void:
	var rules: SliceRules = _slice.rules_to_core()
	var values: Array = [
		rules.start_feathers,
		rules.quota_met_reward,
		rules.quota_short_cost,
		rules.citation_cost,
		rules.daily_loss_cap,
		rules.demote_refill,
		rules.no_seam_seconds,
		rules.huginn_seconds,
		rules.huginn_extra_cost,
		rules.hel_reward,
		rules.tide_threshold,
		rules.hollow_threshold,
		rules.clock_warning_seconds,
	]
	assert_eq(values, [10, 2, 1, 2, 5, 5, 10.0, 5.0, 2, 4, 3, 2, 30.0])
	assert_eq(rules.liar_decree_id, "L2")
	assert_eq(rules.liar_realm, Realm.HEL)
	assert_eq(rules.rank_names.size(), 3)


func test_the_three_days_follow_the_desk_per_day_table() -> void:
	var days: Array[DayRules] = _days()
	var summary: Array = []
	for day: DayRules in days:
		summary.append(
			[
				day.day,
				day.quota,
				day.clock_seconds,
				day.citations,
				day.huginn_answers,
				day.return_slot
			]
		)
	assert_eq(
		summary, [[1, 1, 0.0, false, 0, -1], [2, 1, 300.0, true, 0, -1], [3, 2, 300.0, true, 2, 1]]
	)
	assert_eq(days[0].doors_open, [Realm.VALHALLA, Realm.HEL] as Array[StringName])
	assert_eq(days[1].doors_open, [Realm.VALHALLA, Realm.HEL] as Array[StringName])
	assert_eq(days[2].doors_open, [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR] as Array[StringName])
	assert_eq(days[1].new_decree_ids, ["L4"] as Array[String])
	assert_eq(days[2].new_decree_ids, ["L5"] as Array[String])
	assert_eq(days[2].new_doors, [Realm.FOLKVANGR] as Array[StringName])
	assert_string_contains(days[1].dusk_story, "Father's ring is mine now.")
	for day: DayRules in days:
		assert_eq(day.dawn_lines[0], "Day %d." % day.day)


func test_the_decrees_are_word_for_word_and_arrive_one_a_day() -> void:
	var texts: Array[String] = []
	for decree: EvidenceItem in _days()[2].decrees:
		texts.append("%s %s" % [decree.id, decree.text])
	assert_eq(texts, ["L1 " + L1, "L2 " + L2, "L3 " + L3, "L4 " + L4, "L5 " + L5] as Array[String])
	assert_eq([_days()[0].decrees.size(), _days()[1].decrees.size()], [3, 4])


func test_the_queues_run_in_roster_order() -> void:
	assert_eq(_queue(_slice.days[0]), ["ulf", "kolbeinn", "hallr", "asa"] as Array[String])
	assert_eq(_queue(_slice.days[1]), ["sigvaldi", "hakon", "grim", "brand"] as Array[String])
	assert_eq(_queue(_slice.days[2]), ["freydis", "ragna", "ketil"] as Array[String])
	assert_eq(
		[_slice.returned_ignored.id, _slice.returned_missed.id, _slice.fallback.id],
		[&"hakon_ignored", &"hakon_missed", &"egil"]
	)


func test_ulf_and_kolbeinn_read_as_the_matrix_writes_them() -> void:
	var ulf: Encounter = _soul(&"ulf")
	assert_eq(ulf.item("C1").text, "Speared, in battle.")
	assert_eq(ulf.item("C4").text, "Sif gets the goat.")
	assert_eq(ulf.item("B1").text, "spear wound, chest")
	assert_eq(ulf.seams[0].caption, "the saga is true. Decree I sends him to Valhalla.")
	var kolbeinn: Encounter = _soul(&"kolbeinn")
	assert_eq(kolbeinn.item("C1").text, "Danes axed my chest.")
	assert_eq(kolbeinn.item("B4").text, "night-shirt only, bare feet")
	assert_eq(kolbeinn.seams.size(), 4)
	assert_eq(kolbeinn.seams[0].pair_text, "No wound on his chest, and 'Danes axed my chest'")


func test_the_marked_and_returned_souls_carry_their_name_plates() -> void:
	var ragna: Encounter = _soul(&"ragna")
	assert_true(ragna.hel_marked)
	assert_eq(ragna.plate_label, "Hel asked for her")
	assert_eq(ragna.pronoun, "her")
	for variant: EncounterData in [_slice.returned_ignored, _slice.returned_missed]:
		var hakon: Encounter = variant.to_core()
		assert_true(hakon.returned)
		assert_eq(hakon.plate_label, "Back from Hel. His saga was true.")
		assert_eq(hakon.witness_note, "No witness came back.")
		assert_eq(hakon.items_in(EvidenceItem.Group.WITNESS).size(), 0)
	assert_true(_soul(&"hakon").return_eligible)


func test_every_body_fact_has_a_view_and_a_hit_area() -> void:
	var missing: Array[String] = []
	var all: Array[EncounterData] = [
		_slice.returned_ignored, _slice.returned_missed, _slice.fallback
	]
	for day: DayData in _slice.days:
		all.append_array(day.encounters)
	for data: EncounterData in all:
		for fact: EvidenceItem in data.to_core().items_in(EvidenceItem.Group.BODY):
			if fact.view not in [&"front", &"back"] or fact.place == &"":
				missing.append("%s %s" % [data.id, fact.id])
	assert_eq(missing, [] as Array[String])
	assert_eq(all.size(), 14, "the 14 authored encounters")


func test_the_shared_text_is_section_a() -> void:
	var rules: SliceRules = _slice.rules_to_core()
	assert_eq(rules.citation_format, "Citation: %s. %s.")
	assert_eq(rules.huginn_claim_answer, "Huginn: the claim lies.")
	assert_eq(rules.text.no_seam_timed_format % 10, "No seam between those two. -10 s")
	assert_eq(rules.text.hall_title, "The Hall holds")
	assert_string_contains(rules.hel_offer_format % "Ragna", "Tomorrow Ragna comes to your desk.")
	assert_eq(rules.ledger_open_format % ["Ragna", 4], "Hel: send Ragna to Hel. 4 feathers.")


func test_desk_text_data_carries_every_desk_text_field() -> void:
	var missing: Array[String] = []
	var data := DeskTextData.new()
	for property: Dictionary in DeskText.new().get_property_list():
		var key: String = property["name"]
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not key in data:
			missing.append(key)
	assert_eq(missing, [] as Array[String])
	assert_eq(_slice.desk_text.to_core().standing_format, "Feathers: %d. Rank: %s.")


## The generator names every subresource, so a rebuild never renames one in the .tres diff (the
## review's case: the desk text was saved under an engine-generated "Resource_" id).
func test_every_generated_subresource_has_a_named_id() -> void:
	var unnamed: Array[String] = []
	var subresources: Array[Resource] = [_slice.desk_text]
	for day: DayData in _slice.days:
		for data: EncounterData in day.encounters:
			subresources.append_array(data.body)
			subresources.append_array(data.seams)
			subresources.append_array(data.mentor_steps)
	for resource: Resource in subresources:
		var id: String = resource.resource_scene_unique_id
		if id == "" or id.begins_with("Resource_"):
			unnamed.append("%s %s" % [resource.get_class(), id])
	assert_eq(unnamed, [] as Array[String])
	assert_eq(_slice.desk_text.resource_scene_unique_id, "desk_text")


func test_the_loader_returns_a_desk_at_day_one_dawn() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	assert_eq([desk.phase(), desk.day_number(), desk.feathers()], [&"dawn", 1, 10])
	desk.begin_day()
	assert_eq(desk.current_encounter().soul_name, "Ulf")
	assert_eq(desk.pin("L1", "C1").kind, PinResult.Kind.THREAD)
	assert_true(desk.stamp(Realm.VALHALLA).correct)
	assert_eq(desk.current_encounter().soul_name, "Kolbeinn")


func test_the_three_guided_souls_carry_the_mentors_script() -> void:
	var texts: Array[String] = []
	for id: StringName in [&"ulf", &"kolbeinn", &"hallr"]:
		var soul: Encounter = _soul(id)
		var untils: Array = []
		for step: MentorStep in soul.mentor_steps:
			untils.append(step.until)
			texts.append(step.text)
		assert_eq(
			untils,
			[
				MentorStep.Until.READ,
				MentorStep.Until.READ,
				MentorStep.Until.PIN,
				MentorStep.Until.STAMP
			],
			String(id)
		)
	assert_eq(texts.size(), 12)
	assert_eq(texts[0], "Hover each mark.")
	assert_eq(texts[11], "Where does a liar go?")
	var hallr: Encounter = _soul(&"hallr")
	assert_eq(hallr.mentor_steps[2].highlight, ["B1", "C3"] as Array[String])
	assert_eq(
		hallr.mentor_steps[0].highlight,
		["B1", "B2", "B3", "B4", "C1", "C2", "C3", "C4"] as Array[String]
	)
	assert_eq(_soul(&"ulf").mentor_steps[3].door, Realm.VALHALLA)
	assert_eq(_soul(&"asa").mentor_steps.size(), 0)
	assert_eq(_slice.rules_to_core().mentor_promise_format, "%s. Hel pays well.")


func test_the_dawn_cards_explain_the_tide_and_what_a_citation_needs() -> void:
	# D53, from the WP6 playtest.
	var days: Array[DayRules] = _days()
	assert_true(
		(
			days[0]
			. dawn_lines
			. has(
				"Send a worthy soul to Hel and they join her tide. At three, they break the line at Ragnarok."
			)
		)
	)
	assert_true(
		days[1].dawn_lines.has(
			"Citations begin today: 2 feathers for any stamp against what the desk can show you."
		)
	)
	assert_eq(_slice.rules_to_core().mentor_tide_line, "The Law is kept. Hel's tide grows by one.")


## The id detector below finds every kind of id and nothing that merely starts with B, C, W, L.
func test_the_id_detector_finds_ids_and_only_ids() -> void:
	var ids := RegEx.create_from_string(ID_PATTERN)
	var found: Array[String] = []
	for text: String in [
		"Citation: L2.", "C1 against L1", "His W2.", "B4 and L3", "decree II", "Bersi", "Loki", "W"
	]:
		if ids.search(text) != null:
			found.append(text)
	assert_eq(found, ["Citation: L2.", "C1 against L1", "His W2.", "B4 and L3"] as Array[String])


## D6: the player never reads an id. Every authored text the desk, the dawn card or the dusk
## shows names decrees by their numerals and lines by their words; only ids and commands keep them.
func test_no_displayed_text_names_an_id() -> void:
	var ids := RegEx.create_from_string(ID_PATTERN)
	var texts: Array[String] = []
	var souls: Array[EncounterData] = [
		_slice.returned_ignored, _slice.returned_missed, _slice.fallback
	]
	for day: DayData in _slice.days:
		texts.append_array(day.dawn_lines)
		texts.append(day.dusk_story)
		for decree: DecreeData in day.decrees:
			texts.append(decree.text)
		souls.append_array(day.encounters)
	for data: EncounterData in souls:
		var soul: Encounter = data.to_core()
		texts.append_array([soul.plate_label, soul.witness_note, soul.truth])
		for seam: Seam in soul.seams:
			texts.append_array([seam.caption, seam.pair_text])
		for step: MentorStep in soul.mentor_steps:
			texts.append(step.text)
		for item: EvidenceItem in soul.items:
			texts.append(item.text)
	var leaks: Array[String] = []
	for text: String in texts:
		if ids.search(text) != null:
			leaks.append(text)
	assert_gt(texts.size(), 200)
	assert_eq(leaks, [] as Array[String])
