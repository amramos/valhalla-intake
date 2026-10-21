class_name MentorGuide
extends RefCounted
## Steps a guided soul's mentor script forward (D16): READ on acknowledgement, PIN when its pair
## is threaded (even if it was threaded before the step came up), STAMP at the stamp.


## The step showing on this soul, or null when it has none left.
static func current(record: VerdictRecord) -> MentorStep:
	if record == null or record.mentor_index >= record.encounter.mentor_steps.size():
		return null
	return record.encounter.mentor_steps[record.mentor_index]


## Finishes the current step if it waits for `until` (and, for PIN, for `seam`). True if it moved.
static func finish(record: VerdictRecord, until: MentorStep.Until, seam: Seam = null) -> bool:
	var step: MentorStep = current(record)
	if step == null or step.until != until:
		return false
	if until == MentorStep.Until.PIN and (seam == null or not step.is_pinned_by(seam)):
		return false
	record.mentor_index += 1
	_skip_pinned(record)
	return true


## A PIN step whose pair is already threaded is done as soon as it comes up.
static func _skip_pinned(record: VerdictRecord) -> void:
	var step: MentorStep = current(record)
	while step != null and step.until == MentorStep.Until.PIN:
		var done: bool = false
		for seam: Seam in record.threads:
			done = done or step.is_pinned_by(seam)
		if not done:
			return
		record.mentor_index += 1
		step = current(record)
