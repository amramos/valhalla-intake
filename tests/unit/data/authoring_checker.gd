extends RefCounted
## The authoring check (plan §2.27, D6, D12, D40, D44, D45, D50, matrix rules R1-R7), as pure
## checks that return the problems they find, so a deliberately broken copy of the data can prove
## each one fails. authoring_check_test.gd runs it on the real slice.

## Where each decree sends a soul (D32).
const DECREE_REALMS: Dictionary = {
	"L1": Realm.VALHALLA, "L2": Realm.HEL, "L3": Realm.HEL, "L4": Realm.HEL, "L5": Realm.FOLKVANGR
}
## D50: a testimony line, its "C1 " prefix included, fits 132 px in the desk font.
const LINE_CAP_PX := 132
## D33: a caption-strip text fits two strip lines (matrix A: 688 px).
const STRIP_CAP_PX := 688
const SAGA_TRUE := "the saga is true. "
## The mentor's bubble (entities/mentor/mentor_bubble.gd, 60x64): its label is 52 px wide from the
## top; a READ step's "Next" button starts 48 px down, other steps have 61 px.
const BUBBLE_TEXT_WIDTH := 52
## The evidence panels (entities/evidence_panel/evidence_panel.gd: PADDING) and the witness
## heading's prefix (systems/desk/desk_system.gd).
const DESK_SCENE := "res://scenes/desk/desk.tscn"
const PANEL_PADDING := 2
const WITNESS_PREFIX := "WITNESS "
## The phase card's dawn layout: 320 px wide, padding 6, 10 px a line, then a gap and the button.
const CARD_WIDTH := 320
const CARD_PADDING := 6
const CARD_LINE_PITCH := 10
const CARD_GAP := 4
const CARD_BUTTON := 14
const CARD_MAX_HEIGHT := 266
const BUBBLE_TEXT_HEIGHT_READ := 48
const BUBBLE_TEXT_HEIGHT := 61
const THEME_PATH := "res://scenes/desk/desk_theme.tres"
## R1 (matrix §0, "What makes a law thread"): the evidence that shows each decree's condition.
## Whether a line states a death in battle is the author's reading, not something a check can
## parse, so the matrix's reading is held here, apart from the seams, and a law thread on any other
## line fails. L1 takes a claim line, L4 and L5 a claim or witness line, L3 the body fact; L2 has
## none (a lie seam reaches it). A new condition line is added here on purpose.
const CONDITION_GROUPS: Dictionary = {
	"L1": [EvidenceItem.Group.CLAIM],
	"L3": [EvidenceItem.Group.BODY],
	"L4": [EvidenceItem.Group.CLAIM, EvidenceItem.Group.WITNESS],
	"L5": [EvidenceItem.Group.CLAIM, EvidenceItem.Group.WITNESS],
}
const CONDITION_TEXTS: Dictionary = {
	"L1": ["Speared, in battle.", "Fell in battle. Ness.", "Slain in a sea-battle."],
	"L3": ["nothing in hand"],
	"L4": ["Left the fight.", "Carried me out of it."],
	"L5":
	[
		"I held the door.",
		"My boys behind me.",
		"She held that door.",
		"I held our door.",
		"Held his door. Long.",
	],
}

var _font: Font = null
var _font_size: int = 16
var _line_spacing: int = 0


func _init() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	if theme != null and theme.default_font != null:
		_font = theme.default_font
		_font_size = theme.default_font_size
		_line_spacing = theme.get_constant(&"line_spacing", &"Label")
		PixelFont.configure(_font)


func font_loaded() -> bool:
	return _font != null


## The width a line needs on the desk, measured the way the evidence panel measures it.
func width_of(text: String) -> int:
	return int(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x) - 1


## Every check on one encounter as judged on `day`. herrings: "a|b" pairs (D24).
func check_encounter(
	soul: Encounter, day: DayRules, herrings: Array[String], rules: SliceRules
) -> Array[String]:
	var problems: Array[String] = []
	var tag: String = "%s (day %d)" % [soul.id, day.day]
	for realm: StringName in [soul.worthy_realm, soul.legal_realm]:
		if not day.doors_open.has(realm):
			problems.append("%s: the %s door is closed that day (D40)" % [tag, realm])
	problems.append_array(_check_wrong_stamps(soul, day, rules, tag))
	problems.append_array(_check_seams(soul, day, tag))
	problems.append_array(_check_law_threads(soul, day, rules, tag))
	for pair: String in herrings:
		var ends: PackedStringArray = pair.split("|")
		var pin: PinResult = PinResolver.resolve(soul, day.decrees, ends[0], ends[1], [])
		if pin.kind != PinResult.Kind.NO_SEAM:
			problems.append("%s: red herring %s is not a no-seam pin (D24)" % [tag, pair])
	for item: EvidenceItem in soul.items:
		if item.group != EvidenceItem.Group.BODY and _font != null:
			var width: int = width_of("%s %s" % [item.id, item.text])
			if width > LINE_CAP_PX:
				problems.append(
					"%s: %s is %d px, over %d (D50)" % [tag, item.id, width, LINE_CAP_PX]
				)
	return problems


