class_name Desk
extends Control
## The inspection desk at 480×270, layout A3 (D4, D21): the gate band on top (the waiting soul,
## the doors, Huginn's perch, the HUD), the desk below (the body chart, claim and witness, the Law,
## the caption strip). It wires its DeskSystem to a DeskCommands: the one handed in with
## `use_commands`, or the slice loaded from data.

## The gate band's art slot (doors, wall, perch); empty until the WP2 backdrop lands.
@export var gate_texture: Texture2D = null
@export var gate_placeholder_path: String = "res://docs/art/frames/key-scene.png"
@export var gate_placeholder_region: Rect2i = Rect2i(0, 14, 480, 96)

var _commands: DeskCommands = null

@onready var _system: DeskSystem = $DeskSystem
@onready var _gate: TextureRect = $GateBand


## Hands the desk its commands; call before the desk enters the tree.
func use_commands(p_commands: DeskCommands) -> void:
	_commands = p_commands


func commands() -> DeskCommands:
	return _commands


func system() -> DeskSystem:
	return _system


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	_gate.texture = gate_texture
	if _gate.texture == null:
		_gate.texture = PlaceholderArt.load_texture(gate_placeholder_path, gate_placeholder_region)
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
