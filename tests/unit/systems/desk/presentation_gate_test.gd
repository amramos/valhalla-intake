extends GutTest
## The presentation gate's input contract (D27, D51, plan section 3): for every presentation
## state and every kind of press, exactly one of consumed (the presentation finishes, nothing
## else happens), passed (the desk acts) or ignored (the slam window); a consumed press's release
## is swallowed; pause and restart reach every watched clock.

const STATES: Array[StringName] = [&"idle", &"telling", &"written", &"dawn", &"slamming"]
const PRESSES: Array[StringName] = [&"press", &"double_click", &"right_click", &"release"]
const EXPECTED: Dictionary = {
	&"idle": [&"passed", &"passed", &"passed", &"passed"],
	&"telling": [&"consumed", &"consumed", &"consumed", &"passed"],
	&"written": [&"consumed", &"consumed", &"consumed", &"passed"],
	&"dawn": [&"consumed", &"consumed", &"consumed", &"passed"],
	&"slamming": [&"ignored", &"ignored", &"ignored", &"passed"],
}

var _gate: PresentationGate = null
var _finished: Array[StringName] = []


func before_each() -> void:
	_gate = autofree(PresentationGate.new())
	_finished.clear()


func test_every_state_and_press_has_exactly_one_outcome() -> void:
	var outcomes: Dictionary = {}
	for state: StringName in STATES:
		var row: Array = []
		for press: StringName in PRESSES:
			row.append(_outcome(state, press))
		outcomes[state] = row
	assert_eq(outcomes, EXPECTED)


func test_a_consumed_press_swallows_its_release_and_the_next_press_acts() -> void:
	_gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	var results: Array[bool] = [
		_gate.on_press(_event(MOUSE_BUTTON_LEFT, true)),
		_gate.on_press(_event(MOUSE_BUTTON_LEFT, false)),
		_gate.on_press(_event(MOUSE_BUTTON_LEFT, true)),
		_gate.on_press(_event(MOUSE_BUTTON_LEFT, false)),
	]
	assert_eq(results, [true, true, false, false], "consumed, swallowed, then a press that acts")
	assert_eq(_finished, [&"claim"])


func test_a_swallowed_release_is_only_the_consumed_buttons() -> void:
	_gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	_gate.on_press(_event(MOUSE_BUTTON_LEFT, true))
	assert_false(_gate.on_press(_event(MOUSE_BUTTON_RIGHT, false)), "another button's release")
	assert_true(_gate.on_press(_event(MOUSE_BUTTON_LEFT, false)))


func test_an_ignored_press_swallows_its_release_even_after_the_slam_opens() -> void:
	_gate.slam_lock()
	var press: bool = _gate.on_press(_event(MOUSE_BUTTON_LEFT, true))
	_gate.slam_release()
	assert_eq([press, _gate.on_press(_event(MOUSE_BUTTON_LEFT, false))], [true, true])


func test_the_slam_ignores_a_press_without_finishing_a_telling() -> void:
	_gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	_gate.slam_lock()
	watch_signals(_gate)
	assert_true(_gate.on_press(_event(MOUSE_BUTTON_LEFT, true)))
	assert_eq(_finished, [] as Array[StringName])
	assert_true(_gate.is_consuming())
	assert_signal_not_emitted(_gate, "consumed")


func test_one_press_finishes_every_pending_telling_including_one_it_starts() -> void:
	var witness: Callable = _finisher(&"witness")
	var claim: Callable = func() -> void:
		_finished.append(&"claim")
		_gate.begin(PresentationGate.TELLING, witness)
	_gate.begin(PresentationGate.TELLING, claim)
	_gate.begin(PresentationGate.WRITTEN, _finisher(&"note"))
	watch_signals(_gate)
	assert_true(_gate.on_press(_event(MOUSE_BUTTON_LEFT, true)))
	assert_eq(_finished, [&"claim", &"note", &"witness"])
	assert_false(_gate.is_consuming())
	assert_signal_emit_count(_gate, "consumed", 1)
	assert_signal_emitted_with_parameters(_gate, "consumed", [PresentationGate.TELLING])


func test_an_ended_consumer_lets_the_press_through() -> void:
	var token: int = _gate.begin(PresentationGate.DAWN, _finisher(&"dawn"))
	_gate.end(token)
	_gate.end(token)
	assert_false(_gate.on_press(_event(MOUSE_BUTTON_LEFT, true)))
	assert_eq(_finished, [] as Array[StringName])


func test_the_wheel_is_never_a_press() -> void:
	_gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	assert_false(_gate.on_press(_event(MOUSE_BUTTON_WHEEL_DOWN, true)))
	assert_true(_gate.is_consuming())


