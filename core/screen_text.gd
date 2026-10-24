class_name ScreenText
extends RefCounted
## The text of the flow screens, composed once so the desk and the text harness say the same
## thing (D13, D44): the dawn card (A5), the dusk day-book's spreads (A6, D22) and the slice ending
## (A8, D23). The screens add only layout, marks and buttons.


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


## The day-book's spreads at dusk (D22, D34), each left page headed by the title. The first holds
## the citations ("No citations today." when none, never alone: the quota shares its page), the
## quota with the day's feather changes and the rank on the left, the recap on the right. A second
## spread, only when either page has a line, holds the requests and the ledger on the left and the
## story beat on the right.
static func dusk_spreads(report: DuskReport, rules: SliceRules) -> Array[DuskSpread]:
	var text: DeskText = rules.text
	var title: String = text.dusk_title_format % report.day
	var left: Array[String] = [text.dusk_no_citations]
	if not report.citations.is_empty():
		left = [text.dusk_citations_format % report.citations.size()]
		left.append_array(report.citations)
	left.append_array(_quota_lines(report, text))
	left.append(text.rank_format % report.rank_name)
	var spreads: Array[DuskSpread] = [DuskSpread.make(title, left, report.recap)]
	var story: Array[String] = _story(report)
	if not report.requests.is_empty() or not story.is_empty():
		spreads.append(DuskSpread.make(title, report.requests, story))
	return spreads


## One string per spread, its lines below the title joined by "\n": the spreads flattened, in A6's
## order (citations; the quota with the day's feather changes and the rank; the recap; requests and
## the ledger; the story beat). The harness prints each under the title, as the book shows it.
static func dusk_cards(report: DuskReport, rules: SliceRules) -> Array[String]:
	var cards: Array[String] = []
	for spread: DuskSpread in dusk_spreads(report, rules):
		cards.append(spread.body())
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
	lines.append(text.standing_format % [report.feathers, report.rank_name])
	return lines


## ending_lines grouped with blank lines between: the outcome, the rows, the ledger (when Hel made
## an offer), the standing. Day 3's quota and feathers are on its own dusk spread, which shows
## before the ending.
static func ending_sections(report: EndingReport, rules: SliceRules) -> Array[String]:
	var lines: Array[String] = ending_lines(report, rules)
	var rows_end: int = 2 + report.entries.size()
	var sections: Array[String] = [
		"\n".join(lines.slice(0, 2)), "\n".join(lines.slice(2, rows_end))
	]
	if report.promise_line != "":
		sections.append(lines[rows_end])
	sections.append(lines[-1])
	return sections


## "{name}: {verdict}. Truth: {worthy}.", the record's word (" Matched.", " Worthy, damned.",
## " Liar, admitted.", D23, D47), then " Ignored." or " Missed." on a stamp that drew a citation.
static func row(entry: EndingEntry, text: DeskText) -> String:
	var name: String = display_name(entry, text)
	if entry.verdict == &"":
		return text.ending_never_format % name
	var line: String = (
		text.ending_row_format
		% [name, Realm.display_name(entry.verdict), Realm.display_name(entry.worthy)]
	)
	return line + _record_word(_record_mark(entry), text) + _cited_word(entry, text)


## One row per encounter for the day-book's last page (D23, D47): the words of row(), split for
## the page's columns, with the record mark and the citation's mark.
static func ending_rows(report: EndingReport, rules: SliceRules) -> Array[EndingRow]:
	var rows: Array[EndingRow] = []
	for entry: EndingEntry in report.entries:
		rows.append(ending_row(entry, rules.text))
	return rows


static func ending_row(entry: EndingEntry, text: DeskText) -> EndingRow:
	var shown := EndingRow.new()
	shown.name = display_name(entry, text)
	shown.verdict = entry.verdict
	shown.worthy = entry.worthy
	shown.mark = _record_mark(entry)
	if entry.mark == VerdictRecord.IGNORED:
		shown.cited = EndingRow.IGNORED
	elif entry.mark == VerdictRecord.MISSED:
		shown.cited = EndingRow.MISSED
	shown.text = row(entry, text)
	_split_row(shown, text)
	return shown


