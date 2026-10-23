extends GutTest
## The writ and the stamp on their own (D14, D15): the writ always carries the name, the raised
## stamp asks "<Realm>?" with the realm's glyph, the slam inks that glyph in Ink whoever the soul
## is, the stamped writ keeps its name until it is swept, and the held writ says "Send it on" and
## sends the soul on when clicked.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const PROMPT_SCENE := preload("res://entities/stamp_prompt/stamp_prompt.tscn")

var _prompt: StampPrompt = null


func before_each() -> void:
	var holder := Control.new()
	holder.theme = THEME
	add_child_autofree(holder)
	_prompt = PROMPT_SCENE.instantiate() as StampPrompt
	holder.add_child(_prompt)
	_prompt.set_soul_name("Ulf")


func test_the_writ_carries_the_name_and_no_stamp_until_asked() -> void:
	assert_eq(_prompt.soul_name(), "Ulf", "the writ names the soul at the desk")
	assert_false(_prompt.is_asking())
	assert_false(_prompt.confirm_button().visible, "no stamp is raised")
	assert_eq(_prompt.question(), "")
	_prompt.set_soul_name("")
	assert_eq(_prompt.soul_name(), "", "an empty desk has no writ")
	assert_false(_prompt.writ().is_visible_in_tree())


func test_asking_raises_the_stamp_with_the_realms_glyph_and_question() -> void:
	_prompt.ask("Ulf", &"hel")
	assert_true(_prompt.is_asking())
	assert_eq(_prompt.question(), "Hel?", "the realm with a question mark (D14)")
	assert_eq(StampPrompt.question_for(&"folkvangr"), "Fólkvangr?")
	assert_eq(_prompt.realm, &"hel")
	assert_true(_prompt.confirm_button().visible, "the stamp is the confirm")
	assert_eq(_face().glyph, &"serpent", "Hel's glyph on the stamp")
	assert_eq(_prompt.soul_name(), "Ulf", "the name stays on the writ")
	assert_true(
		_prompt.stamp_rect().encloses(_face().get_global_rect()),
		"a click on the drawn stamp is a click on the confirm"
	)


func test_withdraw_puts_the_stamp_down_once() -> void:
	_prompt.ask("Ulf", &"valhalla")
	watch_signals(_prompt)
	_prompt.withdraw()
	_prompt.withdraw()
	assert_signal_emit_count(_prompt, "cancelled", 1, "only a raised stamp is put down")
	assert_false(_prompt.is_asking())
	assert_eq(_prompt.question(), "")
	assert_false(_prompt.confirm_button().visible)


func test_a_right_click_on_the_stamp_puts_it_down() -> void:
	_prompt.ask("Ulf", &"valhalla")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	_prompt.confirm_button().gui_input.emit(press)
	assert_false(_prompt.is_asking())


func test_the_stamps_press_confirms_once_and_holds_the_name() -> void:
	_prompt.ask("Ulf", &"valhalla")
	watch_signals(_prompt)
	_prompt.confirm_button().pressed.emit()
	_prompt.confirm_button().pressed.emit()
	assert_signal_emit_count(_prompt, "confirmed", 1)
	assert_signal_emitted_with_parameters(_prompt, "confirmed", [&"valhalla"])
	assert_false(_prompt.is_asking(), "pressed, the stamp is no longer asking")
	_prompt.set_soul_name("Kolbeinn")
	assert_eq(_prompt.soul_name(), "Ulf", "core seats the next soul; the stamped writ keeps Ulf")


func test_the_slam_inks_the_realms_glyph_in_ink_for_any_soul() -> void:
	var inked: Array[StringName] = []
	var colours: Array[Color] = []
	for soul_name: String in ["Ulf", "Kolbeinn"]:
		_prompt.reset_writ()
		_prompt.set_soul_name(soul_name)
		_prompt.ask(soul_name, &"valhalla")
		_prompt.stamp_down(&"valhalla")
		_prompt.slam(&"valhalla")
		inked.append(_prompt.writ().inked_glyph())
		colours.append(_prompt.writ().ink_color())
	assert_eq(inked, [&"spear", &"spear"] as Array[StringName], "the glyph is the realm's alone")
	var ink: Color = THEME.get_color(&"ink", &"DeskPalette")
	assert_eq(colours, [ink, ink] as Array[Color], "always Ink, never a reserved colour (D14)")


func test_a_drop_slams_without_a_press_on_the_stamp() -> void:
	_prompt.ask("Ulf", &"hel")
	_prompt.stamp_down(&"hel")
	_prompt.slam(&"hel")
	assert_true(_prompt.is_inked())
	assert_eq(_prompt.writ().inked_glyph(), &"serpent")


func test_the_sweep_gives_the_writ_to_the_next_soul() -> void:
	_prompt.ask("Ulf", &"valhalla")
	_prompt.confirm_button().pressed.emit()
	_prompt.slam(&"valhalla")
	_prompt.set_soul_name("Kolbeinn")
	assert_eq(_prompt.soul_name(), "Ulf", "inked, the writ still names the stamped soul")
	var sweep: Tween = _prompt.sweep()
	assert_not_null(sweep, "the writ slides off")
	await wait_seconds(StampPrompt.SWEEP_SECONDS + StampPrompt.COME_UP_SECONDS + 0.1)
	assert_eq(_prompt.soul_name(), "Kolbeinn", "the next writ names the next soul")
	assert_false(_prompt.is_inked(), "and is clean")
	assert_eq(_prompt.writ().position, Vector2.ZERO, "and back in its place")


