extends GutTest
## The harness writes what the desk's note writes (D6, D44): every thread caption comes from the
## shared CaptionFormatter measured in the desk's font, and no caption, citation or comment it
## prints names an evidence id, while its commands keep the ids.

const Harness := preload("res://tools/harness/harness.gd")
const THEME := "res://scenes/desk/desk_theme.tres"
## Any evidence id: a body fact, a claim or witness line, a decree.
## A raw string: in a plain one "\b" is a backspace, not a word boundary.
const ID_PATTERN := r"\b[BCWL][0-9]+\b"

var _ids := RegEx.create_from_string(ID_PATTERN)


## The detector itself: it finds every kind of id and nothing that merely starts with B, C, W, L.
func test_the_id_detector_finds_ids_and_only_ids() -> void:
	var found: Array[String] = []
	for text: String in [
		"Citation: L2.", "C1 against L1", "His W2.", "B4 and L3", "decree II", "Bersi", "Loki", "W"
	]:
		if _ids.search(text) != null:
			found.append(text)
	assert_eq(found, ["Citation: L2.", "C1 against L1", "His W2.", "B4 and L3"] as Array[String])


## Every soul of the real slice at the desk, by (day, slot, mercy): the legal run (Hakon returns
## missed) and the merciful one (Egil takes his slot).
func _seats() -> Array[Array]:
	var seats: Array[Array] = []
	for mercy: bool in [false, true]:
		for day: int in [1, 2, 3]:
			for slot: int in range(1, 6):
				seats.append([day, slot, mercy])
	return seats


## Seats the harness at (day, slot); false when that slot doesn't exist.
func _seat(harness: Harness, seat: Array) -> bool:
	harness.act("jump %d %d%s" % [seat[0], seat[1], " mercy" if seat[2] else ""])
	var desk: DeskCommands = harness.desk
	return (
		desk.phase() == &"desk"
		and desk.day_number() == seat[0]
		and desk.queue_position().x == seat[1]
	)


## Everything the harness says about one soul: each seam pinned, a no-seam pin, the note, and a
## stamp at every wrong open door with its citation and the mentor's comment.
func _printed_for(seat: Array) -> Array[String]:
	var printed: Array[String] = []
	var harness := Harness.new(SliceLoader.load_slice())
	if not _seat(harness, seat):
		return printed
	var soul: Encounter = harness.desk.current_encounter()
	for seam: Seam in soul.seams:
		var result: String = harness.act("pin %s %s" % [seam.a, seam.b])
		if harness.last_ok:
			printed.append(result)
			printed.append(harness.view.caption)
	for realm: StringName in harness.desk.day_rules().doors_open:
		if realm == soul.legal_realm or not _seat(harness, seat):
			continue
		printed.append(harness.act("stamp %s" % realm))
		for line: String in harness.describe().split("\n"):
			if line.begins_with("Black feather:") or line.begins_with("Caption:"):
				printed.append(line)
	return printed


func test_no_caption_citation_or_comment_names_an_id() -> void:
	var leaks: Array[String] = []
	var printed: int = 0
	for seat: Array in _seats():
		for text: String in _printed_for(seat):
			printed += 1
			if _ids.search(text) != null:
				leaks.append(text)
	assert_gt(printed, 60, "every soul's threads and wrong stamps were printed")
	assert_eq(leaks, [] as Array[String])


func test_a_no_seam_pin_names_no_id_either() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("jump 2 1")
	var result: String = harness.act("pin B2 L4")
	assert_eq(result, "No seam between those two. -10 s", "Sigvaldi's red herring (D36)")


func test_the_harness_caption_is_the_desk_formatters_in_the_desk_font() -> void:
	var theme: Theme = load(THEME) as Theme
	PixelFont.configure(theme.default_font)
	var desk_note := CaptionFormatter.new(
		theme.default_font, theme.default_font_size, Harness.NOTE_WIDTH
	)
	var mismatches: Array[String] = []
	var compared: int = 0
	for seat: Array in _seats():
		var harness := Harness.new(SliceLoader.load_slice())
		if not _seat(harness, seat):
			continue
		var soul: Encounter = harness.desk.current_encounter()
		for seam: Seam in soul.seams:
			harness.act("pin %s %s" % [seam.a, seam.b])
			if not harness.last_ok:
				continue
			compared += 1
			var expected: String = desk_note.thread_caption(
				seam, harness.desk.visible_items(), soul.soul_name, soul.witness_heading_name()
			)
			if harness.view.caption != expected:
				mismatches.append("%s | %s" % [harness.view.caption, expected])
	assert_gt(compared, 30)
	assert_eq(mismatches, [] as Array[String])


func test_commands_keep_the_ids() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("begin")
	assert_eq(
		harness.act("pin C1 L1"),
		(
			'A law thread. "Speared, in..." against decree I: the saga is true. Decree I sends'
			+ " him to Valhalla."
		)
	)
	assert_string_contains(harness.actions(), "ids: B1 B2 B3 C1 C2 C3 C4 L1 L2 L3")
