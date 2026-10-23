class_name StampFlow
extends Node
## The stamp, from choice to consequence (D9, D14, D15, D48). A door click (or a soul dragged over
## an open door) raises the stamp over the soul's writ; only a click on the stamp, or dropping the
## soul on the door, commits, and any other click or a right-click puts it down. The commit slams:
## the slam window opens (the gate ignores every press), core records the stamp, then one tween
## runs the 70 ms hold, the thud with the desk's jolt and the glyph inked on the writ, the door's
## flare, and at the walk's start the window closes: the writ is swept off, the soul walks through
## its door and the next soul walks in. A stamp with a citation (or a day-1 warning) holds the soul,
## its writ, its lit pair and the black feather on the desk; a click on the held writ ("Send it
## on") lets it walk. Nothing in the slam reads the truth (D14). No undo.

## The cited pair to light (or [] to clear), for the desk system that owns highlights.
signal pair_lit(pair: Array[String])
## Any half-made pin must be dropped (a stamp just happened).
signal selection_cleared

## From the press: the hold before the impact, the stamp on the paper before the flare, and the
## whole slam window (the one block, D27), after which the walk begins.
const HOLD_SECONDS := 0.07
const IMPACT_SECONDS := 0.1
const SLAM_SECONDS := 0.5
const WALK_SECONDS := 0.5
const JOLT_PX := 2
const JOLT_SECONDS := 0.1

@export var doors: Array[Door] = []
@export var stamp_prompt: StampPrompt
@export var soul: WaitingSoul
@export var feather: ClickableSprite
## The old "Next soul" button, if the desk still has one; the held writ replaces it (D15).
@export var next_soul_button: Button = null
@export var caption_strip: CaptionStrip
@export var thud_player: AudioStreamPlayer
## Where the walking soul is drawn (above the gate band, under the desk's panels).
@export var walk_layer: Control

var commands: DeskCommands = null
## Owns the slam window and watches the slam's tweens and sound (pause, restart); optional.
var gate: PresentationGate = null
## The desk band's jolt, called as jolt(px, seconds); optional.
var jolt_callback: Callable = Callable()
## Reduce motion (D37) makes the jolt, the walks and the sweep instant; null reads as off.
var options: Options = null

var _citation: String = ""
var _cited_pair: Array[String] = []
## True from the commit until the walk begins.
var _slamming: bool = false
## The slam and the walk after it (or a held soul's walk); null once over.
var _slam: Tween = null
## The stamped soul standing through the slam, then walking; null once its walk has ended.
var _leaving: SoulWalk = null
## A held soul, kept from its stamp for the walk that "Send it on" starts.
var _held: SoulWalk = null
## The mentor's comment on the last stamp: shown over the next soul, and again on a click on her.
var _mentor_line: String = ""
var _carry_mentor: bool = false
## Her comment on a held stamp waits behind the citation's hold; true until the strip shows it.
var _mentor_unseen: bool = false


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	commands.stamped.connect(_on_stamped)
	for door: Door in doors:
		door.door_clicked.connect(ask)
		door.drag_hovered.connect(ask)
		door.dropped.connect(_commit)
	stamp_prompt.confirmed.connect(_commit)
	stamp_prompt.cancelled.connect(_clear_door_selection)
	stamp_prompt.send_on_requested.connect(_send_on)
	feather.clicked.connect(_on_feather_clicked)
	if next_soul_button != null:
		next_soul_button.pressed.connect(_send_on)
	caption_strip.text_shown.connect(_on_caption_shown)


## Raises the stamp for `realm` over the soul's writ (a door click or a drag over the door); never
## while a tale is told, a stamped soul waits or a slam is under way.
func ask(realm: StringName) -> void:
	var encounter: Encounter = commands.current_encounter()
	if encounter == null or commands.awaiting_next() or not _is_open(realm) or _slamming:
		return
	if gate != null and (gate.is_consuming() or gate.is_slamming()):
		return
	for door: Door in doors:
		door.selected = door.realm == realm
	if stamp_prompt.is_asking() and stamp_prompt.realm == realm:
		return
	stamp_prompt.reduce_motion = _reduce_motion()
	stamp_prompt.ask(encounter.soul_name, realm)


