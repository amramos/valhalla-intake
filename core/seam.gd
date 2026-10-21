class_name Seam
extends RefCounted
## A true seam in one encounter: a lie seam (red, grey) or a law thread (D38).
## The pair is unordered: a × b and b × a are the same seam.

enum Kind { RED, GREY, LAW }
enum Liar { NONE, CLAIM, WITNESS }

var a: String = ""
var b: String = ""
var kind: Kind = Kind.RED
## RED/GREY: which side lies. LAW: NONE.
var liar: Liar = Liar.NONE
## LAW only: the realm the pinned decree names (D44).
var destination: StringName = &""
## Shown in the caption strip once the seam is threaded.
var caption: String = ""
## How a citation names this pair (matrix A3); "" builds it from the two items.
var pair_text: String = ""


static func make(
	p_a: String,
	p_b: String,
	p_kind: Kind,
	p_liar: Liar = Liar.NONE,
	p_destination: StringName = &"",
	p_caption: String = ""
) -> Seam:
	var seam := Seam.new()
	seam.a = p_a
	seam.b = p_b
	seam.kind = p_kind
	seam.liar = p_liar
	seam.destination = p_destination
	seam.caption = p_caption
	return seam


func joins(x: String, y: String) -> bool:
	return (a == x and b == y) or (a == y and b == x)


func touches(item_id: String) -> bool:
	return a == item_id or b == item_id
