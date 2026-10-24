extends GutTest
## The raven as the Huginn control on the desk (D40), with real clicks pushed through the desk's
## own SubViewport: a click on the bird or on his post asks about the selected grey thread through
## the existing eligibility and payment path, and he ruffles; a click with nothing selected, or a
## press the presentation gate consumes, spends nothing. He perches only on Huginn's days: an
## empty post otherwise. Reduce motion (D37) reaches him through the options.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## How long a new thread may take to draw in before the test fails.
const THREAD_DEADLINE := 1.0

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func _open(commands: DeskCommands, options: Options = Fixture.instant()) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_desk.use_options(options)
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.dawn_writ.next_button().pressed.emit()


func test_a_click_on_the_bird_asks_about_the_selected_grey_thread() -> void:
	_open(Fixture.commands())
	await _select_grey_thread()
	_click_at(_bird())
	assert_eq(_desk.commands().huginn_left(), 1, "one answer spent")
	assert_ne(_desk.commands().thread_answer(0), "", "and given")
	assert_true(_system.raven.is_ruffling(), "he ruffles as he answers (D17)")


func test_a_click_on_his_post_asks_too() -> void:
	_open(Fixture.commands())
	await _select_grey_thread()
	_click_at(_system.raven.global_position + Raven.POST_RECT.get_center())
	assert_eq(_desk.commands().huginn_left(), 1, "the post is part of the hit area")


func test_a_click_beside_the_post_asks_nothing() -> void:
	_open(Fixture.commands())
	await _select_grey_thread()
	_click_at(Vector2(310, 85))
	assert_eq(_desk.commands().huginn_left(), 2, "the wall beside the post is not the raven")


func test_a_click_with_nothing_selected_costs_nothing_and_says_nothing() -> void:
	_open(Fixture.commands())
	var caption: String = _system.caption_strip.shown_text()
	var clock: float = _desk.commands().time_left()
	_click_at(_bird())
	assert_eq(_desk.commands().huginn_left(), 2)
	assert_eq(_desk.commands().time_left(), clock, "no Huginn charge")
	assert_eq(_system.caption_strip.shown_text(), caption)
	assert_false(_system.raven.is_ruffling())


func test_a_consumed_press_never_spends_an_answer() -> void:
	_open(Fixture.commands())
	await _select_grey_thread()
	_desk.gate().begin(PresentationGate.WRITTEN, func() -> void: pass)
	_click_at(_bird())
	assert_false(_desk.gate().is_consuming(), "the press finished the presentation")
	assert_eq(_desk.commands().huginn_left(), 2, "and asked nothing (D27)")
	_click_at(_bird())
	assert_eq(_desk.commands().huginn_left(), 1, "the next click asks")


func test_his_hover_follows_the_mouse_and_the_count() -> void:
	_open(Fixture.commands())
	await _select_grey_thread()
	_move_to(_bird())
	assert_eq(_system.hover_label.shown_text(), "Ask Huginn: 2 answers left")
	_click_at(_bird())
	assert_eq(_system.hover_label.shown_text(), "Ask Huginn: 1 answer left", "said again")


func test_the_post_is_empty_on_a_day_without_huginn() -> void:
	_open(Fixture.two_days())
	assert_false(_system.raven.visible, "day 2: the empty post")
	_click_at(_bird())
	assert_eq(_desk.commands().huginn_left(), 0)
	_open(Fixture.commands())
	assert_true(_system.raven.visible, "day 3: he perches")


func test_the_ask_huginn_button_is_gone() -> void:
	_open(Fixture.commands())
	assert_null(_desk.get_node_or_null(^"AskHuginn"), "the raven is the control (D40)")
	for child: Node in _desk.get_children():
		var button: Button = child as Button
		assert_true(button == null or not button.text.contains("Huginn"), child.name)


func test_reduce_motion_reaches_him_through_the_options() -> void:
	var options: Options = Fixture.instant()
	options.reduce_motion = true
	_open(Fixture.commands(), options)
	assert_true(_system.raven.reduce_motion)
	_system.raven._process(10.0)
	assert_eq(_system.raven.idle_frame(), 0, "no head tilt")


## D40: the mentor's line when he first matters (the day's first grey thread) says to click him,
## and it fits one line of the clerk's note.
func test_the_mentor_says_to_click_the_raven() -> void:
	_open(SliceLoader.load_slice())
	var line: String = _desk.commands().slice_rules().mentor_grey_huginn_line
	assert_eq(line, "Huginn answers that. Click the raven to ask him.")
	var font: Font = _system.caption_strip.get_theme_default_font()
	var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
	assert_lte(width, float(_system.note_width()), "one line of the note")


func _bird() -> Vector2:
	return _system.raven.global_position + Raven.BIRD_RECT.get_center()


## Pins C1-W1 (a grey seam) and selects its knot for Huginn, all with real clicks.
func _select_grey_thread() -> void:
	_click_at(_system.claim_panel.area("C1").get_global_rect().get_center())
	_click_at(_system.witness_panel.area("W1").get_global_rect().get_center())
	await _threads_drawn()
	_click_at(_knot(0).get_global_rect().get_center())
	assert_eq(_system.huginn_thread, 0, "the grey knot is selected")


func _knot(thread_index: int) -> PinSelectable:
	for child: Node in _system.thread_layer.get_children():
		var line: ThreadLine = child as ThreadLine
		if line != null and not line.is_queued_for_deletion() and line.thread_index == thread_index:
			return line.knot()
	return null


## A new thread is drawn taut in about 0.15 s (D12) and its knot takes clicks once it is whole;
## a drawing still going after THREAD_DEADLINE seconds fails the test instead of falling through.
func _threads_drawn() -> void:
	var started: int = Time.get_ticks_msec()
	var drawing: bool = true
	while drawing and Time.get_ticks_msec() - started < THREAD_DEADLINE * 1000.0:
		drawing = false
		for child: Node in _system.thread_layer.get_children():
			var line: ThreadLine = child as ThreadLine
			drawing = drawing or (line != null and line.is_drawing_in())
		if drawing:
			await get_tree().process_frame
	assert_false(drawing, "the new thread is drawn within %.1f s" % THREAD_DEADLINE)


func _move_to(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)


## A move, a press and a release at `at`, pushed through the desk's viewport.
func _click_at(at: Vector2) -> void:
	_move_to(at)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		_viewport.push_input(event)
