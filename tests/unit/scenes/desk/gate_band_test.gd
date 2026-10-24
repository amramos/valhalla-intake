extends GutTest
## GateBand (D19, D39): the day's band by day (clamped to the frames there are), and the corner
## fog's three frames at 0.7 s each; reduce motion (D37) and the pause hold it on the band as
## painted.

const DAY1 := preload("res://assets/art/scenes/gate-desk.png")
const DAY2 := preload("res://assets/art/scenes/gate-desk-day2.png")
const DAY3 := preload("res://assets/art/scenes/gate-desk-day3.png")
const FOG1 := preload("res://assets/art/fog/fog-day1.png")
const FOG2 := preload("res://assets/art/fog/fog-day2.png")
const FOG3 := preload("res://assets/art/fog/fog-day3.png")

var _band: GateBand = null


func before_each() -> void:
	_band = GateBand.new()
	_band.size = Vector2(480, GateBand.BAND_HEIGHT)
	_band.day_textures = [DAY1, DAY2, DAY3]
	_band.fog_sheets = [FOG1, FOG2, FOG3]
	add_child_autofree(_band)


func test_each_day_shows_its_band_and_its_fog() -> void:
	assert_eq(_band.day(), 1)
	assert_eq(_band.band_texture(), DAY1, "day 1 is the backdrop as painted")
	assert_eq(_band.fog_sheet(), FOG1)
	_band.set_day(2)
	assert_eq(_band.band_texture(), DAY2)
	assert_eq(_band.fog_sheet(), FOG2, "the fog matches its day")
	_band.set_day(3)
	assert_eq(_band.band_texture(), DAY3)
	_band.set_day(8)
	assert_eq(_band.band_texture(), DAY3, "past the last frame, the darkest")
	_band.set_day(0)
	assert_eq(_band.band_texture(), DAY1)


func test_the_fog_drifts_through_three_frames_of_seven_tenths_of_a_second() -> void:
	var frames: Array[int] = []
	for _step: int in range(7):
		frames.append(_band.fog_frame())
		_band._process(GateBand.FOG_FRAME_SECONDS)
	assert_eq(frames, [0, 1, 2, 0, 1, 2, 0] as Array[int])


func test_reduce_motion_and_the_pause_hold_the_band_as_painted() -> void:
	_band._process(GateBand.FOG_FRAME_SECONDS)
	assert_eq(_band.fog_frame(), 1)
	_band.reduce_motion = true
	assert_eq(_band.fog_frame(), 0, "reduce motion: the painted band at once")
	_band._process(GateBand.FOG_FRAME_SECONDS)
	assert_eq(_band.fog_frame(), 0)
	_band.reduce_motion = false
	_band.set_paused(true)
	_band._process(GateBand.FOG_FRAME_SECONDS * 5)
	assert_eq(_band.fog_frame(), 0, "the pause holds the drift")


func test_it_takes_no_mouse() -> void:
	assert_eq(_band.mouse_filter, Control.MOUSE_FILTER_IGNORE)
