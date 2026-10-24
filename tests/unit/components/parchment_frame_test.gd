extends GutTest
## The parchment sheet (D8): the text area is solid flat ground and nothing else, every pixel is a
## palette colour on whole-pixel rectangles, and the same seed always draws the same sheet.

const SIZE := Vector2(120, 60)
const INNER := Rect2(4, 12, 110, 40)
const RULE_Y := 9
const PALETTE_PATH := "res://docs/art/palette.gpl"
const SEEDS: Array[int] = [0, 1, 2, 3, 7, 42, 99, 1234]


func test_the_text_area_is_solid_flat_ground_and_nothing_else() -> void:
	var faults: Array[String] = []
	for torn: bool in [false, true]:
		for sheet_seed: int in SEEDS:
			var frame: ParchmentFrame = await _drawn(sheet_seed, torn, RULE_Y, INNER)
			for fault: String in _inner_faults(frame, INNER):
				faults.append("seed %d torn %s: %s" % [sheet_seed, torn, fault])
	assert_eq(faults, [] as Array[String], "inner is all Parchment 1, under no other colour")


func test_an_inner_reaching_into_the_edge_band_is_solid_ground_to_its_last_column() -> void:
	# A sheet's lines can run to within a pixel or two of its right edge (a playtest bug: the
	# desk showed through under the last columns of a 136 px sheet).
	var faults: Array[String] = []
	var inners: Array[Rect2] = [
		Rect2(4, 12, 114, 40), Rect2(4, 12, 116, 40), Rect2(0, 20, 120, 10), Rect2(1, 1, 118, 58)
	]
	for inner: Rect2 in inners:
		for torn: bool in [false, true]:
			var frame: ParchmentFrame = await _drawn(5, torn, 25, inner)
			for fault: String in _inner_faults(frame, inner):
				faults.append("%s torn %s: %s" % [inner, torn, fault])
	assert_eq(faults, [] as Array[String])


func test_every_colour_is_a_palette_colour() -> void:
	var palette: Array[int] = _palette()
	var strays: Array[String] = []
	for torn: bool in [false, true]:
		var frame: ParchmentFrame = await _drawn(3, torn, RULE_Y, INNER)
		for color: Color in frame.drawn_colors():
			if not palette.has(color.to_rgba32()):
				strays.append(color.to_html(false))
	assert_gt(palette.size(), 20, "the palette file was read")
	assert_eq(strays, [] as Array[String])


func test_every_rect_sits_on_whole_pixels() -> void:
	var frame: ParchmentFrame = await _drawn(11, true, RULE_Y, INNER)
	var fractional: int = 0
	for rect: Rect2 in frame.drawn_rects():
		if rect.position != rect.position.round() or rect.size != rect.size.round():
			fractional += 1
	assert_gt(frame.drawn_rects().size(), 10)
	assert_eq(fractional, 0)


func test_the_same_seed_draws_the_same_sheet_and_another_seed_another() -> void:
	var first: ParchmentFrame = await _drawn(42, true, RULE_Y, INNER)
	var again: ParchmentFrame = await _drawn(42, true, RULE_Y, INNER)
	var other: ParchmentFrame = await _drawn(43, true, RULE_Y, INNER)
	assert_eq(first.drawn_rects(), again.drawn_rects())
	assert_eq(first.drawn_colors(), again.drawn_colors())
	assert_ne(first.drawn_rects(), other.drawn_rects())


func test_a_torn_sheet_loses_outer_edge_pixels() -> void:
	var clean: ParchmentFrame = await _drawn(8, false, -1, INNER)
	var torn: ParchmentFrame = await _drawn(8, true, -1, INNER)
	var clean_top: int = _painted_on_row(clean, 0)
	var torn_top: int = _painted_on_row(torn, 0)
	assert_eq(clean_top, int(SIZE.x) - 1, "a clean sheet's top edge is whole")
	assert_lt(torn_top, clean_top, "bites leave gaps in a torn top edge")


func test_the_shadow_is_wood_along_the_bottom_and_right() -> void:
	var frame: ParchmentFrame = await _drawn(4, false, -1, INNER)
	var shadow_pixels: int = 0
	var other_pixels: int = 0
	var rects: Array[Rect2] = frame.drawn_rects()
	var colors: Array[Color] = frame.drawn_colors()
	for index: int in range(rects.size()):
		var on_shadow: bool = (
			rects[index].position.y == SIZE.y - 1 or rects[index].position.x == SIZE.x - 1
		)
		if on_shadow and colors[index] == ParchmentFrame.WOOD_1:
			shadow_pixels += int(rects[index].get_area())
		elif on_shadow:
			other_pixels += 1
	assert_eq(other_pixels, 0, "only the shadow lies on the last row and column")
	assert_eq(shadow_pixels, int(SIZE.x) - 1 + int(SIZE.y) - 2)


