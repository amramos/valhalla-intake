class_name DuskSpread
extends RefCounted
## One open spread of the clerk's day-book at dusk (D22, D34): the lines of the left page and of
## the right page, as ScreenText composes them. Every spread's left page starts with the title
## ("Dusk, day N."), the book's running head, so the text harness, which prints the title over each
## card, and the book say the same words.

var title: String = ""
var left: Array[String] = []
var right: Array[String] = []


static func make(p_title: String, p_left: Array[String], p_right: Array[String]) -> DuskSpread:
	var spread := DuskSpread.new()
	spread.title = p_title
	spread.left.assign([p_title] + p_left if p_title != "" else p_left)
	spread.right.assign(p_right)
	return spread


## Every line of the spread, the left page first, the title included.
func lines() -> Array[String]:
	return left + right


## The spread's lines below the title, joined by "\n": what the harness prints under its heading.
func body() -> String:
	var from: int = 1 if title != "" and not left.is_empty() and left[0] == title else 0
	return "\n".join(left.slice(from) + right)


## The whole spread as the book shows it, the title first.
func text() -> String:
	return "\n".join(lines())
