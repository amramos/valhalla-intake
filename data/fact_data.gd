class_name FactData
extends Resource
## One body fact as authored: an id, its hover label, the chart view and hit area.

@export var id: String = ""
@export var label: String = ""
## &"front" or &"back".
@export var view: StringName = &""
## The hit area: &"torso_front", &"torso_back", &"hand_right", &"hand_left", &"neck", &"legs",
## &"hem" (the matrix's body chart conventions).
@export var place: StringName = &""


func to_core() -> EvidenceItem:
	return EvidenceItem.make(id, EvidenceItem.Group.BODY, label, view, place)