## How many lines the bubble's label wraps `text` into (word wrap, as the Label does).
func bubble_lines(text: String) -> int:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, _font, _font_size)
	paragraph.width = BUBBLE_TEXT_WIDTH
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	return paragraph.get_line_count()


## The lines that fit the bubble for a step: under the "Next" button on a READ step.
func bubble_room(step: MentorStep) -> int:
	var height: int = BUBBLE_TEXT_HEIGHT
	if step.until == MentorStep.Until.READ:
		height = BUBBLE_TEXT_HEIGHT_READ
	var line: int = int(_font.get_height(_font_size)) + _line_spacing
	# n lines take n * (font height + spacing) - spacing.
	return int((height + _line_spacing) / float(line))


## Every guided step fits the mentor's bubble, and lights only items on the desk.
func check_mentor(soul: Encounter, day: DayRules) -> Array[String]:
	var problems: Array[String] = []
	for step: MentorStep in soul.mentor_steps:
		var lines: int = bubble_lines(step.text)
		if lines > bubble_room(step):
			problems.append(
				(
					"%s: mentor step '%s' wraps to %d lines; the bubble holds %d"
					% [soul.id, step.text, lines, bubble_room(step)]
				)
			)
		for item_id: String in step.highlight:
			if _item(soul, day, item_id) == null:
				problems.append("%s: mentor step lights %s, not on the desk" % [soul.id, item_id])
		if (
			step.until == MentorStep.Until.PIN
			and soul.seam_between(step.highlight[0], step.highlight[1]) == null
		):
			problems.append(
				"%s: mentor pin step %s is not a seam" % [soul.id, "|".join(step.highlight)]
			)
	return problems


## D52: the witness heading (systems/desk/desk_system.gd writes "WITNESS " + the name) fits the
## witness panel's inner width, read from the desk scene.
func check_witness_heading(soul: Encounter) -> Array[String]:
	if soul.witness_heading_name() == "" or _font == null:
		return []
	var heading: String = WITNESS_PREFIX + soul.witness_heading_name()
	var width: int = width_of(heading)
	if width <= witness_heading_room():
		return []
	return [
		(
			"%s: the witness heading '%s' is %d px; the panel holds %d (D52)"
			% [soul.id, heading, width, witness_heading_room()]
		)
	]


## The witness panel's inner width: its width in scenes/desk/desk.tscn less the panel's padding.
func witness_heading_room() -> int:
	var scene: PackedScene = load(DESK_SCENE) as PackedScene
	if scene == null:
		return 0
	var state: SceneState = scene.get_state()
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"WitnessPanel":
			continue
		var edges: Dictionary = {}
		for property: int in state.get_node_property_count(node):
			edges[state.get_node_property_name(node, property)] = state.get_node_property_value(
				node, property
			)
		var width: float = edges.get(&"offset_right", 0.0) - edges.get(&"offset_left", 0.0)
		return int(width) - PANEL_PADDING * 2
	return 0


## The dawn card (entities/phase_card/phase_card.gd) wraps its text at the card's inner width
## and grows to fit, up to the 270 px screen less 4; more lines than that would be cut off.
func check_dawn_card(day: DayRules) -> Array[String]:
	if _font == null:
		return []
	var lines: int = 0
	for line: String in ScreenText.dawn_lines(day):
		lines += wrapped_lines(line, CARD_WIDTH - CARD_PADDING * 2)
	var room: int = int(
		(CARD_MAX_HEIGHT - CARD_PADDING * 2 - CARD_GAP - CARD_BUTTON) / float(CARD_LINE_PITCH)
	)
	if lines <= room:
		return []
	return ["the dawn card of day %d needs %d lines; the screen holds %d" % [day.day, lines, room]]


