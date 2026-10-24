class_name TitleScreen
extends Control
## The title (D24): the gate at dusk as day 1 shows it, its corner fog drifting and the open doors'
## glow pulsing; the game's name in the carved capitals on the desk under the wall; Start, Options
## and Quit as parchment tags nailed to the desk; and the wind. Start opens the desk at day 1's
## dawn; Options opens the options panel, whose changes apply here at once (D37); Quit closes the
## game. The wind starts at once on the desktop, and at the first click on the web, where a
## browser lets audio start only then (D50); it loops by its file's loop points. While the window
## is out of focus the title's own PresentationGate holds the wind, the fog and the doors' pulse,
## as the desk's does (D35). Its words come from the slice's DeskText.

## Emitted instead of changing scene when `change_scene` is off (tests).
signal start_requested
signal quit_requested

const DESK_SCENE := "res://scenes/desk/desk.tscn"
## A user argument (after "--") that presses Start at once: the export smoke test boots the desk
## this way, because release builds refuse a scene path on the command line.
const AUTO_START_ARG := "--auto-start"
## The name is drawn in the capitals at twice their size, centred on the desk.
const NAME_SCALE := 2
const NAME_TOP := 106
## The tags' column: its top, the pitch between tags and the room around the widest word.
const TAGS_TOP := 146
const TAG_PITCH := 18
const TAG_ROOM := 16
const SCREEN_WIDTH := 480

## Off in tests: Start and Quit only emit.
@export var change_scene: bool = true
## Where the options are read and saved (tests point it at a scratch file).
@export var options_path: String = Options.PATH
## The web build waits for the first click to start the wind; set before the title enters the tree.
var web: bool = OS.has_feature("web")

var _options: Options = null
var _wind_on: bool = false
var _name_text: String = ""

@onready var _band: GateBand = $GateBand
@onready var _doors: Array[Door] = [$DoorValhalla, $DoorHel, $DoorFolkvangr]
@onready var _name: Control = $Name
@onready var _start: TagButton = $Start
@onready var _options_tag: TagButton = $Options
@onready var _quit: TagButton = $Quit
@onready var _panel: OptionsPanel = $OptionsPanel
@onready var _wind: AudioStreamPlayer = $WindPlayer
@onready var _gate: PresentationGate = $PresentationGate


func _ready() -> void:
	PixelFont.configure(theme.default_font)
	var text: DeskText = SliceLoader.load_slice().slice_rules().text
	_name_text = text.title_name.to_upper()
	_name.draw.connect(_draw_name)
	_start.text = text.start_label
	_options_tag.text = OptionsPanel.OPENER_LABEL
	_quit.text = text.quit_label
	_layout()
	_start.pressed.connect(_on_start)
	_options_tag.pressed.connect(_panel.open)
	_quit.pressed.connect(_on_quit)
	# Day 1's gate: Valhalla and Hel open and pulsing, Fólkvangr barred. The doors are scenery
	# here, never a click or a hover.
	_band.set_day(1)
	for door: Door in _doors:
		door.set_day(1)
		door.set_state(door.realm != Realm.FOLKVANGR, 0, false)
		door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options = Options.load(options_path)
	_panel.save_path = options_path
	_panel.use_options(_options)
	_panel.changed.connect(apply_options)
	apply_options(_options)
	# Focus loss stops the title's clocks: the wind, the fog drift and the doors' pulse.
	_gate.watch_player(_wind)
	_gate.pause_changed.connect(_band.set_paused)
	for door: Door in _doors:
		_gate.pause_changed.connect(door.set_paused)
	_gate.pause_changed.connect(_on_pause_changed)
	if not web:
		start_wind()
	# The same in-scene cursor as the desk's (D48).
	add_child(CursorSprite.new())
	if OS.get_cmdline_user_args().has(AUTO_START_ARG):
		_on_start.call_deferred()


func start_button() -> GuardedButton:
	return _start


func options_button() -> GuardedButton:
	return _options_tag


func quit_button() -> GuardedButton:
	return _quit


func options_panel() -> OptionsPanel:
	return _panel


func options() -> Options:
	return _options


func gate_band() -> GateBand:
	return _band


func doors() -> Array[Door]:
	return _doors.duplicate()


func wind_player() -> AudioStreamPlayer:
	return _wind


## The name as drawn, in capitals.
func shown_name() -> String:
	return _name_text


## True once the wind has started (it plays when its stream is set).
func is_wind_on() -> bool:
	return _wind_on


## Applies the options here at once: the fog and the doors' pulse hold still under reduce motion,
## the wind follows the volume and mute.
func apply_options(options: Options) -> void:
	_options = options
	_band.reduce_motion = options.reduce_motion
	for door: Door in _doors:
		door.reduce_motion = options.reduce_motion
	for tag: TagButton in [_start, _options_tag, _quit]:
		tag.reduce_motion = options.reduce_motion
	_wind.volume_db = DeskSounds.level_db(options)


func gate() -> PresentationGate:
	return _gate


## Starts the wind; out of focus it waits for the focus to come back.
func start_wind() -> void:
	_wind_on = true
	if _gate.is_paused() or _wind.stream == null or not _wind.is_inside_tree():
		return
	if not _wind.playing and not _wind.stream_paused:
		_wind.play()


## On the web the first click starts the wind; the click goes on to whatever it pressed.
func _input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if web and not _wind_on and button != null and button.pressed:
		start_wind()


## Esc closes the options panel.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _panel.is_open():
		_panel.close()
		get_viewport().set_input_as_handled()


func _layout() -> void:
	var width: int = 0
	for tag: TagButton in [_start, _options_tag, _quit]:
		width = maxi(width, tag.fit_width())
	width += TAG_ROOM
	var y: int = TAGS_TOP
	for tag: TagButton in [_start, _options_tag, _quit]:
		tag.place(Vector2(floori((SCREEN_WIDTH - width) / 2.0), y), width)
		y += TAG_PITCH
	var name_width: int = PixelCapitals.width(_name_text)
	_name.size = Vector2(name_width, PixelCapitals.HEIGHT)
	_name.position = Vector2(floori((SCREEN_WIDTH - name_width * NAME_SCALE) / 2.0), NAME_TOP)
	_name.queue_redraw()


func _draw_name() -> void:
	PixelCapitals.draw(
		_name, _name_text, Vector2.ZERO, get_theme_color(&"text_light", &"DeskPalette")
	)


func _notification(what: int) -> void:
	if _gate == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_gate.set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_gate.set_paused(false)


## A wind asked for while out of focus starts when the focus comes back.
func _on_pause_changed(paused: bool) -> void:
	if not paused and _wind_on:
		start_wind()


func _on_start() -> void:
	start_requested.emit()
	if change_scene:
		get_tree().change_scene_to_file(DESK_SCENE)


func _on_quit() -> void:
	quit_requested.emit()
	if change_scene:
		get_tree().quit()
