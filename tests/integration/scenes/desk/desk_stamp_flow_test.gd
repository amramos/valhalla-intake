extends GutTest
## The stamp's aftermath, with real clicks pushed through the desk's own SubViewport and real time
## for the walk: a second walk after the first has ended, the citation before the mentor's comment
## (D33), a new run that forgets the last one's comment, the mentor's Next held under a pending
## stamp (D9), the walking soul letting clicks through to the doors, her portrait never replaying
## over the horn, and her comment on a held stamp carried to the next soul, never behind the horn.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)


func test_a_stamp_after_the_last_walk_ended_walks_its_soul_too() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	assert_eq(_soul(), "Second", "Asgaut's legal stamp holds nothing")
	await wait_seconds(StampFlow.HOLD_SECONDS + StampFlow.WALK_SECONDS + 0.2)
	assert_eq(_walkers().size(), 0, "the first walk ended and its figure is gone")
	_stamp(&"valhalla")
	assert_eq(_walkers().size(), 1, "the second soul walks through its door")


func test_a_held_stamp_shows_its_citation_before_the_mentors_comment() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.hold_seconds = 0.3
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_true(stamp.citation, "the visible red seam cites the Valhalla stamp")
	assert_ne(stamp.mentor_line, "", "and the unguided soul draws her comment")
	assert_eq(strip.shown_text(), stamp.citation_text, "D33: the citation takes the strip first")
	await wait_seconds(strip.hold_seconds + 0.2)
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment follows once the hold is over")


func test_play_again_forgets_the_last_runs_mentor_comment() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	var old_line: String = _system.stamp_flow.mentor_line()
	assert_ne(old_line, "", "the illegal stamp drew her comment")
	_click(_system.stamp_flow.next_soul_button)
	_stamp(&"valhalla")
	assert_eq(_desk.commands().phase(), RunState.ENDING, "the run is over")
	# The last day's dusk cards, then the ending's Play again, reach the new run's dawn; then Begin.
	for _card: int in 10:
		if _desk.commands().phase() == RunState.DAWN:
			break
		_advance_card()
	assert_eq(_desk.commands().phase(), RunState.DAWN, "Play again reached the new run's dawn")
	_advance_card()
	assert_eq(_soul(), "Asgaut", "a new run seats its first soul")
	assert_eq(_system.stamp_flow.mentor_line(), "", "nothing she said last run is retained")
	_click(_system.mentor_portrait)
	assert_ne(_system.caption_strip.shown_text(), old_line, "a click on her replays nothing old")


func test_the_mentors_next_waits_while_the_stamp_prompt_is_open() -> void:
	_open(SliceLoader.load_slice())
	var step: MentorStep = _desk.commands().mentor_step()
	assert_not_null(step, "Ulf is guided (D16)")
	assert_eq(step.until, MentorStep.Until.READ, "his first step is read")
	_click(_door(&"valhalla"))
	assert_true(_system.stamp_flow.stamp_prompt.visible, "the stamp preview is open")
	var next: GuardedButton = _system.mentor_bubble.next_button()
	next.arm_now()
	_click(next)
	assert_eq(_desk.commands().mentor_step(), step, "no guidance advances under a pending stamp")


