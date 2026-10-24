extends GutTest
## A pin with no seam (D36, D51), with real clicks pushed through the desk's own SubViewport: the
## second pin pops out, a slack thread of no kind drops off the desk and frees itself, the tick
## plays, the candle gutters on a timed day and the note says so. The drop is cosmetic: it takes
## no click and blocks no pin, and the next press, anywhere, ends it and goes on as it would have.
## A charged pin that ends the day still gutters the candle. Reduce motion draws no slack thread
## at all (D37).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## Real time is a little late under a loaded test runner.
const SLACK := 0.2
## A point on the gate band's wall between Valhalla's door and Hel's, where nothing takes a click.
const BARE_STONE := Vector2(160, 40)

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null
var _options: Options = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_options = Fixture.instant()


func test_a_no_seam_pin_drops_a_slack_thread_that_frees_itself() -> void:
	_open(Fixture.commands())
	_pin("C1", "W2")
	assert_eq(_desk.commands().threads().size(), 0, "no thread is made")
	assert_false(_area("C1").selected, "the first pin pops out with the second")
	assert_false(_area("W2").selected)
	var slack: Array[ThreadLine] = _lines()
	assert_eq(slack.size(), 1, "one slack thread between the two")
	assert_true(slack[0].is_slack(), "slack, never a thread of the soul's")
	assert_false(slack[0].has_knot(), "no knot or bead to click")
	await wait_process_frames(2)
	var kinds: Array[Color] = []
	for colour: StringName in [&"thread_red", &"thread_grey", &"thread_law", &"pin_head"]:
		kinds.append(_system.thread_layer.get_theme_color(colour, &"DeskPalette"))
	var drawn: Array[Color] = slack[0].drawn_colors()
	assert_false(drawn.is_empty(), "the slack thread is drawn")
	for colour: Color in kinds:
		assert_false(drawn.has(colour), "no kind's colour, no pin head: %s" % colour)
	var top: float = _top(slack[0])
	await wait_seconds(ThreadLine.SLACK_SECONDS * 0.6)
	if is_instance_valid(slack[0]):
		assert_gt(_top(slack[0]), top, "it falls")
	await wait_seconds(ThreadLine.SLACK_SECONDS * 0.4 + SLACK)
	assert_eq(_lines().size(), 0, "gone once it has fallen")


func test_a_timed_no_seam_pin_ticks_gutters_the_candle_and_says_so() -> void:
	_open(Fixture.commands())
	var before: float = _desk.commands().time_left()
	_pin("C1", "W2")
	var rules: SliceRules = _desk.commands().slice_rules()
	var lost: int = roundi(rules.no_seam_seconds)
	assert_almost_eq(_desk.commands().time_left(), before - lost, 0.01, "the pin cost its time")
	assert_true(_system.tick_player.playing, "the dull tick")
	assert_eq(_system.hud.gutter_label(), "-" + Hud.format_time(lost), "the candle gutters")
	assert_eq(_system.caption_strip.shown_text(), rules.text.no_seam_timed_format % lost)


func test_an_untimed_no_seam_pin_never_gutters() -> void:
	_open(SliceLoader.load_slice())
	_pin("C4", "L3")
	assert_eq(_system.caption_strip.shown_text(), "No seam between those two.")
	assert_eq(_system.hud.gutter_label(), "", "nothing was charged: no gutter")
	assert_eq(_lines().size(), 1, "the slack thread drops all the same")


func test_the_drop_takes_no_click_and_blocks_no_pin() -> void:
	_open(Fixture.commands())
	_pin("C1", "W2")
	assert_false(_desk.gate().is_consuming(), "the drop is no presentation a click must finish")
	_click(_area("C1"))
	assert_true(_area("C1").selected, "the next press during the drop selects (D51)")
	_click(_area("W1"))
	assert_eq(_desk.commands().threads().size(), 1, "and the next pin is made")
	var real: int = 0
	for line: ThreadLine in _lines():
		real += 0 if line.is_slack() else 1
	assert_eq(real, 1, "its thread is drawn")


