extends GutTest
## Real clicks on the timed day-3 fixture desk (desk_fixture.gd), pushed through the desk's own
## SubViewport: an action that ends the day keeps the horn's announcement, and an open stamp
## prompt lets no pin or Huginn answer through underneath it.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(Fixture.instant())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_a_no_seam_pin_that_ends_the_day_keeps_the_horns_caption() -> void:
	_system._process(Fixture.CLOCK_SECONDS - 5.0)
	assert_eq(_desk.commands().phase(), RunState.DESK, "5 s left")
	_click(_system.claim_panel.area("C3"))
	_click(_system.law_panel.area("L1"))
	assert_ne(_desk.commands().phase(), RunState.DESK, "the -10 s pin ended the day")
	assert_eq(
		_system.caption_strip.shown_text(), DeskSystem.HORN_TEXT, "the horn is not overwritten"
	)


func test_an_answer_that_ends_the_day_never_replaces_the_horn() -> void:
	_click(_system.claim_panel.area("C1"))
	_click(_system.witness_panel.area("W1"))
	await _threads_drawn()
	_click(_knot(0))
	_system._process(Fixture.CLOCK_SECONDS - 3.0)
	assert_eq(_desk.commands().phase(), RunState.DESK, "3 s left")
	_click(_system.ask_huginn)
	assert_ne(_desk.commands().phase(), RunState.DESK, "the 5 s answer ended the day")
	var strip: CaptionStrip = _system.caption_strip
	strip._process(strip.hold_seconds + 1.0)
	strip._process(strip.hold_seconds + 1.0)
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "past the hold, the horn still stands")


## A click elsewhere puts the raised stamp down and does nothing else (D14): no pin starts
## under the stamp, and nothing is charged.
func test_a_click_under_the_raised_stamp_puts_it_down_and_pins_nothing() -> void:
	_click(_door(&"hel"))
	assert_true(_system.stamp_flow.stamp_prompt.is_asking())
	var before: float = _desk.commands().time_left()
	_click(_system.claim_panel.area("C3"))
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "the click put the stamp down")
	assert_false(_system.claim_panel.area("C3").selected, "and selected nothing")
	assert_eq(_desk.commands().threads().size(), 0, "no thread under the stamp")
	assert_eq(_desk.commands().time_left(), before, "no charge under the stamp")


func test_an_open_stamp_prompt_lets_no_huginn_answer_through() -> void:
	_click(_system.claim_panel.area("C1"))
	_click(_system.witness_panel.area("W1"))
	await _threads_drawn()
	_click(_knot(0))
	assert_eq(_system.huginn_thread, 0, "the grey knot is selected")
	_click(_door(&"hel"))
	assert_true(_system.stamp_flow.stamp_prompt.is_asking())
	var before: float = _desk.commands().time_left()
	_click(_system.ask_huginn)
	assert_eq(_desk.commands().huginn_left(), 2, "no answer spent under the prompt")
	assert_eq(_desk.commands().thread_answer(0), "")
	assert_eq(_desk.commands().time_left(), before, "no Huginn charge under the prompt")


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _knot(thread_index: int) -> PinSelectable:
	for child: Node in _system.thread_layer.get_children():
		var line: ThreadLine = child as ThreadLine
		if line != null and not line.is_queued_for_deletion() and line.thread_index == thread_index:
			return line.knot()
	return null


## A new thread is drawn taut in about 0.15 s (D12) and its knot takes clicks once it is whole.
func _threads_drawn() -> void:
	for _frame: int in range(120):
		var drawing: bool = false
		for child: Node in _system.thread_layer.get_children():
			var line: ThreadLine = child as ThreadLine
			drawing = drawing or (line != null and line.is_drawing_in())
		if not drawing:
			return
		await get_tree().process_frame


## A move, a press and a release on `target`, pushed through the desk's viewport.
func _click(target: Control) -> void:
	var at: Vector2 = target.get_global_rect().get_center()
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
		_viewport.push_input(event)
