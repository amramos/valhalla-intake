class_name Encounter
extends RefCounted
## One soul's visit to the desk. Decrees come from the day, not from here.

var id: StringName = &""
var soul_name: String = ""
## Body facts, claim lines and witness lines.
var items: Array[EvidenceItem] = []
## "" when there is no witness (day 1, or returned Hakon).
var witness_name: String = ""
## Shown in an empty witness panel ("No witness came back.", D46); "" hides the panel.
var witness_note: String = ""
var seams: Array[Seam] = []
var legal_realm: StringName = &""
var worthy_realm: StringName = &""
var liar: bool = false
## Hel's named soul (D3): the serpent mark on the name plate.
var hel_marked: bool = false
## The name plate's hover label (Hel's mark, a frost-burned plate); desk-visible.
var plate_label: String = ""
## A returned soul (D2): the frost-burned name plate.
var returned: bool = false
## The soul whose stamp to Hel brings it back in a later encounter (D2).
var return_eligible: bool = false
## What really happened; shown only in the dusk recap and on the ending screen.
var truth: String = ""


func item(item_id: String) -> EvidenceItem:
	for candidate: EvidenceItem in items:
		if candidate.id == item_id:
			return candidate
	return null


func items_in(group: EvidenceItem.Group) -> Array[EvidenceItem]:
	var found: Array[EvidenceItem] = []
	for candidate: EvidenceItem in items:
		if candidate.group == group:
			found.append(candidate)
	return found


func seam_between(x: String, y: String) -> Seam:
	for seam: Seam in seams:
		if seam.joins(x, y):
			return seam
	return null
