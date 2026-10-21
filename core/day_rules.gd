class_name DayRules
extends RefCounted
## One day's desk rules: quota, clock, open doors, the Law in force and what changed today.

var day: int = 1
var quota: int = 1
## 0 means untimed (day 1, D10).
var clock_seconds: float = 0.0
var doors_open: Array[StringName] = []
## Group LAW, word for word as D32.
var decrees: Array[EvidenceItem] = []
## false on day 1 (D28): a would-be citation is only a warning.
var citations: bool = false
## Huginn's free answers today; 0 means he is not on the desk (D30).
var huginn_answers: int = 0
## NEW marks until the day's first stamp (D34).
var new_decree_ids: Array[String] = []
var new_doors: Array[StringName] = []
## The queue index a returned soul (or its fallback) takes today; -1 for none (D2).
var return_slot: int = -1
## The dusk story beat for this day ("" for none).
var dusk_story: String = ""


func is_timed() -> bool:
	return clock_seconds > 0.0


func decree(decree_id: String) -> EvidenceItem:
	for item: EvidenceItem in decrees:
		if item.id == decree_id:
			return item
	return null
