extends GutTest
## The desk's art and the mentor with the slice data (Ulf, Kolbeinn): each soul's layer stack on
## the chart and at the gate, the door sprites, the plates, and the mentor's guided steps (D16).

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const MANIFEST := "res://docs/art/slice-asset-manifest.json"
const STACKS := preload("res://entities/body_chart/body_stacks.tres")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")

var _desk: Desk = null
var _system: DeskSystem = null


func before_each() -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(SliceLoader.load_slice())
	_desk.use_options(Fixture.instant())
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_the_stacks_resource_matches_the_art_manifest() -> void:
	var text: String = FileAccess.get_file_as_string(ProjectSettings.globalize_path(MANIFEST))
	var manifest: Dictionary = JSON.parse_string(text)
	var encounters: Dictionary = manifest["encounters"]
	assert_eq(STACKS.stacks.size(), encounters.size(), "one stack per manifest encounter")
	for key: String in encounters:
		var expected := PackedStringArray(encounters[key])
		assert_eq(STACKS.stacks.get(StringName(key), PackedStringArray()), expected, key)


func test_a_variant_id_finds_its_family_stack() -> void:
	assert_eq(STACKS.key_for(&"ulf"), &"ulf")
	assert_eq(STACKS.key_for(&"hakon_returned_ignored"), &"hakon-returned")
	assert_eq(STACKS.key_for(&"hakon"), &"hakon")
	assert_eq(STACKS.key_for(&"nobody"), &"")


func test_every_authored_encounter_has_its_stack_and_returned_hakon_wears_frost() -> void:
	var folder: String = "res://data/encounters"
	for file: String in DirAccess.get_files_at(folder):
		if not file.ends_with(".tres"):
			continue
		var data: Resource = load(folder.path_join(file))
		var id: StringName = data.get("id")
		assert_ne(STACKS.key_for(id), &"", "%s has a layer stack" % id)
	for variant: StringName in [&"hakon_ignored", &"hakon_missed"]:
		assert_eq(STACKS.key_for(variant), &"hakon-returned", "%s is the returned Hakon" % variant)


func test_the_chart_and_the_gate_draw_the_souls_own_layers() -> void:
	var chart: Array[Texture2D] = _system.body_chart.layers()
	assert_eq(chart.size(), 5, "Ulf: base, hand, wound, sword, head")
	assert_eq(chart[0].resource_path, "res://assets/art/body/base-tunic.png")
	assert_eq(chart[4].resource_path, "res://assets/art/body/heads/ulf.png")
	var figure: Array[Texture2D] = _system.soul.figure().layers
	assert_eq(figure[0].resource_path, "res://assets/art/souls/base-tunic.png")
	# The first soul walks in from off the desk (D15); its place is where the walk ends.
	_system.soul.finish_arrival()
	assert_eq(_system.soul.figure().global_position, Vector2(6, -2), "the head is not clipped")
	_stamp(&"valhalla")
	assert_eq(
		_system.body_chart.layers()[0].resource_path, "res://assets/art/body/base-nightshirt.png"
	)
	assert_eq(_system.body_chart.layers().size(), 3, "Kolbeinn's own stack")


func test_the_plate_is_plain_for_an_ordinary_soul() -> void:
	assert_eq(_system.soul.plate_texture().resource_path, "res://assets/art/ui/nameplate-plain.png")


func test_doors_show_lit_or_locked_sprites_and_hover_their_glyph() -> void:
	for door: Door in _system.doors:
		var expected: Texture2D = door.lit_texture if door.is_open else door.locked_texture
		assert_eq(door.shown_texture(), expected, String(door.realm))
		assert_eq(door.shown_texture().get_size(), Vector2(60, 87), "the sprite is 60x87")
		assert_eq(door.size.x, 60.0, "%s's node is as wide as its sprite" % door.realm)
	var folkvangr: Door = _door(&"folkvangr")
	assert_false(folkvangr.is_open)
	assert_eq(
		folkvangr.shown_texture().resource_path, "res://assets/art/doors/folkvangr-locked.png"
	)
	folkvangr.hover_started.emit(
		folkvangr.hover_text(), folkvangr.get_global_rect(), folkvangr.glyph
	)
	assert_eq(_system.hover_label.shown_glyph(), &"boar", "the hover shows the carved glyph")


func test_the_mentor_bubble_shows_the_guided_step_and_its_next_finishes_it() -> void:
	var step: MentorStep = _desk.commands().mentor_step()
	assert_not_null(step, "Ulf is guided (D16)")
	assert_eq(_system.mentor_bubble.shown_text(), step.text)
	assert_eq(_system.mentor_bubble.next_button().visible, step.until == MentorStep.Until.READ)
	while (
		_desk.commands().mentor_step() != null
		and _desk.commands().mentor_step().until == MentorStep.Until.READ
	):
		_system.mentor_bubble.next_button().pressed.emit()
	step = _desk.commands().mentor_step()
	assert_not_null(step)
	assert_eq(step.until, MentorStep.Until.PIN)
	assert_eq(_system.mentor_bubble.shown_text(), step.text, "the bubble follows the script")
	assert_false(_system.mentor_bubble.next_button().visible, "a pin step waits for the pin")
	for item_id: String in step.highlight:
		assert_true(_area(item_id).lit, "%s is lit for the player to pin" % item_id)
	assert_eq(_system.caption_strip.shown_text(), "", "guided prompts never use the strip (D33)")


func test_a_mentor_door_step_points_at_its_door() -> void:
	var commands: DeskCommands = _desk.commands()
	for _guard: int in range(10):
		var step: MentorStep = commands.mentor_step()
		if step == null or step.door != &"":
			break
		if step.until == MentorStep.Until.READ:
			commands.mentor_ack()
		elif step.until == MentorStep.Until.PIN:
			commands.pin(step.highlight[0], step.highlight[1])
		else:
			break
	var pointing: MentorStep = commands.mentor_step()
	assert_not_null(pointing, "Ulf's script points at a door before the stamp")
	assert_true(_door(pointing.door).pointed)


func _stamp(realm: StringName) -> void:
	_door(realm).press()
	_system.stamp_flow.stamp_prompt.confirm_button().arm_now()
	_system.stamp_flow.stamp_prompt.confirm_button().pressed.emit()


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _area(item_id: String) -> PinSelectable:
	if _system.body_chart.has_item(item_id):
		return _system.body_chart.area(item_id)
	for panel: EvidencePanel in [_system.claim_panel, _system.witness_panel, _system.law_panel]:
		if panel.has_item(item_id):
			return panel.area(item_id)
	return null