## The day-book's column headers over the ending's rows: "Sent", "Truth", "Record", "Cited".
static func ending_headers(rules: SliceRules) -> Array[String]:
	var text: DeskText = rules.text
	return [
		text.ending_sent_header,
		text.ending_truth_header,
		text.ending_record_header,
		text.ending_cited_header,
	]


static func display_name(entry: EndingEntry, text: DeskText) -> String:
	return text.returned_name_format % entry.soul_name if entry.returned else entry.soul_name


## The souls stamped to `realm` that weren't worthy of it, one name per encounter (D23).
static func _names(report: EndingReport, realm: StringName, text: DeskText) -> Array[String]:
	var names: Array[String] = []
	for entry: EndingEntry in report.entries:
		if entry.verdict == realm and entry.worthy != realm:
			names.append(display_name(entry, text))
	return names


## The record mark against the worthy destination, counted as the ending counts them
## (EndingCalculator): a worthy soul sent to Hel is frost, a liar let into Valhalla a hollow ring.
static func _record_mark(entry: EndingEntry) -> StringName:
	if entry.verdict == &"":
		return EndingRow.NEVER
	if entry.verdict == entry.worthy:
		return EndingRow.TICK
	if entry.verdict == Realm.HEL:
		return EndingRow.FROST
	if entry.verdict == Realm.VALHALLA:
		return EndingRow.HOLLOW
	return &""


## The record mark's word, with its leading space; "" for a wrong door that tips no ending.
static func _record_word(mark: StringName, text: DeskText) -> String:
	match mark:
		EndingRow.TICK:
			return text.ending_matched
		EndingRow.FROST:
			return text.ending_damned
		EndingRow.HOLLOW:
			return text.ending_admitted
	return ""


static func _cited_word(entry: EndingEntry, text: DeskText) -> String:
	if entry.mark == VerdictRecord.IGNORED:
		return text.ending_ignored
	if entry.mark == VerdictRecord.MISSED:
		return text.ending_missed
	return ""


## Splits the row's words at the format's placeholders into the page's columns: the name with its
## colon, the stamped realm, "Truth:", the worthy realm, the record's word, the citation's word. A
## format without the expected placeholders keeps its words in the first column.
static func _split_row(shown: EndingRow, text: DeskText) -> void:
	if shown.verdict == &"":
		var never: PackedStringArray = text.ending_never_format.split("%s")
		if never.size() != 2:
			shown.name_text = shown.text
			return
		var rest: PackedStringArray = _split_word(never[1])
		shown.name_text = never[0] + shown.name + rest[0]
		shown.verdict_text = rest[1]
		return
	var verdict: String = Realm.display_name(shown.verdict)
	var worthy: String = Realm.display_name(shown.worthy)
	var plain: String = text.ending_row_format % [shown.name, verdict, worthy]
	shown.record_text = _record_word(shown.mark, text).strip_edges()
	shown.cited_text = shown.text.substr(plain.length() + _record_word(shown.mark, text).length())
	shown.cited_text = shown.cited_text.strip_edges()
	var parts: PackedStringArray = text.ending_row_format.split("%s")
	if parts.size() != 4:
		shown.name_text = plain
		return
	var after_name: PackedStringArray = _split_word(parts[1])
	var after_verdict: PackedStringArray = _split_word(parts[2])
	shown.name_text = parts[0] + shown.name + after_name[0]
	shown.verdict_text = after_name[1] + verdict + after_verdict[0]
	shown.truth_label = after_verdict[1]
	shown.truth_text = worthy + parts[3]


## `part` cut at its first space: what precedes it, and the rest without its edge spaces.
static func _split_word(part: String) -> PackedStringArray:
	var space: int = part.find(" ")
	if space < 0:
		return PackedStringArray([part, ""])
	return PackedStringArray([part.substr(0, space), part.substr(space).strip_edges()])


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
