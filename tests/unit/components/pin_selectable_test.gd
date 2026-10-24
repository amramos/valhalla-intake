extends GutTest
## A pin's marks (D12): a hovered line is underlined in ink under its text, a hovered fact shows
## corner brackets, and the selected item carries a stuck 5×5 pin head, never a filled box over
## its text.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const LINE := Vector2(132, 10)
const FACT := Vector2(10, 12)


func test_a_hovered_line_is_underlined_on_its_last_row_under_its_text_only() -> void:
	var hit: PinSelectable = _area(LINE, PinSelectable.HoverMark.UNDERLINE, false)
	hit.underline_width = 60
	hit._on_mouse_entered()
	await wait_process_frames(2)
	assert_eq(hit.drawn_rects(), [Rect2(0, 9, 60, 1)] as Array[Rect2], "one ink row, text-wide")
	assert_eq(hit.drawn_colors(), [hit.underline_color] as Array[Color])
	hit._on_mouse_exited()
	await wait_process_frames(2)
	assert_eq(hit.drawn_rects(), [] as Array[Rect2], "gone when the mouse leaves")


func test_a_hovered_fact_shows_corner_brackets_and_an_idle_one_corner_ticks() -> void:
	var hit: PinSelectable = _area(FACT, PinSelectable.HoverMark.CORNERS, true)
	hit.show_corners = true
	await wait_process_frames(2)
	var idle: Array[Rect2] = hit.drawn_rects()
	hit._on_mouse_entered()
	await wait_process_frames(2)
	var hovered: Array[Rect2] = hit.drawn_rects()
	var interior := Rect2(Vector2(3, 3), FACT - Vector2(6, 6))
	var crossing: int = 0
	var longest: float = 0.0
	for rect: Rect2 in hovered:
		crossing += 1 if rect.intersects(interior) else 0
		longest = maxf(longest, maxf(rect.size.x, rect.size.y))
	assert_eq(Palette.bounds(idle), Rect2(Vector2.ZERO, FACT), "idle ticks sit in the corners")
	assert_eq(longest, float(PinSelectable.BRACKET), "hover brackets are 3 px arms")
	assert_eq(crossing, 0, "no bracket reaches into the fact's middle")


func test_the_selected_line_carries_a_stuck_pin_left_of_its_text() -> void:
	var hit: PinSelectable = _area(LINE, PinSelectable.HoverMark.UNDERLINE, false)
	hit.selected = true
	await wait_process_frames(2)
	var rects: Array[Rect2] = hit.drawn_rects()
	var inside: int = 0
	for rect: Rect2 in rects:
		inside += 1 if rect.intersects(Rect2(Vector2.ZERO, LINE)) else 0
	assert_eq(Palette.bounds(rects), Rect2(-5, 1, 5, 5), "a 5x5 head just left of the line")
	assert_eq(Palette.bounds(rects), hit.pin_rect())
	assert_eq(inside, 0, "nothing is painted over the line's text")
	_assert_pin_colours(hit)


func test_a_selected_fact_carries_its_pin_inside_its_corner() -> void:
	var hit: PinSelectable = _area(FACT, PinSelectable.HoverMark.CORNERS, true)
	hit.selected = true
	await wait_process_frames(2)
	assert_eq(Palette.bounds(hit.drawn_rects()), Rect2(1, 1, 5, 5))
	_assert_pin_colours(hit)


func test_a_lit_selected_item_shows_both_its_outline_and_its_pin() -> void:
	var hit: PinSelectable = _area(LINE, PinSelectable.HoverMark.UNDERLINE, false)
	hit.selected = true
	hit.lit = true
	await wait_process_frames(2)
	var colors: Array[Color] = hit.drawn_colors()
	assert_true(colors.has(hit.lit_color), "the lit outline")
	assert_true(colors.has(hit.pin_color), "the stuck pin")
	assert_eq(Palette.bounds(hit.drawn_rects()), Rect2(-5, 0, LINE.x + 5, LINE.y))


func test_the_pin_head_is_round_with_one_highlight_pixel_and_a_shadow() -> void:
	var canvas := Palette.new()
	var head := Color.RED
	var light := Color.WHITE
	var shade := Color.BLACK
	PinSelectable.draw_pin_head(canvas.paint, Vector2i(10, 20), head, light, shade)
	assert_eq(Palette.bounds(canvas.rects), Rect2(10, 20, 5, 5), "5x5")
	var cut: Array[Color] = []
	for corner: Vector2i in [
		Vector2i(10, 20), Vector2i(14, 20), Vector2i(10, 24), Vector2i(14, 24)
	]:
		cut.append(Palette.color_at(canvas.rects, canvas.colors, corner))
	assert_eq(cut, [Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)])
	var lit: int = 0
	var shadow: int = 0
	for y: int in range(20, 25):
		for x: int in range(10, 15):
			var color: Color = Palette.color_at(canvas.rects, canvas.colors, Vector2i(x, y))
			lit += 1 if color == light else 0
			shadow += 1 if color == shade else 0
	assert_eq(lit, 1, "one highlight pixel")
	assert_eq(shadow, 6, "a shadow along the bottom and right")


func test_the_desk_theme_pin_colours_are_ember_on_palette() -> void:
	var theme: Theme = load("res://scenes/desk/desk_theme.tres")
	var named: Dictionary[String, Color] = Palette.by_name()
	assert_eq(
		theme.get_color(&"pin_selected", &"DeskPalette").to_html(false),
		named["Ember 2"].to_html(false)
	)
	assert_eq(
		theme.get_color(&"pin_selected_shadow", &"DeskPalette").to_html(false),
		named["Ember 0"].to_html(false)
	)
	assert_eq(
		theme.get_color(&"pin_head", &"DeskPalette").to_html(false), named["Wood 3"].to_html(false)
	)
	assert_eq(
		theme.get_color(&"pin_highlight", &"DeskPalette").to_html(false),
		named["Parchment 2"].to_html(false)
	)


func _assert_pin_colours(hit: PinSelectable) -> void:
	var allowed: Array[Color] = [hit.pin_color, hit.pin_highlight, hit.pin_shadow]
	var others: int = 0
	for color: Color in hit.drawn_colors():
		others += 0 if allowed.has(color) else 1
	assert_eq(others, 0, "the stuck pin is drawn in its own colours only")


func _area(area_size: Vector2, mark: PinSelectable.HoverMark, inside: bool) -> PinSelectable:
	var hit := PinSelectable.new()
	hit.size = area_size
	hit.hover_mark = mark
	hit.pin_inside = inside
	add_child_autofree(hit)
	return hit
