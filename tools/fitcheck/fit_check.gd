extends SceneTree
## Development only: the D21 fit check. Renders the real desk scene at 480×270 with the worst
## text the slice holds, measures every line against its panel, prints the measurements, and saves
## a 1:1 PNG and a ×3 copy. Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/fitcheck/fit_check.gd -- [output-folder]
##
## The content: the longest claim and witness lines of the evidence matrix (no ids on the desk,
## D6: a hanging quote instead); the five decrees I–V word for word (D32, L5 as amended by D6) on
## the scroll; every soul's and witness's name as a sheet heading; Ragna's front-view hit areas
## (neck, chest, right hand, hem) and her back; a grey thread with its knot; Ask Huginn and the
## raised stamp; and on the clerk's note the longest grey caption the slice can write, both
## speakers named, built by the desk's own CaptionFormatter, then the longest citation with the
## mentor's comment.

const DESK_SCENE := "res://scenes/desk/desk.tscn"
const OUT_NAME := "vertical-slice-fitcheck.png"
const OUT_NAME_X3 := "vertical-slice-fitcheck-x3.png"

## The longest line for each prefix in docs/plans/vertical-slice-matrix.md, measured in m5x7.
const CLAIM_LINES: Array[String] = [
	"Three Danes hacked me.",
	"Spear in my two hands.",
	"Sword in hand, always.",
	"Mother said come home.",
]
const WITNESS_LINES: Array[String] = [
	"The wall broke behind.",
	"Caught him midstream.",
	"Knifed him. He turned.",
]
## D32, verbatim.
const DECREES: Array[String] = [
	(
		"Valhalla takes only those slain by a weapon in battle. "
		+ "Death by sickness, age or accident goes to Hel."
	),
	"Whoever lies to the Gate goes to Hel, whatever else the Law says.",
	"Even so, a warrior without a weapon in hand goes to Hel.",
	"Even so, those who fled the battle go to Hel.",
	"Those who fell defending hearth and kin go to Fólkvangr, whatever I, III and IV say.",
]
## The longest written messages the note carries, each its own caption: Ragna's citation with the
## ignored suffix (D14), and the mentor's comment on Hel's promise, in the decrees' numerals (D6).
const CITATION_CAPTION := (
	"Citation: decree V. 'I held the door' and decree V. " + "You threaded it yourself."
)
const MENTOR_CAPTION := "'I held the door' and decree V. Hel pays well."
const ENCOUNTERS := "res://data/encounters"

var _out: String = ""
var _desk: Desk = null
var _problems: Array[String] = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://docs/plans")
	_desk = (load(DESK_SCENE) as PackedScene).instantiate() as Desk
	_desk.use_commands(_fit_check_commands())
	root.add_child(_desk)
	_run.call_deferred()


func _run() -> void:
	var system: DeskSystem = _desk.system()
	system.body_chart.outline_all = true
	_desk.commands().begin_day()
	await _frames(2)
	# A press during the tale would only finish it (D27): the check reads the told sheets.
	system.finish_tellings()
	await _frames(2)
	system.claim_panel.area("C2").press()
	system.witness_panel.area("W1").press()
	await _frames(2)
	(system.thread_layer.get_child(0) as ThreadLine).knot().press()
	await _frames(2)
	# Selecting the knot redraws the threads; read the live one.
	var thread: ThreadLine = system.thread_layer.get_child(
		system.thread_layer.get_child_count() - 1
	)
	_door(&"folkvangr").press()
	var hem: PinSelectable = system.body_chart.area("B5")
	system.hover_label.show_for(hem.hover_text, hem.get_global_rect())
	await _frames(2)
	system.caption_strip.take_over(MENTOR_CAPTION)
	await _frames(2)
	_measure_note(system, "mentor", true)
	system.caption_strip.take_over(CITATION_CAPTION)
	await _frames(2)
	_measure_note(system, "citation", true)
	var grey: String = _longest_grey_caption(system)
	system.caption_strip.take_over_caption(
		Caption.make(grey, CaptionStrip.Priority.THREAD, &"pin_grey", [] as Array[String])
	)
	await _frames(3)
	_measure_note(system, "longest grey caption", false)
	_measure(system, thread)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_save(image, OUT_NAME)
	image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
	_save(image, OUT_NAME_X3)
	print("FIT CHECK: %s" % ("PASS" if _problems.is_empty() else "PROBLEMS"))
	for problem: String in _problems:
		print("  - " + problem)
	quit()