## Redraws the held state, and walks in a soul seated with no slam under way (a new day, a held
## soul sent on, a restart).
func refresh() -> void:
	var waiting: bool = commands.phase() == RunState.DESK and commands.awaiting_next()
	if next_soul_button != null:
		next_soul_button.visible = waiting
	feather.visible = waiting and _citation != ""
	soul.set_draggable(not waiting and commands.current_encounter() != null)
	if not _slamming:
		stamp_prompt.set_held(waiting)
		_arrive()


## A new soul (or an empty desk): the last soul's citation and stamp are gone, its name gives way
## on the writ; the mentor's comment on the stamp that seated it goes to the (freshly cleared)
## caption strip, unless the horn's announcement already holds it: her comment never queues behind
## the horn. A slam under way is left to finish: core seats the next soul inside the stamp.
func reset() -> void:
	stamp_prompt.withdraw()
	var encounter: Encounter = commands.current_encounter()
	stamp_prompt.set_soul_name(encounter.soul_name if encounter != null else "")
	_clear_door_selection()
	_citation = ""
	_cited_pair.clear()
	_mentor_unseen = false
	if _carry_mentor and caption_strip.shown_text() == "":
		caption_strip.post_caption(_mentor_caption())
	_carry_mentor = false


## A new run (Pause's Restart or "Play again"): the slam, the walk and the sweep stop where they
## are, and nothing the mentor said in the last run is shown or replayed.
func forget_run() -> void:
	_stop_slam()
	stamp_prompt.reset_writ()
	soul.finish_arrival()
	_held = null
	_mentor_line = ""
	_carry_mentor = false
	_mentor_unseen = false


func mentor_line() -> String:
	return _mentor_line


func citation() -> String:
	return _citation


## True from the stamp's press until its walk begins.
func is_slamming() -> bool:
	return _slamming


func _notification(what: int) -> void:
	# A drag released anywhere but a door cancels its preview (D9).
	if what == NOTIFICATION_DRAG_END and not get_viewport().gui_is_drag_successful():
		stamp_prompt.withdraw()


## Any press but a left one on the raised stamp or on an open door puts the stamp down, and does
## nothing else (D14). A press a presentation takes, or one in the slam window, is the gate's.
func _input(event: InputEvent) -> void:
	var press: InputEventMouseButton = event as InputEventMouseButton
	if press == null or not press.pressed or not stamp_prompt.is_asking():
		return
	if commands == null or commands.is_paused():
		return
	if gate != null and (gate.is_consuming() or gate.is_slamming()):
		return
	if press.button_index == MOUSE_BUTTON_LEFT:
		if stamp_prompt.stamp_rect().has_point(press.position):
			return
		for door: Door in doors:
			if door.is_open and door.get_global_rect().has_point(press.position):
				return
	elif press.button_index != MOUSE_BUTTON_RIGHT:
		return
	stamp_prompt.withdraw()
	get_viewport().set_input_as_handled()


func _commit(realm: StringName) -> void:
	if _slamming or (gate != null and gate.is_slamming()):
		return
	if commands.current_encounter() == null or commands.awaiting_next() or not _is_open(realm):
		return
	_stop_slam()
	soul.finish_arrival()
	var leaving: SoulWalk = SoulWalk.capture(soul.figure(), realm)
	_clear_door_selection()
	stamp_prompt.reduce_motion = _reduce_motion()
	stamp_prompt.stamp_down(realm)
	_slamming = true
	if gate != null:
		gate.slam_lock()
	var result: StampResult = commands.stamp(realm)
	var held: bool = result.citation or result.warning
	if held:
		_held = leaving
	else:
		_leaving = leaving
		_leaving.stand(walk_layer)
	_run_slam(realm, held)


## The slam (D14): the hold, the impact, the flare, then the walk with the window open again.
func _run_slam(realm: StringName, held: bool) -> void:
	if not is_inside_tree():
		_impact(realm)
		_flare(realm)
		_release(held)
		_end_walk()
		return
	_slam = create_tween()
	_slam.tween_interval(HOLD_SECONDS)
	_slam.tween_callback(_impact.bind(realm))
	_slam.tween_interval(IMPACT_SECONDS)
	_slam.tween_callback(_flare.bind(realm))
	_slam.tween_interval(SLAM_SECONDS - HOLD_SECONDS - IMPACT_SECONDS)
	_slam.tween_callback(_release.bind(held))
	_tween_walk()
	_watch(_slam)


