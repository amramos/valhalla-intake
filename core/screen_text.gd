class_name ScreenText
extends RefCounted
## The text of the flow screens, composed once so the desk and the text harness say the same
## thing (D13): the dawn card (A5), the dusk cards (A6) and the slice ending (A8). The screens add
## only layout and buttons.


## m:ss, seconds rounded up: 300 reads "5:00".
static func clock_text(seconds: float) -> String:
	var whole: int = ceili(maxf(seconds, 0.0))
	return "%d:%02d" % [floori(whole / 60.0), whole % 60]


## The day's dawn lines, "{clock}" filled with the day's clock.
static func dawn_lines(day: DayRules) -> Array[String]:
	var lines: Array[String] = []
	for line: String in day.dawn_lines:
		lines.append(line.replace("{clock}", clock_text(day.clock_seconds)))
	return lines


## One string per card, lines joined by "\n", in A6's order: citations; the quota with the day's
## feather changes and the rank; the recap; requests and the ledger; the story beat. A card with
## nothing to say is left out (the citations and quota cards always show).
static func dusk_cards(report: DuskReport, rules: SliceRules) -> Array[String]:
	var text: DeskText = rules.text
	var cards: Array[String] = []
	var citations: Array[String] = [text.dusk_no_citations]
	if not report.citations.is_empty():
		citations = [text.dusk_citations_format % report.citations.size()]
		citations.append_array(report.citations)
	cards.append("\n".join(citations))
	var quota: Array[String] = _quota_lines(report, text)
	quota.append(text.rank_format % report.rank_name)
	cards.append("\n".join(quota))
	for block: Array[String] in [report.recap, report.requests, _story(report)]:
		if not block.is_empty():
			cards.append("\n".join(block))
	return cards


## The ending's lines: title, the outcome naming its souls, one row per encounter, the ledger's
## line for Hel's promise, then the clerk's standing.
static func ending_lines(report: EndingReport, rules: SliceRules) -> Array[String]:
	var text: DeskText = rules.text
	var lines: Array[String] = []
	match report.outcome:
		EndingReport.TIDE:
			lines.append(text.tide_title)
			lines.append(text.tide_format % ", ".join(_names(report, Realm.HEL, text)))
		EndingReport.HOLLOW:
			lines.append(text.hollow_title)
			lines.append(text.hollow_format % ", ".join(_names(report, Realm.VALHALLA, text)))
		_:
			lines.append(text.hall_title)
			lines.append(text.hall_text)
	for entry: EndingEntry in report.entries:
		lines.append(row(entry, text))
	if report.promise_line != "":
		lines.append(report.promise_line)
	if report.last_dusk != null:
		lines.append_array(_quota_lines(report.last_dusk, text))
	lines.append(text.standing_format % [report.feathers, report.rank_name])
	return lines


## ending_lines grouped for a card with blank lines between: the outcome, the rows, the ledger
## (when Hel made an offer), the last day's quota and feathers (D53), the standing.
static func ending_sections(report: EndingReport, rules: SliceRules) -> Array[String]:
	var lines: Array[String] = ending_lines(report, rules)
	var rows_end: int = 2 + report.entries.size()
	var sections: Array[String] = [
		"\n".join(lines.slice(0, 2)), "\n".join(lines.slice(2, rows_end))
	]
	var next: int = rows_end
	if report.promise_line != "":
		sections.append(lines[next])
		next += 1
	if lines.size() - 1 > next:
		sections.append("\n".join(lines.slice(next, lines.size() - 1)))
	sections.append(lines[-1])
	return sections


## "{name}: {verdict}. Truth: {worthy}." plus " Ignored." or " Missed." on a wrong stamp.
static func row(entry: EndingEntry, text: DeskText) -> String:
	var name: String = display_name(entry, text)
	if entry.verdict == &"":
		return text.ending_never_format % name
	var line: String = (
		text.ending_row_format
		% [name, Realm.display_name(entry.verdict), Realm.display_name(entry.worthy)]
	)
	if entry.mark == VerdictRecord.IGNORED:
		line += text.ending_ignored
	elif entry.mark == VerdictRecord.MISSED:
		line += text.ending_missed
	return line


static func display_name(entry: EndingEntry, text: DeskText) -> String:
	return text.returned_name_format % entry.soul_name if entry.returned else entry.soul_name


## The souls stamped to `realm` that weren't worthy of it, one name per encounter (D23).
static func _names(report: EndingReport, realm: StringName, text: DeskText) -> Array[String]:
	var names: Array[String] = []
	for entry: EndingEntry in report.entries:
		if entry.verdict == realm and entry.worthy != realm:
			names.append(display_name(entry, text))
	return names


## The quota result, then the day's feathers: at dawn and now, and every change between.
static func _quota_lines(report: DuskReport, text: DeskText) -> Array[String]:
	var lines: Array[String] = []
	if report.quota_delta >= 0:
		lines.append(text.quota_met_format % [report.quota, report.admitted, report.quota_delta])
	else:
		lines.append(text.quota_short_format % [report.quota, report.admitted, -report.quota_delta])
	lines.append(text.feathers_dawn_format % [report.feathers_at_dawn, report.feathers])
	lines.append_array(report.feather_lines)
	return lines


static func _story(report: DuskReport) -> Array[String]:
	var lines: Array[String] = []
	for line: String in [report.story, report.returned_line]:
		if line != "":
			lines.append(line)
	return lines
