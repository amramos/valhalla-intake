class_name Desk
extends Control
## The inspection desk at 480×270, layout A3 as built (D4, D21, D51): the gate band on top (the
## waiting soul, the doors, Huginn's perch, the HUD), the desk below (the body chart and the mentor,
## claim and witness, the Law, the caption strip). It wires its DeskSystem to a DeskCommands: the
## one handed in with `use_commands`, or the slice loaded from data.

var _commands: DeskCommands = null

@onready var _system: DeskSystem = $DeskSystem


## Hands the desk its commands; call before the desk enters the tree.
func use_commands(p_commands: DeskCommands) -> void:
	_commands = p_commands


func commands() -> DeskCommands:
	return _commands


func system() -> DeskSystem:
	return _system


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	if _commands == null:
		_commands = SliceLoader.load_slice()
	_system.bind(_commands)


func _notification(what: int) -> void:
	# The clock pauses while the window is out of focus (D35).
	if _commands == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_commands.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_commands.set_paused(false)