## The thud, the jolt and the ink, at one instant.
func _impact(realm: StringName) -> void:
	if thud_player != null and thud_player.stream != null and thud_player.is_inside_tree():
		thud_player.play()
		if gate != null:
			gate.watch_player(thud_player)
	if not _reduce_motion() and jolt_callback.is_valid():
		jolt_callback.call(JOLT_PX, JOLT_SECONDS)
	_watch(stamp_prompt.slam(realm))


func _flare(realm: StringName) -> void:
	var door: Door = _door(realm)
	if door != null:
		door.flare()


## The window opens: the writ is swept (or held), and the next soul walks in.
func _release(held: bool) -> void:
	_slamming = false
	if gate != null:
		gate.slam_release()
	if held:
		stamp_prompt.set_held(true)
	else:
		_watch(stamp_prompt.sweep())
	_arrive()


## The held soul is sent on (D15): the next soul is seated, the held one walks through its door
## and its writ is swept.
func _send_on() -> void:
	if not commands.awaiting_next() or _slamming:
		return
	# "Send it on" inside the citation's hold would clear her waiting comment with the strip; it
	# goes to the next soul instead, as an unheld stamp's does.
	if _mentor_unseen:
		_carry_mentor = true
	var leaving: SoulWalk = _held
	_held = null
	stamp_prompt.reduce_motion = _reduce_motion()
	commands.next_soul()
	_stop_slam()
	if leaving != null and is_inside_tree():
		_leaving = leaving
		_leaving.stand(walk_layer)
		_slam = create_tween()
		_tween_walk()
		_watch(_slam)
	_watch(stamp_prompt.sweep())


## Appends the walk to `_slam`: through the door and fading, or gone at once under reduce motion.
func _tween_walk() -> void:
	if _leaving != null and not _reduce_motion():
		_leaving.walk_into(_slam, _door(_leaving.realm), WALK_SECONDS)
	_slam.tween_callback(_end_walk)


func _arrive() -> void:
	if soul.arrive_pending:
		var seconds: float = 0.0 if _reduce_motion() else WaitingSoul.ARRIVE_SECONDS
		_watch(soul.arrive(seconds))


## Stops the slam and the walk under way, if any, and opens the window; the walker never outlives
## its walk.
func _stop_slam() -> void:
	if _slam != null and _slam.is_valid():
		_slam.kill()
	_slam = null
	_end_walk()
	if _slamming:
		_slamming = false
		if gate != null:
			gate.slam_release()


func _end_walk() -> void:
	if _leaving != null:
		_leaving.end()
	_leaving = null


func _watch(tween: Tween) -> void:
	if gate != null and tween != null:
		gate.watch_tween(tween)


func _reduce_motion() -> bool:
	return options != null and options.reduce_motion


func _on_stamped(result: StampResult) -> void:
	selection_cleared.emit()
	var held: bool = result.citation or result.warning
	if held:
		# The citation takes the strip first (D33); her comment waits behind it.
		_citation = result.citation_text
		_cited_pair = [result.citation_a, result.citation_b] as Array[String]
		pair_lit.emit(_cited_pair.duplicate())
		caption_strip.post_caption(_citation_caption())
	if result.mentor_line != "":
		_mentor_line = result.mentor_line
		# A held soul shows her comment after the citation; otherwise the next soul's arrival does.
		_carry_mentor = not held
		if held:
			_mentor_unseen = true
			caption_strip.post_caption(_mentor_caption())


func _on_caption_shown(text: String) -> void:
	if text == _mentor_line:
		_mentor_unseen = false


## A deliberate click on the feather shows its citation again and lights the pair (D33).
func _on_feather_clicked() -> void:
	caption_strip.take_over_caption(_citation_caption())
	pair_lit.emit(_cited_pair.duplicate())


## The citation as the note shows it: the black feather's mark, written out, its pair lit (D10).
func _citation_caption() -> Caption:
	return Caption.make(
		_citation, CaptionStrip.Priority.CITATION, &"feather", _cited_pair.duplicate(), true
	)


## Her comment as the note shows it: her face as the mark, written out (D10).
func _mentor_caption() -> Caption:
	return Caption.make(_mentor_line, CaptionStrip.Priority.MENTOR, &"mentor", [], true)


func _is_open(realm: StringName) -> bool:
	return commands.day_rules().doors_open.has(realm)


func _door(realm: StringName) -> Door:
	for door: Door in doors:
		if door.realm == realm:
			return door
	return null


func _clear_door_selection() -> void:
	for door: Door in doors:
		door.selected = false
