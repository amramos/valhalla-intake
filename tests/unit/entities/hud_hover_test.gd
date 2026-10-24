extends GutTest
## The HUD objects' hover labels (D20; the WP3 critic's readability case: a 7 px icon was the only
## cue): each object's plate has a mouse-through area that hovers its plain-language name, the tag's
## area is the object's column of the HUD's box so the tag hangs under the HUD, the stone between
## the plates takes no mouse, and an object gone from the HUD ends its hover.

const THEME := preload("res://scenes/desk/desk_theme.tres")
## The Hud node: screen (352, 0) to (478, 25).
const SIZE := Vector2(126, 25)
const CLOCK := 300.0
const TEXTS: Dictionary[StringName, String] = {
	&"candle": "the day's clock",
	&"clock": "the day's clock",
	&"quill": "feathers",
	&"slate": "Valhalla's quota today",
	&"raven": "Huginn's answers left",
	&"book": "the ledger",
}


func test_each_objects_plate_hovers_its_name() -> void:
	var hud: Hud = await _hud(_busy())
	watch_signals(hud)
	var map: HudHover = hud.hover_map()
	var box := Rect2(Vector2(Hud.OBJECTS_BOX.position), Vector2(Hud.OBJECTS_BOX.size))
	for object: StringName in TEXTS:
		var plate: Rect2 = map.plate(object)
		assert_true(plate.has_area(), "%s is drawn on day 3" % object)
		assert_true(box.encloses(plate), "%s lies in the box" % object)
		map.area_of(object).mouse_entered.emit()
		assert_eq(map.hovered(), object)
		assert_signal_emitted_with_parameters(
			hud, "hover_started", [TEXTS[object], _column(hud, plate, box)]
		)
	map.area_of(&"book").mouse_exited.emit()
	assert_signal_emitted(hud, "hover_ended", "leaving the HUD ends the label")
	assert_eq(map.hovered(), &"")


## Each object's area lies on its plate and passes every press on (desk_hud_hover_test pushes real
## ones); the HUD itself, and so the stone between the plates, takes no mouse.
func test_only_the_plates_take_the_mouse() -> void:
	var hud: Hud = await _hud(_busy())
	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the stone takes no mouse")
	for object: StringName in TEXTS:
		var area: Control = hud.hover_map().area_of(object)
		assert_true(area.visible, "%s has its area" % object)
		assert_eq(area.get_rect(), hud.hover_map().plate(object), "%s: on its plate" % object)
		assert_eq(area.mouse_filter, Control.MOUSE_FILTER_PASS, "%s: a press passes on" % object)


## Huginn's marks are drawn on day 3 only, and hover only there.
func test_the_raven_marks_hover_only_while_drawn() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	watch_signals(hud)
	assert_false(hud.hover_map().plate(&"raven").has_area(), "no marks before day 3")
	assert_false(hud.hover_map().area_of(&"raven").visible, "and no area to hover")
	hud.hover(&"raven")
	assert_signal_not_emitted(hud, "hover_started")
	assert_eq(hud.hover_map().hovered(), &"")


## The clock leaving the HUD (dusk) ends its label rather than leave it naming nothing.
func test_an_object_gone_from_the_hud_ends_its_hover() -> void:
	var readout: HudReadout = _readout(CLOCK)
	var hud: Hud = await _hud(readout)
	hud.hover(&"clock")
	assert_eq(hud.hover_map().hovered(), &"clock")
	watch_signals(hud)
	readout.clock_shown = false
	hud.refresh(readout)
	await wait_process_frames(2)
	assert_signal_emitted(hud, "hover_ended")
	assert_eq(hud.hover_map().hovered(), &"")
	assert_false(hud.hover_map().area_of(&"clock").visible, "its area went with it")


func _readout(time_left: float) -> HudReadout:
	var readout := HudReadout.new()
	readout.time_left = time_left
	readout.clock_seconds = CLOCK
	readout.feathers = 10
	readout.quota = Vector2i(0, 1)
	return readout


## Day 3 at its fullest: Huginn's answers, a promise, a two-digit quota line.
func _busy() -> HudReadout:
	var readout: HudReadout = _readout(CLOCK * 0.6)
	readout.feathers = 12
	readout.quota = Vector2i(7, 10)
	readout.huginn_on = true
	readout.huginn_left = 3
	readout.promise_open = true
	return readout


func _hud(readout: HudReadout) -> Hud:
	var host := Control.new()
	host.theme = THEME
	host.size = SIZE
	add_child_autofree(host)
	var hud := Hud.new()
	host.add_child(hud)
	hud.size = SIZE
	hud.set_process(false)
	hud.refresh(readout)
	# The draw, then the areas' placement deferred from it.
	await wait_process_frames(2)
	return hud


## The plate's columns over the box's rows, in global pixels: the area a tag is placed against.
func _column(hud: Hud, plate: Rect2, box: Rect2) -> Rect2:
	var at := Vector2(plate.position.x, box.position.y)
	return Rect2(hud.global_position + at, Vector2(plate.size.x, box.size.y))
