extends RefCounted
## What the desk shows, as text, screen by screen (D13): the title, the dawn card, the desk, the
## dusk cards, the ending and the pause menu. Flow text comes from ScreenText and DeskText, the
## same text the screens draw, and the cards between souls follow the desk's own PhaseFlow: day
## 3's dusk, then the ending. It reads only DeskCommands' getters, never a legal or worthy
## destination, the seam list or the truth, except what the dusk recap and the ending reveal by
## design (D15, D23).

const DOORS: Array[StringName] = [Realm.VALHALLA, Realm.FOLKVANGR, Realm.HEL]
## Thread names by Seam.Kind; the line pattern on the desk.
const KIND_NAMES: Array[String] = ["red", "grey", "law"]
const TITLE := &"title"
const PAUSED := &"paused"
const CONFIRM_RESTART := &"confirm_restart"
const CONFIRM_QUIT := &"confirm_quit"
const CLOSED := &"closed"

var desk: DeskCommands
## The newest thread caption on this soul (the caption strip).
var caption: String = ""
## A screen over the run: TITLE, PAUSED, a confirm, CLOSED; &"" shows the run itself.
var screen: StringName = &""
## The place in the dusk cards and the ending, as on the desk.
var phases := PhaseFlow.new()


func _init(p_desk: DeskCommands) -> void:
	desk = p_desk


func text() -> DeskText:
	return desk.slice_rules().text


func describe() -> String:
	if screen != &"":
		return _describe_overlay()
	match desk.phase():
		&"dawn":
			return _describe_dawn()
		&"desk":
			return _describe_desk()
	return _describe_cards()


## The title, the pause menu and its confirms, with D31's labels.
func _describe_overlay() -> String:
	var t: DeskText = text()
	var choice: String = "%s\n  %s / %s"
	var pause: Array[String] = [t.resume_label, t.restart_label, t.quit_label]
	var screens: Dictionary = {
		TITLE: "== %s ==\n  %s\n  %s" % [t.title_name, t.start_label, t.quit_label],
		PAUSED: "== %s ==\n  %s" % [t.pause_title, "\n  ".join(pause)],
		CONFIRM_RESTART: choice % [t.restart_confirm, t.confirm_yes, t.confirm_no],
		CONFIRM_QUIT: choice % [t.quit_confirm, t.confirm_yes, t.confirm_no],
		CLOSED: "(the game has quit)",
	}
	return screens.get(screen, "")


func actions() -> String:
	var lines: Array[String] = ["Actions:"]
	match screen:
		TITLE:
			return (
				"Actions:\n  start                 %s\n  quit                  %s"
				% [text().start_label, text().quit_label]
			)
		PAUSED:
			return "Actions:\n  resume\n  restart\n  quit"
		CONFIRM_RESTART, CONFIRM_QUIT:
			return "Actions:\n  yes\n  no"
		CLOSED:
			return "Actions: none"
	match desk.phase():
		&"dawn":
			lines.append("  begin                 %s" % text().begin_label)
		&"desk":
			if desk.awaiting_next():
				lines.append("  next                  call the next soul")
			else:
				lines.append_array(_desk_actions())
		&"dusk", &"ending":
			var card: PhaseFlow.Card = phases.card(desk)
			if phases.showing_ending():
				lines.append("  restart               %s" % card.next_label)
				return "\n".join(lines)
			lines.append("  next                  %s" % card.next_label)
			if card.skip_label != "":
				lines.append("  skip                  %s" % card.skip_label)
	lines.append("  pause                 %s" % text().pause_title)
	return "\n".join(lines)


func dusk_cards() -> Array[String]:
	return ScreenText.dusk_cards(desk.dusk_report(), desk.slice_rules())


func _describe_dawn() -> String:
	var day: DayRules = desk.day_rules()
	var lines: Array[String] = ["== Day %d, dawn ==" % day.day]
	lines.append_array(ScreenText.dawn_lines(day))
	lines.append(_ledger())
	return "\n".join(lines)


func _describe_desk() -> String:
	var day: DayRules = desk.day_rules()
	var soul: Encounter = desk.current_encounter()
	var position: Vector2i = desk.queue_position()
	var lines: Array[String] = ["== Day %d, soul %d of %d ==" % [day.day, position.x, position.y]]
	var quota: Vector2i = desk.quota_progress()
	var hud: String = (
		"Clock: %s | Feathers: %d | Quota: %d/%d" % [_clock(), desk.feathers(), quota.x, quota.y]
	)
	if day.huginn_answers > 0:
		hud += " | Huginn: %d (%s)" % [desk.huginn_left(), text().huginn_extra_hover]
	lines.append(hud)
	lines.append(_ledger())
	lines.append("Doors: %s" % _doors())
	lines.append(_tide())
	var plate: String = "At the desk: %s" % soul.soul_name
	if soul.returned:
		plate += " (frost-burned name plate)"
	if soul.hel_marked:
		plate += " (serpent mark)"
	if soul.plate_label != "":
		plate += " [plate: %s]" % soul.plate_label
	lines.append(plate)
	for view: StringName in [&"front", &"back"]:
		lines.append("Body, %s:" % view)
		for item: EvidenceItem in soul.items_in(EvidenceItem.Group.BODY):
			if item.view == view:
				lines.append("  %s  %s" % [item.id, item.text])
	lines.append("Claim:")
	lines.append_array(_lines_of(soul, EvidenceItem.Group.CLAIM))
	var witness: Array[String] = _lines_of(soul, EvidenceItem.Group.WITNESS)
	if not witness.is_empty():
		var heading: String = "WITNESS %s" % soul.witness_heading_name()
		if soul.witness_role() != "":
			heading += " (%s)" % soul.witness_role()
		lines.append(heading)
		lines.append_array(witness)
	elif soul.witness_note != "":
		lines.append("Witness: %s" % soul.witness_note)
	lines.append("The Law:")
	lines.append_array(_law_lines())
	lines.append_array(_thread_lines())
	lines.append_array(_mentor_lines())
	if caption != "":
		lines.append("Caption: %s" % caption)
	var held: StampResult = desk.pending_stamp()
	if held != null:
		lines.append("Black feather: %s" % held.citation_text)
		lines.append("Lit pair: %s and %s" % [held.citation_a, held.citation_b])
		lines.append("%s has been stamped; the next soul waits." % soul.soul_name)
	return "\n".join(lines)