## The review's case: the next press must end a falling strand without being taken by it (D51).
func test_a_press_on_another_item_ends_the_drop_and_selects_that_item() -> void:
	_open(Fixture.commands())
	_pin("C1", "W2")
	assert_eq(_slack().size(), 1, "the strand is falling")
	_click(_area("C3"))
	assert_eq(_slack().size(), 0, "the press ended the drop at once")
	assert_true(_area("C3").selected, "and selected the item as any press would")
	assert_eq(_desk.commands().threads().size(), 0)


func test_a_press_on_bare_stone_ends_the_drop_and_does_nothing_else() -> void:
	_open(Fixture.commands())
	_pin("C1", "W2")
	var caption: String = _system.caption_strip.shown_text()
	var time_left: float = _desk.commands().time_left()
	_click_at(BARE_STONE)
	assert_eq(_slack().size(), 0, "the press ended the drop")
	assert_eq(_system.caption_strip.shown_text(), caption, "the note is unchanged")
	assert_eq(_desk.commands().time_left(), time_left, "nothing was charged")
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "no stamp is raised")
	for item_id: String in ["C1", "C3", "W2", "B1"]:
		assert_false(_area(item_id).selected, "nothing is selected: %s" % item_id)


## The review's case: a charged pin whose cost ends the day still gutters the candle (D36).
func test_a_charged_pin_that_ends_the_day_still_gutters_the_candle() -> void:
	_open(Fixture.commands())
	_desk.commands().advance_time(Fixture.CLOCK_SECONDS - 5.0)
	assert_eq(_desk.commands().phase(), RunState.DESK, "5 s left on the clock")
	_pin("C1", "W2")
	assert_ne(_desk.commands().phase(), RunState.DESK, "the pin's 10 s ended the day")
	var lost: int = roundi(_desk.commands().slice_rules().no_seam_seconds)
	assert_eq(_system.hud.gutter_label(), "-" + Hud.format_time(lost), "the candle gutters")
	assert_eq(_system.caption_strip.shown_text(), DeskSystem.HORN_TEXT, "the horn's word stands")


func test_a_restart_after_a_charged_pin_clears_the_gutters_label() -> void:
	_open(Fixture.commands())
	_pin("C1", "W2")
	assert_ne(_system.hud.gutter_label(), "", "the candle gutters")
	_system.restart()
	assert_eq(_system.hud.gutter_label(), "", "the old run's -0:10 leaves with it")


func test_reduce_motion_draws_no_slack_thread_but_keeps_the_tick_gutter_and_note() -> void:
	_options.reduce_motion = true
	_open(Fixture.commands())
	_pin("C1", "W2")
	assert_eq(_lines().size(), 0, "no slack thread at all (D37)")
	assert_true(_system.tick_player.playing, "the tick stays")
	assert_ne(_system.hud.gutter_label(), "", "the gutter's label stays")
	assert_string_starts_with(_system.caption_strip.shown_text(), "No seam between those two.")


func _open(commands: DeskCommands) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_desk.use_options(_options)
	_viewport.add_child(_desk)
	_system = _desk.system()
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	_click(next)


func _pin(a: String, b: String) -> void:
	_system.finish_tellings()
	_click(_area(a))
	_click(_area(b))


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _lines() -> Array[ThreadLine]:
	var lines: Array[ThreadLine] = []
	for child: Node in _system.thread_layer.get_children():
		if child is ThreadLine and not child.is_queued_for_deletion():
			lines.append(child as ThreadLine)
	return lines


## The highest drawn pixel row of `line`.
func _top(line: ThreadLine) -> float:
	var top: float = INF
	for rect: Rect2 in line.drawn_rects():
		top = minf(top, rect.position.y)
	return top


func _slack() -> Array[ThreadLine]:
	var found: Array[ThreadLine] = []
	for line: ThreadLine in _lines():
		if line.is_slack():
			found.append(line)
	return found


func _click(target: Control) -> void:
	_click_at(target.get_global_rect().get_center())


func _click_at(at: Vector2) -> void:
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
