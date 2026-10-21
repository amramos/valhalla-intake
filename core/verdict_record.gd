class_name VerdictRecord
extends RefCounted
## One encounter's record: every pin, the threads, Huginn's answers and the verdict (D8).

const IGNORED := &"ignored"
const MISSED := &"missed"
const UNCERTAIN := &"uncertain"
const NEVER := &"never"

var encounter: Encounter = null
var day: int = 0
## The stamped realm; &"" while unjudged.
var verdict: StringName = &""
## Every pin made on this soul, as "a|b", in order.
var pins: Array[String] = []
## Seams threaded on this soul, in pin order.
var threads: Array[Seam] = []
## Huginn's answer per thread (same index as threads); "" until asked.
var answers: Array[String] = []
var result: StampResult = null
## How many of the encounter's mentor steps are done.
var mentor_index: int = 0
## Against the worthy destination: &"" (right), IGNORED, MISSED, UNCERTAIN or NEVER.
var mark: StringName = &""


static func make(p_encounter: Encounter, p_day: int) -> VerdictRecord:
	var record := VerdictRecord.new()
	record.encounter = p_encounter
	record.day = p_day
	return record


func judged() -> bool:
	return verdict != &""


func is_threaded(seam: Seam) -> bool:
	return threads.has(seam)


func answer_for(seam: Seam) -> String:
	var index: int = threads.find(seam)
	return answers[index] if index >= 0 else ""
