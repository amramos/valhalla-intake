class_name RecapWriter
extends RefCounted
## The dusk recap (matrix A7): up to 3 souls a day, each its truth line and one outcome line.
## Selection: souls stamped against their worthy door, then mercy, then permitted uncertainty,
## then a soul the Law and the truth part on, then souls never judged; queue order within each.

const MAX_SOULS := 3


static func lines(
	day_records: Array[VerdictRecord], day: DayRules, rules: SliceRules
) -> Array[String]:
	var ranked: Array[VerdictRecord] = []
	for rank: int in range(5):
		for record: VerdictRecord in day_records:
			if _rank(record) == rank and ranked.size() < MAX_SOULS:
				ranked.append(record)
	var result: Array[String] = []
	for record: VerdictRecord in ranked:
		result.append("%s %s" % [record.encounter.truth, outcome(record, day, rules)])
	return result


static func outcome(record: VerdictRecord, day: DayRules, rules: SliceRules) -> String:
	var encounter: Encounter = record.encounter
	if not record.judged():
		return rules.recap_never_line
	var stamped: String = Realm.display_name(record.verdict)
	var legal: String = Realm.display_name(encounter.legal_realm)
	var worthy: String = Realm.display_name(encounter.worthy_realm)
	if record.result != null and record.result.uncertain:
		return rules.recap_uncertain_format % stamped
	if record.verdict == encounter.legal_realm and record.verdict == encounter.worthy_realm:
		return rules.recap_agree_format % stamped
	if record.verdict == encounter.legal_realm:
		return rules.recap_legal_format % [encounter.pronoun, legal, worthy]
	if record.verdict == encounter.worthy_realm:
		var seam: Seam = VerdictRules.decisive_seam(record, day, rules)
		var decree: String = VerdictRules.decree_of(seam, day, rules) if seam != null else ""
		return rules.recap_mercy_format % [encounter.pronoun, worthy, decree]
	return rules.recap_neither_format % [encounter.pronoun, stamped, legal, worthy]


## 0 against the worthy door, 1 mercy, 2 uncertainty, 3 Law against truth, 4 never judged, 5 the
## rest (not recapped).
static func _rank(record: VerdictRecord) -> int:
	var encounter: Encounter = record.encounter
	if not record.judged():
		return 4
	var uncertain: bool = record.result != null and record.result.uncertain
	if record.verdict != encounter.worthy_realm and not uncertain:
		return 0
	if record.verdict == encounter.worthy_realm and record.verdict != encounter.legal_realm:
		return 1
	if uncertain:
		return 2
	if encounter.legal_realm != encounter.worthy_realm:
		return 3
	return 5
