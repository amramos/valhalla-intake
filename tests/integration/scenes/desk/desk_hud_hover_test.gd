extends GutTest
## The HUD's hover labels on the running desk (D11, D20; the WP3 critic's readability case): real
## mouse moves over each object's plate show its plain-language name on the parchment tag, which
## never covers one of the HUD's plates (so never a numeral); the book, under the ledger tray's
## click area, hovers through the tray; and a press on a plate passes on while the tray keeps the
## book's click. The desk sits in a SubViewport because GUT's window covers the root viewport.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## In the order a mouse sweeping the HUD would meet them; the raven marks show on day 3.
const TEXTS: Array[Array] = [
	[&"candle", "the day's clock"],
	[&"clock", "the day's clock"],
	[&"quill", "feathers"],
	[&"slate", "Valhalla's quota today"],
	[&"raven", "Huginn's answers left"],
	[&"book", "the ledger"],
]
## Bare stone in the gate band, right of the Folkvangr door and under the HUD: no hover.
const BARE_STONE := Vector2(430, 40)

var _viewport: SubViewport = null
var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(Fixture.commands())
	_desk.use_options(Fixture.instant())
	_viewport.add_child(_desk)
	_system = _desk.system()
	_system.dawn_writ.next_button().pressed.emit()
	_system.finish_tellings()
	await wait_process_frames(2)


func test_hovering_each_hud_object_shows_its_name() -> void:
	var label: HoverLabel = _system.hover_label
	for entry: Array in TEXTS:
		var plate: Rect2 = _system.hud.object_plate(entry[0])
		assert_true(plate.has_area(), "%s is drawn on day 3" % entry[0])
		_move(plate.get_center())
		assert_eq(label.shown_text(), entry[1], "over the %s" % entry[0])
	_move(BARE_STONE)
	assert_eq(label.shown_text(), "", "off the HUD the tag goes")


func test_a_hud_objects_tag_never_covers_a_hud_plate() -> void:
	var label: HoverLabel = _system.hover_label
	var plates: Array[Rect2] = []
	for entry: Array in TEXTS:
		plates.append(_system.hud.object_plate(entry[0]))
	var screen := Rect2(Vector2.ZERO, Vector2(_viewport.size))
	var checked: int = 0
	for entry: Array in TEXTS:
		_move(_system.hud.object_plate(entry[0]).get_center())
		assert_eq(label.shown_text(), entry[1], "the %s's tag shows" % entry[0])
		var tag: Rect2 = label.tag_rect()
		assert_true(screen.encloses(tag), "the %s's tag is on the screen" % entry[0])
		assert_false(tag.intersects(_system.hud.objects_rect()), "%s: clear of the HUD" % entry[0])
		for plate: Rect2 in plates:
			assert_false(tag.intersects(plate), "the %s's tag over a plate %s" % [entry[0], plate])
		checked += 1
	assert_eq(checked, TEXTS.size(), "every object's tag was checked")


## The tray lies over the book and keeps its click; its hover is the HUD's.
func test_the_book_hovers_through_the_tray_which_keeps_its_click() -> void:
	var book: Vector2 = _system.hud.object_plate(&"book").get_center()
	assert_true(_system.ledger_tray.get_global_rect().has_point(book), "the tray covers the book")
	_move(book)
	assert_eq(_system.hover_label.shown_text(), "the ledger")
	_click(book)
	assert_true(_system.ledger_tray.is_open(), "the press opened the ledger")
	_move(BARE_STONE)
	assert_eq(_system.hover_label.shown_text(), "", "leaving the tray ends the book's label")


## A press on a plate is never the HUD's: it reaches the desk under it as a press on the stone.
func test_a_press_on_a_hud_plate_passes_on() -> void:
	var reached: Array[InputEventMouseButton] = []
	_desk.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				reached.append(event as InputEventMouseButton)
	)
	for object: StringName in [&"candle", &"quill", &"slate"]:
		_click(_system.hud.object_plate(object).get_center())
	assert_eq(reached.size(), 6, "each press and release went on to the desk")
	assert_false(_system.ledger_tray.is_open(), "and opened nothing")


## The raven's own tag keeps clear of the HUD's numbers too.
func test_the_ravens_tag_keeps_clear_of_the_hud() -> void:
	assert_true(_system.raven.visible, "Huginn sits on day 3")
	_move(_system.raven.get_global_rect().get_center())
	assert_ne(_system.hover_label.shown_text(), "", "the raven's tag shows")
	assert_false(_system.hover_label.tag_rect().intersects(_system.hud.objects_rect()))


## A move to `at` (window pixels of the viewport).
func _move(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)


## A move, a press and a release at `at`.
func _click(at: Vector2) -> void:
	_move(at)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		_viewport.push_input(event)
