class_name WritLines
extends RefCounted
## The words on Odin's writ (D21): each line of the day its own paragraph, wrapped at TEXT_WIDTH
## and set FACT_GAP below the last, in ink at the 10 px pitch, and Odin's mark under them in soft
## ink, right-aligned: on the last line's row when it fits beside the words, else on a row of its
## own. All of it within TEXT_ROOM px; the authoring check measures the data with `signed_height`.

const TEXT_WIDTH := 224
const TEXT_ROOM := 120
const FACT_GAP := 2
const LABEL_TOP := 3
const LINE_PITCH := 10
const SIGNATURE := "- Odin"
## The least room between the last line's words and the mark on the same row.
const SIGNATURE_GAP := 6
const SIGNATURE_NAME := &"Signature"


## The height of the lines alone, given each line's wrapped row count.
static func text_height(rows: Array[int]) -> int:
	var height: int = 0
	for count: int in rows:
		height += count * LINE_PITCH
	return height + FACT_GAP * maxi(rows.size() - 1, 0)


## Whether the mark fits on the last line's row, beside a last row `last_row_width` px wide.
static func signature_on_last_row(last_row_width: int, signature_width: int) -> bool:
	return last_row_width + SIGNATURE_GAP + signature_width <= TEXT_WIDTH


## The height of the lines with the mark under them: `rows` as `text_height`, the last row's and
## the mark's widths in px.
static func signed_height(rows: Array[int], last_row_width: int, signature_width: int) -> int:
	if rows.is_empty():
		return LINE_PITCH
	var height: int = text_height(rows)
	if not signature_on_last_row(last_row_width, signature_width):
		height += FACT_GAP + LINE_PITCH
	return height


## The width of the last row `text` wraps to at TEXT_WIDTH, as a Label with AUTOWRAP_WORD breaks it.
static func last_row_width(text: String, font: Font, font_size: int) -> int:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, font, font_size)
	paragraph.width = TEXT_WIDTH
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	return ceili(paragraph.get_line_width(paragraph.get_line_count() - 1))


static func text_width(text: String, font: Font, font_size: int) -> int:
	return ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)


## Replaces `box`'s children with one label per line and the mark.
static func write(box: Control, lines: Array[String], ink: Color, soft_ink: Color) -> void:
	# The old lines are freed at once (they hold nothing): a queued free would leave them orphaned
	# until the frame ends.
	for child: Node in box.get_children():
		box.remove_child(child)
		child.free()
	var y: int = 0
	var last: Label = null
	for line: String in lines:
		last = _label(box, line, ink, TextServer.AUTOWRAP_WORD)
		last.position = Vector2(0, y)
		last.size = Vector2(TEXT_WIDTH, 0)
		var rows: int = maxi(1, last.get_line_count())
		last.size = Vector2(TEXT_WIDTH, rows * LINE_PITCH + LABEL_TOP)
		y += rows * LINE_PITCH + FACT_GAP
	var mark: Label = _label(box, SIGNATURE, soft_ink, TextServer.AUTOWRAP_OFF)
	mark.name = SIGNATURE_NAME
	var font: Font = mark.get_theme_font(&"font")
	var font_size: int = mark.get_theme_font_size(&"font_size")
	var width: int = text_width(SIGNATURE, font, font_size)
	if last != null and signature_on_last_row(last_row_width(last.text, font, font_size), width):
		y -= FACT_GAP + LINE_PITCH
	mark.size = Vector2(width, LINE_PITCH + LABEL_TOP)
	mark.position = Vector2(TEXT_WIDTH - width, y)


## The line labels in `box`, in order, without the mark.
static func labels(box: Control) -> Array[Label]:
	var out: Array[Label] = []
	for child: Node in box.get_children():
		if child is Label and child.name != SIGNATURE_NAME:
			out.append(child as Label)
	return out


## Where the mark sits in `box`, one row tall; empty when there is none.
static func signature_rect(box: Control) -> Rect2:
	var mark: Label = box.get_node_or_null(NodePath(SIGNATURE_NAME)) as Label
	if mark == null:
		return Rect2()
	return Rect2(mark.position, Vector2(mark.size.x, LINE_PITCH))


static func _label(
	box: Control, text: String, color: Color, wrap: TextServer.AutowrapMode
) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = wrap
	label.add_theme_color_override(&"font_color", color)
	label.text = text
	box.add_child(label)
	return label
