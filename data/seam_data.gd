class_name SeamData
extends Resource
## One authored seam: a lie seam (red, grey) or a law thread (D38), with its caption.

@export var a: String = ""
@export var b: String = ""
@export var kind: Seam.Kind = Seam.Kind.RED
## RED/GREY: the lying side. LAW: NONE.
@export var liar: Seam.Liar = Seam.Liar.NONE
## LAW only: where the pinned decree sends the soul (D44).
@export var destination: StringName = &""
@export var caption: String = ""
## How a citation names this pair (matrix A3); "" builds it from the two items.
@export var pair_text: String = ""


func to_core() -> Seam:
	var seam: Seam = Seam.make(a, b, kind, liar, destination, caption)
	seam.pair_text = pair_text
	return seam
