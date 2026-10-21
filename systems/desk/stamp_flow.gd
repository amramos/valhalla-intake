class_name StampFlow
extends Node
## The stamp, from choice to consequence (D9, D14, D48). A door click (or a soul dragged over an
## open door) asks "Stamp <name> to <realm>?"; only the separate confirm, or dropping the soul on
## the door, commits. Then the thud: the sound, a short hold, the door's flare and the soul walking
## through. A stamp with a citation (or a day-1 warning) holds the soul on the desk with its pair
## lit and the black feather beside the mentor; "Next soul" lets it go. No undo.

## The cited pair to light (or [] to clear), for the desk system that owns highlights.
signal pair_lit(pair: Array[String])
## Any half-made pin must be dropped (a stamp just happened).
signal selection_cleared

const HOLD_SECONDS := 0.15
const WALK_SECONDS := 0.5

@export var doors: Array[Door] = []
@export var stamp_prompt: StampPrompt
@export var soul: WaitingSoul
@export var feather: ClickableSprite
@export var next_soul_button: Button
@export var caption_strip: CaptionStrip
@export var thud_player: AudioStreamPlayer
## Where the walking soul is drawn (above the gate band, under the desk's panels).
@export var walk_layer: Control

var commands: DeskCommands = null

var _citation: String = ""
var _cited_pair: Array[String] = []
## The soul walking through its door, and its walk; both null once the walk has ended.
var _walker: DragSource = null
var _walk: Tween = null
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
	feather.clicked.connect(_on_feather_clicked)
	next_soul_button.pressed.connect(_on_next_soul_pressed)
	caption_strip.text_shown.connect(_on_caption_shown)


## Asks to stamp the soul at the desk to `realm` (a door click or a drag over the door).
func ask(realm: StringName) -> void:
	var encounter: Encounter = commands.current_encounter()
	if encounter == null or commands.awaiting_next() or not _is_open(realm):
		return
	for door: Door in doors:
		door.selected = door.realm == realm
	if stamp_prompt.visible and stamp_prompt.realm == realm:
		return
	stamp_prompt.ask(encounter.soul_name, realm)


## Redraws the held state: Next soul and the feather while a stamped soul waits.
func refresh() -> void:
	var waiting: bool = commands.phase() == RunState.DESK and commands.awaiting_next()
	next_soul_button.visible = waiting
	feather.visible = waiting and _citation != ""
	soul.set_draggable(not waiting and commands.current_encounter() != null)


## A new soul (or an empty desk): the last soul's citation and prompt are gone; the mentor's
## comment on the stamp that seated it goes to the (freshly cleared) caption strip, unless the
## horn's announcement already holds it: her comment never queues behind the horn.
func reset() -> void:
	stamp_prompt.withdraw()
	_clear_door_selection()
	_citation = ""
	_cited_pair.clear()
	_mentor_unseen = false
	if _carry_mentor and caption_strip.shown_text() == "":
		caption_strip.post(_mentor_line, CaptionStrip.Priority.MENTOR)
	_carry_mentor = false


## A new run (Pause's Restart or "Play again"): nothing the mentor said in the last run is shown or
## replayed, and a soul still walking to its door leaves with the old run.
func forget_run() -> void:
	_end_walk()
	_mentor_line = ""
	_carry_mentor = false
	_mentor_unseen = false


func mentor_line() -> String:
	return _mentor_line


func citation() -> String:
	return _citation


func _notification(what: int) -> void:
	# A drag released anywhere but a door cancels its preview (D9).
	if what == NOTIFICATION_DRAG_END and not get_viewport().gui_is_drag_successful():
		stamp_prompt.withdraw()


func _commit(realm: StringName) -> void:
	if commands.current_encounter() == null or commands.awaiting_next() or not _is_open(realm):
		return
	var leaving: Array[Texture2D] = soul.figure().layers
	var from: Vector2 = soul.figure().global_position
	stamp_prompt.withdraw()
	_clear_door_selection()
	commands.stamp(realm)
	_thud(realm, leaving, from)


## The thud (D9): the sound, a short hold, the door's flare and the soul walking through it.
func _thud(realm: StringName, layers: Array[Texture2D], from: Vector2) -> void:
	if thud_player != null and thud_player.stream != null and thud_player.is_inside_tree():
		thud_player.play()
	var door: Door = _door(realm)
	if door == null or walk_layer == null or not is_inside_tree():
		return
	door.flare()
	_end_walk()
	_walker = DragSource.new()
	_walker.name = "Walker"
	_walker.layers = layers
	_walker.enabled = false
	_walker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walk_layer.add_child(_walker)
	_walker.size = soul.figure().size
	_walker.global_position = from
	var target := Vector2(door.get_global_rect().get_center().x - _walker.size.x / 2.0, from.y)
	_walk = create_tween()
	_walk.tween_interval(HOLD_SECONDS)
	_walk.tween_property(_walker, "global_position", target, WALK_SECONDS)
	_walk.parallel().tween_property(_walker, "modulate:a", 0.0, WALK_SECONDS)
	_walk.tween_callback(_end_walk)


## Stops the walk under way, if any, and frees its figure; the reference never outlives it.
func _end_walk() -> void:
	if _walk != null and _walk.is_valid():
		_walk.kill()
	_walk = null
	if is_instance_valid(_walker):
		_walker.queue_free()
	_walker = null


func _on_stamped(result: StampResult) -> void:
	selection_cleared.emit()
	var held: bool = result.citation or result.warning
	if held:
		# The citation takes the strip first (D33); her comment waits behind it.
		_citation = result.citation_text
		_cited_pair = [result.citation_a, result.citation_b] as Array[String]
		pair_lit.emit(_cited_pair.duplicate())
		caption_strip.post(_citation, CaptionStrip.Priority.CITATION)
	if result.mentor_line != "":
		_mentor_line = result.mentor_line
		# A held soul shows her comment after the citation; otherwise the next soul's arrival does.
		_carry_mentor = not held
		if held:
			_mentor_unseen = true
			caption_strip.post(_mentor_line, CaptionStrip.Priority.MENTOR)


## "Next soul" inside the citation's hold would clear her waiting comment with the strip; it goes
## to the next soul instead, as an unheld stamp's does.
func _on_next_soul_pressed() -> void:
	if _mentor_unseen:
		_carry_mentor = true
	commands.next_soul()


func _on_caption_shown(text: String) -> void:
	if text == _mentor_line:
		_mentor_unseen = false


## A deliberate click on the feather shows its citation again and lights the pair (D33).
func _on_feather_clicked() -> void:
	caption_strip.take_over(_citation)
	pair_lit.emit(_cited_pair.duplicate())


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
