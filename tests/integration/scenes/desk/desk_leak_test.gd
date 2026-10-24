extends GutTest
## Nothing on the desk may tell a liar from a hero before a thread is made (D1, D45; the plan's
## validation §6): two souls that differ only in their legal and worthy realms and whether they
## lie are told through two real desks in lockstep, and their sheets, the reveal step by step, the
## voice's pitch and every sound event must be the same.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
## One step of the lockstep telling, and enough steps to tell both sheets to the end.
const STEP := 1.0 / 60.0
const STEPS := 1200


func test_a_liar_and_a_hero_are_told_alike() -> void:
	var liar: DeskSystem = _open(Fixture.matched(true))
	var hero: DeskSystem = _open(Fixture.matched(false))
	assert_true(liar.commands.current_encounter().liar, "the liar lies")
	assert_false(hero.commands.current_encounter().liar, "the hero does not")
	assert_eq(_sheets(liar), _sheets(hero), "the same sheets, headings and hit areas")
	var liar_events: Array[String] = _record(liar)
	var hero_events: Array[String] = _record(hero)
	for _i: int in range(STEPS):
		liar_events.append(_snapshot(liar))
		hero_events.append(_snapshot(hero))
		if not liar.is_telling() and not hero.is_telling():
			break
		_step(liar)
		_step(hero)
	assert_false(liar.is_telling() or hero.is_telling(), "both tales were told to the end")
	assert_gt(liar_events.size(), 10, "the telling took many steps")
	assert_eq(liar_events, hero_events, "the same reveal, pitch and sounds, step by step")
	assert_eq(_sheets(liar), _sheets(hero), "and the same told sheets")
	assert_true(liar_events.any(func(e: String) -> bool: return e.begins_with("blip")), "voiced")
	assert_true(
		liar_events.any(func(e: String) -> bool: return e.begins_with("play blip")), "heard"
	)


func _open(commands: DeskCommands) -> DeskSystem:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480, 270)
	add_child_autofree(viewport)
	var desk: Desk = DESK_SCENE.instantiate() as Desk
	desk.use_commands(commands)
	desk.use_options(Fixture.normal())
	viewport.add_child(desk)
	var system: DeskSystem = desk.system()
	system.phase_card.next_button().pressed.emit()
	return system


## Every signal the telling can give, in order: lines shown, blips with their pitch, each sound
## the desk asked to play (with its pitch) or stop, the tale's end. Sounds are followed through
## DeskSounds' own signals, never `AudioStreamPlayer.playing`: that follows the real audio clock,
## not the lockstep, and made this test flaky.
func _record(system: DeskSystem) -> Array[String]:
	var events: Array[String] = []
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel]:
		var teller: Teller = panel.teller()
		teller.line_shown.connect(
			func(index: int) -> void: events.append("%s line %d" % [panel.name, index])
		)
		teller.blip.connect(func(pitch: float) -> void: events.append("blip %.4f" % pitch))
		teller.finished.connect(func() -> void: events.append("%s finished" % panel.name))
	var sounds: DeskSounds = system._sounds
	sounds.played.connect(
		func(sound: StringName, pitch: float) -> void:
			events.append("play %s %.4f" % [sound, pitch])
	)
	sounds.stopped.connect(func(sound: StringName) -> void: events.append("stop %s" % sound))
	system.caption_strip.text_shown.connect(func(text: String) -> void: events.append(text))
	return events


func _step(system: DeskSystem) -> void:
	system.claim_panel.teller()._process(STEP)
	system.witness_panel.teller()._process(STEP)


## What shows now: every line's revealed characters and hit area, and whether the tale is told.
func _snapshot(system: DeskSystem) -> String:
	var parts: PackedStringArray = []
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel]:
		for item: EvidenceItem in system.commands.visible_items():
			if panel.has_item(item.id):
				var label: Label = PaperLine.text_label(panel.area(item.id))
				parts.append("%d/%s" % [label.visible_characters, panel.area(item.id).visible])
	parts.append("telling %s" % system.is_telling())
	return " ".join(parts)


## The sheets as drawn: headings, every line's text and hit rect, each paper's size.
func _sheets(system: DeskSystem) -> Array[String]:
	var found: Array[String] = []
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel, system.law_panel]:
		found.append("%s %s %s %s" % [panel.name, panel.heading_text(), panel.size, panel.visible])
		for item: EvidenceItem in system.commands.visible_items():
			if panel.has_item(item.id):
				var area: PinSelectable = panel.area(item.id)
				var text: String = PaperLine.text_label(area).text
				found.append("%s %s %s" % [item.id, text, area.get_global_rect()])
	for item: EvidenceItem in system.commands.visible_items():
		if system.body_chart.has_item(item.id):
			found.append("%s %s" % [item.id, system.body_chart.area(item.id).get_global_rect()])
	return found
