extends GutTest
## The door glyph cue: while a law thread's caption naming a realm shows ("Decree III sends him to
## Hel."), that door's carved glyph is drawn lit; the next caption, whatever it is, puts it out.
## A caption that names no realm (a red or grey thread, "the saga is true" alone, the mentor)
## lights none.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const FIXTURE := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")


func test_the_cue_follows_the_law_captions_lifetime_on_the_desk() -> void:
	var system: DeskSystem = _desk().system()
	system.phase_card.next_button().pressed.emit()
	system.finish_tellings()
	var seen: Array[StringName] = []
	# A law thread to Hel, then a red thread: its caption replaces the law caption once the law
	# caption's hold is over (until then it waits, and the law caption and its cue stay).
	_pin(system, "B3", "L3")
	seen.append(_lit(system))
	_pin(system, "B1", "W2")
	seen.append(_lit(system))
	# A law thread to Fólkvangr, then a pair with no seam: its line replaces the caption.
	_pin(system, "C2", "L5")
	seen.append(_lit(system))
	_pin(system, "C1", "W2")
	seen.append(_lit(system))
	# The thread to Hel again: its caption shows again, and so does the cue.
	_pin(system, "B3", "L3")
	seen.append(_lit(system))
	system.restart()
	seen.append(_lit(system))
	var expected: Array[StringName] = [Realm.HEL, &"", Realm.FOLKVANGR, &"", Realm.HEL, &""]
	assert_eq(seen, expected)


func test_a_caption_without_a_realm_lights_no_glyph() -> void:
	var note: DeskNote = _note()
	var strip: CaptionStrip = _strip_of(note)
	var true_saga := Seam.make("C1", "L1", Seam.Kind.LAW, Seam.Liar.NONE, &"", "the saga is true.")
	var red := Seam.make(
		"B1", "W1", Seam.Kind.RED, Seam.Liar.WITNESS, &"", "the body gives the lie."
	)
	var seen: Array[StringName] = []
	for seam: Seam in [true_saga, red]:
		strip.take_over_caption(note.thread(seam, null, [] as Array[EvidenceItem]))
		seen.append(note.lit_glyph())
	strip.take_over_caption(note.thread(_law(Realm.VALHALLA), null, [] as Array[EvidenceItem]))
	seen.append(note.lit_glyph())
	strip.take_over_caption(note.thread(true_saga, null, [] as Array[EvidenceItem]))
	seen.append(note.lit_glyph())
	assert_eq(seen, [&"", &"", Realm.VALHALLA, &""] as Array[StringName])


func test_a_law_caption_waiting_behind_another_lights_when_it_shows() -> void:
	var note: DeskNote = _note()
	var strip: CaptionStrip = _strip_of(note)
	strip.post_caption(Caption.make("Read the Law.", CaptionStrip.Priority.MENTOR))
	strip.post_caption(note.thread(_law(Realm.HEL), null, [] as Array[EvidenceItem]))
	strip.post_caption(Caption.make("Mind the clock.", CaptionStrip.Priority.MENTOR))
	var seen: Array[StringName] = [note.lit_glyph()]
	strip._process(strip.hold_seconds)
	seen.append(note.lit_glyph())
	strip._process(strip.hold_seconds)
	seen.append(note.lit_glyph())
	note.reset()
	seen.append(note.lit_glyph())
	assert_eq(seen, [&"", Realm.HEL, &"", &""] as Array[StringName], "the thread ranks first")


func test_each_door_finds_its_carved_glyph_and_lights_it_in_the_palette() -> void:
	var system: DeskSystem = _desk().system()
	var named: Dictionary[String, Color] = Palette.by_name()
	var counts: Dictionary[StringName, int] = {}
	for door: Door in system.doors:
		var carving: DoorCarving = DoorCarving.read(door.lit_texture, Door.GLYPH_AREAS[door.glyph])
		counts[door.glyph] = carving.pixels.size()
		var inks: Array[Color] = [carving.ink]
		assert_eq(Palette.strays(inks), [] as Array[String], "%s's carving" % door.glyph)
		assert_eq(door.glyph_pixels().size(), carving.pixels.size())
	assert_gt(counts.get(&"spear", 0), 40, "the spear's shaft and head")
	assert_gt(counts.get(&"serpent", 0), 100, "the serpent's coil")
	assert_gt(counts.get(&"boar", 0), 100, "the boar's body")
	var light: Color = THEME.get_color(&"pin_highlight", &"DeskPalette")
	assert_eq(Palette.strays([light] as Array[Color]), [] as Array[String])
	assert_eq(light.to_html(false), named["Parchment 2"].to_html(false))


func _desk() -> Desk:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480, 270)
	add_child_autofree(viewport)
	var desk: Desk = DESK_SCENE.instantiate() as Desk
	desk.use_commands(FIXTURE.commands())
	desk.use_options(FIXTURE.instant())
	viewport.add_child(desk)
	return desk


## A note over its own strip, with one door per realm.
func _note() -> DeskNote:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var strip := CaptionStrip.new()
	strip.size = Vector2(344, 22)
	host.add_child(strip)
	var gate := PresentationGate.new()
	host.add_child(gate)
	var note := DeskNote.new(strip, gate)
	for realm: StringName in [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR]:
		var door := Door.new()
		door.realm = realm
		host.add_child(door)
		note.doors.append(door)
	return note


func _strip_of(note: DeskNote) -> CaptionStrip:
	return note.doors[0].get_parent().get_child(0) as CaptionStrip


func _law(realm: StringName) -> Seam:
	var text: String = "the saga is true. Decree I sends him to %s." % Realm.display_name(realm)
	return Seam.make("C1", "L1", Seam.Kind.LAW, Seam.Liar.NONE, realm, text)


## A pin, then the note's hold runs out, as it would before the player's next pin.
func _pin(system: DeskSystem, a: String, b: String) -> void:
	_area(system, a).press()
	_area(system, b).press()
	system.caption_strip._process(system.caption_strip.hold_seconds)


func _area(system: DeskSystem, item_id: String) -> PinSelectable:
	if item_id.begins_with("B"):
		return system.body_chart.area(item_id)
	var panels: Dictionary[String, EvidencePanel] = {
		"C": system.claim_panel, "W": system.witness_panel, "L": system.law_panel
	}
	return panels[item_id.left(1)].area(item_id)


## The realm whose door's glyph is lit now; &"" for none.
func _lit(system: DeskSystem) -> StringName:
	var lit: Array[StringName] = []
	for door: Door in system.doors:
		if door.glyph_lit():
			lit.append(door.realm)
	assert_lte(lit.size(), 1, "one glyph at most")
	return lit[0] if not lit.is_empty() else &""
