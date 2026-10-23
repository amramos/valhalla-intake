extends GutTest
## A timed day-3 desk (desk_fixture.gd): the held soul after a citation (D48), the horn, grey
## knots that never cover a hit area, threads that never cross any panel of text, and a restart
## that clears the desk (D31).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(Fixture.instant())
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_while_a_cited_soul_waits_only_next_soul_acts() -> void:
	_pin("C1", "W1")
	_pin("B1", "W2")
	_stamp(&"valhalla")
	assert_true(_desk.commands().awaiting_next(), "the citation holds the soul (D48)")
	assert_eq(_soul(), "Asgaut")

	_door(&"hel").press()
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "a door press is refused")

	var before: float = _desk.commands().time_left()
	_system._process(5.0)
	assert_eq(_desk.commands().time_left(), before, "the clock does not run while the soul waits")

	_knot(0).press()
	assert_eq(_system.huginn_thread, -1, "a knot click does nothing")
	var caption: String = _system.caption_strip.shown_text()
	_system.ask_huginn.pressed.emit()
	assert_eq(_desk.commands().huginn_left(), 2, "Ask Huginn spends nothing")
	assert_eq(_system.caption_strip.shown_text(), caption, "and says nothing")

	_system.claim_panel.area("C3").press()
	assert_false(_system.claim_panel.area("C3").selected, "no new pin starts")

	# Send it on (D15) is refused inside the slam window (D27).
	await wait_seconds(StampFlow.SLAM_SECONDS + 0.1)
	_system.stamp_flow.stamp_prompt.send_on()
	assert_eq(_soul(), "Second", "Next soul seats the next one")
	_system._process(5.0)
	assert_lt(_desk.commands().time_left(), before, "and the clock runs again")


func test_a_held_soul_shows_its_cited_pair_lit_not_a_half_made_pin() -> void:
	_pin("B1", "W2")
	_system.claim_panel.area("C3").press()
	assert_true(_system.claim_panel.area("C3").selected)
	_stamp(&"valhalla")
	var stamp: StampResult = _desk.commands().pending_stamp()
	assert_true(stamp.citation)
	assert_false(_system.claim_panel.area("C3").selected, "the half-made pin is gone")
	assert_true(_area(stamp.citation_a).lit, "%s is lit" % stamp.citation_a)
	assert_true(_area(stamp.citation_b).lit, "%s is lit" % stamp.citation_b)
	assert_false(_area(stamp.citation_a).selected)


func test_the_horn_caption_outlives_the_refresh_it_triggers() -> void:
	_system._process(Fixture.CLOCK_SECONDS + 1.0)
	assert_ne(_desk.commands().phase(), RunState.DESK, "the clock ran out")
	assert_string_contains(_system.caption_strip.shown_text(), "horn")


func test_a_grey_knot_never_covers_another_hit_area() -> void:
	_pin("C2", "L5")
	_pin("C1", "W1")
	assert_eq(_threads().size(), 2)
	var knot: Rect2 = _knot(1).get_global_rect()
	assert_eq(knot.size, Vector2(8, 8), "the knot is 8 px (D8)")
	for area: Rect2 in _hit_rects():
		assert_false(knot.intersects(area), "the knot %s covers the hit area %s" % [knot, area])


func test_threads_never_cross_any_panel_of_text() -> void:
	_pin("C1", "W1")
	_pin("B1", "W2")
	_pin("B3", "L3")
	_pin("C2", "L5")
	assert_eq(_threads().size(), 4)
	var panels: Array[Rect2] = []
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		panels.append(panel.get_global_rect())
	for line: ThreadLine in _threads():
		for pixel: Vector2i in line.pixels():
			for panel: Rect2 in panels:
				assert_false(
					panel.has_point(Vector2(pixel) + Vector2(0.5, 0.5)),
					"thread %d pixel %s lies inside a text panel" % [line.thread_index, pixel]
				)


