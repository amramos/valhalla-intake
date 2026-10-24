extends SceneTree
## Development only: the timed play (D46), a measurement, not a verdict. Plays all three days of
## the slice as a careful player at the normal text speed, through real mouse events, and prints
## how long each soul took and how much of the 5:00 clock each day left. Run it in a window at the
## base resolution:
##
##   godot --path . --resolution 480x270 -s tools/timed_play/timed_play.gd -- <output-folder>
##
## For every soul the careful player:
## - lets the tale be told to its end by itself (a press during it would only finish it, D27);
## - reads the evidence: `READ_SECONDS_PER_LINE` for every claim and witness line;
## - makes the pins the soul's seams need, one item click and then the other, waiting for each
##   caption to be written before the next click (on day 1 it clicks the mentor's READ steps
##   on as they come);
## - stamps the soul at its legal door, by door click and confirm.
## Every click waits `HAND_SECONDS` first, as a hand moving across the desk, and never presses an
## unarmed button. Each soul prints one line, from the moment it is seated (the slam and walk-in
## count in its telling) to the moment the next soul is seated or the day ends:
##
##   SOUL <day> <name> telling=<s> reading=<s> pinning=<s> total=<s>
##
## (total also holds the stamp.) Each day prints `DAY <n> clock_left=<m:ss>` ("none" on day 1,
## which has no clock), each dawn `DAWN <day> <seconds>` (the dark card's gated time, left to run
## out by itself), and the run ends with `RAN_OUT <days>` ("none" when no day's clock ran out).
## The lines are also written to `<output-folder>/timed_play.txt`.
##
## The desk stops every clock while the game is out of focus (D35); the run hands the focus
## straight back (`_notification`), but run it with no other Godot window open.

const TITLE_SCENE := "res://scenes/title/title.tscn"
## The slice's days; the run stops when the last one's desk closes.
const LAST_DAY := 3
## Seconds a careful player reads each claim and witness line.
const READ_SECONDS_PER_LINE := 1.5
## Seconds the hand takes to reach the next thing it clicks.
const HAND_SECONDS := 0.5
## No wait for the desk takes longer than this; a longer wait is a failure, not a hang.
const MAX_WAIT_SECONDS := 30.0
## Mentor READ steps acknowledged at most per soul, so a stuck bubble cannot loop.
const MAX_MENTOR_STEPS := 8

var _out: String = ""
var _desk: Desk = null
var _failures: int = 0
var _lines: PackedStringArray = []
## The clock's time left as last sampled on the desk today (INF when untimed).
var _clock_left: float = INF
## The days whose clock ran out (the horn).
var _ran_out: PackedStringArray = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	var title: Node = (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	_run.call_deferred()


## The engine has just told the scene a focus loss; tell it the focus came back, so the desk's
## clocks run on under the pushed events (the header).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and root != null:
		root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)


func _run() -> void:
	await _frames(3)
	var title: TitleScreen = current_scene as TitleScreen
	await _wait(HAND_SECONDS)
	await _click_control(title.start_button())
	await _frames(4)
	_desk = current_scene as Desk
	_expect(_desk != null, "Start opens the desk")
	if _desk == null:
		_finish()
		return
	_desk.use_options(Options.new())
	_desk.commands().horn.connect(_on_horn)
	for day: int in range(1, LAST_DAY + 1):
		_expect(_desk.commands().day_number() == day, "day %d dawns" % day)
		await _dawn(day)
		_clock_left = _desk.commands().time_left()
		await _play_day(day)
		var left: String = "none" if is_inf(_clock_left) else _clock_text(_clock_left)
		_emit("DAY %d clock_left=%s" % [day, left])
		if day < LAST_DAY:
			await _dusk(day)
	_emit("RAN_OUT %s" % ("none" if _ran_out.is_empty() else " ".join(_ran_out)))
	_finish()


