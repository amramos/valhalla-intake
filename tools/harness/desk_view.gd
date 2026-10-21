extends RefCounted
## What the desk shows, as text: the dawn card, the desk, dusk and the ending (D13). It reads
## only DeskCommands' getters, never a legal or worthy destination, the seam list or the truth,
## except what the dusk recap and the ending screen reveal by design (D15, D23).

## The doors in the gate band, left to right.
const DOORS: Array[StringName] = [Realm.VALHALLA, Realm.FOLKVANGR, Realm.HEL]
## Thread names by Seam.Kind; the line pattern on the desk.
const KIND_NAMES: Array[String] = ["red", "grey", "law"]

var desk: DeskCommands
## The newest thread caption on this soul (the caption strip).
var caption: String = ""


func _init(p_desk: DeskCommands) -> void:
	desk = p_desk


func describe() -> String:
	match desk.phase():
		&"dawn":
			return _describe_dawn()
		&"desk":
			return _describe_desk()
		&"dusk":
			return _describe_dusk()
	return _describe_ending()


func actions() -> String:
	var lines: Array[String] = ["Actions:"]
	match desk.phase():
		&"dawn":
			lines.append("  begin                 open the desk")
		&"desk":
			if desk.awaiting_next():
				lines.append("  next                  call the next soul")
			else:
				lines.append_array(_desk_actions())
		&"dusk":
			lines.append("  next                  go to the next dawn")
		&"ending":
			lines.append("  restart               play again")
	if desk.phase() != &"ending":
		lines.append("  restart               restart the run from day 1 (pause menu)")
	return "\n".join(lines)


func _describe_dawn() -> String:
	var day: DayRules = desk.day_rules()
	var lines: Array[String] = ["== Day %d, dawn ==" % day.day]
	lines.append("Odin wants %d for Valhalla today." % day.quota)
	lines.append("Clock: %s." % (_clock() if day.is_timed() else "untimed"))
	lines.append("Doors: %s" % _doors())
	lines.append(
		"Citations: %s." % ("a broken Law costs feathers" if day.citations else "warnings only")
	)
	if day.huginn_answers > 0:
		lines.append(
			(
				"Huginn: %d answers today. He answers only about a thread you already made."
				% day.huginn_answers
			)
		)
	lines.append("The Law:")
	lines.append_array(_law_lines())
	lines.append_array(_ledger())
	lines.append("Feathers: %d" % desk.feathers())
	return "\n".join(lines)


func _describe_desk() -> String:
	var day: DayRules = desk.day_rules()
	var soul: Encounter = desk.current_encounter()
	var position: Vector2i = desk.queue_position()
	var lines: Array[String] = ["== Day %d, soul %d of %d ==" % [day.day, position.x, position.y]]
	var quota: Vector2i = desk.quota_progress()
	var hud: String = (
		"Clock: %s | Feathers: %d | Quota: %d/%d" % [_clock(), desk.feathers(), quota.x, quota.y]
	)
	if day.huginn_answers > 0:
		hud += " | Huginn: %d (extra answer: 2 feathers)" % desk.huginn_left()
	lines.append(hud)
	lines.append_array(_ledger())
	lines.append("Doors: %s" % _doors())
	var plate: String = "At the desk: %s" % soul.soul_name
	if soul.returned:
		plate += " (frost-burned name plate)"
	if soul.hel_marked:
		plate += " (serpent mark)"
	if soul.plate_label != "":
		plate += " [plate: %s]" % soul.plate_label
	lines.append(plate)
	for view: StringName in [&"front", &"back"]:
		lines.append("Body, %s:" % view)
		for item: EvidenceItem in soul.items_in(EvidenceItem.Group.BODY):
			if item.view == view:
				lines.append("  %s  %s" % [item.id, item.text])
	lines.append("Claim:")
	lines.append_array(_lines_of(soul, EvidenceItem.Group.CLAIM))
	var witness: Array[String] = _lines_of(soul, EvidenceItem.Group.WITNESS)
	if not witness.is_empty():
		lines.append("Witness: %s" % soul.witness_name)
		lines.append_array(witness)
	elif soul.witness_note != "":
		lines.append("Witness: %s" % soul.witness_note)
	lines.append("The Law:")
	lines.append_array(_law_lines())
	lines.append_array(_thread_lines())
	if caption != "":
		lines.append("Caption: %s" % caption)
	var held: StampResult = desk.pending_stamp()
	if held != null:
		lines.append("Black feather: %s" % held.citation_text)
		lines.append("Lit pair: %s and %s" % [held.citation_a, held.citation_b])
		lines.append("%s has been stamped; the next soul waits." % soul.soul_name)
	return "\n".join(lines)


