extends GutTest
## The raven as the Huginn control (D40) and his presence (D17): hover texts, a click with nothing
## selected that does nothing, the bird and the post as the hit area, the head tilt on a seeded
## 3-5 s wait, the ruffle, and reduce motion (D37) and the pause holding him still.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const REST := preload("res://assets/art/portraits/huginn.png")
const TILT := preload("res://assets/art/portraits/huginn-tilt.png")
const RUFFLE := preload("res://assets/art/portraits/huginn-ruffle.png")
const SELECT := "Select a grey thread first."
const PRICE := "Extra answer: 2 feathers."

var _raven: Raven = null
var _asked: int = 0
var _hovers: Array[String] = []


func before_each() -> void:
	_raven = Raven.new()
	_raven.rest_texture = REST
	_raven.tilt_texture = TILT
	_raven.ruffle_texture = RUFFLE
	_raven.size = Vector2(48, 62)
	_raven.position = Vector2(268, 34)
	add_child_autofree(_raven)
	_raven.set_texts(SELECT, PRICE)
	_asked = 0
	_hovers = []
	_raven.asked.connect(func() -> void: _asked += 1)
	_raven.hover_started.connect(func(text: String, _area: Rect2) -> void: _hovers.append(text))


func test_the_hover_names_the_precondition_the_count_and_the_price() -> void:
	_raven.set_answers_left(2)
	assert_eq(_raven.hover_text(), SELECT, "nothing selected")
	_raven.set_selected_thread(true)
	assert_eq(_raven.hover_text(), "Ask Huginn: 2 answers left")
	_raven.set_answers_left(1)
	assert_eq(_raven.hover_text(), "Ask Huginn: 1 answer left")
	_raven.set_answers_left(0)
	_raven.set_extra_cost(2)
	assert_eq(_raven.hover_text(), PRICE, "today's answers spent: the price")
	_raven.set_texts(SELECT, "Extra answer: %d feathers")
	assert_eq(_raven.hover_text(), "Extra answer: 2 feathers", "a price with a number in it")


func test_the_hover_is_said_again_when_it_changes_under_the_mouse() -> void:
	_raven.set_answers_left(2)
	_raven.mouse_entered.emit()
	_raven.set_selected_thread(true)
	_raven.set_answers_left(2)
	_raven.set_answers_left(1)
	assert_eq(_hovers, [SELECT, "Ask Huginn: 2 answers left", "Ask Huginn: 1 answer left"])
	_raven.mouse_exited.emit()
	_raven.set_answers_left(0)
	assert_eq(_hovers.size(), 3, "not after the mouse left")


func test_a_click_with_nothing_selected_does_nothing() -> void:
	_raven.press()
	assert_eq(_asked, 0, "no signal, so nothing can be spent")
	_raven.set_selected_thread(true)
	_raven.press()
	assert_eq(_asked, 1)


func test_a_real_click_on_the_bird_or_the_post_asks_and_a_double_click_once() -> void:
	_raven.set_selected_thread(true)
	_raven._gui_input(_press(false))
	_raven._gui_input(_press(true))
	assert_eq(_asked, 1, "the second press of a double-click is not a second question")


func test_the_hit_area_is_the_bird_and_his_post() -> void:
	assert_true(_raven._has_point(Vector2(20, 10)), "his head")
	assert_true(_raven._has_point(Vector2(30, 30)), "his body")
	assert_true(_raven._has_point(Vector2(20, 55)), "the post (screen 288, 89)")
	assert_false(_raven._has_point(Vector2(2, 55)), "the wall beside the post")
	assert_false(_raven._has_point(Vector2(45, 50)), "the wall right of the post")
	var area: Rect2 = _raven.hit_rect()
	assert_eq(area.end.y, 96.0, "the post reaches the desk's edge")
	assert_true(area.has_point(Vector2(289, 80)), "on screen, the post is inside")


func test_he_tilts_his_head_after_three_to_five_seconds_then_rests() -> void:
	assert_eq(_raven.shown_texture(), REST)
	var wait: float = _raven._idle.time_left()
	assert_between(wait, Raven.TILT_EVERY.x, Raven.TILT_EVERY.y)
	_raven._process(wait + 0.01)
	assert_eq(_raven.idle_frame(), 1)
	assert_eq(_raven.shown_texture(), TILT, "the tilted frame")
	_raven._process(Raven.TILT_HOLD)
	assert_eq(_raven.shown_texture(), REST, "and back")


func test_he_ruffles_when_an_answer_is_given() -> void:
	_raven.ruffle()
	assert_true(_raven.is_ruffling())
	assert_eq(_raven.shown_texture(), RUFFLE)
	_raven._process(Raven.RUFFLE_SECONDS + 0.01)
	assert_false(_raven.is_ruffling())
	assert_eq(_raven.shown_texture(), REST)


func test_reduce_motion_keeps_him_still_on_his_rest_frame() -> void:
	_raven.reduce_motion = true
	_raven._process(10.0)
	_raven.ruffle()
	assert_eq(_raven.idle_frame(), 0)
	assert_false(_raven.is_ruffling())
	assert_eq(_raven.shown_texture(), REST)


func test_the_pause_holds_his_clock() -> void:
	var wait: float = _raven._idle.time_left()
	_raven.set_paused(true)
	_raven._process(wait + 1.0)
	assert_eq(_raven.idle_frame(), 0, "no tilt while paused")
	_raven.set_paused(false)
	_raven._process(wait + 0.01)
	assert_eq(_raven.idle_frame(), 1)


func test_his_frames_are_the_rest_sprite_with_few_pixels_changed_on_the_palette() -> void:
	var rest: Image = REST.get_image()
	var palette: Array[int] = []
	for color: Color in Palette.by_name().values():
		palette.append(color.to_rgba32())
	for frame: Texture2D in [TILT, RUFFLE]:
		var image: Image = frame.get_image()
		assert_eq(image.get_size(), rest.get_size(), frame.resource_path)
		var changed: int = 0
		var strays: int = 0
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var color: Color = image.get_pixel(x, y)
				var was: Color = rest.get_pixel(x, y)
				if color != was and (color.a > 0.0 or was.a > 0.0):
					changed += 1
				if color.a > 0.0 and not palette.has(Color(color, 1.0).to_rgba32()):
					strays += 1
		assert_between(changed, 4, 120, "%s moves a few pixels" % frame.resource_path)
		assert_eq(strays, 0, "%s keeps to the palette" % frame.resource_path)


func _press(double: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = double
	event.position = Vector2(20, 10)
	return event
