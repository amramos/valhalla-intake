extends GutTest
## Real mouse events through the desk's own viewport (D9): the stamp confirm, the doors and the
## phase card's button each take one deliberate click and swallow the second press of a
## double-click. The desk sits in a SubViewport because GUT's window covers the root viewport.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(SliceLoader.load_slice())
	_viewport.add_child(_desk)
	_system = _desk.system()


func test_the_confirm_swallows_a_double_click_and_takes_one_click() -> void:
	_begin()
	_door(&"valhalla").press()
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	var at: Vector2 = confirm.get_global_rect().get_center()
	_click(at, true)
	assert_eq(_soul(), "Ulf", "the second press of a double-click stamps nothing")
	_click(at, false)
	assert_eq(_soul(), "Kolbeinn", "one deliberate click on the armed confirm stamps")


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
	assert_true(_system.stamp_flow.stamp_prompt.visible)


func test_the_phase_card_button_swallows_a_double_click() -> void:
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	var at: Vector2 = next.get_global_rect().get_center()
	_click(at, true)
	assert_eq(_desk.commands().phase(), RunState.DAWN, "a double-click skips no card")
	_click(at, false)
	assert_eq(_desk.commands().phase(), RunState.DESK)


func test_the_prompt_and_next_soul_sit_clear_of_every_door() -> void:
	_begin()
	_door(&"valhalla").press()
	for door: Door in _system.doors:
		var area: Rect2 = door.get_global_rect()
		assert_false(
			area.intersects(_system.stamp_flow.stamp_prompt.get_global_rect()),
			"prompt over %s" % door.realm
		)
		assert_false(
			area.intersects(_system.stamp_flow.next_soul_button.get_global_rect()),
			"Next soul over %s" % door.realm
		)


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


func _soul() -> String:
	return _system.soul.soul_name()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


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
