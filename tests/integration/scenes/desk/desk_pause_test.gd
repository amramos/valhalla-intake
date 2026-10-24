extends GutTest
## The pause and its options on the live desk (D37, D42): the hanging parchment with its column of
## tags; a confirm asked well below its opener, the openers disabled meanwhile, and never taken by
## the opener's double-click; Esc closing the options before it resumes; and each option changing
## the saved file and the desk at once.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const PATH := "user://desk_pause_test.cfg"

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null
var _pause: PauseOverlay = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.quit_closes_game = false
	_desk.use_options(Fixture.normal())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_pause = _desk.pause_overlay()
	_pause.options_panel().save_path = PATH


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_the_pause_hangs_a_parchment_with_four_tags_in_a_column() -> void:
	_escape()
	var openers: Array[TagButton] = [
		_pause.resume_button(),
		_pause.options_button(),
		_pause.restart_button(),
		_pause.quit_button()
	]
	var words: Array[String] = []
	var lefts: Array[float] = []
	var faults: Array[String] = []
	var last_bottom: float = _pause.sheet_rect().position.y
	for tag: TagButton in openers:
		words.append(tag.text)
		lefts.append(tag.position.x)
		if not _pause.sheet_rect().encloses(tag.get_rect()) or tag.position.y < last_bottom:
			faults.append(tag.text)
		last_bottom = tag.get_rect().end.y
	var text: DeskText = _desk.commands().slice_rules().text
	assert_eq(words, [text.resume_label, "Options", text.restart_label, text.quit_label])
	assert_eq(lefts, [lefts[0], lefts[0], lefts[0], lefts[0]] as Array[float], "one column")
	assert_eq(faults, [] as Array[String], "each on the parchment, below the one before")
	assert_eq(_pause.sheet().heading, text.pause_title)
	assert_false(_pause.yes_button().visible or _pause.no_button().visible)
	assert_true(Rect2(Vector2.ZERO, PauseOverlay.SCREEN).encloses(_pause.sheet_rect()))


func test_a_confirm_sits_well_below_its_opener_and_disables_the_openers() -> void:
	_escape()
	var seen: Array = []
	for opener: TagButton in [_pause.restart_button(), _pause.quit_button()]:
		opener.pressed.emit()
		var yes: Rect2 = _pause.yes_button().get_rect()
		var no: Rect2 = _pause.no_button().get_rect()
		(
			seen
			. append(
				[
					yes.position.y - opener.position.y >= PauseOverlay.CONFIRM_GAP,
					no.position.y == yes.position.y,
					_pause.sheet_rect().encloses(yes.merge(no)),
					_disabled_openers(),
					_pause.question() != "",
				]
			)
		)
		_pause.no_button().pressed.emit()
		seen.append(_disabled_openers())
	assert_eq(seen, [[true, true, true, 4, true], 0, [true, true, true, 4, true], 0])


func test_the_openers_double_click_never_takes_the_confirm() -> void:
	watch_signals(_pause)
	_escape()
	var restart: TagButton = _pause.restart_button()
	restart.arm_now()
	var at: Vector2 = restart.get_global_rect().get_center()
	_click(at, false)
	assert_eq(_pause.question(), _desk.commands().slice_rules().text.restart_confirm)
	_click(at, true)
	_click(_pause.yes_button().get_global_rect().get_center(), true)
	_click(_pause.yes_button().get_global_rect().get_center(), false)
	assert_signal_not_emitted(_pause, "restart_confirmed", "nothing before Yes is armed")
	assert_true(_pause.is_open())
	_pause.yes_button().arm_now()
	_click(_pause.yes_button().get_global_rect().get_center(), true)
	assert_signal_not_emitted(_pause, "restart_confirmed", "nor a double-click's second press")
	_click(_pause.yes_button().get_global_rect().get_center(), false)
	assert_signal_emitted(_pause, "restart_confirmed", "a deliberate click on Yes restarts")


func test_esc_closes_the_options_before_it_resumes() -> void:
	_escape()
	_pause.options_button().pressed.emit()
	assert_true(_pause.options_panel().is_open())
	assert_false(_pause.resume_button().visible, "the parchment steps aside")
	_escape()
	var after_first: Array = [
		_pause.is_open(), _pause.options_panel().is_open(), _pause.resume_button().visible
	]
	_escape()
	assert_eq(after_first, [true, false, true])
	assert_false(_pause.is_open())
	assert_false(_desk.commands().is_paused())


func test_text_speed_from_the_pause_is_saved_and_paces_the_desk_at_once() -> void:
	_escape()
	_pause.options_button().pressed.emit()
	var paces: Array[float] = [_system.caption_strip.write_cps]
	_pause.options_panel().speed_button(Options.FAST).pressed.emit()
	paces.append(_system.caption_strip.write_cps)
	var pace: float = DeskNote.WRITE_PACE
	assert_eq(paces, [Options.NORMAL_CPS * pace, Options.FAST_CPS * pace] as Array[float])
	assert_eq(Options.load(PATH).text_speed, Options.FAST)
	assert_same(_desk.options(), _pause.options_panel().options(), "the desk's own options")
	_pause.options_panel().speed_button(Options.INSTANT).pressed.emit()
	assert_true(is_inf(_system.caption_strip.write_cps))
	assert_true(is_inf(_system.mentor_bubble.write_cps))


func test_reduce_motion_from_the_pause_stills_the_jolt_the_fog_and_the_doors() -> void:
	_escape()
	_pause.options_button().pressed.emit()
	_pause.options_panel().motion_button().pressed.emit()
	assert_true(Options.load(PATH).reduce_motion)
	_desk.jolt(2, 0.1)
	var stilled: Array[bool] = [not _desk.is_jolting(), _system.gate_band.reduce_motion]
	for door: Door in _system.doors:
		stilled.append(door.reduce_motion)
	assert_eq(stilled, [true, true, true, true, true] as Array[bool])
	_pause.options_panel().motion_button().pressed.emit()
	_desk.jolt(2, 0.1)
	assert_true(_desk.is_jolting(), "the jolt comes back with it off")


func test_volume_and_mute_from_the_pause_reach_every_player() -> void:
	_escape()
	_pause.options_button().pressed.emit()
	var panel: OptionsPanel = _pause.options_panel()
	panel.tally().press(2)
	var levels: Array = [_levels()]
	panel.mute_button().pressed.emit()
	levels.append(_levels())
	panel.mute_button().pressed.emit()
	levels.append(_levels())
	var players: int = _players().size()
	assert_gt(players, 0)
	assert_eq(levels, [[-24.0], [DeskSounds.MUTED_DB], [-24.0]])
	var saved: Options = Options.load(PATH)
	assert_eq([saved.volume_db, saved.muted], [-24.0, false])


func _disabled_openers() -> int:
	var count: int = 0
	for tag: TagButton in [
		_pause.resume_button(),
		_pause.options_button(),
		_pause.restart_button(),
		_pause.quit_button()
	]:
		count += 1 if tag.disabled else 0
	return count


func _players() -> Array[AudioStreamPlayer]:
	var found: Array[AudioStreamPlayer] = []
	for node: Node in _desk.find_children("*", "AudioStreamPlayer", true, false):
		found.append(node as AudioStreamPlayer)
	return found


## The distinct levels of every player on the desk.
func _levels() -> Array[float]:
	var levels: Array[float] = []
	for player: AudioStreamPlayer in _players():
		if not levels.has(player.volume_db):
			levels.append(player.volume_db)
	return levels


func _escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	_viewport.push_input(key)


func _click(at: Vector2, double: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		event.double_click = double and pressed
		_viewport.push_input(event)
