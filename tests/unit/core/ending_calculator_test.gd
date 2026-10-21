extends GutTest
## The slice ending (D23): counted per encounter by the worthy destination, thresholds in data.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func _judged(soul: Encounter, realm: StringName, mark: StringName = &"") -> VerdictRecord:
	var record: VerdictRecord = Fixture.record(soul)
	record.verdict = realm
	record.mark = mark
	return record


func test_hels_tide_counts_each_encounter_so_a_returned_soul_is_named_twice() -> void:
	var records: Array[VerdictRecord] = [
		_judged(Fixture.asa(), Realm.HEL, VerdictRecord.MISSED),
		_judged(Fixture.hakon(), Realm.HEL, VerdictRecord.IGNORED),
		_judged(Fixture.returned_hakon("ignored"), Realm.HEL, VerdictRecord.MISSED),
		_judged(Fixture.kolbeinn(), Realm.HEL),
	]
	var report: EndingReport = EndingCalculator.calculate(records, Fixture.rules())
	assert_eq(report.tide_names, ["Asa", "Hakon", "Hakon"] as Array[String])
	assert_true(report.tide_reached)
	assert_eq(report.outcome, EndingReport.TIDE)
	assert_eq(report.entries.size(), 4)
	assert_eq(report.entries[1].mark, VerdictRecord.IGNORED)
	assert_eq(report.entries[1].worthy, Realm.VALHALLA)


func test_the_hollow_hall_counts_unworthy_souls_admitted_to_valhalla() -> void:
	var records: Array[VerdictRecord] = [
		_judged(Fixture.ketil(), Realm.VALHALLA, VerdictRecord.UNCERTAIN),
		_judged(Fixture.grim(), Realm.VALHALLA, VerdictRecord.MISSED),
		_judged(Fixture.ulf(), Realm.VALHALLA),
	]
	var report: EndingReport = EndingCalculator.calculate(records, Fixture.rules())
	assert_eq(report.hollow_names, ["Ketil", "Grim"] as Array[String])
	assert_true(report.hollow_reached)
	assert_false(report.tide_reached)
	assert_eq(report.outcome, EndingReport.HOLLOW)


func test_below_both_thresholds_the_hall_holds() -> void:
	var records: Array[VerdictRecord] = [
		_judged(Fixture.asa(), Realm.HEL),
		_judged(Fixture.hakon(), Realm.HEL),
		_judged(Fixture.ketil(), Realm.VALHALLA),
		Fixture.record(Fixture.ragna()),
	]
	var report: EndingReport = EndingCalculator.calculate(records, Fixture.rules())
	assert_eq(report.outcome, EndingReport.HALL_HOLDS)
	assert_eq(report.never_judged, ["Ragna"] as Array[String])
	assert_eq(report.entries[3].mark, VerdictRecord.NEVER)


func test_thresholds_come_from_the_rules() -> void:
	var rules: SliceRules = Fixture.rules()
	rules.tide_threshold = 1
	var records: Array[VerdictRecord] = [_judged(Fixture.asa(), Realm.HEL)]
	assert_eq(EndingCalculator.calculate(records, rules).outcome, EndingReport.TIDE)
