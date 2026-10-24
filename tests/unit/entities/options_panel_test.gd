extends GutTest
## The options panel (D37): each control changes the options, saves them at once and announces
## the change; the chosen text speed is the pinned tag; a malformed file still opens the panel with
## the defaults; a save that fails changes the options all the same; everything drawn is palette.

const THEME := preload("res://scenes/desk/desk_theme.tres")
const PANEL_SCENE := preload("res://entities/options_panel/options_panel.tscn")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const PATH := "user://options_panel_test.cfg"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_each_text_speed_tag_saves_its_speed_and_announces_it() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	watch_signals(panel)
	var saved: Array[StringName] = []
	for speed: StringName in [Options.FAST, Options.INSTANT, Options.NORMAL]:
		panel.speed_button(speed).pressed.emit()
		saved.append(Options.load(PATH).text_speed)
	assert_eq(saved, [Options.FAST, Options.INSTANT, Options.NORMAL] as Array[StringName])
	assert_signal_emit_count(panel, "changed", 3)
	assert_same(get_signal_parameters(panel, "changed")[0], panel.options(), "the edited object")


func test_only_the_chosen_speed_is_pinned_and_in_ember() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.open()
	panel.speed_button(Options.FAST).pressed.emit()
	var pins: Array[TagButton.Pin] = []
	for speed: StringName in Options.SPEEDS:
		pins.append(panel.speed_button(speed).pin)
	assert_eq(
		pins, [TagButton.Pin.NONE, TagButton.Pin.CHOSEN, TagButton.Pin.NONE] as Array[TagButton.Pin]
	)
	await wait_frames(2)
	var fast: TagButton = panel.speed_button(Options.FAST)
	assert_has(fast.drawn_colors(), THEME.get_color(&"pin_selected", &"DeskPalette"))


func test_reduce_motion_and_mute_toggle_read_on_and_off_and_save() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	var seen: Array = []
	panel.motion_button().pressed.emit()
	seen.append([panel.motion_button().text, Options.load(PATH).reduce_motion])
	panel.mute_button().pressed.emit()
	seen.append([panel.mute_button().text, Options.load(PATH).muted])
	panel.motion_button().pressed.emit()
	panel.mute_button().pressed.emit()
	seen.append([panel.motion_button().text, panel.mute_button().text])
	seen.append([Options.load(PATH).reduce_motion, Options.load(PATH).muted])
	assert_eq(seen, [["On", true], ["On", true], ["Off", "Off"], [false, false]])


func test_each_tally_mark_sets_its_volume_from_the_quietest_to_full() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	var saved: Array[float] = []
	var shown: Array[int] = []
	for step: int in range(TallyRow.STEPS):
		panel.tally().press(step)
		saved.append(Options.load(PATH).volume_db)
		shown.append(panel.tally().step)
	assert_eq(saved, [-40.0, -32.0, -24.0, -16.0, -8.0, 0.0] as Array[float])
	assert_eq(shown, [0, 1, 2, 3, 4, 5] as Array[int])


func test_the_chosen_level_is_filled_in_ink_and_the_rest_hollow() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.open()
	panel.tally().press(2)
	await wait_frames(2)
	var tally: TallyRow = panel.tally()
	var ink: Color = THEME.get_color(&"ink", &"DeskPalette")
	var hollow: Color = THEME.get_color(&"ink_soft", &"DeskPalette")
	var middles: Array[Color] = []
	var rims: Array[Color] = []
	for index: int in range(TallyRow.STEPS):
		var mark: Rect2 = tally.mark_rect(index)
		var middle := Vector2i(mark.get_center())
		middles.append(Palette.color_at(tally.drawn_rects(), tally.drawn_colors(), middle))
		rims.append(
			Palette.color_at(tally.drawn_rects(), tally.drawn_colors(), Vector2i(mark.position))
		)
	var clear := Color(0, 0, 0, 0)
	assert_eq(middles, [ink, ink, ink, clear, clear, clear] as Array[Color], "three filled")
	assert_eq(rims, [ink, ink, ink, hollow, hollow, hollow] as Array[Color], "three hollow")
	assert_gt(tally.mark_rect(0).size.x, 2.0, "wide enough to show a hollow at 1x")


