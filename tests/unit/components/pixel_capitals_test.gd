extends GutTest
## The carved capitals (D3): every capital, digit and the Roman numerals have a glyph; each letter
## is a face ringed by an ink outline 8×11 px with a shadow one pixel right and down; widths add
## up; only the three carved colours are painted, on whole pixels, within the drawn box; accents
## fall back to their base letters.

const PALETTE_PATH := "res://docs/art/palette.gpl"
const THEME_PATH := "res://scenes/desk/desk_theme.tres"
const FACE := Color(1, 0, 0)
const INK := Color(0, 1, 0)
const SHADOW := Color(0, 0, 1)
const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const DIGITS := "0123456789"


func test_every_capital_digit_and_numeral_has_a_glyph_of_nine_even_rows() -> void:
	var faults: Array[String] = []
	for character: String in LETTERS + DIGITS:
		var rows: Array = PixelCapitals.GLYPHS.get(character, [])
		if rows.size() != 9:
			faults.append("%s has %d rows" % [character, rows.size()])
			continue
		for row: Variant in rows:
			if (row as String).length() != (rows[0] as String).length():
				faults.append("%s has uneven rows" % character)
	assert_eq(faults, [] as Array[String])


func test_a_letter_is_eight_by_eleven_with_its_outline_and_one_more_for_the_shadow() -> void:
	var box: Rect2i = _box(_pixels("D"))
	assert_eq(box, Rect2i(0, 0, 9, 12), "D: 8×11 carved, the shadow's column and row beyond")
	assert_eq(_box(_pixels("D", [INK, FACE])), Rect2i(0, 0, 8, 11), "the outline is 8×11")
	assert_eq(PixelCapitals.HEIGHT, 12)


func test_widths_add_up_and_draw_returns_the_width() -> void:
	assert_eq(PixelCapitals.width("D"), 9)
	assert_eq(PixelCapitals.width("I"), 7, "the numeral I is narrow, so III reads as three")
	assert_eq(PixelCapitals.width("M"), 10)
	assert_eq(PixelCapitals.width(" "), PixelCapitals.SPACE)
	assert_eq(PixelCapitals.width("DAY II"), 9 + 9 + 9 + 4 + 7 + 7 + 5 * PixelCapitals.GAP)
	assert_eq(PixelCapitals.GAP, 1, "a clear column between letters")
	var pair: Dictionary[Vector2i, Color] = _pixels("HH")
	var touching: int = 0
	for y: int in range(PixelCapitals.HEIGHT):
		touching += int(pair.has(Vector2i(9, y)))
	assert_eq(touching, 0, "so neighbours' outlines never merge")
	assert_eq(PixelCapitals.width(""), 0)
	for text: String in ["DAY III", "VALHALLA INTAKE", "Dusk, day 1", "Hel's tide"]:
		var drawn: int = PixelCapitals.paint_runs(text, Vector2i(3, 4), _ignore, FACE, INK, SHADOW)
		assert_eq(drawn, PixelCapitals.width(text), text)


func test_only_the_three_carved_colours_on_whole_pixels_inside_the_drawn_box() -> void:
	var at := Vector2i(17, 5)
	var text := "DAY III 0123456789"
	var rects: Array[Rect2] = []
	var colors: Array[Color] = []
	var width: int = PixelCapitals.paint_runs(
		text,
		at,
		func(rect: Rect2, color: Color) -> void:
			rects.append(rect)
			colors.append(color),
		FACE,
		INK,
		SHADOW
	)
	var bounds := Rect2(Vector2(at), Vector2(width, PixelCapitals.HEIGHT))
	var faults: Array[String] = []
	for index: int in range(rects.size()):
		var rect: Rect2 = rects[index]
		if not [FACE, INK, SHADOW].has(colors[index]):
			faults.append("colour %s" % colors[index])
		if rect.position != rect.position.round() or rect.size != rect.size.round():
			faults.append("fractional %s" % rect)
		if rect.size.y != 1.0 or not bounds.encloses(rect):
			faults.append("outside or not a row run %s" % rect)
	assert_gt(rects.size(), 50)
	assert_eq(faults, [] as Array[String])


func test_the_outline_rings_every_face_pixel_and_the_shadow_falls_bottom_right() -> void:
	var faults: Array[String] = []
	for character: String in LETTERS + DIGITS:
		var grid: Dictionary[Vector2i, Color] = _pixels(character)
		for pixel: Vector2i in grid:
			if grid[pixel] == FACE:
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var next: Vector2i = pixel + Vector2i(dx, dy)
						if not grid.has(next) or grid[next] == SHADOW:
							faults.append("%s: face %s is open at %s" % [character, pixel, next])
			elif grid[pixel] == SHADOW:
				var behind: Vector2i = pixel - Vector2i.ONE
				if not grid.has(behind) or grid[behind] == SHADOW:
					faults.append("%s: shadow %s casts from nothing" % [character, pixel])
		if _box(grid).position != Vector2i.ZERO:
			faults.append("%s does not start at its top-left" % character)
	assert_eq(faults, [] as Array[String])


func test_lower_case_and_accents_fall_back_to_the_base_capitals() -> void:
	assert_eq(PixelCapitals.base_text("Fólkvangr"), "FOLKVANGR")
	assert_eq(PixelCapitals.base_text("Rán Ragnarök"), "RAN RAGNAROK")
	assert_eq(PixelCapitals.base_text("Æsir"), "AESIR")
	assert_eq(_pixels("Ó"), _pixels("O"), "an accented capital draws its base letter")
	assert_eq(_pixels("day"), _pixels("DAY"))
	assert_eq(PixelCapitals.width("#"), PixelCapitals.SPACE, "a character with no glyph is a gap")


