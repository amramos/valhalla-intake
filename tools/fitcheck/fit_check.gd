extends SceneTree
## Development only: the D21 fit check. Renders the real desk scene at 480×270 with the worst
## text the slice holds, measures every line against its panel, prints the measurements, and saves
## a 1:1 PNG and a ×3 copy. Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/fitcheck/fit_check.gd -- [output-folder]
##
## The content: the longest claim and witness lines of the evidence matrix, with their prefixes;
## the five decrees L1–L5 word for word (D32); Ragna's front-view hit areas (neck, chest, right
## hand, hem) and her back; a grey thread with its knot; Ask Huginn and the stamp confirm; and a
## two-line caption.

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
	"Those who fell defending hearth and kin go to Fólkvangr, whatever L1, L3 and L4 say.",
]
## The longest message the strip carries: a citation with the ignored suffix (D14) and Ragna's
## mentor comment from the matrix.
const TWO_LINE_CAPTION := (
	"Citation: L5. C2 against L5. You threaded it yourself. "
	+ "L5. 'I held the door.' Hel pays well."
)

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
	system.caption_strip.take_over(TWO_LINE_CAPTION)
	var hem: PinSelectable = system.body_chart.area("B5")
	system.hover_label.show_for(hem.hover_text, hem.get_global_rect())
	await _frames(3)
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
	print("caption: %d lines" % system.caption_strip.line_count())
	if system.caption_strip.line_count() > 2:
		_problems.append("the caption takes %d lines" % system.caption_strip.line_count())
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
	ragna.id = &"fit_check"
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
