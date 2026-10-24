extends GutTest
## The soul speaks while its tale is told (D4, D17): the desk's telling lights the soul's plate
## from the first line to the last, and each voice blip dips the figure 1 px; once the tale is
## told (by pace or a finishing click) the plate goes dark and the soul is still. Reduce motion
## keeps the lit plate and drops the bob (D37); at "instant" there is no telling to speak.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _desk: Desk = null
var _system: DeskSystem = null
## The figure's height at each blip, read just after the desk handled it.
var _heights: Array[float] = []


func test_the_soul_speaks_while_its_tale_is_told() -> void:
	_open(Fixture.normal())
	assert_true(_system.is_telling(), "the tale is being told")
	assert_true(_system.soul.is_speaking(), "and the soul speaks: its plate lights")
	await wait_seconds(0.6)
	assert_gt(_heights.size(), 0, "the voice blips")
	for height: float in _heights:
		assert_eq(height, WaitingSoul.FIGURE_AT.y + WaitingSoul.BOB_PX, "1 px down on each blip")
	_system.finish_tellings()
	assert_false(_system.soul.is_speaking(), "the tale told, the plate goes dark")
	assert_eq(_system.soul.figure().position.y, WaitingSoul.FIGURE_AT.y, "and the soul is still")


func test_reduce_motion_lights_the_plate_without_a_bob() -> void:
	var options: Options = Fixture.normal()
	options.reduce_motion = true
	_open(options)
	assert_true(_system.soul.is_speaking(), "the lit plate stays (D37)")
	await wait_seconds(0.6)
	assert_gt(_heights.size(), 0)
	for height: float in _heights:
		assert_eq(height, WaitingSoul.FIGURE_AT.y, "no bob")


func test_an_instant_tale_is_never_spoken() -> void:
	_open(Fixture.instant())
	assert_false(_system.is_telling())
	assert_false(_system.soul.is_speaking(), "nothing to speak: the plate stays dark")


func _open(options: Options) -> void:
	_heights.clear()
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(options)
	add_child_autofree(_desk)
	_system = _desk.system()
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel]:
		panel.teller().blip.connect(_on_blip)
	_system.dawn_writ.next_button().pressed.emit()


func _on_blip(_pitch_scale: float) -> void:
	_heights.append(_system.soul.figure().position.y)
