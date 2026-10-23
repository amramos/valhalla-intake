extends GutTest
## The in-scene cursor on the desk (D13, D48). Its hotspot is checked at 1× and 3× against an 8×8
## hit area (the smallest a fact may have): real presses pushed through a viewport stretched like
## the window, swept across the area's edges, land on the area exactly when the pixel the tip
## covers is inside it, so the tip never points at one thing while the click goes to another. On
## the desk it carries a pin while an item is selected and grabs over the waiting soul.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const TITLE_SCENE := preload("res://scenes/title/title.tscn")
const FIXTURE := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const SCREEN := Vector2i(480, 270)
## The 8×8 target, in screen pixels.
const TARGET := Rect2i(100, 100, 8, 8)
## How far past each edge of the target the sweep reaches, in screen pixels.
const MARGIN := 3


func test_the_hotspot_lands_on_an_eight_pixel_target_at_one_x() -> void:
	_sweep(1)


func test_the_hotspot_lands_on_an_eight_pixel_target_at_three_x() -> void:
	_sweep(3)


func test_a_change_of_shape_keeps_the_hotspot_still_at_one_x() -> void:
	_hold_still(1)


func test_a_change_of_shape_keeps_the_hotspot_still_at_three_x() -> void:
	_hold_still(3)


func test_the_desk_keeps_its_cursor_on_top() -> void:
	var desk: Desk = _desk()
	assert_not_null(desk.cursor())
	assert_eq(desk.cursor().layer, CursorSprite.LAYER)
	assert_eq(desk.cursor().shape(), CursorSprite.Shape.POINTER)


func test_the_cursor_carries_a_pin_while_an_item_is_selected() -> void:
	var desk: Desk = _desk()
	var system: DeskSystem = desk.system()
	_begin(system)
	var shapes: Array[CursorSprite.Shape] = []
	system.body_chart.area("B1").press()
	shapes.append(desk.cursor().shape())
	system.body_chart.area("B1").press()
	shapes.append(desk.cursor().shape())
	system.body_chart.area("B1").press()
	system.witness_panel.area("W2").press()
	shapes.append(desk.cursor().shape())
	system.body_chart.area("B3").press()
	system.cancel_selection()
	shapes.append(desk.cursor().shape())
	var expected: Array[CursorSprite.Shape] = [
		CursorSprite.Shape.PIN,
		CursorSprite.Shape.POINTER,
		CursorSprite.Shape.POINTER,
		CursorSprite.Shape.POINTER,
	]
	assert_eq(shapes, expected, "selected, deselected, pair made, cancelled")


func test_the_cursor_grabs_over_the_waiting_soul_only_while_it_can_be_picked_up() -> void:
	var viewport: SubViewport = _viewport(1)
	var desk: Desk = _desk(viewport)
	var system: DeskSystem = desk.system()
	_begin(system)
	var over_soul: Vector2 = system.soul.figure().get_global_rect().get_center()
	var away := Vector2(240, 200)
	var shapes: Array[CursorSprite.Shape] = []
	_move(viewport, over_soul)
	shapes.append(desk.cursor().shape())
	_move(viewport, away)
	shapes.append(desk.cursor().shape())
	system.soul.set_draggable(false)
	_move(viewport, over_soul)
	shapes.append(desk.cursor().shape())
	var expected: Array[CursorSprite.Shape] = [
		CursorSprite.Shape.GRAB, CursorSprite.Shape.POINTER, CursorSprite.Shape.POINTER
	]
	assert_eq(shapes, expected, "the hand over the soul, the pointer off it and under a hold")


func test_the_title_has_the_same_cursor() -> void:
	var title: TitleScreen = TITLE_SCENE.instantiate() as TitleScreen
	title.change_scene = false
	add_child_autofree(title)
	var found: Array[Node] = title.find_children("*", "CursorSprite", false, false)
	assert_eq(found.size(), 1)


