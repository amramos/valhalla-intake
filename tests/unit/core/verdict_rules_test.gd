extends GutTest
## Stamps (GDD §3.7, D8, D28, D37, D38): correct is the legal realm; a citation follows a wrong
## stamp where a visible seam showed the legal realm; ignored means that seam was pinned.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")

var _rules: SliceRules = Fixture.rules()


func _day(number: int) -> DayRules:
	return Fixture.days()[number - 1]


func _thread(record: VerdictRecord, a: String, b: String, answer: String = "") -> void:
	record.threads.append(record.encounter.seam_between(a, b))
	record.answers.append(answer)


func test_correct_means_the_legal_realm() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.hakon())
	var legal: StampResult = VerdictRules.judge(record, Realm.HEL, _day(2), _rules)
	var mercy: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(2), _rules)
	assert_true(legal.correct, "Hakon's legal realm is Hel even though he is worthy")
	assert_false(legal.citation)
	assert_false(mercy.correct)


func test_a_missed_red_seam_still_cites() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.grim())
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(2), _rules)
	assert_true(result.citation, "the red seam was visible")
	assert_false(result.ignored, "never pinned: missed")
	assert_eq(
		result.citation_text, "Citation: decree II. Wet to the knee, and 'Never left the hill'."
	)
	assert_eq([result.citation_a, result.citation_b], ["B4", "C1"])


func test_a_pinned_seam_makes_the_stamp_ignored() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.hakon())
	_thread(record, "W1", "L4")
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(2), _rules)
	assert_true(result.citation)
	assert_true(result.ignored)
	assert_eq([result.citation_a, result.citation_b], ["W1", "L4"], "the pinned pair is named")
	assert_true(result.citation_text.begins_with("Citation: decree IV."))
	assert_true(result.citation_text.ends_with(_rules.threaded_line))


func test_day_one_gives_a_warning_not_a_citation() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.kolbeinn(), 1)
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(1), _rules)
	assert_false(result.citation)
	assert_true(result.warning)
	assert_ne(result.citation_text, "")


func test_an_unanswered_grey_thread_is_uncertainty() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.ketil(), 3)
	_thread(record, "C2", "W1")
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(3), _rules)
	assert_false(result.correct)
	assert_false(result.citation, "D37: the desk couldn't prove which side lied")
	assert_false(result.ignored)
	assert_true(result.uncertain)


func test_an_unpinned_grey_seam_is_uncertainty_too() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.ketil(), 3)
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(3), _rules)
	assert_false(result.citation)
	assert_true(result.uncertain)


func test_a_grey_thread_huginn_answered_cites() -> void:
	var record: VerdictRecord = Fixture.record(Fixture.ketil(), 3)
	_thread(record, "C2", "W1", _rules.huginn_claim_answer)
	var result: StampResult = VerdictRules.judge(record, Realm.VALHALLA, _day(3), _rules)
	assert_true(result.citation)
	assert_true(result.ignored)
	assert_false(result.uncertain)


func test_a_law_thread_to_another_realm_does_not_cite_but_the_lie_does() -> void:
	# Egil: L5 names Fólkvangr, but L2 (his red seam) sends him to Hel.
	var record: VerdictRecord = Fixture.record(Fixture.egil(), 3)
	_thread(record, "C2", "L5")
	var result: StampResult = VerdictRules.judge(record, Realm.FOLKVANGR, _day(3), _rules)
	assert_true(result.citation)
	assert_eq([result.citation_a, result.citation_b], ["B4", "C3"])
	assert_false(result.ignored, "he pinned L5, not the seam that showed Hel")


func test_a_seam_whose_decree_is_not_in_force_is_not_visible() -> void:
	# Egil judged under day-2 rules: no L5 on the desk, and his law thread can't cite.
	var soul: Encounter = Fixture.egil()
	soul.seams = [soul.seam_between("C2", "L5")]
	soul.legal_realm = Realm.FOLKVANGR
	var record: VerdictRecord = Fixture.record(soul, 2)
	var result: StampResult = VerdictRules.judge(record, Realm.HEL, _day(2), _rules)
	assert_false(result.citation)


func test_ending_marks_follow_the_worthy_destination() -> void:
	var day: DayRules = _day(2)
	var pinned: VerdictRecord = Fixture.record(Fixture.hakon())
	_thread(pinned, "C3", "L4")
	pinned.verdict = Realm.HEL
	var unpinned: VerdictRecord = Fixture.record(Fixture.hakon())
	unpinned.verdict = Realm.HEL
	var merciful: VerdictRecord = Fixture.record(Fixture.hakon())
	merciful.verdict = Realm.VALHALLA
	var unjudged: VerdictRecord = Fixture.record(Fixture.hakon())
	assert_eq(VerdictRules.mark_for(pinned, day, _rules), VerdictRecord.IGNORED)
	assert_eq(VerdictRules.mark_for(unpinned, day, _rules), VerdictRecord.MISSED)
	assert_eq(VerdictRules.mark_for(merciful, day, _rules), &"", "worthy: no mark")
	assert_eq(VerdictRules.mark_for(unjudged, day, _rules), VerdictRecord.NEVER)