func test_the_rule_row_crosses_the_sheet_only_when_asked() -> void:
	var ruled: ParchmentFrame = await _drawn(6, false, RULE_Y, INNER)
	var plain: ParchmentFrame = await _drawn(6, false, -1, INNER)
	assert_eq(_painted_on_row(ruled, RULE_Y), int(SIZE.x), "the rule, the edge band, the shadow")
	assert_eq(_painted_on_row(plain, RULE_Y), 5, "without a rule only the band and the shadow")


func test_the_desk_theme_colours_paint_the_sheet() -> void:
	var theme: Theme = load("res://scenes/desk/desk_theme.tres")
	var frame := ParchmentFrame.new()
	frame.theme = theme
	frame.size = SIZE
	frame.seed = 2
	frame.rule_y = RULE_Y
	frame.inner = INNER
	add_child_autofree(frame)
	await wait_process_frames(2)
	var expected: Array[Color] = [theme.get_color(&"parchment", &"DeskPalette")]
	for color_name: StringName in [&"parchment_edge", &"parchment_shadow", &"rule"]:
		if theme.has_color(color_name, &"DeskPalette"):
			expected.append(theme.get_color(color_name, &"DeskPalette"))
	var colors: Array[Color] = frame.drawn_colors()
	assert_eq(colors[0], expected[0], "the ground is the theme's parchment")
	for color: Color in expected:
		assert_true(colors.has(color), "the sheet uses %s" % color.to_html(false))


func _drawn(sheet_seed: int, torn: bool, rule_y: int, inner: Rect2) -> ParchmentFrame:
	var frame := ParchmentFrame.new()
	frame.size = SIZE
	frame.seed = sheet_seed
	frame.torn = torn
	frame.rule_y = rule_y
	frame.inner = inner
	add_child_autofree(frame)
	await wait_process_frames(2)
	return frame


## What breaks "inner is solid flat ground": a pixel under `inner` that ends up anything but
## Parchment 1 (or unpainted), a ground that isn't Parchment 1, or any rect but the ground (the
## first) crossing `inner`. The rects are replayed in order on a pixel grid, as `_draw` paints.
func _inner_faults(frame: ParchmentFrame, inner: Rect2) -> Array[String]:
	var faults: Array[String] = []
	var rects: Array[Rect2] = frame.drawn_rects()
	var colors: Array[Color] = frame.drawn_colors()
	var grid: Dictionary[Vector2i, Color] = {}
	for index: int in range(rects.size()):
		var rect: Rect2 = rects[index]
		if index == 0 and colors[index] != ParchmentFrame.PARCHMENT_1:
			faults.append("the ground is %s" % colors[index].to_html(false))
		elif index > 0 and rect.intersects(inner):
			faults.append("%s in %s crosses inner" % [rect, colors[index].to_html(false)])
		for y: int in range(int(rect.position.y), int(rect.end.y)):
			for x: int in range(int(rect.position.x), int(rect.end.x)):
				grid[Vector2i(x, y)] = colors[index]
	for y: int in range(int(SIZE.y)):
		for x: int in range(int(SIZE.x)):
			if not inner.intersects(Rect2(x, y, 1, 1)):
				continue
			var at := Vector2i(x, y)
			if not grid.has(at):
				faults.append("%s unpainted" % at)
			elif grid[at] != ParchmentFrame.PARCHMENT_1:
				faults.append("%s is %s" % [at, grid[at].to_html(false)])
	return faults


## Pixels painted on row `y` over the ground (the ground, the first rect, is left out).
func _painted_on_row(frame: ParchmentFrame, y: int) -> int:
	var pixels: int = 0
	var rects: Array[Rect2] = frame.drawn_rects()
	for rect: Rect2 in rects.slice(1):
		if rect.position.y <= y and rect.end.y > y:
			pixels += int(rect.size.x)
	return pixels


func _palette() -> Array[int]:
	var colors: Array[int] = []
	var file: FileAccess = FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		return colors
	var entry := RegEx.create_from_string(r"^\s*(\d+)\s+(\d+)\s+(\d+)")
	while not file.eof_reached():
		var found: RegExMatch = entry.search(file.get_line())
		if found != null:
			var rgb: Color = Color8(
				int(found.get_string(1)), int(found.get_string(2)), int(found.get_string(3))
			)
			colors.append(rgb.to_rgba32())
	return colors
