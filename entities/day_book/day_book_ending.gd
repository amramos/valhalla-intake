class_name DayBookEnding
extends RefCounted
## What the day-book's last spread holds (D23, D47): the carved heading, the outcome lines, the
## ledger's line, the standing and one row per soul, and, once laid out, its lines in reading
## order for the ink. `text()` is the ending as ScreenText.ending_sections words it, blank lines
## between the sections, which is what the text harness prints.

var heading: String = ""
var outcome_lines: Array[String] = []
var ledger_line: String = ""
var standing: String = ""
var rows: Array[EndingRow] = []
## The column headers over the rows: the stamped realm, the truth, the record, the citation.
var headers: Array[String] = []
## The page's lines in the order the ink writes them (filled by DayBookLayout.ending).
var order: Array[Label] = []
## The row, in right-page pixels, of the "Play again" tag.
var play_again_y: int = 0


static func make(
	p_rows: Array[EndingRow],
	p_heading: String,
	p_outcome_lines: Array[String],
	p_ledger_line: String,
	p_standing: String
) -> DayBookEnding:
	var ending := DayBookEnding.new()
	ending.rows = p_rows.duplicate()
	ending.heading = p_heading
	ending.outcome_lines = p_outcome_lines.duplicate()
	ending.ledger_line = p_ledger_line
	ending.standing = p_standing
	return ending


func text() -> String:
	var row_lines: Array[String] = []
	for row: EndingRow in rows:
		row_lines.append(row.text)
	var sections: Array[String] = ["\n".join([heading] + outcome_lines), "\n".join(row_lines)]
	if ledger_line != "":
		sections.append(ledger_line)
	sections.append(standing)
	return "\n\n".join(sections)


## How many rows carry `mark` (the tableau's marchers are the worthy sent to Hel).
func count_mark(mark: StringName) -> int:
	var count: int = 0
	for row: EndingRow in rows:
		if row.mark == mark:
			count += 1
	return count