func wrapped_lines(text: String, width: int) -> int:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, _font, _font_size)
	paragraph.width = width
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	return paragraph.get_line_count()


## The souls whose wrong stamp is cited only once Huginn has answered a grey thread (D30).
func needs_huginn(soul: Encounter, day: DayRules, rules: SliceRules) -> bool:
	for realm: StringName in day.doors_open:
		if realm != soul.legal_realm:
			var record := VerdictRecord.make(soul, day.day)
			if VerdictRules.decisive_seam(record, day, rules) == null:
				return true
	return false


## D6: every fact state (label) has a seam use, and a red-herring use within `herring_souls`.
func check_coverage(
	souls: Array[Encounter], herring_souls: Array[Encounter], herrings: Dictionary
) -> Array[String]:
	var seamed: Dictionary = {}
	var herringed: Dictionary = {}
	var labels: Dictionary = {}
	for soul: Encounter in souls:
		for fact: EvidenceItem in soul.items_in(EvidenceItem.Group.BODY):
			labels[fact.text] = true
		for seam: Seam in soul.seams:
			for end: String in [seam.a, seam.b]:
				var fact: EvidenceItem = soul.item(end)
				if fact != null and fact.group == EvidenceItem.Group.BODY:
					seamed[fact.text] = true
	for soul: Encounter in herring_souls:
		var pairs: Array[String] = []
		pairs.assign(herrings.get(soul.id, []))
		for pair: String in pairs:
			for end: String in pair.split("|"):
				var fact: EvidenceItem = soul.item(end)
				if fact != null and fact.group == EvidenceItem.Group.BODY:
					herringed[fact.text] = true
	var problems: Array[String] = []
	for label: String in labels:
		if not seamed.has(label):
			problems.append("fact state '%s' has no seam use (D6)" % label)
		if not herringed.has(label):
			problems.append("fact state '%s' has no red-herring use (D6)" % label)
	return problems


## Every wrong door has a visible pair to cite, unless only a grey thread shows it (permitted
## uncertainty, D37); then Huginn must be on the desk, and his answer must make it citable.
func _check_wrong_stamps(
	soul: Encounter, day: DayRules, rules: SliceRules, tag: String
) -> Array[String]:
	var problems: Array[String] = []
	for realm: StringName in day.doors_open:
		if realm == soul.legal_realm:
			continue
		var record := VerdictRecord.make(soul, day.day)
		var seam: Seam = VerdictRules.decisive_seam(record, day, rules)
		if seam == null:
			for grey: Seam in soul.seams:
				if grey.kind == Seam.Kind.GREY:
					record.threads.append(grey)
					record.answers.append(rules.huginn_claim_answer)
			seam = VerdictRules.decisive_seam(record, day, rules)
			if seam != null and day.huginn_answers <= 0:
				problems.append("%s: a stamp to %s needs Huginn, who isn't there" % [tag, realm])
		if seam == null:
			problems.append("%s: a stamp to %s has no visible pair to cite" % [tag, realm])
			continue
		var text: String = VerdictRules.citation_text(seam, soul, day, rules, true)
		if _font != null and width_of(text) > STRIP_CAP_PX:
			problems.append("%s: the citation runs past two strip lines" % tag)
	return problems


func _check_seams(soul: Encounter, day: DayRules, tag: String) -> Array[String]:
	var problems: Array[String] = []
	var seen: Array[String] = []
	for seam: Seam in soul.seams:
		var key: String = "%s|%s" % ([seam.a, seam.b] if seam.a < seam.b else [seam.b, seam.a])
		if seen.has(key):
			problems.append("%s: %s is listed twice" % [tag, key])
		seen.append(key)
		var a: EvidenceItem = _item(soul, day, seam.a)
		var b: EvidenceItem = _item(soul, day, seam.b)
		if a == null or b == null:
			problems.append("%s: %s-%s names an item not on the desk" % [tag, seam.a, seam.b])
			continue
		var groups: Array = [a.group, b.group]
		match seam.kind:
			Seam.Kind.RED:
				if not _body_against_testimony(a, b):
					problems.append(
						"%s: red %s-%s is not body against testimony" % [tag, a.id, b.id]
					)
			Seam.Kind.GREY:
				var testimony: bool = (
					groups.has(EvidenceItem.Group.CLAIM) and groups.has(EvidenceItem.Group.WITNESS)
				)
				if not testimony:
					problems.append(
						"%s: grey %s-%s is not claim against witness" % [tag, a.id, b.id]
					)
	return problems


