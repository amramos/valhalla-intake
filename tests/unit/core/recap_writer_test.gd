extends GutTest
## The dusk recap (matrix A7) and the ledger entry (A6): one outcome line per case, and the
## selection order of up to three souls.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")

var _rules: SliceRules = Fixture.rules()


func _stamped(soul: Encounter, realm: StringName, day: int = 2) -> VerdictRecord:
	var record: VerdictRecord = Fixture.record(soul, day)
	record.verdict = realm
	record.result = VerdictRules.judge(record, realm, Fixture.days()[day - 1], _rules)
	return record


func _outcome(record: VerdictRecord) -> String:
	return RecapWriter.outcome(record, Fixture.days()[record.day - 1], _rules)


func test_each_outcome_has_its_line() -> void:
	var lines: Array[String] = [
		_outcome(_stamped(Fixture.sigvaldi(), Realm.VALHALLA)),
		_outcome(_stamped(Fixture.hakon(), Realm.HEL)),
		_outcome(_stamped(Fixture.hakon(), Realm.VALHALLA)),
		_outcome(_stamped(Fixture.grim(), Realm.VALHALLA)),
		_outcome(_stamped(Fixture.ketil(), Realm.VALHALLA, 3)),
		_outcome(Fixture.record(Fixture.grim())),
	]
	assert_eq(
		lines,
		(
			[
				"Valhalla, as the Law and the truth agree.",
				"The Law sent him to Hel. The truth was Valhalla.",
				"You sent him to Valhalla against L4. The truth agrees.",
				"You sent him to Valhalla. The Law said Hel. The truth was Hel.",
				"Valhalla. Which side lied couldn't be proven at the desk.",
				"Never judged.",
			]
			as Array[String]
		)
	)


func test_the_recap_picks_three_souls_in_the_matrix_order() -> void:
	var records: Array[VerdictRecord] = [
		_stamped(Fixture.sigvaldi(), Realm.VALHALLA),
		Fixture.record(Fixture.asa(), 2),
		_stamped(Fixture.hakon(), Realm.VALHALLA),
		_stamped(Fixture.grim(), Realm.VALHALLA),
	]
	var lines: Array[String] = RecapWriter.lines(records, Fixture.days()[1], _rules)
	assert_eq(lines.size(), 3)
	assert_true(lines[0].begins_with("The truth about Grim."), "against the worthy door first")
	assert_true(lines[1].begins_with("The truth about Hakon."), "then mercy")
	assert_true(lines[2].begins_with("The truth about Asa. Never judged."), "then never judged")


func test_the_ledger_reads_each_state_of_hels_promise() -> void:
	var lines: Array[String] = []
	for state: StringName in [
		RunState.PROMISE_NONE,
		RunState.PROMISE_OPEN,
		RunState.PROMISE_KEPT,
		RunState.PROMISE_BROKEN,
		RunState.PROMISE_LAPSED,
	]:
		lines.append(Ledger.line(state, "Ragna", Realm.FOLKVANGR, _rules))
	assert_eq(
		lines,
		(
			[
				"",
				"Hel: send Ragna to Hel. 4 feathers.",
				"Kept. Ragna went to Hel. Hel paid 4 feathers.",
				"Broken. Ragna went to Fólkvangr.",
				"Lapsed. Ragna was never judged.",
			]
			as Array[String]
		)
	)
