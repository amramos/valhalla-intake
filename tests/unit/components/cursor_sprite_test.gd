extends GutTest
## The in-scene cursor (D13, D48): a 7×9 pointer in ink and Parchment 2 on layer 100 that follows
## the mouse in whole pixels, carries a pin while an item is selected, becomes a 9×9 grab hand over
## the soul and while dragging, never takes the mouse, and hides the OS cursor only while the
## mouse is inside the window.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")


func test_it_sits_on_the_top_layer_and_never_takes_the_mouse() -> void:
	var cursor: CursorSprite = _cursor()
	assert_eq(cursor.layer, 100)
	assert_eq(cursor.sprite().mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_nothing_shows_before_the_mouse_moves() -> void:
	var cursor: CursorSprite = _cursor()
	assert_false(cursor.is_shown(), "a headless run has no mouse: the cursor waits for one")
	assert_false(cursor.hides_os_cursor())


func test_it_follows_the_mouse_in_whole_pixels() -> void:
	var cursor: CursorSprite = _cursor()
	_move(cursor, Vector2(10.7, 20.2))
	assert_true(cursor.is_shown())
	assert_eq(cursor.tip(), Vector2i(10, 20), "the hotspot covers the pixel under the mouse")
	assert_eq(cursor.sprite().position, Vector2(10, 20), "the pointer's tip is its hotspot")


func test_the_pointer_is_seven_by_nine_in_ink_parchment_and_shadow() -> void:
	var cursor: CursorSprite = _cursor()
	var drawn: Dictionary[Vector2i, Color] = cursor.pixels()
	var named: Dictionary[String, Color] = Palette.by_name()
	assert_eq(cursor.shape(), CursorSprite.Shape.POINTER)
	assert_eq(_bounds(drawn), Rect2i(0, 0, 7, 9))
	assert_eq(_hex(drawn[cursor.hotspot()]), _hex(named["Night 0"]), "the tip is ink")
	var colors: Array[Color] = []
	colors.assign(drawn.values())
	var expected: Array[String] = [
		_hex(named["Night 0"]), _hex(named["Parchment 2"]), _hex(named["Night 1"])
	]
	assert_eq(_distinct(colors), expected)


## A capture finding: on parchment the fill vanishes, so the pointer and the hand carry 2 px of ink
## past the right and bottom of their fill, lined inside by a Night 1 shadow.
func test_the_pointer_and_hand_read_on_parchment_and_on_the_band() -> void:
	var cursor: CursorSprite = _cursor()
	var named: Dictionary[String, Color] = Palette.by_name()
	var ink: String = _hex(named["Night 0"])
	var shade: String = _hex(named["Night 1"])
	var wrong: Array[String] = []
	var shadows: Array[int] = []
	for grab: bool in [false, true]:
		cursor.set_grab(grab)
		var drawn: Dictionary[Vector2i, Color] = cursor.pixels()
		var box: Rect2i = _bounds(drawn)
		var inner: Array[Vector2i] = []
		for at: Vector2i in drawn:
			if _hex(drawn[at]) != ink:
				inner.append(at)
		shadows.append(
			inner.filter(func(at: Vector2i) -> bool: return _hex(drawn[at]) == shade).size()
		)
		for at: Vector2i in inner:
			for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				if not _last_in_line(inner, at, step):
					continue
				for reach: int in [1, 2]:
					var past: Vector2i = at + step * reach
					if not box.has_point(past) or _hex(drawn.get(past, Color())) != ink:
						wrong.append("%s %s +%d" % ["hand" if grab else "pointer", at, reach])
	assert_eq(wrong, [] as Array[String], "2 px of ink past the fill's right and bottom")
	assert_true(shadows[0] > 0 and shadows[1] > 0, "both shapes carry the Night 1 shadow")


func test_it_carries_a_pin_while_an_item_is_selected() -> void:
	var cursor: CursorSprite = _cursor()
	cursor.set_carrying_pin(true)
	var drawn: Dictionary[Vector2i, Color] = cursor.pixels()
	var named: Dictionary[String, Color] = Palette.by_name()
	assert_eq(cursor.shape(), CursorSprite.Shape.PIN)
	assert_eq(cursor.hotspot(), Vector2i.ZERO, "the pin never moves the hotspot")
	assert_eq(_hex(drawn[Vector2i.ZERO]), _hex(named["Night 0"]), "and never covers the tip")
	var colors: Array[Color] = []
	colors.assign(drawn.values())
	assert_has(
		_distinct(colors), _hex(named["Ember 2"]), "the carried pin is the stuck pin's ember"
	)
	cursor.set_carrying_pin(false)
	assert_eq(cursor.shape(), CursorSprite.Shape.POINTER)


func test_it_is_a_grab_hand_over_the_soul_and_the_hand_wins() -> void:
	var cursor: CursorSprite = _cursor()
	cursor.set_carrying_pin(true)
	cursor.set_grab(true)
	_move(cursor, Vector2(50, 60))
	assert_eq(cursor.shape(), CursorSprite.Shape.GRAB)
	assert_eq(_bounds(cursor.pixels()), Rect2i(0, 0, 9, 9))
	assert_eq(cursor.sprite().position, Vector2(46, 56), "the palm is on the mouse's pixel")
	cursor.set_grab(false)
	assert_eq(cursor.shape(), CursorSprite.Shape.PIN)


func test_a_drag_shows_the_grab_hand_until_it_ends() -> void:
	var cursor: CursorSprite = _cursor()
	cursor.notification(Node.NOTIFICATION_DRAG_BEGIN)
	assert_eq(cursor.shape(), CursorSprite.Shape.GRAB)
	cursor.notification(Node.NOTIFICATION_DRAG_END)
	assert_eq(cursor.shape(), CursorSprite.Shape.POINTER)


func test_every_shape_is_drawn_in_palette_colours() -> void:
	var cursor: CursorSprite = _cursor()
	var colors: Array[Color] = []
	for step: int in range(3):
		cursor.set_carrying_pin(step == 1)
		cursor.set_grab(step == 2)
		colors.append_array(cursor.pixels().values())
	assert_eq(Palette.strays(colors), [] as Array[String])


func test_the_os_cursor_hides_inside_the_window_and_returns_when_the_mouse_leaves() -> void:
	var cursor: CursorSprite = _cursor()
	var leaves: Dictionary[int, int] = {
		Node.NOTIFICATION_WM_MOUSE_EXIT: Node.NOTIFICATION_WM_MOUSE_ENTER,
		Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT: Node.NOTIFICATION_WM_WINDOW_FOCUS_IN,
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT: Node.NOTIFICATION_APPLICATION_FOCUS_IN,
	}
	var seen: Array[bool] = []
	for what: int in leaves:
		_move(cursor, Vector2(5, 5))
		seen.append(cursor.hides_os_cursor())
		cursor.notification(what)
		seen.append(cursor.hides_os_cursor() or cursor.is_shown())
		cursor.notification(leaves[what])
	assert_eq(seen, [true, false, true, false, true, false] as Array[bool])


## The review's case: a mouse event after the mouse left (a drag's capture) never hides the OS
## cursor outside the window; the next one after the mouse comes back in does.
func test_an_event_after_the_mouse_left_keeps_the_os_cursor_until_it_comes_back() -> void:
	var cursor: CursorSprite = _cursor()
	_move(cursor, Vector2(5, 5))
	cursor.notification(Node.NOTIFICATION_WM_MOUSE_EXIT)
	_move(cursor, Vector2(8, 8))
	var after_exit: Array[bool] = [cursor.hides_os_cursor(), cursor.is_shown()]
	cursor.notification(Node.NOTIFICATION_WM_MOUSE_ENTER)
	_move(cursor, Vector2(8, 8))
	assert_eq(after_exit, [false, false] as Array[bool], "still outside: the OS cursor stays")
	assert_true(cursor.hides_os_cursor() and cursor.is_shown(), "back inside: ours again")


## The review's case: focus lost, then a mouse event over the unfocused window.
func test_an_event_after_focus_is_lost_keeps_the_os_cursor_until_focus_returns() -> void:
	var losses: Dictionary[int, int] = {
		Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT: Node.NOTIFICATION_WM_WINDOW_FOCUS_IN,
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT: Node.NOTIFICATION_APPLICATION_FOCUS_IN,
	}
	var seen: Array[bool] = []
	for lost: int in losses:
		var cursor: CursorSprite = _cursor()
		_move(cursor, Vector2(5, 5))
		cursor.notification(lost)
		_move(cursor, Vector2(8, 8))
		seen.append(cursor.hides_os_cursor() or cursor.is_shown())
		cursor.notification(losses[lost])
		_move(cursor, Vector2(8, 8))
		seen.append(cursor.hides_os_cursor() and cursor.is_shown())
	assert_eq(seen, [false, true, false, true] as Array[bool])


## An event outside the viewport (a drag's capture past the edge, a letterbox bar) gives the OS
## cursor back instead of claiming it.
func test_an_event_outside_the_viewport_gives_the_os_cursor_back() -> void:
	var cursor: CursorSprite = _cursor()
	var seen: Array[bool] = []
	var size: Vector2 = cursor.sprite().get_viewport_rect().size
	for at: Vector2 in [Vector2(-1, 5), Vector2(5, -0.5), Vector2(size.x, 5), Vector2(5, size.y)]:
		_move(cursor, Vector2(5, 5))
		_move(cursor, at)
		seen.append(cursor.hides_os_cursor() or cursor.is_shown())
	assert_eq(seen, [false, false, false, false] as Array[bool])


## The review's case: a change of shape with the mouse still keeps the hotspot on its pixel.
func test_a_change_of_shape_keeps_the_hotspot_on_the_mouse_without_a_mouse_event() -> void:
	var cursor: CursorSprite = _cursor()
	_move(cursor, Vector2(50.6, 60.2))
	var drawn: Array[Vector2i] = []
	var steps: Array[Callable] = [
		cursor.set_grab.bind(true),
		cursor.set_grab.bind(false),
		cursor.notification.bind(Node.NOTIFICATION_DRAG_BEGIN),
		cursor.set_carrying_pin.bind(true),
		cursor.notification.bind(Node.NOTIFICATION_DRAG_END),
		cursor.set_carrying_pin.bind(false),
	]
	for step: Callable in steps:
		step.call()
		drawn.append(Vector2i(cursor.sprite().position) + cursor.hotspot())
	var expected: Array[Vector2i] = []
	expected.resize(steps.size())
	expected.fill(Vector2i(50, 60))
	assert_eq(drawn, expected, "the drawn hotspot never leaves the mouse's pixel")


func test_leaving_the_tree_gives_the_os_cursor_back() -> void:
	var cursor: CursorSprite = _cursor()
	_move(cursor, Vector2(5, 5))
	remove_child(cursor)
	assert_false(cursor.hides_os_cursor())
	cursor.free()


func _cursor() -> CursorSprite:
	var cursor := CursorSprite.new()
	add_child_autofree(cursor)
	return cursor


func _move(cursor: CursorSprite, at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	cursor._input(motion)


func _bounds(drawn: Dictionary[Vector2i, Color]) -> Rect2i:
	var box := Rect2i()
	var first: bool = true
	for at: Vector2i in drawn:
		var pixel := Rect2i(at, Vector2i.ONE)
		box = pixel if first else box.merge(pixel)
		first = false
	return box


func _distinct(colors: Array[Color]) -> Array[String]:
	var out: Array[String] = []
	for color: Color in colors:
		if not out.has(_hex(color)):
			out.append(_hex(color))
	return out


## Whether `at` is the last fill or shadow pixel of its row (`step` right) or column (down).
func _last_in_line(inner: Array[Vector2i], at: Vector2i, step: Vector2i) -> bool:
	for other: Vector2i in inner:
		var along: int = (other - at).x if step == Vector2i.RIGHT else (other - at).y
		var across: int = (other - at).y if step == Vector2i.RIGHT else (other - at).x
		if across == 0 and along > 0:
			return false
	return true


func _hex(color: Color) -> String:
	return Color8(color.r8, color.g8, color.b8).to_html(false)
