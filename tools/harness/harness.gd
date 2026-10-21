extends RefCounted
## The text harness (D13): runs commands on DeskCommands as the desk does, and prints only what
## the desk shows (through DeskView).

const DeskView := preload("res://tools/harness/desk_view.gd")
## Simulated reading time per stamp; thinking time is not simulated, only action costs.
const STAMP_SECONDS := 20.0

var desk: DeskCommands
var view: DeskView
## Whether the last act() was a command the desk accepted.
var last_ok: bool = false

var _horn: bool = false
var _warning: bool = false


func _init(p_desk: DeskCommands) -> void:
	desk = p_desk
	view = DeskView.new(desk)
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
	}
	var text: String = ""
	if handlers.has(words[0]):
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
	return "Huginn takes 2 feathers for one more answer."


func _cmd_stamp(words: PackedStringArray) -> String:
	if desk.phase() != &"desk" or words.size() != 2:
		return ""
	return _stamp(_realm(words[1]))


## "next" calls the next soul after a citation (D48), or the next dawn at dusk.
func _cmd_next(_words: PackedStringArray) -> String:
	if desk.awaiting_next():
		desk.next_soul()
		if desk.phase() == &"desk":
			return "Next at the desk: %s." % _soul_name()
		return "The last soul is gone; the day is over."
	if desk.phase() != &"dusk":
		return ""
	desk.next_day()
	return "Dawn of day %d." % desk.day_number()


func _cmd_restart(_words: PackedStringArray) -> String:
	desk.restart_run()
	view.caption = ""
	return "The run restarts at the dawn of day 1."


## Debug: jump <day> <soul> [mercy].
func _cmd_jump(words: PackedStringArray) -> String:
	if words.size() < 3 or not words[1].is_valid_int() or not words[2].is_valid_int():
		return ""
	desk.debug_jump(words[1].to_int(), words[2].to_int(), words.has("mercy"))
	view.caption = ""
	return "(debug) Jumped to day %d, soul %s." % [desk.day_number(), _soul_name()]


## Debug: wait <seconds> of real time on the desk.
func _cmd_wait(words: PackedStringArray) -> String:
	if words.size() != 2 or not words[1].is_valid_float():
		return ""
	desk.advance_time(words[1].to_float())
	return "(debug) %s seconds pass." % words[1]


func _pin(a: String, b: String) -> String:
	var result: PinResult = desk.pin(a, b)
	match result.kind:
		PinResult.Kind.THREAD:
			view.caption = result.seam.caption
			return "A %s thread: %s" % [DeskView.KIND_NAMES[result.seam.kind], result.seam.caption]
		PinResult.Kind.ALREADY:
			view.caption = result.seam.caption
			return "Already threaded: %s" % result.seam.caption
		PinResult.Kind.NO_SEAM:
			if result.seconds_lost > 0.0:
				return "No seam. The clock loses %d s." % int(result.seconds_lost)
			return "No seam."
	return _refuse("Those can't be pinned: %s and %s." % [a, b])


func _ask(number: int) -> String:
	var answer: String = desk.ask_huginn(number - 1)
	if answer == "":
		return _refuse("Huginn doesn't answer that.")
	return "Huginn, on thread %d: %s" % [number, answer]


func _stamp(realm: StringName) -> String:
	var soul: String = _soul_name()
	var result: StampResult = desk.stamp(realm)
	if not result.valid:
		return _refuse("That door is closed.")
	var lines: Array[String] = ["%s goes through to %s." % [soul, Realm.display_name(realm)]]
	if result.warning:
		lines.append(
			"The mentor warns: %s From tomorrow, that costs feathers." % result.citation_text
		)
	if result.citation:
		lines.append(
			"A black feather drops (-%d): %s" % [result.citation_loss, result.citation_text]
		)
	if result.reward > 0:
		lines.append("Hel pays %d feathers." % result.reward)
	if result.demoted:
		lines.append("Demoted: %s. Feathers refilled." % desk.rank_name())
	view.caption = ""
	if desk.awaiting_next():
		lines.append("%s stays on the desk with the black feather until you call: next." % soul)
	elif desk.phase() == &"desk":
		lines.append("Next at the desk: %s." % _soul_name())
	return "\n".join(lines)


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
