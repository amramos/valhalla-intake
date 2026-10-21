extends RefCounted
## The text harness (D13): runs commands on DeskCommands as the desk does, screen by screen
## (title, dawn, desk, dusk cards, ending, pause), and prints only what the desk shows (DeskView).

const DeskView := preload("res://tools/harness/desk_view.gd")
## Simulated reading time per stamp; thinking time is not simulated, only action costs.
const STAMP_SECONDS := 20.0

var desk: DeskCommands
var view: DeskView
## Whether the last act() was a command the desk accepted.
var last_ok: bool = false

var _horn: bool = false
## The screen a declined confirm returns to.
var _back: StringName = DeskView.PAUSED
var _warning: bool = false


## at_title: start on the title screen, as the game does (play.gd); tests start at dawn.
func _init(p_desk: DeskCommands, at_title: bool = false) -> void:
	desk = p_desk
	view = DeskView.new(desk)
	if at_title:
		view.screen = DeskView.TITLE
	desk.set_stamp_seconds(STAMP_SECONDS)
	desk.horn.connect(_on_horn)
	desk.clock_warning.connect(_on_warning)


func act(command: String) -> String:
	last_ok = true
	_horn = false
	_warning = false
	var words: PackedStringArray = command.strip_edges().split(" ", false)
	if words.is_empty() or words[0] == "look":
		return ""
	var text: String = _run(words)
	view.phases.sync(desk)
	if _warning:
		text += "\nThirty seconds left."
	if _horn:
		text += "\nThe horn sounds. The day is over."
	return text


func describe() -> String:
	return view.describe()


func actions() -> String:
	return view.actions()


func _run(words: PackedStringArray) -> String:
	var handlers: Dictionary = {
		"begin": _cmd_begin,
		"pin": _cmd_pin,
		"huginn": _cmd_huginn,
		"buy": _cmd_buy,
		"stamp": _cmd_stamp,
		"next": _cmd_next,
		"restart": _cmd_restart,
		"jump": _cmd_jump,
		"wait": _cmd_wait,
		"ack": _cmd_ack,
		"skip": _cmd_skip,
		"pause": _cmd_pause,
	}
	var text: String = ""
	if view.screen != &"":
		text = _overlay(words[0])
	elif handlers.has(words[0]):
		text = (handlers[words[0]] as Callable).call(words)
	return text if text != "" else _refuse("You can't do that now: %s" % " ".join(words))


func _cmd_begin(_words: PackedStringArray) -> String:
	if desk.phase() != &"dawn":
		return ""
	desk.begin_day()
	view.caption = ""
	return "The desk opens. %s waits." % _soul_name()


func _cmd_pin(words: PackedStringArray) -> String:
	if desk.phase() != &"desk" or words.size() != 3:
		return ""
	return _pin(words[1].to_upper(), words[2].to_upper())


func _cmd_huginn(words: PackedStringArray) -> String:
	if desk.phase() != &"desk" or words.size() != 2 or not words[1].is_valid_int():
		return ""
	return _ask(words[1].to_int())


func _cmd_buy(_words: PackedStringArray) -> String:
	if not desk.buy_huginn_answer():
		return ""
	return (_text().huginn_bought_format % "").strip_edges()


func _cmd_stamp(words: PackedStringArray) -> String:
	if desk.phase() != &"desk" or words.size() != 2:
		return ""
	return _stamp(_realm(words[1]))


## "next" calls the next soul after a citation (D48); at dusk it turns the card, and after the
## last card it opens the next dawn, or after day 3's dusk the ending (PhaseFlow, as on the desk).
func _cmd_next(_words: PackedStringArray) -> String:
	if desk.awaiting_next():
		desk.next_soul()
		if desk.phase() == &"desk":
			return "Next at the desk: %s." % _soul_name()
		return "The last soul is gone; the day is over."
	if not _at_dusk_cards():
		return ""
	view.phases.advance(desk)
	return _after_cards()


## "skip" is dusk's "Skip all": straight to the next dawn, or the ending after day 3; nothing with
## consequences is lost (D15).
func _cmd_skip(_words: PackedStringArray) -> String:
	if not _at_dusk_cards():
		return ""
	view.phases.skip(desk)
	return _after_cards()


## A dusk card shows: the dusk, or day 3's dusk before the ending.
func _at_dusk_cards() -> bool:
	view.phases.sync(desk)
	var ending: bool = desk.phase() == &"ending" and not view.phases.showing_ending()
	return desk.phase() == &"dusk" or ending


func _after_cards() -> String:
	if desk.phase() == &"dawn":
		return "Dawn of day %d." % desk.day_number()
	if view.phases.showing_ending():
		return "The ending: %s." % ScreenText.ending_lines(desk.ending(), desk.slice_rules())[0]
	return "%s (card %d)" % [_text().next_label, view.phases.card_index() + 1]


## At the ending "restart" is "Play again"; on the desk or at dusk it opens the pause menu's
## confirm (D31).
func _cmd_restart(_words: PackedStringArray) -> String:
	if _at_ending():
		return _restart()
	_pause()
	view.screen = DeskView.CONFIRM_RESTART
	return _text().restart_confirm


func _cmd_pause(_words: PackedStringArray) -> String:
	if _at_ending():
		return ""
	_pause()
	return _text().pause_title


