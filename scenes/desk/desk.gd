class_name Desk
extends Control
## The inspection desk at 480×270, layout A3 as built (D4, D21, D51): the gate band on top (the
## waiting soul, the doors, Huginn's perch, the HUD), the desk below (the body chart and the mentor,
## claim and witness, the Law, the caption strip). It wires its DeskSystem to a DeskCommands: the
## one handed in with `use_commands`, or the slice loaded from data. Esc opens the pause (D31).

## Emitted when the player confirms Quit; the game closes unless `quit_closes_game` is off.
signal quit_requested

## Off in tests: a confirmed Quit only emits.
@export var quit_closes_game: bool = true

var _commands: DeskCommands = null

@onready var _system: DeskSystem = $DeskSystem
@onready var _pause: PauseOverlay = $PauseOverlay


## Hands the desk its commands; call before the desk enters the tree.
func use_commands(p_commands: DeskCommands) -> void:
	_commands = p_commands


func commands() -> DeskCommands:
	return _commands


func system() -> DeskSystem:
	return _system


func pause_overlay() -> PauseOverlay:
	return _pause


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	if _commands == null:
		_commands = SliceLoader.load_slice()
	_system.bind(_commands)
	_pause.configure(_commands.slice_rules().text)
	_pause.resumed.connect(func() -> void: _commands.set_paused(false))
	_pause.restart_confirmed.connect(_on_restart_confirmed)
	_pause.quit_confirmed.connect(_on_quit_confirmed)


## Esc: open the pause, or close it again (D31).
func toggle_pause() -> void:
	if _pause.is_open():
		_pause.close()
	else:
		_commands.set_paused(true)
		_system.hover_label.hide_label()
		_pause.open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# The clock pauses while the window is out of focus (D35), and stays paused under the pause.
	if _commands == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_commands.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and not _pause.is_open():
		_commands.set_paused(false)


func _on_restart_confirmed() -> void:
	_system.restart()
	_commands.set_paused(false)


func _on_quit_confirmed() -> void:
	quit_requested.emit()
	if quit_closes_game:
		get_tree().quit()
