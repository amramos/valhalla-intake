extends GutTest
## ClickableSprite's idle (D17): the mentor's blink shows its frame for a moment every 4-7 s;
## reduce motion (D37) keeps the rest frame and the gate's pause holds the clock.

const MENTOR := preload("res://assets/art/portraits/mentor.png")
const BLINK := preload("res://assets/art/portraits/mentor-blink.png")

var _sprite: ClickableSprite = null


func before_each() -> void:
	_sprite = ClickableSprite.new()
	_sprite.size = Vector2(32, 32)
	add_child_autofree(_sprite)
	_sprite.set_idle_frames([MENTOR, BLINK], 5.5, 1.5, 0.15)


func test_she_blinks_every_four_to_seven_seconds_for_a_moment() -> void:
	assert_eq(_sprite.texture, MENTOR, "the first frame rests")
	assert_eq(_sprite.shown_texture(), MENTOR)
	var waits: Array[float] = []
	for _blink: int in range(6):
		var wait: float = _sprite._idle.time_left()
		waits.append(wait)
		_sprite._process(wait + 0.001)
		assert_eq(_sprite.shown_texture(), BLINK, "eyes closed")
		_sprite._process(0.15)
		assert_eq(_sprite.shown_texture(), MENTOR, "and open again")
	var outside: Array[float] = waits.filter(
		func(wait: float) -> bool: return wait < 4.0 or wait > 7.0
	)
	assert_eq(outside, [] as Array[float], "every wait is 4 to 7 s")


func test_reduce_motion_keeps_her_eyes_open() -> void:
	_sprite.reduce_motion = true
	_sprite._process(30.0)
	assert_eq(_sprite.idle_frame(), 0)
	assert_eq(_sprite.shown_texture(), MENTOR)
	_sprite.reduce_motion = false
	_sprite._process(_sprite._idle.time_left() + 0.001)
	assert_eq(_sprite.idle_frame(), 1, "the idle comes back with motion")


func test_the_pause_holds_the_blink() -> void:
	_sprite.set_paused(true)
	_sprite._process(30.0)
	assert_eq(_sprite.idle_frame(), 0)


func test_a_sprite_without_idle_frames_never_changes() -> void:
	var plain := ClickableSprite.new()
	plain.texture = MENTOR
	add_child_autofree(plain)
	plain._process(30.0)
	assert_eq(plain.shown_texture(), MENTOR)


func test_the_blink_closes_both_eyes_and_nothing_else() -> void:
	var rest: Image = MENTOR.get_image()
	var blink: Image = BLINK.get_image()
	var changed: Array[Vector2i] = []
	for y: int in range(rest.get_height()):
		for x: int in range(rest.get_width()):
			if rest.get_pixel(x, y) != blink.get_pixel(x, y):
				changed.append(Vector2i(x, y))
	assert_eq(changed.size(), 6, "two 3-pixel lids")
	for at: Vector2i in changed:
		assert_eq(at.y, 13, "on the eyes' row")
