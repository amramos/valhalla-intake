class_name DeskText
extends RefCounted
## The desk's presentation text that no rule composes (matrix section A): pin results, Huginn's
## control, the dusk cards and the slice ending. The UI and the harness format these; core's own
## lines (citations, recaps, the ledger) live in SliceRules. Defaults are the matrix's text.

## A1. A thread's caption is built by CaptionFormatter, which names the pair by its words.
## Only what the pin showed, never "agree" (D36).
var no_seam_line: String = "No seam between those two."
## Format: the seconds lost.
var no_seam_timed_format: String = "No seam between those two. -%d s"
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
## Dusk (A6). Format: the day.
var dusk_title_format: String = "Dusk, day %d."
## Format: the rank name.
var rank_format: String = "Rank: %s."
## The day's feather changes (D36). Formats: dawn and now; a soul and the loss;
var feathers_dawn_format: String = "Feathers: %d at dawn, %d now."
## the cost; Hel's reward; the signed quota result; the cap's loss and the full loss.
var feather_citation_format: String = "Citation (%s): -%d."
var feather_huginn_format: String = "Huginn's extra answer: -%d."
var feather_hel_format: String = "Hel paid %d."
var feather_quota_format: String = "Quota: %+d."
var feather_cap_format: String = "Loss cap reached: -%d instead of -%d."
## Placeholder until section A has it. Format: the new rank, the refill.
var demoted_format: String = "Demoted to %s: feathers refilled to %d."
## The shell (D31).
var title_name: String = "Valhalla Intake"
var start_label: String = "Start"
var quit_label: String = "Quit"
var pause_title: String = "Paused"
var resume_label: String = "Resume"
var restart_label: String = "Restart the run"
var restart_confirm: String = "Restart the run from day 1? Everything since is lost."
var quit_confirm: String = "Quit the game?"
var confirm_yes: String = "Yes"
var confirm_no: String = "No"
var begin_label: String = "Begin"
var next_label: String = "Next"
var skip_all_label: String = "Skip all"
var next_day_label: String = "Next day"
var ledger_title: String = "Ledger"
var ledger_empty: String = "No requests yet."
