class_name PaperLine
extends RefCounted
## Builds one line of an EvidencePanel (D6, D8, D9): its pin hit area holding the line's label,
## a saga line opening with a straight quote mark, a decree with its roman numeral right-aligned
## in a column of its own. The panel places the hit area and connects its signals.
##
## A decree's first line starts after the numeral column and its wrapped lines run back under the
## numeral, the full width of the scroll: indenting every line would push decree I to four lines
## (slice D49 allows three).

## A sheet line opens with this mark (D8); it counts toward the 132 px cap.
const QUOTE := '"'
## Pixels between text lines (font size 16, line_spacing −3; ADR-0008).
const LINE_PITCH := 10
## The label's first ink row sits this far below its top; lines are shifted up to match.
const LABEL_TOP := 3
## Pixels between the numeral column and a decree's text.
const NUMERAL_GAP := 3
## The numerals the column is sized for (decrees I..V).
const NUMERALS: Array[String] = ["I", "II", "III", "IV", "V"]


## The hit area for `item`, `width` pixels wide and as tall as its text, its label named "Text"
## (and on the scroll its numeral named "Numeral"). `owner` gives the theme; the hit is added to
## `owner` so its label can measure its wrapped lines.
static func build(
	owner: Control, item: EvidenceItem, scroll: bool, show_ids: bool, width: int, wrap: bool
) -> PinSelectable:
	var hit := PinSelectable.new()
	hit.name = "Line%s" % item.id
	hit.item_id = item.id
	hit.hover_mark = PinSelectable.HoverMark.UNDERLINE
	hit.underline_color = owner.get_theme_color(&"ink", &"DeskPalette")
	hit.select_color = owner.get_theme_color(&"select_light", &"DeskPalette")
	hit.lit_color = owner.get_theme_color(&"lit", &"DeskPalette")
	hit.pin_color = owner.get_theme_color(&"pin_selected", &"DeskPalette")
	hit.pin_shadow = owner.get_theme_color(&"pin_selected_shadow", &"DeskPalette")
	hit.pin_highlight = owner.get_theme_color(&"pin_highlight", &"DeskPalette")
	var label: Label = make_label(owner.get_theme_color(&"ink", &"DeskPalette"))
	label.name = "Text"
	if scroll:
		label.text = _indent(owner, _add_numeral(owner, hit, item.id, show_ids)) + item.text
	else:
		label.text = ("%s %s" % [item.id, item.text]) if show_ids else QUOTE + item.text
	label.position = Vector2(0, -LABEL_TOP)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hit.add_child(label)
	owner.add_child(hit)
	if wrap:
		label.size = Vector2(width, 0)
	var lines: int = maxi(1, label.get_line_count())
	hit.size = Vector2(width, lines * LINE_PITCH)
	hit.underline_width = width_of(owner, label.text) if lines == 1 else -1
	return hit


## The first line's text indent on the scroll: the spaces that reach `x` pixels.
static func _indent(owner: Control, x: int) -> String:
	var space: int = maxi(width_of(owner, " ") + 1, 1)
	return " ".repeat(ceili(float(x) / float(space)))


## Where a decree's text begins on its first line (tests and tools).
static func text_start(label: Label, owner: Control) -> int:
	var text: String = label.text
	return width_of(owner, text.substr(0, text.length() - text.lstrip(" ").length())) + 1


## The line's label.
static func text_label(hit: PinSelectable) -> Label:
	return hit.get_node(^"Text") as Label


## The width `text` needs on one line in `owner`'s Label font, in pixels.
static func width_of(owner: Control, text: String) -> int:
	var font: Font = owner.get_theme_font(&"font", &"Label")
	var font_size: int = owner.get_theme_font_size(&"font_size", &"Label")
	return int(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) - 1


## The numeral column's width: the widest numeral it may hold.
static func numeral_column(owner: Control, show_ids: bool) -> int:
	var widest: int = 0
	for numeral: String in NUMERALS:
		widest = maxi(widest, width_of(owner, numeral))
	if show_ids:
		widest = maxi(widest, width_of(owner, "L5"))
	return widest


static func make_label(color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	return label


## The decree's numeral, right-aligned in its column (D6, D9); returns where the text begins.
static func _add_numeral(
	owner: Control, hit: PinSelectable, item_id: String, show_ids: bool
) -> int:
	var column: int = numeral_column(owner, show_ids)
	var numeral: Label = make_label(owner.get_theme_color(&"ink_soft", &"DeskPalette"))
	numeral.name = "Numeral"
	numeral.text = item_id if show_ids else DecreeNumeral.roman(item_id)
	numeral.position = Vector2(column - width_of(owner, numeral.text), -LABEL_TOP)
	hit.add_child(numeral)
	return column + NUMERAL_GAP
