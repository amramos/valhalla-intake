extends GutTest
## Pins and thread (D12, D36): a 5×5 wooden pin head at each end, a 3 px thread (ink halo, core in
## the kind's colour, lighter edge) in its kind's pattern, a taut draw from the first end, an 8 px
## tied knot that fills once answered, and the cosmetic slack drop on a pin with no seam.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const ROUTE: Array[Vector2] = [Vector2(10, 10), Vector2(40, 10), Vector2(40, 30)]
const TRANSPARENT := Color(0, 0, 0, 0)


func test_a_pin_head_sits_on_each_end_of_the_thread() -> void:
	var line: ThreadLine = await _line(Seam.Kind.RED)
	var ends: Array[Rect2] = [Rect2(8, 8, 5, 5), Rect2(38, 28, 5, 5)]
	assert_eq(line.pin_head_rects(), ends, "5x5, centred on the route's ends")
	var head: Color = THEME.get_color(&"pin_head", &"DeskPalette")
	var highlight: Color = THEME.get_color(&"pin_highlight", &"DeskPalette")
	for end: Rect2 in ends:
		var centre := Vector2i(end.position) + Vector2i(2, 2)
		assert_eq(_at(line, centre), head, "a Wood 3 head at %s" % centre)
		assert_eq(_at(line, Vector2i(end.position) + Vector2i(1, 1)), highlight, "its highlight")


func test_the_thread_is_three_pixels_halo_core_and_lighter_edge() -> void:
	var line: ThreadLine = await _line(Seam.Kind.RED)
	var ink: Color = THEME.get_color(&"ink", &"DeskPalette")
	var across: Array[Color] = []
	for y: int in range(8, 13):
		across.append(_at(line, Vector2i(25, y)))
	var expected: Array[Color] = [
		TRANSPARENT,
		ink,
		THEME.get_color(&"thread_red", &"DeskPalette"),
		THEME.get_color(&"thread_red_light", &"DeskPalette"),
		TRANSPARENT,
	]
	assert_eq(across, expected, "halo, core, edge: 3 px in all")


func test_each_kind_keeps_its_pattern_with_the_halo_unbroken() -> void:
	var ink: Color = THEME.get_color(&"ink", &"DeskPalette")
	var patterns: Dictionary[int, String] = {}
	for kind: int in [Seam.Kind.RED, Seam.Kind.GREY, Seam.Kind.LAW]:
		var line: ThreadLine = await _line(kind)
		var pattern: String = ""
		for x: int in range(14, 24):
			pattern += "0" if _at(line, Vector2i(x, 10)) == ink else "1"
		patterns[kind] = pattern
	assert_eq(patterns[Seam.Kind.RED], "1111111111", "red: unbroken")
	assert_eq(patterns[Seam.Kind.GREY], "1010101010", "grey: dotted")
	assert_eq(patterns[Seam.Kind.LAW], "0111001110", "law: dashed")


func test_the_thread_draws_taut_from_its_first_end_and_shows_its_knot_last() -> void:
	var line: ThreadLine = await _line(Seam.Kind.GREY)
	var tween: Tween = line.draw_in(0.15)
	tween.pause()
	tween.custom_step(0.075)
	await wait_process_frames(1)
	assert_true(line.is_drawing_in())
	assert_ne(_at(line, Vector2i(12, 10)), TRANSPARENT, "the first end is drawn")
	assert_eq(_at(line, Vector2i(40, 28)), TRANSPARENT, "the far end is not yet")
	assert_false(line.knot().visible, "the knot waits for the whole thread")
	tween.custom_step(0.1)
	await wait_process_frames(1)
	assert_false(line.is_drawing_in())
	assert_ne(_at(line, Vector2i(40, 28)), TRANSPARENT, "the thread is whole")
	assert_true(line.knot().visible)


func test_drawing_in_with_no_time_draws_at_once() -> void:
	var line: ThreadLine = await _line(Seam.Kind.LAW)
	assert_null(line.draw_in(0.0), "reduce motion: no tween")
	assert_false(line.is_drawing_in())


func test_the_grey_knot_is_a_tied_knot_filled_once_answered() -> void:
	var line: ThreadLine = await _line(Seam.Kind.GREY)
	var grey: Color = THEME.get_color(&"thread_grey", &"DeskPalette")
	var box := Rect2(line.knot().global_position, line.knot().size)
	var open: int = _count_in(line, box, grey)
	line.answered = true
	await wait_process_frames(2)
	var filled: int = _count_in(line, box, grey)
	assert_eq(line.knot().size, Vector2(8, 8), "8 px")
	assert_eq(open, _knot_cells("#"), "the knot's strands")
	assert_eq(filled, _knot_cells("#") + _knot_cells("o"), "answered: the loop fills")


func test_slack_thread_drops_twenty_pixels_and_frees_itself() -> void:
	var line: ThreadLine = await _line(Seam.Kind.RED)
	var tween: Tween = line.slacken_and_drop(0.4)
	tween.pause()
	assert_eq(line.knot().mouse_filter, Control.MOUSE_FILTER_IGNORE, "D51: never takes a click")
	tween.custom_step(0.5)
	assert_true(line.is_queued_for_deletion(), "gone once it has fallen")


func test_every_colour_is_a_palette_colour() -> void:
	for kind: int in [Seam.Kind.RED, Seam.Kind.GREY, Seam.Kind.LAW]:
		var line: ThreadLine = await _line(kind)
		line.answered = true
		line.selected = true
		await wait_process_frames(2)
		assert_eq(Palette.strays(line.drawn_colors()), [] as Array[String], "kind %d" % kind)


func _at(line: ThreadLine, at: Vector2i) -> Color:
	return Palette.color_at(line.drawn_rects(), line.drawn_colors(), at)


func _count_in(line: ThreadLine, box: Rect2, color: Color) -> int:
	var count: int = 0
	for y: int in range(int(box.position.y), int(box.end.y)):
		for x: int in range(int(box.position.x), int(box.end.x)):
			count += 1 if _at(line, Vector2i(x, y)) == color else 0
	return count


func _knot_cells(code: String) -> int:
	var count: int = 0
	for row: String in ThreadLine.KNOT:
		count += row.count(code)
	return count


func _line(kind: int) -> ThreadLine:
	var host := Control.new()
	host.theme = THEME
	host.size = Vector2(80, 60)
	add_child_autofree(host)
	var line := ThreadLine.new()
	host.add_child(line)
	line.size = host.size
	var caps: Array[Rect2] = []
	line.setup(kind, 0, PackedVector2Array(ROUTE), caps, "")
	# Keep the knot clear of the strip the tests read.
	line.knot().global_position = Vector2(50, 40)
	await wait_process_frames(2)
	return line