## Commands on a screen over the run: the title, the pause menu and its confirms (D31).
func _overlay(command: String) -> String:
	var key: String = "%s %s" % [view.screen, command]
	if key == "confirm_restart yes":
		return _restart()
	var t: DeskText = _text()
	var moves: Dictionary = {
		"title start": [&"", "Day %d dawns." % desk.day_number()],
		"title quit": [DeskView.CONFIRM_QUIT, t.quit_confirm],
		"paused quit": [DeskView.CONFIRM_QUIT, t.quit_confirm],
		"paused resume": [&"", t.resume_label],
		"paused restart": [DeskView.CONFIRM_RESTART, t.restart_confirm],
		"confirm_quit yes": [DeskView.CLOSED, t.quit_label],
		"confirm_quit no": [_back, t.confirm_no],
		"confirm_restart no": [DeskView.PAUSED, t.confirm_no],
	}
	if not moves.has(key):
		return ""
	if view.screen in [DeskView.TITLE, DeskView.PAUSED]:
		_back = view.screen
	view.screen = moves[key][0]
	desk.set_paused(view.screen != &"" and view.screen != DeskView.TITLE)
	return moves[key][1]


func _at_ending() -> bool:
	view.phases.sync(desk)
	return desk.phase() == &"ending" and view.phases.showing_ending()


func _pause() -> void:
	desk.set_paused(true)
	view.screen = DeskView.PAUSED


func _restart() -> String:
	view.phases.reset()
	desk.restart_run()
	view.screen = &""
	view.caption = ""
	return "The run restarts at the dawn of day 1."


## Debug: jump <day> <soul> [mercy].
func _cmd_jump(words: PackedStringArray) -> String:
	if words.size() < 3 or not words[1].is_valid_int() or not words[2].is_valid_int():
		return ""
	view.phases.reset()
	desk.debug_jump(words[1].to_int(), words[2].to_int(), words.has("mercy"))
	view.caption = ""
	return "(debug) Jumped to day %d, soul %s." % [desk.day_number(), _soul_name()]


## "ack" finishes the mentor's READ step.
func _cmd_ack(_words: PackedStringArray) -> String:
	var step: MentorStep = desk.mentor_step()
	if step == null or step.until != MentorStep.Until.READ:
		return ""
	desk.mentor_ack()
	return "You nod to the mentor."


## Debug: wait <seconds> of real time on the desk.
func _cmd_wait(words: PackedStringArray) -> String:
	if words.size() != 2 or not words[1].is_valid_float():
		return ""
	desk.advance_time(words[1].to_float())
	return "(debug) %s seconds pass." % words[1]


func _pin(a: String, b: String) -> String:
	var result: PinResult = desk.pin(a, b)
	match result.kind:
		PinResult.Kind.THREAD, PinResult.Kind.ALREADY:
			view.caption = _text().thread_format % [a, b, result.seam.caption]
			var kind: String = DeskView.KIND_NAMES[result.seam.kind]
			var line: String = "A %s thread. %s" % [kind, view.caption]
			if result.mentor_line != "":
				line += "\nThe mentor: %s" % result.mentor_line
			return line
		PinResult.Kind.NO_SEAM:
			if result.seconds_lost > 0.0:
				return _text().no_seam_timed_format % roundi(result.seconds_lost)
			return _text().no_seam_line
	return _refuse("Those can't be pinned: %s and %s." % [a, b])


func _ask(number: int) -> String:
	var answer: String = desk.ask_huginn(number - 1)
	if answer == "":
		return _refuse("Huginn doesn't answer that.")
	return "Thread %d. %s" % [number, answer]


func _stamp(realm: StringName) -> String:
	var soul: String = _soul_name()
	var result: StampResult = desk.stamp(realm)
	if not result.valid:
		return _refuse("That door is closed.")
	var lines: Array[String] = ["%s goes through to %s." % [soul, Realm.display_name(realm)]]
	if result.warning:
		lines.append("A warning, no feathers today: %s" % result.citation_text)
	if result.citation:
		lines.append(
			"A black feather drops (-%d): %s" % [result.citation_loss, result.citation_text]
		)
	if result.mentor_line != "":
		lines.append("The mentor: %s" % result.mentor_line)
	if result.reward > 0:
		lines.append("Hel pays %d feathers." % result.reward)
	if result.demoted:
		lines.append(_text().demoted_format % [desk.rank_name(), desk.feathers()])
	view.caption = ""
	if desk.awaiting_next():
		lines.append("%s stays on the desk with the black feather until you call: next." % soul)
	elif desk.phase() == &"desk":
		lines.append("Next at the desk: %s." % _soul_name())
	return "\n".join(lines)


func _text() -> DeskText:
	return desk.slice_rules().text


func _soul_name() -> String:
	var soul: Encounter = desk.current_encounter()
	return soul.soul_name if soul != null else "nobody"


func _realm(word: String) -> StringName:
	match word.to_lower():
		"valhalla":
			return Realm.VALHALLA
		"folkvangr", "fólkvangr":
			return Realm.FOLKVANGR
		"hel":
			return Realm.HEL
		"ran", "rán":
			return Realm.RAN
	return &""


func _refuse(text: String) -> String:
	last_ok = false
	return text


func _on_horn() -> void:
	_horn = true


func _on_warning() -> void:
	_warning = true
