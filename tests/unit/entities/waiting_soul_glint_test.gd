extends GutTest
## A returned soul's frost glints (D17): three rime pixels of the frost plate flash Parchment 2 for
## a moment every 2 s. Only the frost plate; never while the soul speaks; reduce motion (D37) and
## the pause hold it.

const PLAIN := preload("res://assets/art/ui/nameplate-plain.png")
const FROST := preload("res://assets/art/ui/nameplate-frost.png")
const HEL := preload("res://assets/art/ui/nameplate-hel.png")

var _soul: WaitingSoul = null


func before_each() -> void:
	_soul = WaitingSoul.new()
	_soul.size = Vector2(60, 96)
	_soul.plate_plain = PLAIN
	_soul.plate_frost = FROST
	_soul.plate_hel = HEL
	add_child_autofree(_soul)


func test_the_frost_glints_every_two_seconds() -> void:
	_soul.show_soul(_encounter(true))
	assert_false(_soul.is_glinting())
	_soul._process(WaitingSoul.GLINT_EVERY - WaitingSoul.GLINT_HOLD + 0.01)
	assert_true(_soul.is_glinting(), "the glint")
	_soul._process(WaitingSoul.GLINT_HOLD)
	assert_false(_soul.is_glinting(), "gone again")
	_soul._process(WaitingSoul.GLINT_EVERY - WaitingSoul.GLINT_HOLD)
	assert_true(_soul.is_glinting(), "2 s after the last")


func test_a_plain_plate_never_glints() -> void:
	_soul.show_soul(_encounter(false))
	for _step: int in range(10):
		_soul._process(0.5)
		assert_false(_soul.is_glinting())


func test_no_glint_while_speaking_or_under_reduce_motion_or_paused() -> void:
	_soul.show_soul(_encounter(true))
	_soul.set_speaking(true)
	_soul._process(WaitingSoul.GLINT_EVERY - WaitingSoul.GLINT_HOLD + 0.01)
	assert_false(_soul.is_glinting(), "the lit plate shows no glint")
	_soul.set_speaking(false)
	_soul.reduce_motion = true
	assert_false(_soul.is_glinting(), "reduce motion")
	_soul.reduce_motion = false
	_soul.show_soul(_encounter(true))
	_soul.set_paused(true)
	_soul._process(5.0)
	assert_false(_soul.is_glinting(), "the pause holds it")


## The glint sits on the plate's rime (Fog 2 pixels), so it never touches evidence.
func test_the_glint_pixels_are_rime_on_the_frost_plate() -> void:
	var image: Image = FROST.get_image()
	for at: Vector2i in WaitingSoul.GLINT_PIXELS:
		assert_eq(image.get_pixelv(at).to_html(false), "a3aeb0", "Fog 2 at %s" % at)


func _encounter(returned: bool) -> Encounter:
	var encounter := Encounter.new()
	encounter.id = &"glint_test"
	encounter.soul_name = "Hakon"
	encounter.returned = returned
	return encounter
