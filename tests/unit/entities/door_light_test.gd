extends GutTest
## A door's light (D19, D39): the glow pulses at 2.5 s between the lit sprite and its dim frame,
## only while lit, never under reduce motion (D37); each later day shows its own sprites.

const DOORS := "res://assets/art/doors/"

var _light: DoorLight = null


func before_each() -> void:
	_light = DoorLight.new()


func test_the_glow_pulses_at_two_and_a_half_seconds() -> void:
	assert_false(_light.is_dim(), "it starts lit")
	_light.advance(DoorLight.PULSE_SECONDS / 2.0 - 0.01, true)
	assert_false(_light.is_dim())
	assert_true(_light.advance(0.02, true))
	assert_true(_light.is_dim(), "dim for the second half")
	_light.advance(DoorLight.PULSE_SECONDS / 2.0, true)
	assert_false(_light.is_dim(), "lit again after one period")
	assert_gte(DoorLight.PULSE_SECONDS, 2.0, "D19: slow, 2 s or more")


func test_a_locked_door_never_pulses() -> void:
	_light.advance(DoorLight.PULSE_SECONDS, false)
	assert_false(_light.is_dim())


func test_reduce_motion_holds_the_lit_sprite() -> void:
	_light.reduce_motion = true
	_light.advance(DoorLight.PULSE_SECONDS * 0.75, true)
	assert_false(_light.is_dim())


func test_each_later_day_shows_its_own_sprite_and_the_last_holds() -> void:
	var base: Texture2D = load(DOORS + "hel-lit.png")
	var later: Array[Texture2D] = [
		load(DOORS + "day2/hel-lit.png"), load(DOORS + "day3/hel-lit.png")
	]
	assert_eq(_light.for_day(base, later), base, "day 1")
	_light.set_day(2)
	assert_eq(_light.for_day(base, later), later[0])
	_light.set_day(3)
	assert_eq(_light.for_day(base, later), later[1])
	_light.set_day(8)
	assert_eq(_light.for_day(base, later), later[1], "past the last frame, the darkest")
	assert_eq(_light.for_day(base, [] as Array[Texture2D]), base, "no later sprites: the base")
	_light.set_day(0)
	assert_eq(_light.day(), 1)


## The dim frame changes only the glow's core, into the band around it: a recolour, never a tint.
func test_each_dim_frame_only_turns_core_pixels_into_the_band_around_them() -> void:
	var cores: Dictionary[String, Array] = {
		"valhalla": ["e08a4a", "a6623b"],
		"hel": ["bbc983", "8b9361"],
		"folkvangr": ["f6e0b7", "d3c9ab"],
	}
	for realm: String in cores:
		var lit: Image = load(DOORS + realm + "-lit.png").get_image()
		var dim: Image = load(DOORS + realm + "-lit-dim.png").get_image()
		var wrong: Array[String] = []
		var changed: int = 0
		for y: int in range(lit.get_height()):
			for x: int in range(lit.get_width()):
				var before: String = lit.get_pixel(x, y).to_html(false)
				var after: String = dim.get_pixel(x, y).to_html(false)
				if before == after:
					continue
				changed += 1
				if before != cores[realm][0] or after != cores[realm][1]:
					wrong.append("%d,%d %s>%s" % [x, y, before, after])
		assert_eq(wrong, [] as Array[String], realm)
		assert_gt(changed, 40, "%s's core visibly shrinks" % realm)
