extends GutTest
## Reduce motion turned on mid-presentation (D37; the review's case): pause during the jolt, the
## stamp's rise or the slam, turn reduce motion on from the pause's options, resume. The decorative
## movement under way settles at its end state at once (the band home, the stamp raised, no veil
## or flash), the state cues stay (the raised stamp, the squash, the ink, the shockwave) and the
## slam still completes in its own time. Real timing throughout, every wait bounded in seconds.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const PATH := "user://desk_settle_motion_test.cfg"
## No wait here takes longer: the whole slam window is StampFlow.SLAM_SECONDS (0.5 s).
const DEADLINE := 1.0

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null
var _prompt: StampPrompt = null
var _face: StampFace = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.quit_closes_game = false
	_desk.use_commands(Fixture.commands())
	_desk.use_options(Fixture.instant())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_desk.pause_overlay().options_panel().save_path = PATH
	_prompt = _system.stamp_flow.stamp_prompt
	_face = _prompt.get_node("Face") as StampFace
	_system.dawn_writ.next_button().pressed.emit()
	_system.finish_tellings()


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func test_reduce_motion_under_the_pause_settles_the_jolt_and_the_slam_completes() -> void:
	var homes: Array[Vector2] = _band_positions()
	_stamp(&"hel")
	assert_true(await _until(_desk.is_jolting), "the jolt began")
	_desk.toggle_pause()
	assert_ne(_band_positions(), homes, "paused mid-jolt, the band is down")
	_turn_reduce_motion_on()
	assert_false(_desk.is_jolting(), "the jolt is over")
	assert_eq(_band_positions(), homes, "the band is home at once")
	_resume()
	assert_true(await _until(_slam_over), "the slam still completes")
	assert_eq(_band_positions(), homes, "and the band stays home")
	assert_eq(_system.soul.plate_name(), "Second", "the next soul came in")


func test_reduce_motion_under_the_pause_places_the_rising_stamp_and_lifts_the_veil() -> void:
	_door(&"hel").press()
	_desk.toggle_pause()
	assert_ne(_face.position.y, StampPrompt.RAISED_Y, "paused mid-rise")
	assert_eq(_prompt.marks().veil_alpha(), StampPrompt.CHOICE_DIM, "under the choice's veil")
	_turn_reduce_motion_on()
	assert_eq(_face.position.y, StampPrompt.RAISED_Y, "the stamp stands raised at once")
	assert_eq(_prompt.marks().veil_alpha(), 0.0, "the raised stamp is the cue, not the veil")
	assert_true(_prompt.is_asking(), "still asking")
	_resume()
	await wait_process_frames(3)
	assert_eq(_face.position.y, StampPrompt.RAISED_Y, "nothing moves it again")
	_confirm()
	assert_true(await _until(_slam_over), "the slam still completes")
	assert_eq(_prompt.soul_name(), "Second", "the stamped writ was swept for the next one")
	assert_eq(_system.soul.plate_name(), "Second", "the next soul came in")


func test_reduce_motion_under_the_pause_drops_the_slams_flash_and_veil_and_keeps_its_cues() -> void:
	_stamp(&"hel")
	var squashed: Callable = func() -> bool: return _face.block_height() == StampFace.SQUASH_HEIGHT
	assert_true(await _until(squashed), "the stamp landed")
	_desk.toggle_pause()
	_turn_reduce_motion_on()
	var settled: Array = [_face.is_flashing(), _prompt.writ().is_flashing()]
	settled.append(_prompt.marks().veil_alpha())
	assert_eq(settled, [false, false, 0.0], "no flash and no veil")
	assert_true(_prompt.is_inked(), "the ink stays")
	assert_eq(_face.block_height(), StampFace.SQUASH_HEIGHT, "and the squash")
	_resume()
	var veils: Array[float] = []
	var rings: Array[int] = []
	var started: int = Time.get_ticks_msec()
	while not _slam_over() and Time.get_ticks_msec() - started < DEADLINE * 1000.0:
		await get_tree().process_frame
		if not veils.has(_prompt.marks().veil_alpha()):
			veils.append(_prompt.marks().veil_alpha())
		if not rings.has(_prompt.marks().ring_stage()):
			rings.append(_prompt.marks().ring_stage())
	assert_true(_slam_over(), "the slam completed in its own time")
	assert_eq(veils, [0.0] as Array[float], "the veil never came back")
	assert_true(rings.has(1) or rings.has(2), "the shockwave, a cue, still rang")


## Pause, Options, the reduce-motion toggle: the player's own path to it.
func _turn_reduce_motion_on() -> void:
	var pause: PauseOverlay = _desk.pause_overlay()
	pause.options_button().pressed.emit()
	pause.options_panel().motion_button().pressed.emit()
	assert_true(_desk.options().reduce_motion, "reduce motion is on")


## Esc closes the options, then the pause, which resumes the desk.
func _resume() -> void:
	_desk.toggle_pause()
	if _desk.pause_overlay().is_open():
		_desk.toggle_pause()
	assert_false(_desk.pause_overlay().is_open(), "resumed")


func _slam_over() -> bool:
	return not _desk.gate().is_slamming()


## Awaits frames until `condition` holds or DEADLINE seconds pass; returns whether it held.
func _until(condition: Callable) -> bool:
	var started: int = Time.get_ticks_msec()
	while not condition.call() and Time.get_ticks_msec() - started < DEADLINE * 1000.0:
		await get_tree().process_frame
	return condition.call()


func _band_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for path: NodePath in Desk.DESK_BAND:
		positions.append((_desk.get_node(path) as Control).position)
	return positions


func _stamp(realm: StringName) -> void:
	_door(realm).press()
	_confirm()


func _confirm() -> void:
	_prompt.confirm_button().arm_now()
	_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null