func test_the_carved_colours_are_palette_colours_and_the_desk_theme_names_them() -> void:
	var palette: Array[int] = _palette()
	assert_gt(palette.size(), 20, "the palette file was read")
	for color: Color in [PixelCapitals.PARCHMENT_2, PixelCapitals.NIGHT_0, PixelCapitals.NIGHT_1]:
		assert_true(palette.has(color.to_rgba32()), color.to_html(false))
	var theme: Theme = load(THEME_PATH)
	assert_eq(
		theme.get_color(&"ink", &"DeskPalette").to_rgba32(), PixelCapitals.NIGHT_0.to_rgba32()
	)
	assert_eq(
		theme.get_color(&"night", &"DeskPalette").to_rgba32(), PixelCapitals.NIGHT_1.to_rgba32()
	)
	assert_eq(
		theme.get_color(&"text_light", &"DeskPalette").to_rgba32(),
		PixelCapitals.PARCHMENT_2.to_rgba32()
	)


func test_draw_paints_on_a_canvas_and_returns_the_width() -> void:
	var canvas := Control.new()
	canvas.theme = load(THEME_PATH)
	canvas.size = Vector2(120, 20)
	var drawn: Array[int] = []
	canvas.draw.connect(
		func() -> void: drawn.append(PixelCapitals.draw(canvas, "DAY II", Vector2(2, 2), FACE))
	)
	add_child_autofree(canvas)
	await wait_process_frames(2)
	assert_eq(drawn.size(), 1, "drawn once")
	assert_eq(drawn[0] if not drawn.is_empty() else -1, PixelCapitals.width("DAY II"))


func test_roman_numerals_for_the_titles() -> void:
	var numerals: Array[String] = []
	for number: int in [1, 2, 3, 4, 5, 9, 14, 40, 0]:
		numerals.append(PixelCapitals.roman(number))
	assert_eq(numerals, ["I", "II", "III", "IV", "V", "IX", "XIV", "XL", ""] as Array[String])


## A critic's finding: N read as a Pi at 3x. Its two stems are joined by a diagonal stepping down
## from the left stem to the right one, one pixel a row, and no letter with a V or a diagonal
## (M, N, W, K) has a solid bar across its stems.
func test_n_has_its_diagonal_and_no_letter_bars_its_stems() -> void:
	var rows: Array = PixelCapitals.GLYPHS["N"]
	var diagonal: Array[int] = []
	for y: int in range(1, 7):
		var inner: String = (rows[y] as String).substr(2, 2)
		assert_eq(inner.count("#"), 1, "N row %d: one diagonal pixel between the stems" % y)
		diagonal.append(inner.find("#"))
	assert_eq(diagonal, [0, 0, 0, 1, 1, 1] as Array[int], "stepping from left to right")
	assert_eq(rows[0] as String, "##..##", "no top bar")
	for letter: String in ["M", "N", "W", "K", "0"]:
		for row: Variant in PixelCapitals.GLYPHS[letter]:
			assert_ne((row as String).count("."), 0, "%s has no solid bar" % letter)


func test_a_title_card_draws_the_capitals_at_twice_their_size() -> void:
	assert_eq(PixelCapitals.width("DAY II", 2), PixelCapitals.width("DAY II") * 2)
	var single: Dictionary[Vector2i, Color] = _pixels("DAY II")
	var double: Dictionary[Vector2i, Color] = {}
	PixelCapitals.paint_runs(
		"DAY II",
		Vector2i.ZERO,
		func(rect: Rect2, color: Color) -> void:
			for y: int in range(int(rect.position.y), int(rect.end.y)):
				for x: int in range(int(rect.position.x), int(rect.end.x)):
					double[Vector2i(x, y)] = color,
		FACE,
		INK,
		SHADOW,
		2
	)
	var faults: int = 0
	for pixel: Vector2i in double:
		if single.get(pixel / 2, Color.BLACK) != double[pixel]:
			faults += 1
	assert_eq(double.size(), single.size() * 4, "each pixel a 2x2 block")
	assert_eq(faults, 0, "of the same colour")


## Every painted pixel of `text` drawn at the origin, last colour wins, limited to `only`.
func _pixels(text: String, only: Array[Color] = [FACE, INK, SHADOW]) -> Dictionary[Vector2i, Color]:
	var grid: Dictionary[Vector2i, Color] = {}
	PixelCapitals.paint_runs(
		text,
		Vector2i.ZERO,
		func(rect: Rect2, color: Color) -> void:
			if only.has(color):
				for x: int in range(int(rect.position.x), int(rect.end.x)):
					grid[Vector2i(x, int(rect.position.y))] = color,
		FACE,
		INK,
		SHADOW
	)
	return grid


func _ignore(_rect: Rect2, _color: Color) -> void:
	pass


func _box(grid: Dictionary[Vector2i, Color]) -> Rect2i:
	var box := Rect2i()
	var first: bool = true
	for pixel: Vector2i in grid:
		if first:
			box = Rect2i(pixel, Vector2i.ONE)
			first = false
		else:
			box = box.expand(pixel).expand(pixel + Vector2i.ONE)
	return box


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
