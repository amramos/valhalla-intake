extends GutTest
## Hover tags (D20): a small parchment tag pinned by a 3×3 head, the same plain text, never taking
## the mouse; placed above the hovered area, then below, then beside, inside the screen and never
## over a sheet heading or the note (WP1's playtest: "Send it on" covered the claim heading).

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const SCREEN := Rect2(0, 0, 480, 270)
const TAG := Vector2(40, 13)


func test_the_tag_goes_above_the_hovered_area_first() -> void:
	var area := Rect2(200, 120, 20, 10)
	var at: Vector2 = HoverLabel.place(TAG, area, SCREEN, [] as Array[Rect2])
	assert_eq(at, Vector2(200, 120 - 1 - TAG.y), "1 px above, left-aligned")


func test_the_tag_goes_below_when_there_is_no_room_above() -> void:
	var area := Rect2(200, 4, 20, 10)
	var at: Vector2 = HoverLabel.place(TAG, area, SCREEN, [] as Array[Rect2])
	assert_eq(at, Vector2(200, 15))


func test_the_tag_keeps_clear_of_headings_and_the_note() -> void:
	var area := Rect2(140, 140, 30, 10)
	var heading := Rect2(134, 120, 136, 13)
	var note := Rect2(134, 160, 344, 22)
	var at: Vector2 = HoverLabel.place(TAG, area, SCREEN, [heading, note] as Array[Rect2])
	var tag := Rect2(at, TAG)
	assert_false(tag.intersects(heading), "never over the heading")
	assert_false(tag.intersects(note), "never over the note")
	assert_false(tag.intersects(area), "never over what it labels")
	assert_eq(at, Vector2(171, 140), "beside it, to the right")


## WP1's playtest: the held writ's "Send it on" sat over the claim heading.
func test_the_writs_tag_never_covers_the_claim_heading() -> void:
	var writ := Rect2(188, 80, 36, 14)
	var claim_heading := Rect2(136, 97, 40, 13)
	var at: Vector2 = HoverLabel.place(
		Vector2(56, 13), writ, SCREEN, [claim_heading] as Array[Rect2]
	)
	assert_false(Rect2(at, Vector2(56, 13)).intersects(claim_heading))
	assert_eq(at.y, writ.position.y - 1 - 13, "above the writ, away from the sheets")


## The first desk run's case: a back fact's tag below the fact ran across the claim sheet's lines.
## Ending at the fact's right edge keeps it on the chart.
func test_the_tag_slides_left_to_stay_off_a_sheet() -> void:
	var fact := Rect2(86, 137, 24, 12)
	var claim := Rect2(134, 100, 136, 54)
	var tag_size := Vector2(86, 13)
	var at: Vector2 = HoverLabel.place(tag_size, fact, SCREEN, [claim] as Array[Rect2])
	assert_false(Rect2(at, tag_size).intersects(claim), "clear of the sheet")
	assert_eq(at, Vector2(110 - 86, 137 - 1 - 13), "above, ending at the fact's right edge")


## The day-3 capture's case: a knot between the two sheets has no spot clear of paper. The tag
## covers sheet lines (avoided) rather than the witness heading (kept clear), and the fewest.
func test_a_heading_outranks_the_sheets_when_no_spot_is_free() -> void:
	var knot := Rect2(126, 147, 8, 8)
	var tag_size := Vector2(164, 13)
	var heading := Rect2(134, 157, 136, 12)
	var sheets: Array[Rect2] = [Rect2(134, 100, 136, 54), Rect2(134, 157, 136, 44)]
	var keep_clear: Array[Rect2] = [heading]
	var at: Vector2 = HoverLabel.place(tag_size, knot, SCREEN, keep_clear, sheets)
	assert_false(Rect2(at, tag_size).intersects(heading), "never over the heading")
	assert_eq(at, Vector2(0, 133), "above, ending at the knot's right edge: the least paper")


func test_the_tag_stays_inside_the_screen() -> void:
	var area := Rect2(470, 200, 10, 10)
	var at: Vector2 = HoverLabel.place(TAG, area, SCREEN, [] as Array[Rect2])
	assert_true(SCREEN.encloses(Rect2(at, TAG)), "clamped to the right edge")
	assert_eq(at, Vector2(440, 186))


func test_the_tag_shows_the_same_text_through_the_mouse() -> void:
	var tag: HoverLabel = _tag()
	tag.show_for("Send it on", Rect2(100, 100, 20, 10))
	await wait_process_frames(2)
	assert_eq(tag.shown_text(), "Send it on")
	assert_eq(tag.mouse_filter, Control.MOUSE_FILTER_IGNORE, "mouse-through")
	assert_eq(tag.tag_rect().end.y, 99.0, "above the area")
	assert_eq(tag.tag_rect().position, tag.tag_rect().position.round(), "whole pixels")
	tag.show_for("", Rect2(100, 100, 20, 10))
	assert_eq(tag.shown_text(), "", "an empty text hides it")


func test_the_tag_is_parchment_pinned_by_a_3x3_head_clear_of_the_text() -> void:
	var tag: HoverLabel = _tag()
	tag.show_for("the mentor", Rect2(100, 100, 20, 10))
	await wait_process_frames(2)
	var frame: ParchmentFrame = tag.get_node(^"Tag") as ParchmentFrame
	assert_false(frame.torn, "a clean tag")
	assert_eq(frame.size, tag.size)
	assert_eq(Palette.bounds(tag.drawn_rects()), Rect2(1, 1, 3, 3), "a 3x3 head in the corner")
	assert_eq(Palette.strays(tag.drawn_colors()), [] as Array[String])
	assert_eq(Palette.strays(frame.drawn_colors()), [] as Array[String])
	var text_left: float = HoverLabel.TEXT_AT.x
	assert_true(text_left > HoverLabel.PIN_AT.x + HoverLabel.PIN_SIZE, "the text starts past it")
	# Nothing but the ground lies under the text row: the frame's edge is one pixel.
	var ink := Rect2(text_left, 2, tag.size.x - text_left - HoverLabel.TEXT_RIGHT, 9)
	var ground: Color = THEME.get_color(&"parchment", &"DeskPalette")
	var others: Array[String] = []
	for y: int in range(int(ink.position.y), int(ink.end.y)):
		for x: int in range(int(ink.position.x), int(ink.end.x)):
			var color: Color = Palette.color_at(
				frame.drawn_rects(), frame.drawn_colors(), Vector2i(x, y)
			)
			if color != ground and others.size() < 3:
				others.append("%d,%d" % [x, y])
	assert_eq(others, [] as Array[String], "plain parchment under the text")


func test_a_doors_tag_still_leads_with_its_glyph() -> void:
	var tag: HoverLabel = _tag()
	tag.show_for("Valhalla", Rect2(100, 100, 20, 10), &"spear")
	assert_eq(tag.shown_glyph(), &"spear")


func _tag() -> HoverLabel:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var tag := HoverLabel.new()
	host.add_child(tag)
	return tag