func _finish() -> void:
	_emit("TIMED PLAY: %s" % ("PASS" if _failures == 0 else "%d FAILED" % _failures))
	var file: FileAccess = FileAccess.open(_out.path_join("timed_play.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
		file.close()
	quit(0 if _failures == 0 else 1)


## The dark "DAY N" card, left to end by itself, then Odin's writ and its Begin tab.
func _dawn(day: int) -> void:
	var writ: DawnWrit = _desk.system().dawn_writ
	var gate: PresentationGate = _desk.gate()
	await _frames(2)
	_expect(writ.is_showing_card(), "day %d dawns on the dark card" % day)
	await _until(func() -> bool: return not writ.is_showing_card(), "the dark card ends by itself")
	_emit("DAWN %d %.2f" % [day, gate.gated_seconds()])
	gate.reset_gated_seconds()
	await _click_button(writ.next_button())
	_expect(_desk.commands().phase() == RunState.DESK, "Begin opens the desk on day %d" % day)


## Plays every soul of the day until the desk closes (the last stamp or the horn).
func _play_day(day: int) -> void:
	var commands: DeskCommands = _desk.commands()
	for _guard: int in range(16):
		if commands.phase() != RunState.DESK:
			return
		if commands.awaiting_next():
			_expect(false, "a legal stamp held the desk on day %d" % day)
			await _click_control(_desk.system().stamp_flow.stamp_prompt.writ())
			continue
		await _play_soul(day)


## One soul, from its seat to the next soul's (or the day's end).
func _play_soul(day: int) -> void:
	var commands: DeskCommands = _desk.commands()
	var system: DeskSystem = _desk.system()
	var encounter: Encounter = commands.current_encounter()
	var name: String = encounter.soul_name
	var start: int = Time.get_ticks_msec()
	# The slam and walk-in come first: the tale is told once the soul's evidence is on the desk.
	await _until(func() -> bool: return not system.stamp_flow.is_slamming(), "the slam releases")
	await _frames(2)
	await _until(func() -> bool: return not system.is_telling(), "%s's tale ends" % name)
	var told: int = Time.get_ticks_msec()
	var lines: int = encounter.items_in(EvidenceItem.Group.CLAIM).size()
	lines += encounter.items_in(EvidenceItem.Group.WITNESS).size()
	await _wait(lines * READ_SECONDS_PER_LINE)
	_sample_clock()
	var read: int = Time.get_ticks_msec()
	for seam: Seam in encounter.seams:
		await _ack_mentor()
		if not _seated(encounter):
			break
		await _click_item(seam.a)
		await _click_item(seam.b)
		_expect(commands.threads().has(seam) or not _seated(encounter), "%s pinned" % seam.caption)
	await _ack_mentor()
	_sample_clock()
	var pinned: int = Time.get_ticks_msec()
	if _seated(encounter):
		await _stamp(encounter)
	var end: int = Time.get_ticks_msec()
	var times: Array[float] = [
		(told - start) / 1000.0, (read - told) / 1000.0, (pinned - read) / 1000.0
	]
	var line: String = "SOUL %d %s telling=%.1f reading=%.1f pinning=%.1f total=%.1f"
	_emit(line % [day, name, times[0], times[1], times[2], (end - start) / 1000.0])


## The legal door's click, the confirm, and the wait for the next soul (or the day's end).
func _stamp(encounter: Encounter) -> void:
	var commands: DeskCommands = _desk.commands()
	var prompt: StampPrompt = _desk.system().stamp_flow.stamp_prompt
	await _settle()
	await _click_control(_door(encounter.legal_realm))
	_expect(prompt.is_asking(), "the %s door raises the stamp" % encounter.legal_realm)
	_sample_clock()
	await _click_button(prompt.confirm_button())
	await _until(
		func() -> bool: return not _seated(encounter) or commands.awaiting_next(),
		"%s is stamped" % encounter.soul_name
	)
	if commands.awaiting_next():
		_expect(false, "the legal stamp of %s held the desk" % encounter.soul_name)
		await _click_control(prompt.writ())


## Clicks every READ step the mentor shows on, once her words are written and the bubble armed.
func _ack_mentor() -> void:
	var bubble: MentorBubble = _desk.system().mentor_bubble
	for _step: int in range(MAX_MENTOR_STEPS):
		await _settle()
		if not bubble.wants_ack() or _desk.commands().phase() != RunState.DESK:
			return
		await _until(bubble.is_armed, "the mentor's bubble arms")
		await _wait(HAND_SECONDS)
		var at: Vector2 = bubble.get_global_rect().position + bubble.arrow_rect().get_center()
		await _hover_at(at)
		await _press(at)


## A click on a body fact, a claim or witness line or a decree, once the desk is still.
func _click_item(item_id: String) -> void:
	var system: DeskSystem = _desk.system()
	var target: Control = system.body_chart.area(item_id)
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel, system.law_panel]:
		if target == null and panel.has_item(item_id):
			target = panel.area(item_id)
	_expect(target != null, "item %s is on the desk" % item_id)
	if target == null:
		return
	await _settle()
	await _wait(HAND_SECONDS)
	await _click_control(target)


## Waits until no presentation would take a press: no writing, no slam.
func _settle() -> void:
	var gate: PresentationGate = _desk.gate()
	await _until(
		func() -> bool: return not gate.is_consuming() and not gate.is_slamming(),
		"the desk settles"
	)


## Waits for the hand, then for the button to arm, and clicks it.
func _click_button(button: GuardedButton) -> void:
	await _settle()
	await _wait(HAND_SECONDS)
	await _until(button.is_armed, "%s arms" % button.name)
	await _click_control(button)


## Notes the clock's time left while today's desk is open.
func _sample_clock() -> void:
	if _desk.commands().phase() == RunState.DESK:
		_clock_left = _desk.commands().time_left()


func _on_horn() -> void:
	_clock_left = 0.0
	_ran_out.append(str(_desk.commands().day_number()))


## Presses Next through the day-book's spreads, each once its ink is dry, until the next dawn.
func _dusk(day: int) -> void:
	var book: DayBook = _desk.system().day_book
	for _page: int in range(10):
		await _frames(2)
		await _until(func() -> bool: return not book.is_writing(), "the day-book's ink dries")
		await _click_button(book.next_button())
		if _desk.commands().phase() == RunState.DAWN and _desk.commands().day_number() > day:
			_desk.gate().reset_gated_seconds()
			return
	_expect(false, "day %d's dusk leads to the next dawn" % day)


## True while `encounter` is the soul being judged at an open desk.
func _seated(encounter: Encounter) -> bool:
	var commands: DeskCommands = _desk.commands()
	return commands.phase() == RunState.DESK and commands.current_encounter() == encounter


func _until(condition: Callable, what: String) -> void:
	var start: int = Time.get_ticks_msec()
	while not condition.call() and Time.get_ticks_msec() - start < MAX_WAIT_SECONDS * 1000.0:
		await process_frame
	_expect(condition.call(), "%s within %d s" % [what, MAX_WAIT_SECONDS])


static func _clock_text(seconds: float) -> String:
	var whole: int = ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


func _emit(line: String) -> void:
	print(line)
	_lines.append(line)


func _expect(condition: bool, what: String) -> void:
	if not condition:
		_failures += 1
		_emit("FAIL: " + what)


func _door(realm: StringName) -> Door:
	for door: Door in _desk.system().doors:
		if door.realm == realm:
			return door
	return null


func _hover_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = motion.position
	root.push_input(motion)
	await _frames(2)


func _click_control(target: Control) -> void:
	var at: Vector2 = target.get_global_rect().get_center()
	await _hover_at(at)
	await _press(at)


func _press(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		root.push_input(event)
		await _frames(1)
	await _frames(2)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
