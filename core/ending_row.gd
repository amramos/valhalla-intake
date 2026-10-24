class_name EndingRow
extends RefCounted
## One soul's row on the day-book's last page (D23, D47), derived from an EndingEntry: the name,
## the stamped realm and the truth, the record mark and, when the stamp was wrong where a seam
## showed, the citation's mark. `text` is the row exactly as ScreenText.row words it, and the
## segments split those words for the page's columns: joined by single spaces they are `text`.

const TICK := &"tick"
const FROST := &"frost"
const HOLLOW := &"hollow"
const NEVER := &"never"
const IGNORED := &"ignored"
const MISSED := &"missed"

var name: String = ""
## The stamped realm; &"" when never judged.
var verdict: StringName = &""
var worthy: StringName = &""
## The record mark: TICK (matched), FROST (a worthy soul sent to Hel), HOLLOW (a liar admitted to
## Valhalla), NEVER (never judged), or &"" for any other wrong door (it tips no ending).
var mark: StringName = &""
## &"", IGNORED or MISSED: the black feather's word.
var cited: StringName = &""
## The row as ScreenText.row words it.
var text: String = ""
## "Hakon (returned):", "Hel.", "Truth:", "Valhalla.", "Worthy, damned.", "Missed." (an empty
## segment is not shown).
var name_text: String = ""
var verdict_text: String = ""
var truth_label: String = ""
var truth_text: String = ""
var record_text: String = ""
var cited_text: String = ""


## The segments in reading order, empty ones left out; joined by " " they equal `text`.
func segments() -> Array[String]:
	var out: Array[String] = []
	for part: String in [name_text, verdict_text, truth_label, truth_text, record_text, cited_text]:
		if part != "":
			out.append(part)
	return out
