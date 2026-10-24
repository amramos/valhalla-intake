class_name TitleScreen
extends Control
## The title (D31): the game's name over the gate, Start and Quit. Start opens the desk at day 1's
## dawn; Quit closes the game. Its words come from the slice's DeskText.

## Emitted instead of changing scene when `change_scene` is off (tests).
signal start_requested
signal quit_requested

const DESK_SCENE := "res://scenes/desk/desk.tscn"
## A user argument (after "--") that presses Start at once: the export smoke test boots the desk
## this way, because release builds refuse a scene path on the command line.
const AUTO_START_ARG := "--auto-start"

## Off in tests: Start and Quit only emit.
@export var change_scene: bool = true

@onready var _name: Label = $Name
@onready var _start: GuardedButton = $Start
@onready var _quit: GuardedButton = $Quit


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	var text: DeskText = SliceLoader.load_slice().slice_rules().text
	_name.text = text.title_name
	_start.text = text.start_label
	_quit.text = text.quit_label
	_start.pressed.connect(_on_start)
	_quit.pressed.connect(_on_quit)
	# The same in-scene cursor as the desk's (D48).
	add_child(CursorSprite.new())
	if OS.get_cmdline_user_args().has(AUTO_START_ARG):
		_on_start.call_deferred()


func start_button() -> GuardedButton:
	return _start


func quit_button() -> GuardedButton:
	return _quit


func _on_start() -> void:
	start_requested.emit()
	if change_scene:
		get_tree().change_scene_to_file(DESK_SCENE)


func _on_quit() -> void:
	quit_requested.emit()
	if change_scene:
		get_tree().quit()