func test_cancel_all_finishes_nothing_ends_everything_and_releases_the_slam() -> void:
	var holder: Node = add_child_autofree(Node.new())
	var tween: Tween = holder.create_tween()
	tween.tween_interval(5.0)
	_gate.watch_tween(tween)
	_gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	_gate.slam_lock()
	watch_signals(_gate)
	_gate.cancel_all()
	assert_eq(_finished, [] as Array[StringName])
	assert_false(_gate.is_consuming())
	assert_false(_gate.is_slamming())
	assert_false(tween.is_valid(), "the watched tween is killed")
	assert_signal_emit_count(_gate, "released", 1)


func test_released_comes_once_per_slam() -> void:
	watch_signals(_gate)
	_gate.slam_release()
	_gate.slam_lock()
	_gate.slam_release()
	_gate.slam_release()
	_gate.cancel_all()
	assert_signal_emit_count(_gate, "released", 1)


func test_pause_stops_tellers_and_tweens_without_the_tree_or_the_time_scale() -> void:
	var holder: Node = add_child_autofree(Node.new())
	var tween: Tween = holder.create_tween()
	tween.tween_interval(5.0)
	var teller: Teller = autofree(Teller.new())
	_gate.register_teller(teller)
	_gate.watch_tween(tween)
	_gate.set_paused(true)
	var paused: Array[bool] = [teller.is_paused(), tween.is_running()]
	var tree_paused: bool = get_tree().paused
	var time_scale: float = Engine.time_scale
	_gate.set_paused(false)
	assert_eq(paused, [true, false], "the teller and the tween stop")
	assert_eq([teller.is_paused(), tween.is_running()], [false, true], "and resume")
	assert_false(tree_paused)
	assert_eq(time_scale, 1.0)


func test_pause_holds_a_playing_player_and_resumes_it() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var silence := PackedByteArray()
	silence.resize(22050 * 2)
	wav.data = silence
	var player: AudioStreamPlayer = add_child_autofree(AudioStreamPlayer.new())
	player.stream = wav
	player.play()
	_gate.watch_player(player)
	_gate.set_paused(true)
	var held: bool = player.stream_paused
	_gate.set_paused(false)
	assert_eq([held, player.stream_paused], [true, false])


func test_a_teller_registered_while_paused_starts_paused() -> void:
	_gate.set_paused(true)
	var teller: Teller = autofree(Teller.new())
	_gate.register_teller(teller)
	assert_true(teller.is_paused())


func test_pause_resumes_only_the_tweens_it_paused() -> void:
	var holder: Node = add_child_autofree(Node.new())
	var stopped: Tween = holder.create_tween()
	stopped.tween_interval(5.0)
	stopped.pause()
	_gate.watch_tween(stopped)
	_gate.set_paused(true)
	_gate.set_paused(false)
	assert_false(stopped.is_running(), "a tween its owner paused stays paused")


func test_gated_seconds_count_only_consuming_or_slamming_unpaused_time() -> void:
	_gate._process(1.0)
	var token: int = _gate.begin(PresentationGate.TELLING, _finisher(&"claim"))
	_gate._process(0.5)
	_gate.set_paused(true)
	_gate._process(1.0)
	_gate.set_paused(false)
	_gate.end(token)
	_gate.slam_lock()
	_gate._process(0.25)
	_gate.slam_release()
	_gate._process(1.0)
	var counted: float = _gate.gated_seconds()
	_gate.reset_gated_seconds()
	assert_almost_eq(counted, 0.75, 0.0001)
	assert_eq(_gate.gated_seconds(), 0.0)


## Plays `press` against a fresh gate in `state` and names what happened.
func _outcome(state: StringName, press: StringName) -> StringName:
	_gate = autofree(PresentationGate.new())
	_finished.clear()
	match state:
		&"telling":
			_gate.begin(PresentationGate.TELLING, _finisher(state))
		&"written":
			_gate.begin(PresentationGate.WRITTEN, _finisher(state))
		&"dawn":
			_gate.begin(PresentationGate.DAWN, _finisher(state))
		&"slamming":
			_gate.slam_lock()
	var signals: Array[StringName] = []
	_gate.consumed.connect(func(kind: StringName) -> void: signals.append(kind))
	var event: InputEventMouseButton = _event(MOUSE_BUTTON_LEFT, true)
	match press:
		&"double_click":
			event.double_click = true
		&"right_click":
			event.button_index = MOUSE_BUTTON_RIGHT
		&"release":
			event.pressed = false
	var taken: bool = _gate.on_press(event)
	if not taken:
		return &"passed" if _finished.is_empty() and signals.is_empty() else &"broken"
	if _finished.is_empty():
		return &"ignored" if signals.is_empty() else &"broken"
	if _finished == [state] and signals == [state] and not _gate.is_consuming():
		return &"consumed"
	return &"broken"


func _finisher(tag: StringName) -> Callable:
	return func() -> void: _finished.append(tag)


func _event(button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	return event
