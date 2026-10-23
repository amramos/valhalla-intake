extends GutTest
## Hel's tide at the slam (D38): a stamp that grows the tide steps its new figure in from 2 px
## below at the slam's impact, exactly once, from the StampResult it holds; a refresh never steps
## it, and every refresh before the impact draws the tide as it was; reduce motion places the
## figure at once (D37). The door's own step on a bare door too.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## Real time is a little late under a loaded test runner.
const SLACK := 0.2

var _desk: Desk = null
var _system: DeskSystem = null


func test_a_stamp_that_grows_the_tide_steps_it_once_at_the_impact() -> void:
	_open(Fixture.instant())
	var hel: Door = _door(&"hel")
	var threshold: int = _desk.commands().slice_rules().tide_threshold
	await _stamp_asgaut()
	assert_eq(hel.tide_steps, 0, "a stamp that adds no figure steps nothing")
	_stamp(&"hel")
	assert_eq(_desk.commands().hel_tide(), 1, "the worthy soul swells Hel's tide")
	assert_eq(hel.tide, Vector2i(0, threshold), "the figure waits for the impact")
	assert_eq(hel.tide_steps, 0)
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	assert_eq(hel.tide, Vector2i(1, threshold), "at the impact the figure is there")
	assert_eq(hel.tide_steps, 1, "one step for the stamp")
	assert_gt(hel.tide_rise(), 0, "stepping up from below")
	assert_lte(hel.tide_rise(), Door.TIDE_RISE_PX, "from 2 px below at most")
	await wait_seconds(Door.TIDE_RISE_SECONDS + SLACK)
	assert_eq(hel.tide_rise(), 0, "in its slot after 0.3 s")
	_system.refresh()
	_system.refresh()
	assert_eq(hel.tide_steps, 1, "a refresh never steps the tide")
	assert_eq(hel.tide, Vector2i(1, threshold))


## The review's case: the refresh inside the stamp, and any refresh before the impact (a plain one,
## or the clock running out), must not show the new figure early; the pending stamp's tide is what
## the desk draws until the impact releases it, once.
func test_refreshes_in_the_hold_keep_the_tide_as_it_was_until_the_impact() -> void:
	_open(Fixture.instant(), Fixture.worthy_first())
	var hel: Door = _door(&"hel")
	var threshold: int = _desk.commands().slice_rules().tide_threshold
	_stamp(&"hel")
	assert_eq(_desk.commands().hel_tide(), 1, "the worthy soul swells Hel's tide")
	assert_eq(_system.stamp_flow.displayed_tide(), 0, "the desk shows the tide as it was")
	_system.refresh()
	assert_eq(hel.tide, Vector2i(0, threshold), "a refresh in the hold keeps the figure waiting")
	_desk.commands().advance_time(Fixture.CLOCK_SECONDS)
	assert_ne(_desk.commands().phase(), RunState.DESK, "the clock ran out inside the hold")
	assert_eq(hel.tide, Vector2i(0, threshold), "the horn's refresh keeps it waiting too")
	assert_eq(hel.tide_steps, 0)
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	assert_eq(hel.tide, Vector2i(1, threshold), "the impact steps it in")
	assert_eq(hel.tide_steps, 1, "once")
	assert_eq(_system.stamp_flow.displayed_tide(), 1, "released: the committed count")
	_system.refresh()
	assert_eq(hel.tide_steps, 1, "and no refresh steps it again")


func test_reduce_motion_puts_the_new_figure_in_its_slot_at_once() -> void:
	var options: Options = Fixture.instant()
	options.reduce_motion = true
	_open(options)
	var hel: Door = _door(&"hel")
	await _stamp_asgaut()
	_stamp(&"hel")
	await wait_seconds(StampFlow.HOLD_SECONDS + 0.03)
	assert_eq(hel.tide.x, 1, "the figure is there at the impact")
	assert_eq(hel.tide_steps, 1, "the step is still the stamp's, once")
	assert_eq(hel.tide_rise(), 0, "with no movement (D37)")


func test_a_restart_before_the_impact_steps_nothing() -> void:
	_open(Fixture.instant())
	var hel: Door = _door(&"hel")
	await _stamp_asgaut()
	_stamp(&"hel")
	_system.restart()
	await wait_seconds(StampFlow.SLAM_SECONDS + SLACK)
	assert_eq(hel.tide_steps, 0, "the killed slam never reached its impact")
	assert_eq(hel.tide.x, 0, "the new run's tide is empty")


func test_a_door_steps_its_newest_figure_and_a_refresh_never_does() -> void:
	var door := Door.new()
	door.size = Vector2(60, 80)
	add_child_autofree(door)
	door.set_tide(0, 3)
	assert_eq([door.tide_steps, door.tide_rise()], [0, 0], "a refresh sets the tide as it is")
	var step: Tween = door.step_tide(1, 3)
	assert_not_null(step)
	assert_eq(door.tide, Vector2i(1, 3))
	assert_eq(door.tide_rise(), Door.TIDE_RISE_PX, "the new figure starts 2 px below")
	door.set_tide(1, 3)
	assert_eq(door.tide_rise(), Door.TIDE_RISE_PX, "a refresh of the same tide lets it step on")
	step.custom_step(Door.TIDE_RISE_SECONDS + 0.01)
	assert_eq(door.tide_rise(), 0, "in its slot")
	door.step_tide(2, 3)
	door.set_tide(0, 3)
	assert_eq(door.tide_rise(), 0, "a different tide (a restart) settles every figure")
	assert_null(door.step_tide(1, 3, 0.0), "no time: at once")
	assert_eq(door.tide_rise(), 0)
	assert_eq(door.tide_steps, 3, "one count per step, none per refresh")


func _open(options: Options, commands: DeskCommands = null) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands if commands != null else Fixture.commands())
	_desk.use_options(options)
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


## Asgaut to Hel (his legal and worthy realm: no figure), sent on if held, the window open again.
func _stamp_asgaut() -> void:
	_stamp(&"hel")
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.1)
	if _desk.commands().awaiting_next():
		_system.stamp_flow.stamp_prompt.send_on()
	await wait_seconds(StampFlow.WALK_SECONDS)


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
