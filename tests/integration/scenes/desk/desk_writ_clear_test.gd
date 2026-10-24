extends GutTest
## The soul's writ under the doors (D14, D15) stays clear of the evidence. The final critic's case:
## Kolbeinn's writ, caught as it rose from under the desk edge after Ulf's stamp, had its name cut
## by the Claim sheet's top. For the longest names in the slice and the returned Hakon, the writ at
## rest and the slot that clips it reach no evidence sheet and not the Law, and stay in the gate's
## strip above the desk; through a whole sweep no drawn part of the writ reaches a sheet, and the
## next soul's writ never moves once it carries its name (it fades in where it lies).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## The slice's longest names (and its returned soul) by day and slot.
const LONG_NAMES: Dictionary[String, Vector2i] = {
	"Kolbeinn": Vector2i(1, 2),
	"Sigvaldi": Vector2i(2, 1),
	"Freydis": Vector2i(3, 1),
	"Hakon": Vector2i(3, 2),
}
## The gate's strip the writ lies in: under the HUD's line, down to the sheets' top (the band and
## the desk lip under the doors, y 96-100, where the writ rests).
const STRIP := Rect2(0, 16, 480, 84)
## A sweep, its fade and the slam before it end well inside this.
const SWEEP_BOUND_MS := 3000

var _desk: Desk = null
var _system: DeskSystem = null


func test_the_longest_names_lie_whole_on_the_writ_off_every_sheet() -> void:
	var problems: Array[String] = []
	for soul_name: String in LONG_NAMES:
		await _open(LONG_NAMES[soul_name])
		var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
		var writ: Writ = prompt.writ()
		if prompt.soul_name() != soul_name:
			problems.append("%s: the writ names %s" % [soul_name, prompt.soul_name()])
		if soul_name == "Hakon" and not _desk.commands().current_encounter().returned:
			problems.append("Hakon on day 3 is not the returned soul")
		var label: Label = writ.get_node("Name") as Label
		var face := Rect2(label.global_position, label.get_minimum_size())
		if face.size.x > Writ.NAME_MAX_WIDTH or not writ.get_global_rect().encloses(face):
			problems.append("%s: the name %s runs off the writ" % [soul_name, face])
		var slot: Control = prompt.get_node("WritSlot") as Control
		problems.append_array(_off_sheets(soul_name + " at rest", _drawn(prompt)))
		problems.append_array(_off_sheets(soul_name + "'s slot", slot.get_global_rect()))
		if not STRIP.encloses(_drawn(prompt)):
			problems.append("%s: the writ %s leaves the strip" % [soul_name, _drawn(prompt)])
		_desk.queue_free()
		await wait_process_frames(1)
	assert_eq(problems, [] as Array[String], "every long name whole, off every sheet")


func test_the_next_souls_writ_never_rises_from_under_the_sheets() -> void:
	await _open(Vector2i(1, 1))
	_system.finish_tellings()
	var prompt: StampPrompt = _system.stamp_flow.stamp_prompt
	assert_eq(prompt.soul_name(), "Ulf", "day 1 opens on Ulf")
	_door(&"valhalla").press()
	prompt.confirm_button().arm_now()
	prompt.confirm_button().pressed.emit()
	var writ: Writ = prompt.writ()
	var problems: Array[String] = []
	var fading_seen: bool = false
	var until: int = Time.get_ticks_msec() + SWEEP_BOUND_MS
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var tag: String = "%s at y %.2f" % [writ.soul_name(), writ.position.y]
		problems.append_array(_off_sheets(tag, _drawn(prompt)))
		if writ.soul_name() != "Kolbeinn":
			continue
		if writ.position.y != 0.0:
			problems.append("Kolbeinn's writ moves: " + tag)
		fading_seen = fading_seen or writ.modulate.a < 1.0
		if writ.modulate.a == 1.0 and not _desk.gate().is_slamming():
			break
	assert_eq(problems, [] as Array[String], "no drawn writ on a sheet, the next one never moved")
	assert_true(fading_seen, "Kolbeinn's writ fades in")
	assert_eq(writ.soul_name(), "Kolbeinn", "the sweep brought Kolbeinn's writ")
	assert_eq(writ.modulate.a, 1.0, "fully shown at the end")


## The jumped slice desk at `day_slot` (day, slot), the soul seated and its tale shown.
func _open(day_slot: Vector2i) -> void:
	var commands: DeskCommands = SliceLoader.load_slice()
	commands.debug_jump(day_slot.x, day_slot.y)
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.quit_closes_game = false
	_desk.use_commands(commands)
	_desk.use_options(Fixture.instant())
	add_child_autofree(_desk)
	_system = _desk.system()
	await wait_process_frames(3)


## The part of the writ drawn now: its rect cut to the slot that clips it.
func _drawn(prompt: StampPrompt) -> Rect2:
	var slot: Control = prompt.get_node("WritSlot") as Control
	return prompt.writ().get_global_rect().intersection(slot.get_global_rect())


## `area` against every evidence sheet and the Law, as they stand now.
func _off_sheets(what: String, area: Rect2) -> Array[String]:
	var found: Array[String] = []
	var sheets: Array[Control] = [
		_system.body_chart, _system.claim_panel, _system.witness_panel, _system.law_panel
	]
	for sheet: Control in sheets:
		if area.has_area() and area.intersects(sheet.get_global_rect()):
			found.append("%s %s reaches %s %s" % [what, area, sheet.name, sheet.get_global_rect()])
	return found


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null
