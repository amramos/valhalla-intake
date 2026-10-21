class_name DeskTextData
extends Resource
## The authored desk text of matrix section A that no rule composes (see core/desk_text.gd).

@export_group("Pin results (A1)")
@export var thread_format: String = ""
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
@export var ending_never_format: String = ""
@export var returned_name_format: String = ""
@export var standing_format: String = ""
@export var play_again: String = ""


func to_core() -> DeskText:
	var text := DeskText.new()
	for property: Dictionary in get_property_list():
		var key: String = property["name"]
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and key in text:
			text.set(key, get(key))
	return text
