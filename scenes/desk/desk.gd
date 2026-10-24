class_name Desk
extends Control
## The inspection desk at 480×270, layout A3 as built (D4, D21, D51): the gate band on top (the
## waiting soul, the doors, Huginn's perch, the HUD), the desk below (the body chart and the mentor,
## claim and witness, the Law, the caption strip). It wires its DeskSystem to a DeskCommands: the
## one handed in with `use_commands`, or the slice loaded from data. Esc opens the pause (D31).
##
## Every mouse button event reaches the PresentationGate first (ADR-0009): a press that finishes a
## telling or a written caption, or falls in the slam window, goes no further (D27). The pause and
## the window's focus stop the gate's presentations with the clock.

## Emitted when the player confirms Quit; the game closes unless `quit_closes_game` is off.
signal quit_requested

## The desk band: everything below the gate band (y >= 96) that the stamp's jolt shakes (D14).
const DESK_BAND: Array[NodePath] = [
	^"BodyChart",
	^"MentorPortrait",
	^"Feather",
	^"MentorBubble",
	^"ClaimPanel",
	^"WitnessPanel",
	^"LawPanel",
	^"CaptionStrip",
	^"ThreadLayer",
]

## Off in tests: a confirmed Quit only emits.
@export var quit_closes_game: bool = true

var _commands: DeskCommands = null
var _options: Options = null
var _band: Array[Control] = []
var _band_home: Array[Vector2] = []
var _jolt: Tween = null
var _cursor: CursorSprite = null

@onready var _system: DeskSystem = $DeskSystem
@onready var _pause: PauseOverlay = $PauseOverlay
@onready var _gate: PresentationGate = $PresentationGate


## Hands the desk its commands; call before the desk enters the tree.
func use_commands(p_commands: DeskCommands) -> void:
	_commands = p_commands


func commands() -> DeskCommands:
	return _commands


## Hands the desk the player's options (tests, the options panel); without it the desk loads
## them from user://options.cfg (D37).
func use_options(p_options: Options) -> void:
	_options = p_options
	if is_node_ready():
		_system.use_options(_options)


func options() -> Options:
	return _options


func gate() -> PresentationGate:
	return _gate


func system() -> DeskSystem:
	return _system


func pause_overlay() -> PauseOverlay:
	return _pause


func cursor() -> CursorSprite:
	return _cursor


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	if _commands == null:
		_commands = SliceLoader.load_slice()
	if _options == null:
		_options = Options.load()
	for path: NodePath in DESK_BAND:
		var node: Control = get_node(path) as Control
		_band.append(node)
		_band_home.append(node.position)
	_system.options = _options
	_system.stamp_flow.jolt_callback = jolt
	_system.bind(_commands)
	# The in-scene cursor (D13, D48) carries a pin while an item is selected and grabs the soul.
	_cursor = CursorSprite.new()
	add_child(_cursor)
	_system.highlights().selection_changed.connect(_cursor.set_carrying_pin)
	_system.soul.figure_hover_started.connect(_on_figure_hovered.bind(true))
	_system.soul.figure_hover_ended.connect(_on_figure_hovered.bind(false))
	_pause.configure(_commands.slice_rules().text)
	_pause.resumed.connect(_set_paused.bind(false))
	_pause.restart_confirmed.connect(_on_restart_confirmed)
	_pause.quit_confirmed.connect(_on_quit_confirmed)


## Esc: open the pause, or close it again (D31).
func toggle_pause() -> void:
	if _pause.is_open():
		_pause.close()
	else:
		_set_paused(true)
		_system.hover_label.hide_label()
		_pause.open()


## The stamp's jolt (D14): the desk band drops `px` pixels and comes back over `seconds`, in
## whole pixels. Reduce motion (D37) leaves it still; the thud and the slam stay.
func jolt(px: int = 2, seconds: float = 0.1) -> void:
	if _options.reduce_motion or px == 0:
		return
	_end_jolt()
	_offset_band(px)
	if seconds <= 0.0 or not is_inside_tree():
		_end_jolt()
		return
	_jolt = create_tween()
	_jolt.tween_method(_offset_band, float(px), 0.0, seconds)
	_jolt.tween_callback(_end_jolt)
	_gate.watch_tween(_jolt)


func is_jolting() -> bool:
	return _jolt != null


func _offset_band(px: float) -> void:
	for index: int in range(_band.size()):
		_band[index].position = _band_home[index] + Vector2(0, roundi(px))


func _end_jolt() -> void:
	if _jolt != null and _jolt.is_valid():
		_jolt.kill()
	_jolt = null
	_offset_band(0.0)


## Every mouse button event goes to the gate first; what it takes (a finishing press, a press in
## the slam window, the release of either) is handled here and reaches nothing else. The open
## pause has its own buttons and lets every press through.
func _input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or _pause.is_open():
		return
	if _gate.on_press(button):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# The clock pauses while the window is out of focus (D35), and stays paused under the pause.
	if _commands == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and not _pause.is_open():
		_set_paused(false)


## The clock and every presentation stop and resume together (the plan's timing policy).
func _set_paused(paused: bool) -> void:
	_commands.set_paused(paused)
	_gate.set_paused(paused)


## The grab hand over the waiting soul, only while it can be picked up (not under a held stamp).
func _on_figure_hovered(over: bool) -> void:
	_cursor.set_grab(over and _system.soul.figure().enabled)


func _on_restart_confirmed() -> void:
	_end_jolt()
	_system.restart()
	_set_paused(false)


func _on_quit_confirmed() -> void:
	quit_requested.emit()
	if quit_closes_game:
		get_tree().quit()
