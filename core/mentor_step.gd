class_name MentorStep
extends RefCounted
## One guided step of the mentor on a tutorial soul (D16): her bubble, what she lights, and what
## finishes the step.

## READ: the player acknowledges it. PIN: the highlighted pair is threaded. STAMP: the stamp.
enum Until { READ, PIN, STAMP }

var text: String = ""
## Item ids to light (a PIN step: exactly the pair to thread).
var highlight: Array[String] = []
## The door she points at; &"" for none.
var door: StringName = &""
var until: Until = Until.READ


static func make(
	p_text: String, p_until: Until, p_highlight: Array[String] = [], p_door: StringName = &""
) -> MentorStep:
	var step := MentorStep.new()
	step.text = p_text
	step.until = p_until
	step.highlight = p_highlight
	step.door = p_door
	return step


## A PIN step is done once its pair is threaded (either order).
func is_pinned_by(seam: Seam) -> bool:
	return until == Until.PIN and highlight.size() == 2 and seam.joins(highlight[0], highlight[1])