func _check_law_threads(
	soul: Encounter, day: DayRules, rules: SliceRules, tag: String
) -> Array[String]:
	var problems: Array[String] = []
	var lie_lines: Array[String] = []
	var grey_lines: Array[String] = []
	var reds: int = 0
	for seam: Seam in soul.seams:
		if seam.kind == Seam.Kind.RED:
			var first: EvidenceItem = _item(soul, day, seam.a)
			# Only a valid red seam counts toward R7 (the review's case: a body-body "red seam").
			if _body_against_testimony(first, _item(soul, day, seam.b)):
				reds += 1
			var body_first: bool = first != null and first.group == EvidenceItem.Group.BODY
			lie_lines.append(seam.b if body_first else seam.a)
		elif seam.kind == Seam.Kind.GREY:
			grey_lines.append_array([seam.a, seam.b])
	var grey_alone: bool = _rests_on_grey_alone(soul, day, rules)
	for seam: Seam in soul.seams:
		if seam.kind != Seam.Kind.LAW:
			continue
		var decree_id: String = seam.b if day.decree(seam.b) != null else seam.a
		var evidence_id: String = seam.a if decree_id == seam.b else seam.b
		var evidence: EvidenceItem = soul.item(evidence_id)
		var thread: String = "%s: law %s-%s" % [tag, evidence_id, decree_id]
		if evidence == null or day.decree(decree_id) == null:
			problems.append("%s links no evidence to a decree in force" % thread)
			continue
		var realm: StringName = DECREE_REALMS.get(decree_id, &"")
		if seam.destination != realm:
			problems.append(
				(
					"%s names %s, but %s sends to %s (D44)"
					% [thread, seam.destination, decree_id, realm]
				)
			)
		var expected: String = (
			"%s sends %s to %s." % [decree_id, soul.pronoun, Realm.display_name(realm)]
		)
		if not soul.liar:
			expected = SAGA_TRUE + expected
		if seam.caption != expected:
			problems.append(
				"%s caption '%s' should read '%s' (R2, R3)" % [thread, seam.caption, expected]
			)
		if not _shows_condition(evidence, decree_id):
			problems.append("%s: the evidence can't show %s's condition (R1)" % [thread, decree_id])
		if lie_lines.has(evidence_id):
			problems.append("%s: a line the body shows false makes no law thread (R4)" % thread)
		if grey_lines.has(evidence_id):
			problems.append("%s: a line of a grey seam makes no law thread (R5)" % thread)
		if grey_alone:
			problems.append(
				"%s: a soul decided by a grey seam alone has no law threads (R6)" % thread
			)
		if not seam.caption.begins_with(SAGA_TRUE) and reds == 0:
			problems.append(
				"%s: a law thread without 'the saga is true.' needs a red seam (R7)" % thread
			)
	return problems


## R1, per decree: the evidence is of the decree's group and is a line the matrix reads as
## stating its condition (CONDITION_TEXTS).
func _shows_condition(evidence: EvidenceItem, decree_id: String) -> bool:
	var groups: Array = CONDITION_GROUPS.get(decree_id, [])
	var texts: Array = CONDITION_TEXTS.get(decree_id, [])
	return groups.has(evidence.group) and texts.has(evidence.text)


## A red seam: exactly one body fact, against one claim or witness line.
func _body_against_testimony(a: EvidenceItem, b: EvidenceItem) -> bool:
	if a == null or b == null:
		return false
	var testimony: Array = [EvidenceItem.Group.CLAIM, EvidenceItem.Group.WITNESS]
	if a.group == EvidenceItem.Group.BODY:
		return testimony.has(b.group)
	return b.group == EvidenceItem.Group.BODY and testimony.has(a.group)


## R6: no red seam shows the liars' realm, so only a grey seam can decide the soul (Ketil).
func _rests_on_grey_alone(soul: Encounter, day: DayRules, rules: SliceRules) -> bool:
	if soul.legal_realm != rules.liar_realm:
		return false
	var record := VerdictRecord.make(soul, day.day)
	var has_grey: bool = false
	for seam: Seam in soul.seams:
		if seam.kind == Seam.Kind.RED and VerdictRules.shown_realm(seam, record, rules) != &"":
			return false
		has_grey = has_grey or seam.kind == Seam.Kind.GREY
	return has_grey


func _item(soul: Encounter, day: DayRules, item_id: String) -> EvidenceItem:
	var item: EvidenceItem = soul.item(item_id)
	return item if item != null else day.decree(item_id)