func test_the_walking_soul_lets_a_click_through_to_the_door_under_it() -> void:
	_open(Fixture.commands())
	_stamp(&"hel")
	var walkers: Array[DragSource] = _walkers()
	assert_eq(walkers.size(), 1)
	var walker: DragSource = walkers[0]
	assert_eq(walker.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the walker is decoration")
	var hel: Door = _door(&"hel")
	# The walk frees its figure when it ends: a walk that ends early fails here, never errors. The
	# wait holds a weak reference, since a lambda's captured node that is freed is itself an error.
	var walker_ref: WeakRef = weakref(walker)
	var over_door: Callable = func() -> bool:
		var walking: DragSource = walker_ref.get_ref() as DragSource
		if not is_instance_valid(walking):
			return false
		return walking.get_global_rect().intersection(hel.get_global_rect()).get_area() >= 16.0
	await wait_until(over_door, StampFlow.HOLD_SECONDS + StampFlow.WALK_SECONDS)
	if not is_instance_valid(walker_ref.get_ref()):
		fail_test("the walk ended before the walker reached Hel's door")
		return
	var overlap: Rect2 = walker.get_global_rect().intersection(hel.get_global_rect())
	assert_true(overlap.has_area(), "the walker is over Hel's door")
	watch_signals(hel)
	_click_at(overlap.get_center())
	assert_signal_emitted(hel, "door_clicked", "the click under the walker reaches the door")


## The review's case: a stamp drew her comment, then the clock ran out; a click on her portrait
## must not replay the old comment over the horn's announcement.
func test_a_click_on_the_mentor_after_the_horn_keeps_the_horns_caption() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_ne(_system.stamp_flow.mentor_line(), "", "the illegal stamp drew her comment")
	_click(_system.stamp_flow.next_soul_button)
	_desk.commands().advance_time(Fixture.CLOCK_SECONDS)
	assert_ne(_desk.commands().phase(), RunState.DESK, "the clock ran out")
	var strip: CaptionStrip = _system.caption_strip
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "the horn's announcement shows")
	_click(_system.mentor_portrait)
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "a click on her never covers the horn")


## The review's case: her comment on a held stamp waits behind the citation's hold; "Next soul"
## clicked inside that hold carries it to the next soul instead of dropping it.
func test_her_comment_on_a_held_stamp_follows_a_next_soul_clicked_inside_the_hold() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_eq(strip.shown_text(), stamp.citation_text, "the citation holds the strip")
	_click(_system.stamp_flow.next_soul_button)
	assert_eq(_soul(), "Second", "the next soul is seated inside the hold")
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment arrives with the next soul")


func test_her_comment_follows_the_next_soul_after_the_feather_retook_the_strip() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	_click(_system.stamp_flow.feather)
	assert_eq(_system.caption_strip.shown_text(), stamp.citation_text, "the feather re-shows it")
	_click(_system.stamp_flow.next_soul_button)
	assert_eq(_system.caption_strip.shown_text(), stamp.mentor_line, "her comment is not lost")


func test_her_comment_once_shown_is_not_repeated_on_the_next_soul() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	var strip: CaptionStrip = _system.caption_strip
	strip.hold_seconds = 0.2
	strip.clear()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	await wait_seconds(strip.hold_seconds + 0.2)
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment showed during the hold")
	_click(_system.stamp_flow.next_soul_button)
	assert_eq(strip.shown_text(), "", "the next soul starts on a clear strip")


func test_a_carried_comment_never_queues_behind_the_horn() -> void:
	_open(Fixture.commands())
	_pin("B1", "W2")
	# The held stamp runs the clock out; the horn waits for Next soul (D36, D48).
	_desk.commands().set_stamp_seconds(Fixture.CLOCK_SECONDS)
	_stamp(&"valhalla")
	assert_true(_desk.commands().awaiting_next())
	_click(_system.stamp_flow.next_soul_button)
	var strip: CaptionStrip = _system.caption_strip
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "the horn sounds on Next soul")
	strip._process(strip.hold_seconds + 1.0)
	strip._process(strip.hold_seconds + 1.0)
	assert_eq(strip.shown_text(), DeskSystem.HORN_TEXT, "past the hold, the horn still stands")


func _open(commands: DeskCommands) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_viewport.add_child(_desk)
	_system = _desk.system()
	_advance_card()


func _advance_card() -> void:
	var next: GuardedButton = _system.phase_card.next_button()
	next.arm_now()
	_click(next)


func _soul() -> String:
	return _system.soul.soul_name()


func _walkers() -> Array[DragSource]:
	var found: Array[DragSource] = []
	for child: Node in _system.stamp_flow.walk_layer.get_children():
		if child is DragSource and not child.is_queued_for_deletion():
			found.append(child as DragSource)
	return found


func _pin(a: String, b: String) -> void:
	_click(_area(a))
	_click(_area(b))


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _stamp(realm: StringName) -> void:
	_click(_door(realm))
	var confirm: GuardedButton = _system.stamp_flow.stamp_prompt.confirm_button()
	confirm.arm_now()
	_click(confirm)


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _click(target: Control) -> void:
	_click_at(target.get_global_rect().get_center())


## A move, a press and a release at `at`, pushed through the desk's viewport.
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
