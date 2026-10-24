extends GutTest
## The title (D24, D37, D50): day 1's gate with its drifting fog and pulsing doors that never
## take a click, the name in capitals, Start / Options / Quit as tags on the desk, the options
## panel whose changes save and apply at once, and the wind: at once on the desktop, at the first
## click on the web.

const TITLE_SCENE := preload("res://scenes/title/title.tscn")
const PATH := "user://title_test_options.cfg"
## The desk's top edge: everything below the gate band.
const DESK_TOP := 96

var _viewport: SubViewport = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_the_name_and_three_tags_sit_on_the_desk_in_the_slices_words() -> void:
	var title: TitleScreen = _title(false)
	var text: DeskText = SliceLoader.load_slice().slice_rules().text
	var tags: Array[GuardedButton] = [
		title.start_button(), title.options_button(), title.quit_button()
	]
	var words: Array[String] = []
	var faults: Array[String] = []
	var desk := Rect2(0, DESK_TOP, 480, 270 - DESK_TOP)
	var last_bottom: float = DESK_TOP
	for tag: GuardedButton in tags:
		words.append(tag.text)
		if not desk.encloses(tag.get_rect()) or tag.position.y < last_bottom:
			faults.append(tag.text)
		last_bottom = tag.get_rect().end.y
	assert_eq(words, [text.start_label, OptionsPanel.OPENER_LABEL, text.quit_label])
	assert_eq(faults, [] as Array[String], "on the desk, one below the other")
	assert_eq(title.shown_name(), text.title_name.to_upper())
	var name_node: Control = title.get_node("Name") as Control
	var name_rect := Rect2(name_node.position, name_node.size * name_node.scale)
	assert_true(desk.encloses(name_rect), "the name on the desk under the wall")
	assert_lt(name_rect.end.y, title.start_button().position.y, "above the tags")


func test_the_open_doors_pulse_and_the_fog_drifts_but_no_door_takes_a_click() -> void:
	var title: TitleScreen = _title(false)
	var states: Array = []
	for door: Door in title.doors():
		door.set_process(false)
		states.append([door.realm, door.is_open, door.mouse_filter == Control.MOUSE_FILTER_IGNORE])
	assert_eq(
		states,
		[
			[Realm.VALHALLA, true, true],
			[Realm.HEL, true, true],
			[Realm.FOLKVANGR, false, true],
		]
	)
	var valhalla: Door = title.doors()[0]
	valhalla._process(DoorLight.PULSE_SECONDS / 2.0 + 0.01)
	assert_eq(valhalla.drawn_texture(), valhalla.lit_dim_texture, "the glow pulses")
	var band: GateBand = title.gate_band()
	band.set_process(false)
	band._process(GateBand.FOG_FRAME_SECONDS + 0.01)
	assert_ne(band.fog_frame(), 0, "the fog drifts")


func test_options_from_the_title_save_and_apply_at_once() -> void:
	var title: TitleScreen = _title(false)
	title.options_button().pressed.emit()
	var panel: OptionsPanel = title.options_panel()
	assert_true(panel.is_open())
	panel.motion_button().pressed.emit()
	var stilled: Array[bool] = [title.gate_band().reduce_motion]
	for door: Door in title.doors():
		stilled.append(door.reduce_motion)
	assert_eq(stilled, [true, true, true, true] as Array[bool])
	panel.tally().press(1)
	var levels: Array[float] = [title.wind_player().volume_db]
	panel.mute_button().pressed.emit()
	levels.append(title.wind_player().volume_db)
	assert_eq(levels, [-32.0, DeskSounds.MUTED_DB] as Array[float])
	var saved: Options = Options.load(PATH)
	assert_eq([saved.reduce_motion, saved.volume_db, saved.muted], [true, -32.0, true])


func test_a_malformed_options_file_still_opens_the_panel_with_the_defaults() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("[options\ntext_speed = = fast\nvolume_db = {{\n")
	file.close()
	var title: TitleScreen = _title(false)
	title.options_button().pressed.emit()
	var panel: OptionsPanel = title.options_panel()
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
	assert_engine_error("ConfigFile parse error")


func test_esc_closes_the_titles_options() -> void:
	var title: TitleScreen = _title(false)
	title.options_button().pressed.emit()
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	_viewport.push_input(key)
	assert_false(title.options_panel().is_open())


func test_the_wind_starts_at_once_on_the_desktop() -> void:
	var title: TitleScreen = _title(false)
	assert_true(title.is_wind_on())


func test_on_the_web_the_wind_waits_for_the_first_click() -> void:
	var title: TitleScreen = _title(true)
	var before: bool = title.is_wind_on()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(20, 250)
	press.global_position = press.position
	_viewport.push_input(press)
	assert_eq([before, title.is_wind_on()], [false, true])


func test_focus_loss_holds_the_wind_the_fog_and_the_pulse() -> void:
	var title: TitleScreen = _title(false)
	var wind: AudioStreamPlayer = title.wind_player()
	assert_not_null(wind.stream, "the title has its wind")
	assert_true(wind.playing, "the wind blows at once on the desktop")
	var band: GateBand = title.gate_band()
	var valhalla: Door = title.doors()[0]
	band.set_process(false)
	valhalla.set_process(false)
	title._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	band._process(GateBand.FOG_FRAME_SECONDS + 0.01)
	valhalla._process(DoorLight.PULSE_SECONDS / 2.0 + 0.01)
	var held: Array = [
		wind.stream_paused, band.fog_frame(), valhalla.drawn_texture() == valhalla.lit_texture
	]
	title._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	band._process(GateBand.FOG_FRAME_SECONDS + 0.01)
	valhalla._process(DoorLight.PULSE_SECONDS / 2.0 + 0.01)
	assert_eq(held, [true, 0, true], "out of focus: the wind, the fog and the pulse hold")
	assert_eq(
		[wind.stream_paused, band.fog_frame() != 0, valhalla.drawn_texture()],
		[false, true, valhalla.lit_dim_texture],
		"back in focus they go on"
	)


func test_a_web_wind_asked_for_out_of_focus_waits_for_the_focus() -> void:
	var title: TitleScreen = _title(true)
	title._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	title.start_wind()
	var out_of_focus: bool = title.wind_player().playing
	title._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_eq([out_of_focus, title.wind_player().playing], [false, true])


func _title(web: bool) -> TitleScreen:
	var title: TitleScreen = TITLE_SCENE.instantiate() as TitleScreen
	title.change_scene = false
	title.options_path = PATH
	title.web = web
	_viewport.add_child(title)
	return title
