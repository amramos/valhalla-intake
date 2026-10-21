class_name EndingCalculator
extends RefCounted
## Counts the slice ending per encounter by the worthy destination (D23). A returned soul is its
## own encounter, so it can be named twice.


static func calculate(records: Array[VerdictRecord], rules: SliceRules) -> EndingReport:
	var report := EndingReport.new()
	for record: VerdictRecord in records:
		var encounter: Encounter = record.encounter
		var entry := EndingEntry.new()
		entry.soul_name = encounter.soul_name
		entry.returned = encounter.returned
		entry.day = record.day
		entry.verdict = record.verdict
		entry.worthy = encounter.worthy_realm
		entry.truth = encounter.truth
		entry.mark = record.mark if record.judged() else VerdictRecord.NEVER
		report.entries.append(entry)
		if not record.judged():
			report.never_judged.append(encounter.soul_name)
		elif record.verdict == Realm.HEL and encounter.worthy_realm != Realm.HEL:
			report.tide_names.append(encounter.soul_name)
		elif record.verdict == Realm.VALHALLA and encounter.worthy_realm != Realm.VALHALLA:
			report.hollow_names.append(encounter.soul_name)
	report.tide_reached = report.tide_names.size() >= rules.tide_threshold
	report.hollow_reached = report.hollow_names.size() >= rules.hollow_threshold
	if report.tide_reached:
		report.outcome = EndingReport.TIDE
	elif report.hollow_reached:
		report.outcome = EndingReport.HOLLOW
	else:
		report.outcome = EndingReport.HALL_HOLDS
	return report
