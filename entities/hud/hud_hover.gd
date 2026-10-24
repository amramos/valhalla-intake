class_name HudHover
extends RefCounted
## Which HUD object the mouse is over, and its plain-language label (D20), so a 7 px icon is never
## the only cue: the candle and its m:ss are the day's clock, the quill the feathers, the slate the
## quota, the raven marks Huginn's answers and the book the ledger. The HUD records each object's
## plate as it draws it, and each object has a mouse-through area on its plate (`build`,
## `place_areas`): it takes the hover and lets every press pass on, so the bare stone between the
## plates takes no mouse and a click on a plate reaches whatever is under the HUD.
##
## The hovered area it reports is the object's column of the HUD's whole box (`box`), so the
## parchment tag, which goes above or below its area, hangs under the HUD and never covers a plate.

signal started(text: String, area: Rect2)
signal ended

const TEXTS: Dictionary[StringName, String] = {
	&"candle": "the day's clock",
	&"clock": "the day's clock",
	&"quill": "feathers",
	&"slate": "Valhalla's quota today",
	&"raven": "Huginn's answers left",
	&"book": "the ledger",
}

## Every object's plate lies inside this box (the HUD's local pixels); see `area`.
var box := Rect2()
var _plates: Dictionary[StringName, Rect2] = {}
var _areas: Dictionary[StringName, Control] = {}
var _over: StringName = &""


## One hover area per object under `hud`, hidden until `place_areas` puts it on a drawn plate.
func build(hud: Control) -> void:
	for object: StringName in TEXTS:
		var area := Control.new()
		area.name = String(object).capitalize() + "Hover"
		area.mouse_filter = Control.MOUSE_FILTER_PASS
		area.visible = false
		area.mouse_entered.connect(hover.bind(object))
		area.mouse_exited.connect(_left.bind(object))
		hud.add_child(area)
		_areas[object] = area


## Puts each area on the plate the last draw recorded; an object not drawn (the clock at dusk,
## Huginn's marks before day 3) has none, and its hover ends.
func place_areas() -> void:
	for object: StringName in _areas:
		var area: Control = _areas[object]
		var on: Rect2 = plate(object)
		area.visible = on.has_area()
		if area.visible and (area.position != on.position or area.size != on.size):
			area.position = on.position
			area.size = on.size
	if _over != &"" and not _plates.has(_over):
		hover(&"")


## The hover area of `object` (tests and tools); null before `build`.
func area_of(object: StringName) -> Control:
	return _areas.get(object, null)


## Forgets the last draw's plates (a draw is about to record them again).
func clear() -> void:
	_plates.clear()


## The plate `object` was drawn on, in the HUD's local pixels.
func record(object: StringName, plate: Rect2) -> void:
	_plates[object] = plate


## The plate `object` was last drawn on (local); empty when it was not drawn.
func plate(object: StringName) -> Rect2:
	return _plates.get(object, Rect2())


## Every plate the last draw recorded (local).
func plates() -> Array[Rect2]:
	var all: Array[Rect2] = []
	all.assign(_plates.values())
	return all


## The area the tag is placed against: the plate's columns, the box's rows (local).
func area(object: StringName) -> Rect2:
	var on: Rect2 = plate(object)
	return Rect2(on.position.x, box.position.y, on.size.x, box.size.y)


func hovered() -> StringName:
	return _over


## The mouse is now over `object` (&"" for none): the old label ends and the new one starts. An
## object the last draw did not paint (Huginn's marks before day 3) shows nothing.
func hover(object: StringName) -> void:
	if not _plates.has(object):
		object = &""
	if object == _over:
		return
	if _over != &"":
		ended.emit()
	_over = object
	if object != &"":
		started.emit(TEXTS.get(object, ""), area(object))


## The mouse left `object`'s area: its label ends unless another object's has already begun.
func _left(object: StringName) -> void:
	if _over == object:
		hover(&"")
