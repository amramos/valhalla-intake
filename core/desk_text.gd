class_name DeskText
extends RefCounted
## The desk's presentation text that no rule composes (matrix section A): pin results, Huginn's
## control, the dusk cards and the slice ending. The UI and the harness format these; core's own
## lines (citations, recaps, the ledger) live in SliceRules. Defaults are the matrix's text.

## A1. Format: the two pinned ids, then the thread's caption.
var thread_format: String = "%s against %s: %s"
var no_seam_line: String = "No seam: those two agree."
## Format: the seconds lost.
var no_seam_timed_format: String = "No seam: those two agree. -%d s"
## A4.
var huginn_select_hover: String = "Select a grey thread first."
var huginn_extra_hover: String = "Extra answer: 2 feathers."
## Format: Huginn's answer.
var huginn_bought_format: String = "Huginn takes 2 feathers. %s"
## A6. Formats: the count; quota, admitted, feathers.
var dusk_citations_format: String = "Citations today: %d."
var dusk_no_citations: String = "No citations today."
var quota_met_format: String = "Odin wanted %d. Valhalla took %d. +%d feathers."
var quota_short_format: String = "Odin wanted %d. Valhalla took %d. -%d feathers."
## A8. The tide and hollow texts take the names, joined.
var tide_title: String = "Hel's tide"
var tide_format: String = (
	"The worthy you damned march with Hel." + " At the first horn they break the line: %s."
)
var hollow_title: String = "The hollow hall"
var hollow_format: String = (
	"The liars you let in fled at the first horn." + " Their benches stand empty: %s."
)
var hall_title: String = "The Hall holds"
var hall_text: String = "Odin counts his einherjar and finds them true. The gate holds, for now."
## Formats: name, verdict, worthy realm; then the suffixes for a wrong stamp.
var ending_row_format: String = "%s: %s. Truth: %s."
var ending_ignored: String = " Ignored."
var ending_missed: String = " Missed."
## Format: the name.
var ending_never_format: String = "%s: never judged."
var returned_name_format: String = "%s (returned)"
## Format: feathers, rank name.
var standing_format: String = "Feathers: %d. Rank: %s."
var play_again: String = "Play again"