func _measure(system: DeskSystem, thread: ThreadLine) -> void:
	var viewport: Vector2 = root.get_visible_rect().size
	print("viewport %dx%d" % [viewport.x, viewport.y])
	if viewport != Vector2(480, 270):
		_problems.append("viewport is %s, not 480x270: run with --resolution 480x270" % viewport)
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel]:
		print("%s: inner width %d px" % [panel.name, panel.inner_width()])
		for item: EvidenceItem in _desk.commands().visible_items():
			if not panel.has_item(item.id):
				continue
			var width: int = panel.text_width(item.id)
			var over: int = width - panel.inner_width()
			print(
				(
					"  %s %s: %d px%s"
					% [item.id, item.text, width, " (over by %d)" % over if over > 0 else ""]
				)
			)
			if over > 0:
				var problem: String = (
					"%s %s runs %d px past the %s" % [item.id, item.text, over, panel.name]
				)
				_problems.append(problem + " (D50: at most 132 px)")
	var law: EvidencePanel = system.law_panel
	print("LawPanel: inner width %d px, height %d px" % [law.inner_width(), law.size.y])
	for index: int in range(DECREES.size()):
		var id: String = "L%d" % (index + 1)
		print("  %s: %d lines" % [id, law.line_count(id)])
		if law.line_count(id) > 3:
			_problems.append("%s wraps to %d lines (D49 allows 3)" % [id, law.line_count(id)])
	print("  content bottom %d of %d" % [law.content_bottom(), law.size.y])
	if law.overflows():
		_problems.append(
			"the Law runs past its panel (%d > %d)" % [law.content_bottom(), law.size.y]
		)
	_measure_headings(system)
	print("knot at %s, size %s" % [thread.knot().global_position, thread.knot().size])
	var knot: Rect2 = thread.knot().get_global_rect()
	var areas: Array[Rect2] = system.body_chart.hit_rects()
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel, system.law_panel]:
		areas.append_array(panel.hit_rects())
	for area: Rect2 in areas:
		if knot.intersects(area):
			_problems.append("the knot %s covers the hit area %s" % [knot, area])
	for id: String in ["B1", "B2", "B3", "B4", "B5"]:
		var hit: PinSelectable = system.body_chart.area(id)
		print("  %s %s: %s" % [id, hit.hover_text, hit.get_global_rect()])
		if hit.size.x < 8 or hit.size.y < 8:
			_problems.append("%s is smaller than 8x8" % id)


## The note's lines for the shown caption: at most two, the mark column left clear (D10).
func _measure_note(system: DeskSystem, what: String, finish: bool) -> void:
	var strip: CaptionStrip = system.caption_strip
	if finish:
		strip.finish_writing()
	var label: Label = strip.get_node("Text") as Label
	print(
		(
			"note (%s): %d lines, text from x %d, width %d px: %s"
			% [what, strip.line_count(), label.position.x, label.size.x, strip.shown_text()]
		)
	)
	if strip.line_count() > 2:
		_problems.append("the note's %s takes %d lines (D10 allows 2)" % [what, strip.line_count()])
	if label.position.x < CaptionStrip.RULE_X + 1:
		_problems.append("the note's text overlaps its mark column")


## Every soul's and witness's name, as the sheets head them, against the sheet's width (D6).
func _measure_headings(system: DeskSystem) -> void:
	var widest: String = ""
	var widest_px: int = 0
	for encounter: Encounter in _slice_encounters():
		for name: String in [encounter.soul_name, encounter.witness_heading_name()]:
			var width: int = PaperLine.width_of(system.claim_panel, name)
			if width > widest_px:
				widest = name
				widest_px = width
	var inner: int = system.witness_panel.inner_width()
	print("widest heading: %s, %d px of %d" % [widest, widest_px, inner])
	if widest_px > inner:
		_problems.append("the heading %s runs past the sheet" % widest)


