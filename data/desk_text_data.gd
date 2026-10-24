class_name DeskTextData
extends Resource
## The authored desk text of matrix section A that no rule composes (see core/desk_text.gd).

@export_group("Pin results (A1)")
@export var no_seam_line: String = ""
@export var no_seam_timed_format: String = ""
@export_group("Huginn (A4)")
@export var huginn_select_hover: String = ""
@export var huginn_extra_hover: String = ""
@export var huginn_bought_format: String = ""
@export_group("Dusk (A6)")
@export var dusk_citations_format: String = ""
@export var dusk_no_citations: String = ""
@export var quota_met_format: String = ""
@export var quota_short_format: String = ""
@export_group("Ending (A8)")
@export var tide_title: String = ""
@export_multiline var tide_format: String = ""
@export var hollow_title: String = ""
@export_multiline var hollow_format: String = ""
@export var hall_title: String = ""
@export_multiline var hall_text: String = ""
@export var ending_row_format: String = ""
@export var ending_ignored: String = ""
@export var ending_missed: String = ""
@export var ending_matched: String = ""
@export var ending_damned: String = ""
@export var ending_admitted: String = ""
@export var ending_sent_header: String = ""
@export var ending_truth_header: String = ""
@export var ending_record_header: String = ""
@export var ending_cited_header: String = ""
@export var ending_never_format: String = ""
@export var returned_name_format: String = ""
@export var standing_format: String = ""
@export var play_again: String = ""
@export_group("Feathers, shell and cards (WP5)")
@export var dusk_title_format: String = ""
@export var rank_format: String = ""
@export var feathers_dawn_format: String = ""
@export var feather_citation_format: String = ""
@export var feather_huginn_format: String = ""
@export var feather_hel_format: String = ""
@export var feather_quota_format: String = ""
@export var feather_cap_format: String = ""
@export var demoted_format: String = ""
@export var title_name: String = ""
@export var start_label: String = ""
@export var quit_label: String = ""
@export var pause_title: String = ""
@export var resume_label: String = ""
@export var restart_label: String = ""
@export var restart_confirm: String = ""
@export var quit_confirm: String = ""
@export var confirm_yes: String = ""
@export var confirm_no: String = ""
@export var begin_label: String = ""
@export var next_label: String = ""
@export var skip_all_label: String = ""
@export var next_day_label: String = ""
@export var ledger_title: String = ""
@export var ledger_empty: String = ""


func to_core() -> DeskText:
	var text := DeskText.new()
	for property: Dictionary in get_property_list():
		var key: String = property["name"]
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and key in text:
			text.set(key, get(key))
	return text