## Presses swept across the target's rows and columns, MARGIN pixels past each edge, at every
## window pixel (so every sub-pixel position at 3×): each lands on the target exactly when the
## pixel the tip covers is inside it, and the tip's pixel covers the press.
func _sweep(scale: int) -> void:
	var viewport: SubViewport = _viewport(scale)
	var host := Control.new()
	host.size = Vector2(SCREEN)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(host)
	var target := PinSelectable.new()
	target.item_id = "T"
	target.position = Vector2(TARGET.position)
	target.size = Vector2(TARGET.size)
	host.add_child(target)
	var cursor := CursorSprite.new()
	viewport.add_child(cursor)
	var hits: Array[int] = [0]
	target.clicked.connect(func(_id: String) -> void: hits[0] += 1)
	var wrong: Array[String] = []
	var reach: Rect2i = TARGET.grow(MARGIN)
	var middle: Vector2i = TARGET.get_center()
	var half: int = floori(scale / 2.0)
	var presses: Array[Vector2i] = []
	for x: int in range(reach.position.x * scale, reach.end.x * scale):
		presses.append(Vector2i(x, middle.y * scale + half))
	for y: int in range(reach.position.y * scale, reach.end.y * scale):
		presses.append(Vector2i(middle.x * scale + half, y))
	for window: Vector2i in presses:
		var before: int = hits[0]
		_press(viewport, Vector2(window) + Vector2(0.5, 0.5))
		var tip: Vector2i = cursor.tip()
		var covered := Rect2i(tip * scale, Vector2i(scale, scale))
		var on_target: bool = TARGET.has_point(tip)
		if not covered.has_point(window) or (hits[0] > before) != on_target:
			wrong.append("%s: tip %s, hit %s" % [window, tip, hits[0] > before])
	assert_eq(wrong, [] as Array[String], "at %dx" % scale)
	assert_eq(hits[0], 2 * TARGET.size.x * scale, "every press over the target reached it")


## The review's case: the mouse rests on the target's pixel (2, 3) and the shape changes (the hand
## over the soul, a drag, a pin) with no mouse event; after each change the drawn hotspot is still
## the mouse's pixel and covers the mouse, and a press there (no move) reaches the target.
func _hold_still(scale: int) -> void:
	var viewport: SubViewport = _viewport(scale)
	var target := PinSelectable.new()
	target.item_id = "T"
	target.position = Vector2(TARGET.position)
	target.size = Vector2(TARGET.size)
	viewport.add_child(target)
	var cursor := CursorSprite.new()
	viewport.add_child(cursor)
	var hits: Array[int] = [0]
	target.clicked.connect(func(_id: String) -> void: hits[0] += 1)
	var window: Vector2 = Vector2((TARGET.position + Vector2i(2, 3)) * scale) + Vector2(0.5, 0.5)
	window += Vector2(scale - 1, scale - 1)
	_move(viewport, window)
	var steps: Array[Callable] = [
		cursor.set_grab.bind(true),
		cursor.notification.bind(Node.NOTIFICATION_DRAG_BEGIN),
		cursor.set_grab.bind(false),
		cursor.notification.bind(Node.NOTIFICATION_DRAG_END),
		cursor.set_carrying_pin.bind(true),
		cursor.set_carrying_pin.bind(false),
	]
	var wrong: Array[String] = []
	for index: int in range(steps.size()):
		steps[index].call()
		var hot: Vector2i = Vector2i(cursor.sprite().position) + cursor.hotspot()
		var covered := Rect2i(hot * scale, Vector2i(scale, scale))
		if hot != TARGET.position + Vector2i(2, 3) or not covered.has_point(Vector2i(window)):
			wrong.append("step %d: drawn hotspot %s" % [index, hot])
		_click_only(viewport, window)
	assert_eq(wrong, [] as Array[String], "at %dx" % scale)
	assert_eq(hits[0], steps.size(), "every press without a move reached the target")


func _viewport(scale: int) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = SCREEN * scale
	viewport.size_2d_override = SCREEN
	viewport.size_2d_override_stretch = true
	add_child_autofree(viewport)
	return viewport


func _desk(viewport: SubViewport = null) -> Desk:
	if viewport == null:
		viewport = _viewport(1)
	var desk: Desk = DESK_SCENE.instantiate() as Desk
	desk.use_commands(FIXTURE.commands())
	desk.use_options(FIXTURE.instant())
	viewport.add_child(desk)
	return desk


func _begin(system: DeskSystem) -> void:
	system.phase_card.next_button().pressed.emit()
	system.finish_tellings()


## A move to `at` (window pixels of the viewport), pushed as the window would.
func _move(viewport: SubViewport, at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	viewport.push_input(motion)


## A move, a press and a release at `at` (window pixels).
func _press(viewport: SubViewport, at: Vector2) -> void:
	_move(viewport, at)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		viewport.push_input(event)


## A press and a release at `at` (window pixels), with no move first.
func _click_only(viewport: SubViewport, at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		viewport.push_input(event)