func _describe_dusk() -> String:
	var report: DuskReport = desk.dusk_report()
	var lines: Array[String] = ["== Day %d, dusk ==" % report.day]
	lines.append("Citations: none" if report.citations.is_empty() else "Citations:")
	for citation: String in report.citations:
		lines.append("  " + citation)
	lines.append(
		"Quota: %d/%d (%+d feathers)" % [report.admitted, report.quota, report.quota_delta]
	)
	if report.demoted:
		lines.append("Demoted to %s; feathers refilled." % report.rank_name)
	if not report.never_judged.is_empty():
		lines.append("Never judged: %s" % ", ".join(report.never_judged))
	lines.append("What really happened:")
	for line: String in report.recap:
		lines.append("  " + line)
	for line: String in report.requests:
		lines.append(line)
	if report.story != "":
		lines.append(report.story)
	if report.returned_line != "":
		lines.append(report.returned_line)
	lines.append_array(_ledger())
	lines.append("Feathers: %d | Rank: %s" % [report.feathers, report.rank_name])
	return "\n".join(lines)


func _describe_ending() -> String:
	var report: EndingReport = desk.ending()
	var lines: Array[String] = ["== The slice ends =="]
	match report.outcome:
		EndingReport.TIDE:
			lines.append("Hel's tide: %s march with Hel." % ", ".join(report.tide_names))
		EndingReport.HOLLOW:
			lines.append("The hollow hall: %s sit in Valhalla." % ", ".join(report.hollow_names))
		_:
			lines.append("The Hall holds.")
	for entry: EndingEntry in report.entries:
		var verdict: String = "never judged"
		if entry.verdict != &"":
			verdict = "stamped %s" % Realm.display_name(entry.verdict)
		var line: String = (
			"  Day %d  %s: %s; deserved %s"
			% [entry.day, entry.soul_name, verdict, Realm.display_name(entry.worthy)]
		)
		if entry.mark in [&"ignored", &"missed", &"uncertain"]:
			line += " (%s)" % entry.mark
		lines.append(line)
	lines.append_array(_ledger())
	lines.append("Standing: %d feathers, %s" % [report.feathers, report.rank_name])
	return "\n".join(lines)


func _desk_actions() -> Array[String]:
	var ids: Array[String] = []
	for item: EvidenceItem in desk.visible_items():
		ids.append(item.id)
	var lines: Array[String] = ["  pin <id> <id>         ids: %s" % " ".join(ids)]
	var greys: Array[String] = []
	var threads: Array[Seam] = desk.threads()
	for index: int in threads.size():
		if threads[index].kind == Seam.Kind.GREY and desk.thread_answer(index) == "":
			greys.append(str(index + 1))
	if desk.day_rules().huginn_answers > 0:
		if not greys.is_empty() and desk.huginn_left() > 0:
			lines.append("  huginn <thread>       ask about grey thread %s" % " or ".join(greys))
		elif desk.huginn_left() == 0:
			lines.append("  buy                   one more Huginn answer for 2 feathers")
	var open: Array[String] = []
	for realm: StringName in desk.day_rules().doors_open:
		open.append(String(realm))
	lines.append("  stamp <realm>         open doors: %s" % ", ".join(open))
	return lines


func _thread_lines() -> Array[String]:
	var threads: Array[Seam] = desk.threads()
	var lines: Array[String] = ["Threads: none" if threads.is_empty() else "Threads:"]
	for index: int in threads.size():
		var seam: Seam = threads[index]
		var line: String = (
			"  %d. %s-%s %s thread" % [index + 1, seam.a, seam.b, KIND_NAMES[seam.kind]]
		)
		if seam.kind == Seam.Kind.GREY:
			line += " (knot)"
		line += ": %s" % seam.caption
		if desk.thread_answer(index) != "":
			line += " Huginn: %s" % desk.thread_answer(index)
		lines.append(line)
	return lines


func _law_lines() -> Array[String]:
	var day: DayRules = desk.day_rules()
	var lines: Array[String] = []
	for decree: EvidenceItem in day.decrees:
		var mark: String = ""
		if desk.shows_new_marks() and day.new_decree_ids.has(decree.id):
			mark = " [NEW]"
		lines.append("  %s  %s%s" % [decree.id, decree.text, mark])
	return lines


func _lines_of(soul: Encounter, group: EvidenceItem.Group) -> Array[String]:
	var lines: Array[String] = []
	for item: EvidenceItem in soul.items_in(group):
		lines.append('  %s  "%s"' % [item.id, item.text])
	return lines


func _doors() -> String:
	var day: DayRules = desk.day_rules()
	var parts: Array[String] = []
	for realm: StringName in DOORS:
		var state: String = "open"
		if not day.doors_open.has(realm):
			var opens: int = desk.door_open_day(realm)
			state = "closed until day %d" % opens if opens > day.day else "closed"
		elif desk.shows_new_marks() and day.new_doors.has(realm):
			state = "open [NEW]"
		parts.append("%s (%s)" % [Realm.display_name(realm), state])
	return ", ".join(parts)


## The ledger entry stays readable in every phase once Hel has asked (D3, D15).
func _ledger() -> Array[String]:
	if desk.promise_soul() == "":
		return []
	return [
		(
			"Ledger: Hel asks you to send %s to Hel, for %d feathers (%s)."
			% [desk.promise_soul(), desk.promise_reward(), desk.promise_state()]
		)
	]


func _clock() -> String:
	var left: float = desk.time_left()
	if left == INF:
		return "untimed"
	var seconds: int = ceili(left)
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]
