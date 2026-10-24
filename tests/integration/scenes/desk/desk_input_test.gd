extends GutTest
## Real mouse events through the desk's own viewport (D9, D14): the stamp, the doors and the phase
## card's button each take one deliberate click and swallow the second press of a double-click;
## the stamp commits on the press, and a right-click puts it down. The desk sits in a SubViewport
## because GUT's window covers the root viewport.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
## How much of a door's foot the raised stamp may stand over (D54).
## 24 since the critic's last stamp pass enlarged the block to 28x28 (it stands over 22 px).
const FOOT_PX := 24

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(SliceLoader.load_slice())
	_desk.use_options(Options.new())
	_viewport.add_child(_desk)
	_system = _desk.system()


func test_the_stamp_swallows_a_double_click_and_takes_one_click() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	var at: Vector2 = confirm.get_global_rect().get_center()
	_click(at, true)
	assert_eq(_soul(), "Ulf", "the second press of a double-click stamps nothing")
	assert_true(_system.stamp_flow.stamp_prompt.is_asking(), "and leaves the stamp raised")
	_click(at, false)
	assert_eq(_soul(), "Kolbeinn", "one deliberate click on the armed stamp stamps")


func test_the_stamp_slams_on_the_press_not_the_release() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	var at: Vector2 = confirm.get_global_rect().get_center()
	_press(at, MOUSE_BUTTON_LEFT, true)
	assert_eq(_soul(), "Kolbeinn", "the press alone stamps (D14)")
	assert_true(_system.stamp_flow.is_slamming())
	_press(at, MOUSE_BUTTON_LEFT, false)


func test_a_right_click_on_the_raised_stamp_puts_it_down() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	var at: Vector2 = confirm.get_global_rect().get_center()
	_press(at, MOUSE_BUTTON_RIGHT, true)
	_press(at, MOUSE_BUTTON_RIGHT, false)
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "the stamp is put down")
	assert_false(_door(&"valhalla").selected)
	assert_eq(_soul(), "Ulf", "and nothing is stamped")


func test_the_confirm_ignores_a_click_before_it_is_armed() -> void:
	_begin()
	_door(&"valhalla").press()
	_click(_system.stamp_flow.stamp_prompt.confirm_button().get_global_rect().get_center(), false)
	assert_eq(_soul(), "Ulf")


func test_a_door_ignores_the_second_press_of_a_double_click() -> void:
	_begin()
	var door: Door = _door(&"valhalla")
	watch_signals(door)
	var at: Vector2 = door.get_global_rect().get_center()
	_click(at, true)
	assert_signal_not_emitted(door, "door_clicked")
	_click(at, false)
	assert_signal_emitted(door, "door_clicked")
	assert_true(_system.stamp_flow.stamp_prompt.is_asking())


func test_the_phase_card_button_swallows_a_double_click() -> void:
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	var at: Vector2 = next.get_global_rect().get_center()
	_click(at, true)
	assert_eq(_desk.commands().phase(), RunState.DAWN, "a double-click skips no card")
	_click(at, false)
	assert_eq(_desk.commands().phase(), RunState.DESK)


## D54: the writ sits clear of every door; the raised stamp may stand over a door's foot only, so
## a click on the door's body is always the door's.
func test_the_writ_sits_clear_of_every_door_and_the_stamp_over_a_foot_at_most() -> void:
	_begin()
	_door(&"valhalla").press()
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	for door: Door in _system.doors:
		var area: Rect2 = door.get_global_rect()
		assert_false(area.intersects(prompt.writ().get_global_rect()), "writ over %s" % door.realm)
		var over: Rect2 = area.intersection(prompt.stamp_rect())
		if over.has_area():
			assert_eq(over.end.y, area.end.y, "only the foot of %s" % door.realm)
			assert_lte(over.size.y, float(FOOT_PX), "at most %d px of %s" % [FOOT_PX, door.realm])
	var face: Rect2 = (prompt.get_node("Face") as Control).get_global_rect()
	assert_true(prompt.stamp_rect().encloses(face), "the drawn stamp is its click target")


func test_asking_again_rearms_the_confirm() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	assert_true(confirm.is_armed())
	_door(&"hel").press()
	assert_false(confirm.is_armed(), "another door's prompt waits out its own arm time")


func _begin() -> void:
	_system.phase_card.next_button().pressed.emit()
	_system.finish_tellings()


func _soul() -> String:
	return _system.soul.soul_name()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


## One press or release at `at`, after a move there.
func _press(at: Vector2, button: MouseButton, pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = at
	event.global_position = at
	event.pressed = pressed
	_viewport.push_input(event)


## A move, a press and a release at `at`, pushed through the desk's viewport.
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
