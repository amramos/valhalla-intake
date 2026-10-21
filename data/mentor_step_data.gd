class_name MentorStepData
extends Resource
## One authored mentor step on a guided soul (D16).

@export_multiline var text: String = ""
@export var highlight: Array[String] = []
@export var door: StringName = &""
@export var until: MentorStep.Until = MentorStep.Until.READ


func to_core() -> MentorStep:
	return MentorStep.make(text, until, highlight.duplicate(), door)