## A dusk card (day 3's too, before the ending), or the ending itself, as PhaseFlow shows them.
func _describe_cards() -> String:
	var card: PhaseFlow.Card = phases.card(desk)
	if phases.showing_ending():
		return card.body
	var heading: String = (
		"== %s Card %d of %d ==" % [card.title, phases.card_index() + 1, phases.card_count()]
	)
	var lines: Array[String] = [heading, card.body]
	lines.append(_tide())
	lines.append(_ledger())
	return "\n".join(lines)


func _desk_actions() -> Array[String]:
	var ids: Array[String] = []
	for item: EvidenceItem in desk.visible_items():
		ids.append(item.id)
	var lines: Array[String] = ["  pin <id> <id>         ids: %s" % " ".join(ids)]
	var step: MentorStep = desk.mentor_step()
	if step != null and step.until == MentorStep.Until.READ:
		lines.append("  ack                   the mentor's next step")
	var greys: Array[String] = []
	var threads: Array[Seam] = desk.threads()
	for index: int in threads.size():
		if threads[index].kind == Seam.Kind.GREY and desk.thread_answer(index) == "":
			greys.append(str(index + 1))
	if desk.day_rules().huginn_answers > 0:
		if not greys.is_empty() and desk.huginn_left() > 0:
			lines.append("  huginn <thread>       ask about grey thread %s" % " or ".join(greys))
		elif desk.huginn_left() == 0:
			lines.append("  buy                   %s" % text().huginn_extra_hover)
	var open: Array[String] = []
	for realm: StringName in desk.day_rules().doors_open:
		open.append(String(realm))
	lines.append("  stamp <realm>         open doors: %s" % ", ".join(open))
	return lines


func _thread_lines() -> Array[String]:
	var threads: Array[Seam] = desk.threads()
	var lines: Array[String] = ["Threads: none" if threads.is_empty() else "Threads:"]
	for index: int in threads.size():
		var seam: Seam = threads[index]
		var line: String = (
			"  %d. %s-%s %s thread" % [index + 1, seam.a, seam.b, KIND_NAMES[seam.kind]]
		)
		if seam.kind == Seam.Kind.GREY:
			line += " (knot)"
		line += ": %s" % seam.caption
		if desk.thread_answer(index) != "":
			line += " [%s]" % desk.thread_answer(index)
		lines.append(line)
	return lines


func _law_lines() -> Array[String]:
	var day: DayRules = desk.day_rules()
	var lines: Array[String] = []
	for decree: EvidenceItem in day.decrees:
		var mark: String = ""
		if desk.shows_new_marks() and day.new_decree_ids.has(decree.id):
			mark = " [NEW]"
		lines.append("  %s  %s%s" % [decree.id, decree.text, mark])
	return lines


func _lines_of(soul: Encounter, group: EvidenceItem.Group) -> Array[String]:
	var lines: Array[String] = []
	for item: EvidenceItem in soul.items_in(group):
		lines.append('  %s  "%s"' % [item.id, item.text])
	return lines


func _doors() -> String:
	var day: DayRules = desk.day_rules()
	var parts: Array[String] = []
	for realm: StringName in DOORS:
		var state: String = "open"
		if not day.doors_open.has(realm):
			var opens: int = desk.door_open_day(realm)
			state = "closed until day %d" % opens if opens > day.day else "closed"
		elif desk.shows_new_marks() and day.new_doors.has(realm):
			state = "open [NEW]"
		parts.append("%s (%s)" % [Realm.display_name(realm), state])
	return ", ".join(parts)


## The figures at Hel's door, with empty slots up to the threshold (D21).
func _tide() -> String:
	return "Hel's tide: %d of %d" % [desk.hel_tide(), desk.slice_rules().tide_threshold]


## The mentor's bubble on a guided soul (D16): her words, what she lights, what finishes it.
func _mentor_lines() -> Array[String]:
	var step: MentorStep = desk.mentor_step()
	if step == null:
		return []
	var line: String = "The mentor: %s" % step.text
	if not step.highlight.is_empty():
		line += " [lit: %s]" % ", ".join(step.highlight)
	if step.door != &"":
		line += " [points at the %s door]" % Realm.display_name(step.door)
	var waits: Array[String] = ["ack to go on", "pin the lit pair", "stamp"]
	line += " (%s)" % waits[step.until]
	return [line]


## The ledger tray: its one entry, in every phase once Hel has asked (D3, D15).
func _ledger() -> String:
	var entry: String = desk.ledger_line()
	return "%s: %s" % [text().ledger_title, entry if entry != "" else text().ledger_empty]


func _clock() -> String:
	var left: float = desk.time_left()
	return "untimed" if left == INF else ScreenText.clock_text(left)
