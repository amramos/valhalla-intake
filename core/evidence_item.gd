class_name EvidenceItem
extends RefCounted
## One pinnable piece of evidence: a body fact, a claim line, a witness line or a decree.

enum Group { BODY, CLAIM, WITNESS, LAW }

## "B1", "C2", "W1", "L3": unique within an encounter plus the day's decrees.
var id: String = ""
var group: Group = Group.BODY
## The hover label (body) or the line itself.
var text: String = ""
## Body only: &"front" or &"back"; empty otherwise.
var view: StringName = &""
## Body only: the hit area on the chart (&"torso_front", &"torso_back", &"hand_right",
## &"hand_left", &"neck", &"legs", &"hem"); empty otherwise.
var place: StringName = &""


static func make(
	p_id: String,
	p_group: Group,
	p_text: String,
	p_view: StringName = &"",
	p_place: StringName = &""
) -> EvidenceItem:
	var item := EvidenceItem.new()
	item.id = p_id
	item.group = p_group
	item.text = p_text
	item.view = p_view
	item.place = p_place
	return item
