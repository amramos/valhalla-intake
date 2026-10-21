extends GutTest
## The WP1 data: the slice's tunables, day 1 with L1-L3 word for word (D32), and Ulf and Kolbeinn
## as the evidence matrix writes them.

const L1 := (
	"Valhalla takes only those slain by a weapon in battle. "
	+ "Death by sickness, age or accident goes to Hel."
)
const L2 := "Whoever lies to the Gate goes to Hel, whatever else the Law says."
const L3 := "Even so, a warrior without a weapon in hand goes to Hel."

var _slice: SliceData = load("res://data/slice.tres") as SliceData


func _soul(id: StringName) -> Encounter:
	for encounter: EncounterData in _slice.days[0].encounters:
		if encounter.id == id:
			return encounter.to_core()
	return null


func _seam_pairs(soul: Encounter) -> Array[String]:
	var pairs: Array[String] = []
	for seam: Seam in soul.seams:
		pairs.append("%s-%s:%d" % [seam.a, seam.b, seam.kind])
	return pairs


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


func test_day_one_is_untimed_with_valhalla_and_hel_and_no_citations() -> void:
	var day: DayRules = _slice.days[0].to_core()
	assert_eq([day.day, day.quota, day.clock_seconds], [1, 1, 0.0])
	assert_eq(day.doors_open, [Realm.VALHALLA, Realm.HEL] as Array[StringName])
	assert_false(day.citations)
	assert_eq(day.huginn_answers, 0)


func test_day_one_decrees_are_word_for_word() -> void:
	var day: DayRules = _slice.days[0].to_core()
	var texts: Array[String] = []
	for decree: EvidenceItem in day.decrees:
		texts.append("%s %s" % [decree.id, decree.text])
		assert_eq(decree.group, EvidenceItem.Group.LAW)
	assert_eq(texts, ["L1 " + L1, "L2 " + L2, "L3 " + L3] as Array[String])


func test_ulf_is_the_matrix_slot_one() -> void:
	var ulf: Encounter = _soul(&"ulf")
	assert_eq(
		[ulf.legal_realm, ulf.worthy_realm, ulf.liar], [Realm.VALHALLA, Realm.VALHALLA, false]
	)
	assert_eq(ulf.item("C1").text, "Axed, in battle.")
	assert_eq(ulf.item("C4").text, "Sif gets the goat now.")
	assert_eq(ulf.item("B3").text, "sword, gripped")
	assert_eq(ulf.item("B2").view, &"back")
	assert_eq(_seam_pairs(ulf), ["C1-L1:2"] as Array[String])
	assert_eq(ulf.seams[0].caption, "the saga is true. L1 sends him to Valhalla.")
	assert_eq(ulf.seams[0].destination, Realm.VALHALLA)


func test_kolbeinn_is_the_reviewed_matrix_slot_two() -> void:
	var kolbeinn: Encounter = _soul(&"kolbeinn")
	assert_eq(
		[kolbeinn.legal_realm, kolbeinn.worthy_realm, kolbeinn.liar], [Realm.HEL, Realm.HEL, true]
	)
	assert_eq(kolbeinn.item("C1").text, "Danes axed my chest.")
	assert_eq(kolbeinn.item("C3").text, "Died sword in hand.")
	assert_eq(kolbeinn.item("B4").text, "night-shirt only, bare feet")
	# The review removed "no wound, back" against C1.
	assert_eq(_seam_pairs(kolbeinn), ["B1-C1:0", "B4-C2:0", "B3-C3:0", "B3-L3:2"] as Array[String])
	assert_null(kolbeinn.seam_between("B2", "C1"))
	assert_eq(kolbeinn.seam_between("B3", "L3").caption, "L3 sends him to Hel.")


func test_every_body_fact_has_a_view_and_a_hit_area() -> void:
	var missing: Array[String] = []
	for id: StringName in [&"ulf", &"kolbeinn"]:
		for fact: EvidenceItem in _soul(id).items_in(EvidenceItem.Group.BODY):
			if fact.view not in [&"front", &"back"] or fact.place == &"":
				missing.append("%s %s" % [id, fact.id])
	assert_eq(missing, [] as Array[String])
	assert_eq(_soul(&"kolbeinn").item("B4").place, &"hem")


func test_the_loader_returns_a_desk_at_day_one_dawn() -> void:
	var desk: DeskCommands = SliceLoader.load_slice()
	assert_eq([desk.phase(), desk.day_number(), desk.feathers()], [&"dawn", 1, 10])
	desk.begin_day()
	assert_eq(desk.current_encounter().soul_name, "Ulf")
	var result: PinResult = desk.pin("L1", "C1")
	assert_eq(result.kind, PinResult.Kind.THREAD)
	assert_eq(desk.stamp(Realm.VALHALLA).correct, true)
	assert_eq(desk.current_encounter().soul_name, "Kolbeinn")
