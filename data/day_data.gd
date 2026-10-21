class_name DayData
extends Resource
## One authored day: its rules and its queue of encounters, in roster order.

@export var day: int = 0
@export var quota: int = 0
## 0 means untimed (day 1, D10).
@export var clock_seconds: float = 0.0
@export var doors_open: Array[StringName] = []
@export var decrees: Array[DecreeData] = []
@export var citations: bool = false
@export var huginn_answers: int = 0
@export var new_decree_ids: Array[String] = []
@export var new_doors: Array[StringName] = []
@export var encounters: Array[EncounterData] = []
## The queue index the returned soul (or its fallback) takes; -1 for none (D2).
@export var return_slot: int = -1
@export_multiline var dusk_story: String = ""
## The dawn card's lines in order (D34); "{clock}" stands for the day's clock.
@export var dawn_lines: Array[String] = []


func to_core() -> DayRules:
	var rules := DayRules.new()
	rules.day = day
	rules.quota = quota
	rules.clock_seconds = clock_seconds
	rules.doors_open.assign(doors_open)
	for decree: DecreeData in decrees:
		rules.decrees.append(decree.to_core())
	rules.citations = citations
	rules.huginn_answers = huginn_answers
	rules.new_decree_ids.assign(new_decree_ids)
	rules.new_doors.assign(new_doors)
	rules.return_slot = return_slot
	rules.dusk_story = dusk_story
	rules.dawn_lines.assign(dawn_lines)
	return rules


func encounters_to_core() -> Array[Encounter]:
	var queue: Array[Encounter] = []
	for encounter: EncounterData in encounters:
		queue.append(encounter.to_core())
	return queue
