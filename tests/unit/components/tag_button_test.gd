extends GutTest
## The nailed paper tag (D24, D37, D42): a guarded button drawn as a small torn parchment sheet
## with its drop shadow and a 5×5 pin head in its corner; the chosen tag of a choice carries the
## ember pin, a disabled tag dims, a hovered one lifts 1 px (not under reduce motion) and is rimmed
## in wood, and the guard still swallows a double-click's second press.

const THEME := preload("res://scenes/desk/desk_theme.tres")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")


func test_a_tag_is_as_wide_as_its_text_and_one_tag_high() -> void:
	var tag: TagButton = _tag("Restart the run")
	var font: Font = THEME.default_font
	var text: int = ceili(font.get_string_size(tag.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	assert_eq(tag.size, Vector2(TagButton.TEXT_LEFT + text + TagButton.TEXT_RIGHT, 14))
	# 3 px of ground after the last letter, then the ring, the edge and the shadow: the torn
	# right edge never sits against the text (a critic read it as "!").
	var ground_after: float = tag.sheet().inner.end.x - 1 - (TagButton.TEXT_LEFT + text)
	assert_gte(ground_after, 3.0)
	assert_eq(tag.text_origin(), Vector2i(8, 10), "the text clears the pin, a row below the edge")
	tag.place(Vector2(10.6, 20.2), 200)
	assert_eq(tag.get_rect(), Rect2(10, 20, 200, 14), "placed on whole pixels, as wide as asked")
	tag.place(Vector2(0, 0), 4)
	assert_eq(tag.size.x, float(tag.fit_width()), "never narrower than its text")


func test_the_pin_head_is_wood_ember_when_chosen_and_absent_when_bare() -> void:
	var tag: TagButton = _tag("Fast")
	var heads: Array = []
	for pin: TagButton.Pin in [TagButton.Pin.WOOD, TagButton.Pin.CHOSEN, TagButton.Pin.NONE]:
		tag.pin = pin
		await wait_frames(2)
		heads.append(Palette.color_at(tag.drawn_rects(), tag.drawn_colors(), Vector2i(3, 3)))
	assert_eq(
		heads,
		[
			THEME.get_color(&"pin_head", &"DeskPalette"),
			THEME.get_color(&"pin_selected", &"DeskPalette"),
			Color(0, 0, 0, 0),
		]
	)


func test_the_pin_head_is_five_by_five_with_its_highlight_and_shadow() -> void:
	var tag: TagButton = _tag("Start")
	await wait_frames(2)
	var at: Array[Color] = []
	for pixel: Vector2i in [Vector2i(2, 2), Vector2i(3, 3), Vector2i(5, 3), Vector2i(3, 5)]:
		at.append(Palette.color_at(tag.drawn_rects(), tag.drawn_colors(), pixel))
	var shadow: Color = THEME.get_color(&"parchment_shadow", &"DeskPalette")
	assert_eq(
		at,
		(
			[
				THEME.get_color(&"pin_highlight", &"DeskPalette"),
				THEME.get_color(&"pin_head", &"DeskPalette"),
				shadow,
				shadow,
			]
			as Array[Color]
		)
	)
	assert_eq(Palette.bounds(tag.drawn_rects()), Rect2(1, 1, 5, 5), "the pin is all it paints")


func test_the_sheet_is_torn_its_own_way_with_a_wood_drop_shadow() -> void:
	var start: TagButton = _tag("Start")
	var quit: TagButton = _tag("Quit")
	quit.size.x = start.size.x
	await wait_frames(2)
	assert_true(start.sheet().torn and quit.sheet().torn)
	assert_ne(start.sheet().seed, quit.sheet().seed, "one seed per tag")
	var wood_1: Color = THEME.get_color(&"parchment_shadow", &"DeskPalette")
	var bottom: int = int(start.size.y) - 1
	var shadow: int = 0
	for index: int in range(start.sheet().drawn_rects().size()):
		var rect: Rect2 = start.sheet().drawn_rects()[index]
		if rect.position.y == bottom and start.sheet().drawn_colors()[index] == wood_1:
			shadow += int(rect.size.x)
	assert_gt(shadow, int(start.size.x) / 2, "most of the bottom row is the Wood 1 shadow")
	assert_ne(start.sheet().drawn_rects(), quit.sheet().drawn_rects(), "the two tear differently")


func test_a_hovered_tag_lifts_one_pixel_unless_motion_is_reduced() -> void:
	var tag: TagButton = _tag("Resume")
	var rest: Rect2 = tag.get_rect()
	tag._set_hovered(true)
	var lifted: Array = [tag.lift(), tag.sheet().position.y, tag.get_rect() == rest]
	tag.reduce_motion = true
	var still: Array = [tag.lift(), tag.sheet().position.y]
	await wait_frames(2)
	var rim: Color = Palette.color_at(tag.drawn_rects(), tag.drawn_colors(), Vector2i(10, 0))
	assert_eq(lifted, [1, -1.0, true], "the sheet lifts; the hit area stays")
	assert_eq(still, [0, 0.0], "reduce motion: no lift")
	assert_eq(rim, THEME.get_color(&"frame", &"DeskPalette"), "but the rim still shows")


func test_a_disabled_tag_dims_its_ground_and_a_hovered_one_is_rimmed() -> void:
	var tag: TagButton = _tag("Quit")
	tag.disabled = true
	await wait_frames(2)
	var ground: Color = Palette.color_at(tag.drawn_rects(), tag.drawn_colors(), Vector2i(5, 6))
	tag.disabled = false
	tag._set_hovered(true)
	await wait_frames(2)
	var rim: Color = Palette.color_at(tag.drawn_rects(), tag.drawn_colors(), Vector2i(8, -1))
	assert_eq(
		[ground, rim],
		[
			THEME.get_color(&"parchment_edge", &"DeskPalette"),
			THEME.get_color(&"frame", &"DeskPalette"),
		]
	)


func test_the_guard_still_swallows_a_double_clicks_second_press() -> void:
	var tag: TagButton = _tag("Yes")
	tag.arm_now()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.double_click = true
	assert_true(tag.blocks(press))
	tag.rearm()
	press.double_click = false
	assert_true(tag.blocks(press), "and any press before it is armed")


func test_everything_drawn_is_a_palette_colour() -> void:
	var colors: Array[Color] = []
	for pin: TagButton.Pin in [TagButton.Pin.WOOD, TagButton.Pin.CHOSEN]:
		var tag: TagButton = _tag("Options")
		tag.pin = pin
		tag._set_hovered(true)
		var dim: TagButton = _tag("Resume")
		dim.disabled = true
		await wait_frames(2)
		for drawn: TagButton in [tag, dim]:
			colors.append_array(drawn.drawn_colors())
			colors.append_array(drawn.sheet().drawn_colors())
	assert_gt(colors.size(), 20)
	assert_eq(Palette.strays(colors), [] as Array[String])


## The darker face for a tag over a parchment page: Wood 4 ground, Wood 3 edges, ink text.
func test_a_dark_tag_has_a_wood_face_and_ink_text() -> void:
	var tag: TagButton = _tag("Play again")
	tag.dark = true
	await wait_frames(2)
	var wood_4: Color = THEME.get_color(&"wood_light", &"DeskPalette")
	assert_eq(tag.sheet().drawn_colors()[0], wood_4, "the ground is Wood 4")
	var parchment: Color = THEME.get_color(&"parchment", &"DeskPalette")
	assert_false(tag.sheet().drawn_colors().has(parchment), "no parchment left on it")
	assert_eq(Palette.strays(tag.sheet().drawn_colors()), [] as Array[String], "palette only")
	tag.dark = false
	await wait_frames(2)
	assert_eq(tag.sheet().drawn_colors()[0], parchment, "and back to parchment")


func _tag(text: String) -> TagButton:
	var host := Control.new()
	host.theme = THEME
	host.size = Vector2(480, 270)
	add_child_autofree(host)
	var tag := TagButton.new()
	tag.text = text
	host.add_child(tag)
	return tag
