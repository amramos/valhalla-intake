extends GutTest
## The review's cases for the desk's presentations (D27, D28, D37, D48, the plan's timing policy):
## a held citation's lit pair outlives the mentor's comment; the pause and focus loss stop every
## presentation clock (the note's hold, a door's flare, the stamp's rise); reduce motion draws a
## new thread whole; a skipped tale and a restart leave no voice playing. The timed day-3 fixture
## desk (desk_fixture.gd), in the desk's own SubViewport.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func _open(options: Options) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(options)
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_a_held_citation_keeps_its_pair_lit_through_the_mentors_comment() -> void:
	_open(Fixture.normal())
	_system.finish_tellings()
	_system.body_chart.area("B1").press()
	_system.witness_panel.area("W2").press()
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_true(stamp.citation, "a visible contradiction stamped wrongly is cited")
	assert_ne(stamp.mentor_line, "", "and draws her comment, queued behind the citation")
	var strip: CaptionStrip = _system.caption_strip
	for _caption: int in range(4):
		if strip.shown_text() == stamp.mentor_line:
			break
		strip.finish_writing()
		strip._process(strip.hold_seconds)
	strip.finish_writing()
	assert_eq(strip.shown_text(), stamp.mentor_line, "her comment shows after the citation")
	assert_true(_desk.commands().awaiting_next(), "the soul still waits for Send it on")
	assert_true(_area(stamp.citation_a).lit, "D48: %s stays lit" % stamp.citation_a)
	assert_true(_area(stamp.citation_b).lit, "D48: %s stays lit" % stamp.citation_b)


func test_the_pause_and_focus_loss_hold_the_notes_message() -> void:
	_open(Fixture.instant())
	var strip: CaptionStrip = _system.caption_strip
	strip.clear()
	strip.post("first", CaptionStrip.Priority.MENTOR)
	strip.post("second", CaptionStrip.Priority.HUGINN)
	_desk.toggle_pause()
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), "first", "the pause holds the note's hold")
	_desk.pause_overlay().resume_button().pressed.emit()
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), "first", "so does focus loss")
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), "second", "resumed, the hold runs out and the next shows")


func test_the_pause_and_focus_loss_hold_a_doors_flare() -> void:
	_open(Fixture.instant())
	var hel: Door = _door(&"hel")
	hel.flare()
	_desk.toggle_pause()
	hel._process(Door.FLARE_SECONDS + 1.0)
	assert_true(hel.is_flaring(), "the pause holds the flare")
	_desk.pause_overlay().resume_button().pressed.emit()
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	hel._process(Door.FLARE_SECONDS + 1.0)
	assert_true(hel.is_flaring(), "so does focus loss")
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	hel._process(Door.FLARE_SECONDS + 1.0)
	assert_false(hel.is_flaring(), "resumed, the flare ends")


func test_the_pause_and_focus_loss_hold_the_stamps_rise() -> void:
	_open(Fixture.instant())
	var face: Control = _system.stamp_flow.stamp_prompt.get_node("Face") as Control
	_door(&"hel").press()
	assert_eq(face.position.y, StampPrompt.CONTACT_Y, "the stamp starts low")
	_desk.toggle_pause()
	await wait_seconds(StampPrompt.RISE_SECONDS + 0.1)
	assert_eq(face.position.y, StampPrompt.CONTACT_Y, "the pause holds the rise")
	_desk.pause_overlay().resume_button().pressed.emit()
	_door(&"valhalla").press()
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await wait_seconds(StampPrompt.RISE_SECONDS + 0.1)
	assert_eq(face.position.y, StampPrompt.CONTACT_Y, "so does focus loss")
	_desk._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await wait_seconds(StampPrompt.RISE_SECONDS + 0.1)
	assert_eq(face.position.y, StampPrompt.RAISED_Y, "resumed, the stamp finishes rising")


func test_reduce_motion_draws_a_new_thread_and_its_knot_whole_at_once() -> void:
	var options: Options = Fixture.instant()
	options.reduce_motion = true
	_open(options)
	_system.claim_panel.area("C1").press()
	_system.witness_panel.area("W1").press()
	var line: ThreadLine = _line(0)
	assert_false(line.is_drawing_in(), "D37: no draw-in")
	assert_true(line.knot().visible, "the knot shows at once")


func test_a_skipped_tale_stops_its_voice() -> void:
	_open(Fixture.normal())
	var blip: AudioStreamPlayer = _system.blip_player
	_system.claim_panel.teller()._process(0.2)
	assert_true(blip.playing, "the soul speaks as its lines are told (D41)")
	_click(_system.claim_panel.area("C1").get_global_rect().get_center())
	assert_false(_system.is_telling(), "the click finished the tale")
	assert_false(blip.playing, "and its voice stops with it")


func test_a_restart_never_resumes_the_old_runs_paused_voice() -> void:
	_open(Fixture.normal())
	var blip: AudioStreamPlayer = _system.blip_player
	_system.claim_panel.teller()._process(0.2)
	assert_true(blip.playing)
	_desk.toggle_pause()
	assert_true(blip.stream_paused, "the pause holds the voice")
	_desk.pause_overlay().restart_button().pressed.emit()
	_desk.pause_overlay().yes_button().pressed.emit()
	assert_false(blip.playing, "the restart stops it")
	assert_false(blip.stream_paused, "and the resume has nothing old to play")


func test_the_gates_restart_stops_a_player_its_pause_holds() -> void:
	var gate := PresentationGate.new()
	add_child_autofree(gate)
	var player := AudioStreamPlayer.new()
	player.stream = load("res://assets/audio/horn.wav") as AudioStream
	add_child_autofree(player)
	player.play()
	gate.watch_player(player)
	gate.set_paused(true)
	assert_true(player.stream_paused)
	gate.cancel_all()
	gate.set_paused(false)
	assert_false(player.playing, "a resume after the restart plays nothing of the old run")


func _stamp(realm: StringName) -> void:
	_door(realm).press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


func _line(thread_index: int) -> ThreadLine:
	for child: Node in _system.thread_layer.get_children():
		var line: ThreadLine = child as ThreadLine
		if line != null and not line.is_queued_for_deletion() and line.thread_index == thread_index:
			return line
	return null


## A move, a press and a release at `at`, pushed through the desk's viewport.
func _click(at: Vector2) -> void:
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