func test_reduce_motion_sweeps_at_once() -> void:
	_prompt.reduce_motion = true
	_prompt.ask("Ulf", &"valhalla")
	_prompt.confirm_button().pressed.emit()
	_prompt.slam(&"valhalla")
	_prompt.set_soul_name("Kolbeinn")
	assert_null(_prompt.sweep(), "no movement under reduce motion (D37)")
	assert_eq(_prompt.soul_name(), "Kolbeinn")
	assert_false(_prompt.is_inked())


func test_asking_during_a_sweep_finishes_it() -> void:
	_prompt.ask("Ulf", &"valhalla")
	_prompt.confirm_button().pressed.emit()
	_prompt.slam(&"valhalla")
	_prompt.set_soul_name("Kolbeinn")
	_prompt.sweep()
	_prompt.ask("Kolbeinn", &"hel")
	assert_eq(_prompt.soul_name(), "Kolbeinn", "the next writ is in place at once")
	assert_eq(_prompt.writ().position, Vector2.ZERO)
	assert_eq(_prompt.question(), "Hel?")


func test_the_held_writ_says_send_it_on_and_sends_the_soul_on() -> void:
	_prompt.ask("Ulf", &"hel")
	_prompt.confirm_button().pressed.emit()
	_prompt.slam(&"hel")
	watch_signals(_prompt)
	_prompt.send_on()
	_prompt.writ().clicked.emit()
	assert_signal_emit_count(_prompt, "send_on_requested", 1, "only the held writ is a control")
	_prompt.set_held(true)
	assert_true(_prompt.is_held())
	assert_eq(_prompt.writ().mouse_filter, Control.MOUSE_FILTER_STOP, "the held writ takes clicks")
	_prompt.writ().mouse_entered.emit()
	assert_signal_emitted_with_parameters(
		_prompt, "hover_started", [Writ.HELD_HOVER, _prompt.writ().get_global_rect()]
	)
	assert_eq(Writ.HELD_HOVER, "Send it on")
	_prompt.send_on()
	assert_signal_emit_count(_prompt, "send_on_requested", 2)
	_prompt.set_held(false)
	assert_signal_emitted(_prompt, "hover_ended", "letting go of the hold ends its hover")
	assert_eq(_prompt.writ().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_reset_writ_clears_the_stamp_the_ink_and_the_hold() -> void:
	_prompt.ask("Ulf", &"hel")
	_prompt.confirm_button().pressed.emit()
	_prompt.slam(&"hel")
	_prompt.set_held(true)
	_prompt.set_soul_name("Asgaut")
	_prompt.reset_writ()
	assert_false(_prompt.is_inked())
	assert_false(_prompt.is_held())
	assert_false(_prompt.is_asking())
	assert_eq(_prompt.soul_name(), "Asgaut", "the waiting name takes the writ")


func test_every_slice_soul_name_fits_left_of_the_ink_box() -> void:
	var font: Font = THEME.default_font
	var too_wide: Array[String] = []
	for encounter: EncounterData in _slice_encounters():
		var width: float = (
			font
			. get_string_size(encounter.soul_name, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE)
			. x
		)
		if Writ.NAME_AT.x + width > Writ.INK_BOX.position.x - 1:
			too_wide.append("%s (%d px)" % [encounter.soul_name, width])
	assert_eq(too_wide, [] as Array[String], "every name clears the ink box")


func test_the_stamp_and_the_writ_draw_palette_colours_only() -> void:
	_prompt.ask("Ulf", &"valhalla")
	await wait_process_frames(2)
	var face: StampFace = _face()
	assert_eq(Palette.strays(face.drawn_colors()), [] as Array[String], "the stamp")
	var bounds: Rect2 = Palette.bounds(face.drawn_rects())
	assert_true(Rect2(Vector2.ZERO, Vector2(StampFace.SIZE)).encloses(bounds), "inside 16x16")
	var paper: ParchmentFrame = _prompt.writ().get_node("Paper") as ParchmentFrame
	assert_eq(Palette.strays(paper.drawn_colors()), [] as Array[String], "the writ's paper")
	var ink: Array[Color] = [_prompt.writ().ink_color()]
	assert_eq(Palette.strays(ink), [] as Array[String], "the ink is Ink, a palette colour")


func _face() -> StampFace:
	return _prompt.get_node("Face") as StampFace


func _slice_encounters() -> Array[EncounterData]:
	var found: Array[EncounterData] = []
	var directory: DirAccess = DirAccess.open("res://data/encounters")
	for file: String in directory.get_files():
		if file.ends_with(".tres"):
			var encounter: EncounterData = load("res://data/encounters/" + file) as EncounterData
			if encounter != null:
				found.append(encounter)
	return found
