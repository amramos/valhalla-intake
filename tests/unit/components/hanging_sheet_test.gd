extends GutTest
## The hanging sheet (D37, D42): a parchment hung by two pin heads at its top corners, its heading
## in the carved capitals centred near its top, everything in palette colours.

const THEME := preload("res://scenes/desk/desk_theme.tres")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")


func test_two_pin_heads_hang_it_by_its_top_corners() -> void:
	var sheet: HangingSheet = await _sheet("PAUSED", Vector2(170, 90))
	var head: Color = THEME.get_color(&"pin_head", &"DeskPalette")
	var found: Array[Color] = []
	for pin: Rect2 in sheet.pin_rects():
		var middle := Vector2i(pin.position) + Vector2i(1, 1)
		found.append(Palette.color_at(sheet.drawn_rects(), sheet.drawn_colors(), middle))
	assert_eq(sheet.pin_rects(), [Rect2(3, 3, 3, 3), Rect2(163, 3, 3, 3)] as Array[Rect2])
	assert_eq(found, [head, head] as Array[Color])


func test_the_heading_is_centred_in_capitals_with_a_parchment_face() -> void:
	var sheet: HangingSheet = await _sheet("Options", Vector2(232, 128))
	var heading: Rect2 = sheet.heading_rect()
	assert_eq(heading.size.x, float(PixelCapitals.width("Options")))
	assert_almost_eq(heading.get_center().x, 116.0, 1.0)
	assert_has(sheet.drawn_colors(), THEME.get_color(&"parchment_light", &"DeskPalette"))
	assert_true(Rect2(Vector2.ZERO, sheet.size).encloses(heading))


func test_everything_drawn_is_a_palette_colour() -> void:
	var sheet: HangingSheet = await _sheet("PAUSED", Vector2(170, 90))
	var colors: Array[Color] = sheet.drawn_colors()
	colors.append_array((sheet.get_child(0) as ParchmentFrame).drawn_colors())
	assert_gt(colors.size(), 20)
	assert_eq(Palette.strays(colors), [] as Array[String])


func _sheet(heading: String, size: Vector2) -> HangingSheet:
	var host := Control.new()
	host.theme = THEME
	host.size = Vector2(480, 270)
	add_child_autofree(host)
	var sheet := HangingSheet.new()
	sheet.heading = heading
	host.add_child(sheet)
	sheet.size = size
	await wait_frames(2)
	return sheet
