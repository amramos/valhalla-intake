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
##
## What the stamp leaves (the citation and her comment on the note, the feather's fall, the tide's
## step) is StampConsequences', landed at the impact from the StampResult in hand (D16, D38).

## The cited pair to light (or [] to clear), for the desk system that owns highlights.
signal pair_lit(pair: Array[String])
## Any half-made pin must be dropped (a stamp just happened).
signal selection_cleared
## The slam window opened again at the walk's start: the stamped soul's evidence may leave the desk
## now, and the next soul's come in (D14, D15).
signal slam_released

## From the press: the hold before the impact, the stamp on the paper before the flare, and the
## whole slam window (the one block, D27), after which the walk begins.
const HOLD_SECONDS := 0.07
const IMPACT_SECONDS := 0.1
const SLAM_SECONDS := 0.5
const WALK_SECONDS := 0.5
const JOLT_PX := 3
const JOLT_SECONDS := 0.1
## The feather's drift (StampConsequences'), beside the slam's timings it follows.
const FEATHER_DRIFT_FROM_X := StampConsequences.FEATHER_DRIFT_FROM_X
const FEATHER_DRIFT_SECONDS := StampConsequences.FEATHER_DRIFT_SECONDS

@export var doors: Array[Door] = []
@export var stamp_prompt: StampPrompt
@export var soul: WaitingSoul
@export var feather: ClickableSprite
## The old "Next soul" button, if the desk still has one; the held writ replaces it (D15).
@export var next_soul_button: Button = null
@export var caption_strip: CaptionStrip
@export var thud_player: AudioStreamPlayer
## The feather's dry caw (D16); optional (a desk without it falls silently).
@export var caw_player: AudioStreamPlayer = null
## Where the walking soul is drawn (above the gate band, under the desk's panels).
@export var walk_layer: Control

var commands: DeskCommands = null
## Owns the slam window and watches the slam's tweens and sound (pause, restart); optional.
var gate: PresentationGate = null
## The desk band's jolt, called as jolt(px, seconds); optional.
var jolt_callback: Callable = Callable()
## Reduce motion (D37) makes the jolt, the walks and the sweep instant; null reads as off.
var options: Options = null

var _consequences := StampConsequences.new()
## True from the commit until the walk begins.
var _slamming: bool = false
## The slam and the walk after it (or a held soul's walk); null once over.
var _slam: Tween = null
## The stamped soul standing through the slam, then walking; null once its walk has ended.
var _leaving: SoulWalk = null
## A held soul, kept from its stamp for the walk that "Send it on" starts.
var _held: SoulWalk = null


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	_consequences.bind(commands, gate, feather, caw_player, caption_strip, doors)
	_consequences.pair_lit.connect(pair_lit.emit)
	_consequences.selection_cleared.connect(selection_cleared.emit)
	for door: Door in doors:
		door.door_clicked.connect(ask)
		door.drag_hovered.connect(ask)
		door.dropped.connect(_commit)
	stamp_prompt.confirmed.connect(_commit)
	stamp_prompt.cancelled.connect(_clear_door_selection)
	stamp_prompt.send_on_requested.connect(_send_on)
	# The doors stay bright with the writ and the stamp while the desk dims (D56); the pause covers
	# all of it.
	var companions: Array[CanvasItem] = []
	companions.assign(doors)
	stamp_prompt.marks().set_companions(companions)
	if gate != null:
		gate.pause_changed.connect(stamp_prompt.marks().set_suspended)
	if next_soul_button != null:
		next_soul_button.pressed.connect(_send_on)


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
	# The rise stops under the pause like every presentation (the gate watches it).
	_watch(stamp_prompt.ask(encounter.soul_name, realm))


## Redraws the held state, and walks in a soul seated with no slam under way (a new day, a held
## soul sent on, a restart).
func refresh() -> void:
	var waiting: bool = commands.phase() == RunState.DESK and commands.awaiting_next()
	if next_soul_button != null:
		next_soul_button.visible = waiting
	_consequences.show_feather(waiting)
	soul.set_draggable(not waiting and commands.current_encounter() != null)
	if not _slamming:
		stamp_prompt.set_held(waiting)
		_arrive()


## A new soul (or an empty desk): the last soul's stamp is put down and its name gives way on the
## writ. A slam under way is left to finish: core seats the next soul inside the stamp.
func reset() -> void:
	stamp_prompt.withdraw()
	var encounter: Encounter = commands.current_encounter()
	stamp_prompt.set_soul_name(encounter.soul_name if encounter != null else "")
	_clear_door_selection()


## The new soul's evidence is on the desk (after the slam, if one was under way): the last soul's
## citation is gone, and the mentor's comment on the stamp that seated it goes to the freshly
## cleared note (StampConsequences).
func reset_note() -> void:
	_consequences.reset()


## A new run (Pause's Restart or "Play again"): the slam, the walk and the sweep stop where they
## are, and nothing the mentor said in the last run is shown or replayed.
func forget_run() -> void:
	_stop_slam()
	stamp_prompt.reset_writ()
	soul.finish_arrival()
	_held = null
	_consequences.forget_run()


## Hel's tide as the desk must draw it: a stamp's new figure waits for the slam's impact (D38).
func displayed_tide() -> int:
	return _consequences.displayed_tide()


func mentor_line() -> String:
	return _consequences.mentor_line()


func citation() -> String:
	return _consequences.citation()


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
	_consequences.hold(held, result.tide_delta == 1)
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


## The squash, the ink and the yield first, then the thud and the jolt in the same call: the
## sound starts on the very frame the stamp lands, never before it (D55).
func _impact(realm: StringName) -> void:
	_watch(stamp_prompt.slam(realm))
	if thud_player != null and thud_player.stream != null and thud_player.is_inside_tree():
		thud_player.play()
		if gate != null:
			gate.watch_player(thud_player)
	if not _reduce_motion() and jolt_callback.is_valid():
		jolt_callback.call(JOLT_PX, JOLT_SECONDS)
	_consequences.land(_reduce_motion())


func _flare(realm: StringName) -> void:
	var door: Door = _door(realm)
	if door != null:
		door.flare()


## The window opens: the writ is swept (or held), and the next soul walks in.
func _release(held: bool) -> void:
	_slamming = false
	if gate != null:
		gate.slam_release()
	slam_released.emit()
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
	_consequences.send_on()
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
	_consequences.cancel()
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
