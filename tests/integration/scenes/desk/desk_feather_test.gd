extends GutTest
## The black feather (D16, D53): on a held stamp the feather waits, unseen, for the slam's impact,
## then drifts in from off-screen left to its place beside the mentor, at its resting height (0.5
## s, a 2 px sway), with a dry caw; its path crosses no evidence, and its click target is at its
## resting place from the first frame. No feather on a stamp that holds nothing, none after a
## restart in the slam window, and under reduce motion it appears in place (D37). The sprite's own
## drift is checked on a bare ClickableSprite.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const CAW := preload("res://assets/audio/caw.wav")
## Real time is a little late under a loaded test runner.
const SLACK := 0.2

var _desk: Desk = null
var _system: DeskSystem = null
var _caw: AudioStreamPlayer = null


func test_a_held_stamp_drifts_the_feather_in_at_the_impact_with_a_caw() -> void:
	_open(Fixture.instant())
	var feather: ClickableSprite = _system.feather
	var rest: Rect2 = feather.get_global_rect()
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_true(_desk.commands().pending_stamp().citation, "the visible seam drew a citation")
	assert_false(feather.visible, "the feather waits for the impact")
	assert_false(_caw.playing)
	# Read on the impact's own frame: the caw is short, and a loaded runner may be late.
	await wait_until(func() -> bool: return feather.visible, StampFlow.SLAM_SECONDS)
	assert_true(feather.visible, "at the impact it is on the desk")
	assert_true(feather.is_drifting(), "drifting in")
	assert_lt(feather.drift_offset().x, 0, "from the left")
	assert_gte(
		rest.position.x + feather.drift_offset().x,
		float(StampFlow.FEATHER_DRIFT_FROM_X),
		"from no further than off-screen left"
	)
	assert_eq(feather.mouse_filter, Control.MOUSE_FILTER_STOP, "it takes the click at once")
	assert_true(_caw.playing, "the dry caw")
	# Past the desk band's 0.1 s jolt, which carries the feather with it, mid-drift.
	await wait_seconds(StampFlow.JOLT_SECONDS + 0.05)
	assert_true(feather.is_drifting(), "still drifting")
	assert_eq(feather.get_global_rect(), rest, "its click target never left its place")
	await wait_seconds(StampFlow.FEATHER_DRIFT_SECONDS + SLACK)
	assert_false(feather.is_drifting(), "landed")
	assert_eq(feather.drift_offset(), Vector2i.ZERO, "beside the mentor")
	assert_true(feather.visible, "and stays with the held soul")


## The review's case: the old fall dropped 40 px through the slab. Every drawn frame of the drift
## must stay clear of the body chart and the sheets.
func test_the_drift_never_crosses_the_slab_or_a_sheet() -> void:
	_open(Fixture.instant())
	var feather: ClickableSprite = _system.feather
	_pin("B1", "W2")
	_stamp(&"valhalla")
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	var drift: Tween = _system.feather.drift_in(
		StampFlow.FEATHER_DRIFT_FROM_X - feather.global_position.x,
		StampFlow.FEATHER_DRIFT_SECONDS,
		StampConsequences.FEATHER_SWAY_PX
	)
	drift.pause()
	var evidence: Array[Control] = [_system.body_chart, _system.claim_panel, _system.witness_panel]
	var crossed: Array[String] = []
	var lowest: int = 0
	for _step: int in range(52):
		var drawn := Rect2(feather.global_position + Vector2(feather.drift_offset()), feather.size)
		lowest = maxi(lowest, feather.drift_offset().y)
		for area: Control in evidence:
			if drawn.intersects(area.get_global_rect()):
				crossed.append("%s at %s" % [area.name, drawn.position])
		drift.custom_step(StampFlow.FEATHER_DRIFT_SECONDS / 50.0)
	assert_eq(crossed, [] as Array[String], "the drift crosses no evidence")
	assert_eq(lowest, StampConsequences.FEATHER_SWAY_PX, "a 2 px sway, downwards only")
	assert_eq(feather.drift_offset(), Vector2i.ZERO, "and it rests in its place")


