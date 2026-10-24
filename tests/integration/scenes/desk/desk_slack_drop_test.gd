extends GutTest
## A pin with no seam drops a slack thread (D36), and the drop never carries it onto a paper: it
## falls only through a gutter and frees itself the frame before any drawn pixel would enter the
## slab, a sheet, the Law or the note. Checked frame by frame against the thread's drawn rects.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## Long enough for the whole 0.4 s drop under a loaded test runner, at any frame rate: the drop
## runs on time, so the watch is bounded by time, never by a count of frames.
const MAX_SECONDS := 1.0
## No-seam pairs of the fixture's first soul, one per route kind: claim to witness in the body
## gutter, claim and witness to the Law in the Law gutter, front and back facts along the top.
const PAIRS: Array[Array] = [
	["C1", "W2"],
	["C1", "L4"],
	["W3", "L4"],
	["W1", "L2"],
	["B4", "C2"],
	["B2", "L1"],
]

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)


func test_clear_drop_stops_one_pixel_above_a_paper() -> void:
	var strand: Array[Vector2i] = [Vector2i(10, 10), Vector2i(11, 10), Vector2i(10, 12)]
	var below: Array[Rect2] = [Rect2(0, 18, 40, 5)]
	var aside: Array[Rect2] = [Rect2(30, 0, 10, 100)]
	var under: Array[Rect2] = [Rect2(0, 0, 40, 40)]
	var found: Array[int] = [
		ThreadBoard.clear_drop(strand, below, 20),
		ThreadBoard.clear_drop(strand, aside, 20),
		ThreadBoard.clear_drop(strand, under, 20),
	]
	assert_eq(found, [5, 20, 0] as Array[int], "above a paper, beside one, already on one")


func test_a_slack_thread_never_falls_onto_a_paper() -> void:
	_open()
	var crossings: Array[String] = []
	var fell: Array[String] = []
	for pair: Array in PAIRS:
		var line: ThreadLine = _drop(pair[0], pair[1])
		if line == null:
			crossings.append("%s-%s: no slack thread" % pair)
			continue
		var papers: Array[Rect2] = _system.threads_board.papers()
		var deepest: int = 0
		var crossing: String = ""
		var start_ms: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - start_ms < int(MAX_SECONDS * 1000.0):
			await wait_process_frames(1)
			if not is_instance_valid(line) or line.is_queued_for_deletion():
				break
			deepest = maxi(deepest, line.fallen())
			if crossing == "":
				crossing = _crossing(line, papers)
		if crossing != "":
			crossings.append("%s-%s %s" % [pair[0], pair[1], crossing])
		if is_instance_valid(line) and not line.is_queued_for_deletion():
			crossings.append("%s-%s: never freed" % pair)
		if deepest > 0:
			fell.append("%s-%s" % pair)
	assert_eq(crossings, [] as Array[String], "no drawn pixel of a falling strand on a paper")
	assert_has(fell, "C1-W2", "a strand in a clear gutter still falls (D36)")


func test_a_strand_already_on_the_slab_never_falls() -> void:
	_open()
	var line: ThreadLine = _drop("B4", "C2")
	assert_not_null(line, "a slack thread between a fact and a line")
	assert_eq(line.drop_limit, 0, "its lead lies on the slab: it may not fall at all")


## Where the falling `line`'s drawn pixels first lie on one of `papers`; "" when they never do (a
## strand at rest is drawn where its taut thread would be, so only a fallen one is checked).
func _crossing(line: ThreadLine, papers: Array[Rect2]) -> String:
	if line.fallen() == 0:
		return ""
	for rect: Rect2 in line.drawn_rects():
		var at := Rect2(rect.position + line.global_position, rect.size)
		for paper: Rect2 in papers:
			if at.intersects(paper):
				return "at %d px: %s on %s" % [line.fallen(), at, paper]
	return ""


func _open() -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(Fixture.instant())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_begin_day()
	_system.finish_tellings()


## Begins the day as a player does: the first click only ends the dark "DAY I" card (the gate
## consumes it), the dark's lift is run out, and the writ's tab takes a deliberate click.
func _begin_day() -> void:
	_click(_system.dawn_writ)
	_system.dawn_writ._process(DawnWrit.LIFT_SECONDS)
	var next: GuardedButton = _system.dawn_writ.next_button()
	next.arm_now()
	_click(next)


## Pins `a` then `b` (a pair with no seam) and returns the slack thread it drops.
func _drop(a: String, b: String) -> ThreadLine:
	_click(_area(a))
	_click(_area(b))
	for child: Node in _system.thread_layer.get_children():
		var line: ThreadLine = child as ThreadLine
		if line != null and line.is_slack() and not line.is_queued_for_deletion():
			return line
	return null


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null


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