## The review's case: the whole 3 px stroke of threads in both lanes of every gutter stays out of
## the papers, not only the route's centre line. Pin heads and knots are checked against the hit
## areas instead: a pin sits on a paper's edge by design (D12).
func test_every_drawn_stroke_stays_in_the_gutters_in_both_lanes() -> void:
	_pin("C1", "W1")
	_pin("B1", "W2")
	_pin("B3", "L3")
	_pin("C2", "L5")
	await wait_process_frames(2)
	var lines: Array[ThreadLine] = _threads()
	var lanes: Dictionary[int, bool] = {}
	var panels: Array[Rect2] = []
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		panels.append(panel.get_global_rect())
	var crossings: Array[String] = []
	var strokes: int = 0
	for line: ThreadLine in lines:
		lanes[line.lane] = true
		var marks: Array[Rect2] = line.pin_head_rects()
		if line.has_knot():
			marks.append(line.knot().get_global_rect())
		for mark: Rect2 in marks:
			for area: Rect2 in _hit_rects():
				if mark.intersects(area):
					crossings.append("thread %d mark %s on %s" % [line.thread_index, mark, area])
		for local: Rect2 in line.drawn_rects():
			var rect := Rect2(local.position + line.global_position, local.size)
			if _inside_any(rect, marks):
				continue
			strokes += 1
			for panel: Rect2 in panels:
				if rect.intersects(panel):
					crossings.append("thread %d stroke %s in %s" % [line.thread_index, rect, panel])
	assert_eq(lines.size(), 4)
	assert_eq(lanes.size(), 2, "both lanes are drawn")
	assert_gt(strokes, 100, "the strokes were drawn and read")
	assert_eq(crossings, [] as Array[String])


## The review's case: a restart from a soul at the desk (D31) leaves nothing of that soul under
## the dawn card, although no soul is at the desk before or after the run restarts. A click drops
## the lit pair, so the half-made pin is checked on a second restart.
func test_a_restart_from_a_soul_at_the_desk_clears_the_whole_desk() -> void:
	_pin("C1", "W1")
	_knot(0).press()
	_pin("C1", "W1")
	_door(&"valhalla").press()
	assert_eq(_system.huginn_thread, 0, "a grey knot is selected for Huginn")
	assert_eq(_system._lit, ["C1", "W1"] as Array[String], "the threaded pair is lit")
	assert_ne(_system.caption_strip.shown_text(), "", "a caption shows")
	assert_true(_system.stamp_flow.stamp_prompt.is_asking(), "a stamp preview is open")
	_restart()
	_assert_empty_dawn()
	assert_eq(_system._lit, [] as Array[String], "nothing lit")
	assert_eq(_system.huginn_thread, -1, "no thread for Huginn")

	_system.phase_card.next_button().pressed.emit()
	_area("C3").press()
	assert_true(_system.claim_panel.area("C3").selected, "a half-made pin")
	_restart()
	_assert_empty_dawn()
	assert_false(_system.selection.has_selection(), "no half-made pin")


func _restart() -> void:
	_desk.toggle_pause()
	_desk.pause_overlay().restart_button().pressed.emit()
	_desk.pause_overlay().yes_button().pressed.emit()


func _assert_empty_dawn() -> void:
	assert_eq(_desk.commands().phase(), RunState.DAWN)
	assert_true(_system.phase_card.visible, "the dawn card shows")
	assert_eq(_soul(), "", "no soul at the desk")
	assert_false(_system.body_chart.has_item("B1"), "no body facts")
	assert_false(_system.claim_panel.has_item("C1"), "no claim")
	assert_false(_system.witness_panel.visible, "no witness")
	assert_eq(_system.caption_strip.shown_text(), "", "no caption")
	assert_false(_system.stamp_flow.stamp_prompt.is_asking(), "no stamp preview")
	for door: Door in _system.doors:
		assert_false(door.selected, "the %s door is not selected" % door.realm)
	assert_eq(_threads().size(), 0, "no threads")


func _soul() -> String:
	return _system.soul.soul_name()


func _pin(a: String, b: String) -> void:
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
	_door(realm).press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _threads() -> Array[ThreadLine]:
	var lines: Array[ThreadLine] = []
	for child: Node in _system.thread_layer.get_children():
		if child is ThreadLine and not child.is_queued_for_deletion():
			lines.append(child as ThreadLine)
	return lines


func _knot(thread_index: int) -> PinSelectable:
	for line: ThreadLine in _threads():
		if line.thread_index == thread_index and line.has_knot():
			return line.knot()
	return null


func _inside_any(rect: Rect2, boxes: Array[Rect2]) -> bool:
	for box: Rect2 in boxes:
		if box.encloses(rect):
			return true
	return false


func _hit_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = _system.body_chart.hit_rects()
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		rects.append_array(panel.hit_rects())
	return rects