## The longest caption a grey thread in the slice can write, through the desk's own formatter and
## with the day-3 Law on the desk, so the excerpts are cut against every decree.
func _longest_grey_caption(system: DeskSystem) -> String:
	var font: Font = system.caption_strip.get_theme_font(&"font", &"Label")
	var formatter := CaptionFormatter.new(font, DeskNote.FONT_SIZE, system.note_width())
	var law: Array[EvidenceItem] = _desk.commands().day_rules().decrees
	var longest: String = ""
	for encounter: Encounter in _slice_encounters():
		var items: Array[EvidenceItem] = encounter.items.duplicate()
		items.append_array(law)
		for seam: Seam in encounter.seams:
			if seam.kind != Seam.Kind.GREY:
				continue
			var text: String = formatter.thread_caption(
				seam, items, encounter.soul_name, encounter.witness_heading_name()
			)
			if formatter.width_of(text) > formatter.width_of(longest):
				longest = text
	print("longest grey caption: %d px" % formatter.width_of(longest))
	return longest


func _slice_encounters() -> Array[Encounter]:
	var found: Array[Encounter] = []
	for file: String in DirAccess.get_files_at(ENCOUNTERS):
		if file.ends_with(".tres"):
			found.append((load(ENCOUNTERS.path_join(file)) as EncounterData).to_core())
	return found


func _fit_check_commands() -> DeskCommands:
	var day := DayRules.new()
	day.day = 3
	day.quota = 2
	day.clock_seconds = 300.0
	day.doors_open = [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR]
	day.citations = true
	day.huginn_answers = 2
	for index: int in range(DECREES.size()):
		day.decrees.append(
			EvidenceItem.make("L%d" % (index + 1), EvidenceItem.Group.LAW, DECREES[index])
		)
	var ragna := Encounter.new()
	ragna.id = &"ragna"
	ragna.soul_name = "Ragna"
	ragna.hel_marked = true
	ragna.plate_label = "Hel asked for her"
	ragna.witness_name = "Skeggi"
	ragna.legal_realm = Realm.FOLKVANGR
	ragna.worthy_realm = Realm.FOLKVANGR
	ragna.items = [
		EvidenceItem.make(
			"B1", EvidenceItem.Group.BODY, "no wound, front", &"front", &"torso_front"
		),
		EvidenceItem.make("B2", EvidenceItem.Group.BODY, "no wound, back", &"back", &"torso_back"),
		EvidenceItem.make("B3", EvidenceItem.Group.BODY, "sword, gripped", &"front", &"hand_right"),
		EvidenceItem.make("B4", EvidenceItem.Group.BODY, "neck, broken", &"front", &"neck"),
		EvidenceItem.make(
			"B5", EvidenceItem.Group.BODY, "night-shirt, bare feet", &"front", &"hem"
		),
	]
	for index: int in range(CLAIM_LINES.size()):
		ragna.items.append(
			EvidenceItem.make("C%d" % (index + 1), EvidenceItem.Group.CLAIM, CLAIM_LINES[index])
		)
	for index: int in range(WITNESS_LINES.size()):
		ragna.items.append(
			EvidenceItem.make("W%d" % (index + 1), EvidenceItem.Group.WITNESS, WITNESS_LINES[index])
		)
	ragna.seams = [
		Seam.make("C2", "W1", Seam.Kind.GREY, Seam.Liar.WITNESS, &"", "one of them lies.")
	]
	var commands := DeskCommands.new()
	var days: Array[DayRules] = [day]
	commands.start_run(days, [[ragna]], SliceRules.new(), {})
	return commands


func _door(realm: StringName) -> Door:
	for door: Door in _desk.system().doors:
		if door.realm == realm:
			return door
	return null


func _save(image: Image, file_name: String) -> void:
	var path: String = _out.path_join(file_name)
	image.save_png(path)
	print("saved %s (%dx%d)" % [path, image.get_width(), image.get_height()])


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