func test_a_click_on_a_stroke_chooses_it_and_a_double_clicks_second_press_does_not() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	var tally: TallyRow = panel.tally()
	tally._gui_input(_press(tally.mark_rect(1).get_center(), false))
	var after_click: float = panel.options().volume_db
	tally._gui_input(_press(tally.mark_rect(4).get_center(), true))
	assert_eq([after_click, panel.options().volume_db], [-32.0, -32.0])


func test_a_saved_volume_shows_as_its_nearest_mark() -> void:
	var steps: Array[int] = []
	for volume: float in [0.0, -3.9, -4.1, -21.0, -40.0]:
		steps.append(OptionsPanel.volume_step(volume))
	assert_eq(steps, [5, 5, 4, 2, 0] as Array[int])


func test_a_malformed_file_still_opens_the_panel_with_the_defaults() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string('[options\ntext_speed = = warp\nvolume_db = "loud')
	file.close()
	var panel: OptionsPanel = _panel(Options.load(PATH))
	panel.open()
	assert_true(panel.is_open())
	assert_eq(
		[
			panel.speed_button(Options.NORMAL).pin,
			panel.motion_button().text,
			panel.tally().step,
			panel.mute_button().text,
		],
		[TagButton.Pin.CHOSEN, "Off", TallyRow.STEPS - 1, "Off"]
	)
	# The engine logs the parse error itself; the panel carries on with the defaults.
	assert_engine_error("ConfigFile parse error")


func test_a_save_that_fails_still_changes_and_announces_the_option() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.save_path = "user://no_such_folder/deeper/options.cfg"
	watch_signals(panel)
	panel.mute_button().pressed.emit()
	assert_true(panel.options().muted)
	assert_signal_emitted(panel, "changed")
	assert_false(FileAccess.file_exists(panel.save_path))


func test_back_closes_the_panel_once() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.open()
	watch_signals(panel)
	panel.back_button().pressed.emit()
	panel.close()
	assert_false(panel.is_open())
	assert_signal_emit_count(panel, "closed", 1)


func test_everything_sits_on_the_sheet_inside_the_screen() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.open()
	var sheet: Rect2 = panel.sheet_rect()
	var outside: Array[String] = []
	var controls: Array[Control] = [panel.motion_button(), panel.mute_button(), panel.back_button()]
	controls.append(panel.tally())
	for speed: StringName in Options.SPEEDS:
		controls.append(panel.speed_button(speed))
	for control: Control in controls:
		if not sheet.encloses(control.get_rect()):
			outside.append(control.name)
	assert_eq(outside, [] as Array[String])
	assert_true(Rect2(Vector2.ZERO, OptionsPanel.SCREEN).encloses(sheet))


func test_everything_drawn_is_a_palette_colour() -> void:
	var panel: OptionsPanel = _panel(Options.new())
	panel.dim = false
	panel.open()
	panel.speed_button(Options.FAST).pressed.emit()
	panel.mute_button().disabled = true
	await wait_frames(2)
	var colors: Array[Color] = panel.sheet().drawn_colors()
	colors.append_array(panel.tally().drawn_colors())
	for tag: TagButton in [panel.speed_button(Options.FAST), panel.mute_button()]:
		colors.append_array(tag.drawn_colors())
	assert_gt(colors.size(), 20)
	assert_eq(Palette.strays(colors), [] as Array[String])


func _panel(options: Options) -> OptionsPanel:
	var host := Control.new()
	host.theme = THEME
	host.size = OptionsPanel.SCREEN
	add_child_autofree(host)
	var panel: OptionsPanel = PANEL_SCENE.instantiate() as OptionsPanel
	panel.save_path = PATH
	host.add_child(panel)
	panel.use_options(options)
	return panel


func _press(at: Vector2, double: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = double
	event.position = at
	return event
