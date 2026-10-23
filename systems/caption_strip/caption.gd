class_name Caption
extends RefCounted
## One message for the clerk's note (D10, D28, D43): its text, its rank, the speaker mark drawn at
## its left, the pair of evidence it quotes (lit on the desk while it shows), and whether it is
## written out with a quill (the mentor, a citation) or shown at once (a thread, Huginn).

## The speaker marks the note can draw.
const MARKS: Array[StringName] = [
	&"none", &"pin_red", &"pin_grey", &"pin_law", &"raven", &"mentor", &"feather"
]

var text: String = ""
## CaptionStrip.Priority: lower is more urgent.
var priority: int = 0
## One of MARKS.
var mark: StringName = &"none"
## The ids of the two items a thread's caption quotes; empty for none.
var pair: Array[String] = []
## Written out at the quill's pace; the hold starts when the writing ends.
var written: bool = false


static func make(
	p_text: String,
	p_priority: int,
	p_mark: StringName = &"none",
	p_pair: Array[String] = [],
	p_written: bool = false
) -> Caption:
	var caption := Caption.new()
	caption.text = p_text
	caption.priority = p_priority
	caption.mark = p_mark if MARKS.has(p_mark) else &"none"
	caption.pair = p_pair.duplicate()
	caption.written = p_written
	return caption
