extends GutTest
## The soul's arrival (D15): a soul shown after `prepare_arrival` waits off-screen to the left while
## the plate keeps the stamped soul's name, plate and label (blank when nobody stood at the desk);
## `arrive` walks it in (0.3 s) or places it at once, and a soul shown
## without it simply stands in its place. While it speaks (D4, D17) its plate lights and it dips
## 1 px on each blip; silent, or under reduce motion (D37), it never bobs.

var _soul: WaitingSoul = null


func before_each() -> void:
	_soul = WaitingSoul.new()
	_soul.size = Vector2(60, 96)
	add_child_autofree(_soul)


func test_a_soul_shown_plainly_stands_in_its_place() -> void:
	_soul.show_soul(_encounter("Ulf"))
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)
	assert_false(_soul.is_arriving())
	assert_null(_soul.arrive(), "nothing waits to arrive")


func test_a_prepared_soul_waits_off_screen_until_it_arrives() -> void:
	_soul.prepare_arrival()
	_soul.show_soul(_encounter("Kolbeinn"))
	assert_eq(_soul.figure().position.x, WaitingSoul.ARRIVE_FROM_X, "off the left edge")
	assert_lt(_soul.figure().get_global_rect().end.x, 0.0, "wholly off-screen")
	assert_eq(_soul.soul_name(), "Kolbeinn", "the desk already knows who is next")
	assert_false(_name_label().visible, "the plate waits for the soul")
	assert_true(_soul.is_arriving())
	var walk: Tween = _soul.arrive()
	assert_not_null(walk, "the walk-in")
	assert_true(_name_label().visible)
	await wait_seconds(WaitingSoul.ARRIVE_SECONDS + 0.1)
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT, "in its place after 0.3 s")
	assert_false(_soul.is_arriving())


func test_an_instant_arrival_places_the_soul_at_once() -> void:
	_soul.prepare_arrival()
	_soul.show_soul(_encounter("Kolbeinn"))
	assert_null(_soul.arrive(0.0), "reduce motion: the end state, no tween (D37)")
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)


func test_finish_arrival_skips_the_walk_in() -> void:
	_soul.prepare_arrival()
	_soul.show_soul(_encounter("Kolbeinn"))
	_soul.arrive()
	_soul.finish_arrival()
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)
	assert_false(_soul.is_arriving())


func test_an_empty_gate_forgets_a_pending_arrival() -> void:
	_soul.prepare_arrival()
	_soul.show_soul(null)
	assert_false(_soul.arrive_pending)
	_soul.show_soul(_encounter("Ulf"))
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT, "the next soul simply stands")


func test_a_speaking_soul_lights_its_plate() -> void:
	_soul.show_soul(_encounter("Ulf"))
	assert_false(_soul.is_speaking(), "a soul is silent until its tale is told")
	_soul.set_speaking(true)
	assert_true(_soul.is_speaking())
	var plate := Rect2(Vector2.ZERO, _soul.get_node("Plate").size)
	assert_true(plate.encloses(_soul.speaking_backing()), "the lit backing is on the plate")
	assert_eq(_soul.speaking_backing().position, Vector2.ONE, "inside its 1 px rim")
	_soul.set_speaking(false)
	assert_false(_soul.is_speaking())


func test_each_blip_dips_a_speaking_soul_one_pixel_and_back() -> void:
	_soul.show_soul(_encounter("Ulf"))
	_soul.set_speaking(true)
	var bob: Tween = _soul.bob()
	assert_not_null(bob)
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT + Vector2(0, 1), "1 px down")
	await wait_seconds(WaitingSoul.BOB_SECONDS + 0.1)
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT, "and back")


func test_a_silent_soul_never_bobs() -> void:
	_soul.show_soul(_encounter("Ulf"))
	assert_null(_soul.bob(), "still unless it speaks (D17)")
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)


func test_the_tale_ending_mid_bob_puts_the_figure_back() -> void:
	_soul.show_soul(_encounter("Ulf"))
	_soul.set_speaking(true)
	_soul.bob()
	_soul.set_speaking(false)
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)


func test_reduce_motion_lights_the_plate_but_never_bobs() -> void:
	_soul.reduce_motion = true
	_soul.show_soul(_encounter("Ulf"))
	_soul.set_speaking(true)
	assert_true(_soul.is_speaking(), "the lit plate is a state cue: it stays")
	assert_null(_soul.bob(), "no bob (D37)")
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT)


func test_a_bob_during_the_walk_in_keeps_the_walks_course() -> void:
	_soul.prepare_arrival()
	_soul.show_soul(_encounter("Kolbeinn"))
	_soul.arrive()
	_soul.set_speaking(true)
	var x: float = _soul.figure().position.x
	_soul.bob()
	assert_eq(_soul.figure().position.x, x, "only the height moves")
	await wait_seconds(WaitingSoul.ARRIVE_SECONDS + 0.1)
	assert_eq(_soul.figure().position, WaitingSoul.FIGURE_AT, "the walk ends in its place")


## The WP2 captures' case: the plate went blank from the slam's impact to the walk-in. The stamped
## soul's name, plate and hover label stay on it until the next soul's walk-in starts.
func test_the_stamped_souls_plate_stays_until_the_next_soul_walks_in() -> void:
	_soul.plate_plain = _texture(Color.WHITE)
	_soul.plate_frost = _texture(Color.GRAY)
	var ulf: Encounter = _encounter("Ulf")
	ulf.plate_label = "Ulf's plate"
	var kolbeinn: Encounter = _encounter("Kolbeinn")
	kolbeinn.returned = true
	kolbeinn.plate_label = "Back from Hel."
	_soul.show_soul(ulf)
	_soul.prepare_arrival()
	_soul.show_soul(kolbeinn)
	watch_signals(_soul)
	_soul._on_plate_entered()
	assert_eq(_soul.soul_name(), "Kolbeinn", "the desk knows who is next")
	assert_eq(_soul.plate_name(), "Ulf", "the plate still names the stamped soul")
	assert_eq(_soul.plate_texture(), _soul.plate_plain, "on his own plate")
	assert_signal_emitted_with_parameters(
		_soul, "plate_hover_started", ["Ulf's plate", _plate().get_global_rect()]
	)
	_soul.arrive()
	assert_eq(_soul.plate_name(), "Kolbeinn", "the walk-in brings the next name")
	assert_eq(_soul.plate_texture(), _soul.plate_frost, "and its frost-burned plate")
	_soul._on_plate_entered()
	assert_signal_emitted_with_parameters(
		_soul, "plate_hover_started", ["Back from Hel.", _plate().get_global_rect()]
	)


## A skipped walk-in, as a stamp's press skips one, brings the next name at once too.
func test_finishing_the_arrival_puts_the_next_name_on_the_plate() -> void:
	_soul.show_soul(_encounter("Ulf"))
	_soul.prepare_arrival()
	_soul.show_soul(_encounter("Kolbeinn"))
	assert_eq(_soul.plate_name(), "Ulf")
	_soul.finish_arrival()
	assert_eq(_soul.plate_name(), "Kolbeinn")


func _plate() -> Control:
	return _soul.get_node("Plate") as Control


func _texture(color: Color) -> Texture2D:
	var image: Image = Image.create(60, 10, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _name_label() -> Label:
	return _soul.get_node("Plate").get_child(0) as Label


func _encounter(soul_name: String) -> Encounter:
	var encounter := Encounter.new()
	encounter.id = StringName(soul_name.to_lower())
	encounter.soul_name = soul_name
	return encounter