func test_a_stamp_that_holds_nothing_drops_no_feather() -> void:
	_open(Fixture.instant())
	_stamp(&"hel")
	assert_false(_desk.commands().awaiting_next(), "Asgaut's legal stamp holds nothing")
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	assert_false(_system.feather.visible, "no feather")
	assert_false(_caw.playing, "no caw")


func test_reduce_motion_puts_the_feather_in_place_at_the_impact() -> void:
	var options: Options = Fixture.instant()
	options.reduce_motion = true
	_open(options)
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_false(_system.feather.visible)
	var landed: Callable = func() -> bool: return _system.feather.visible
	await wait_until(landed, StampFlow.SLAM_SECONDS)
	assert_true(_system.feather.visible, "the feather landing is a state cue: it stays (D37)")
	assert_false(_system.feather.is_drifting(), "no drift")
	assert_eq(_system.feather.drift_offset(), Vector2i.ZERO, "in its place")
	assert_true(_caw.playing, "the caw stays")


func test_a_restart_in_the_slam_window_drops_no_feather() -> void:
	_open(Fixture.instant())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	_system.restart()
	await wait_seconds(StampFlow.SLAM_SECONDS + SLACK)
	assert_false(_system.feather.visible, "the killed slam never reached its impact")
	assert_false(_caw.playing)


func test_a_desk_without_the_caw_player_still_drops_the_feather() -> void:
	_open(Fixture.instant(), false)
	_pin("B1", "W2")
	_stamp(&"valhalla")
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	assert_true(_system.feather.visible, "the drift needs no sound")


func test_the_sprite_drifts_into_place_from_the_left_swaying_down() -> void:
	var sprite := ClickableSprite.new()
	sprite.size = Vector2(16, 16)
	add_child_autofree(sprite)
	var drift: Tween = sprite.drift_in(-68.0, 0.5, 2)
	drift.pause()
	assert_eq(sprite.drift_offset(), Vector2i(-68, 0), "starts 68 px to the left, at its height")
	var xs: Array[int] = []
	var ys: Array[int] = []
	for _step: int in range(55):
		drift.custom_step(0.01)
		xs.append(sprite.drift_offset().x)
		ys.append(sprite.drift_offset().y)
	for index: int in range(1, xs.size()):
		assert_gte(xs[index], xs[index - 1], "always drifting right, never back")
	assert_eq(ys.min(), 0, "never above its place")
	assert_eq(ys.max(), 2, "swaying 2 px down")
	assert_eq(sprite.drift_offset(), Vector2i.ZERO, "in place after 0.5 s")
	assert_false(sprite.is_drifting())


func test_the_sprite_takes_a_click_mid_drift_and_rests_when_hidden() -> void:
	var sprite := ClickableSprite.new()
	sprite.size = Vector2(16, 16)
	add_child_autofree(sprite)
	watch_signals(sprite)
	sprite.drift_in(-68.0, 0.5, 2)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	sprite._gui_input(press)
	assert_signal_emit_count(sprite, "clicked", 1, "live from the first frame")
	sprite.visible = false
	assert_eq(sprite.drift_offset(), Vector2i.ZERO, "hiding it ends the drift")
	assert_false(sprite.is_drifting())
	assert_null(sprite.drift_in(-68.0, 0.0, 2), "no time: in place at once")
	assert_eq(sprite.drift_offset(), Vector2i.ZERO)


func _open(options: Options, with_caw: bool = true) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(options)
	var flow: StampFlow = _desk.get_node("StampFlow") as StampFlow
	if flow.caw_player == null:
		# Until the desk scene carries its own caw player, the test brings one.
		var player := AudioStreamPlayer.new()
		player.stream = CAW
		_desk.add_child(player)
		flow.caw_player = player
	_caw = flow.caw_player
	if not with_caw:
		flow.caw_player = null
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.dawn_writ.next_button().pressed.emit()


func _pin(a: String, b: String) -> void:
	_system.finish_tellings()
	_area(a).press()
	_area(b).press()


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _stamp(realm: StringName) -> void:
	_system.finish_tellings()
	_door(realm).press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null
