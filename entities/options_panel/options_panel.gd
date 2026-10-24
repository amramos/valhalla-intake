class_name OptionsPanel
extends Control
## The options (D37), reached from the title and the pause: a parchment nailed up by two pin
## heads, "OPTIONS" in the carved capitals, and four rows: text speed (Normal, Fast and Instant
## tags, the chosen one pinned in ember), reduce motion (a tag reading On or Off), the volume (six
## tally marks, a click sets the level) and mute (On or Off); a Back tag closes it. Every change
## is saved at once through `Options.save()` and announced by `changed`, so the title and the desk
## apply it while the panel is still open; a save that fails only logs (Options warns). While it
## shows, nothing under it takes a click.

## An option changed; `options` is the edited object, already saved.
signal changed(options: Options)
## Back (or Esc) closed the panel.
signal closed

## The words on the panel. Kept here until the slice's text data carries them.
const OPENER_LABEL := "Options"
const TITLE := "OPTIONS"
const SPEED_LABEL := "Text speed"
const MOTION_LABEL := "Reduce motion"
const VOLUME_LABEL := "Volume"
const MUTE_LABEL := "Mute"
const BACK_LABEL := "Back"
const ON_LABEL := "On"
const OFF_LABEL := "Off"
const SPEED_WORDS: Dictionary[StringName, String] = {
	Options.NORMAL: "Normal",
	Options.FAST: "Fast",
	Options.INSTANT: "Instant",
}
const SCREEN := Vector2(480, 270)
## The sheet and its rows, in screen pixels.
const SHEET := Rect2(118, 40, 244, 128)
const FIRST_ROW := 26
const ROW_PITCH := 18
const LABEL_LEFT := 10
const CONTROL_LEFT := 90
const TAG_GAP := 3
const TOGGLE_WIDTH := 30
const BACK_TOP := 104
## A label's first ink row sits this far below its top (ADR-0008); a tag's text sits 3 px lower.
const LABEL_RISE := 1
## The volume's steps run from Options.MIN_VOLUME_DB (step 0) to MAX_VOLUME_DB (the last).
const STEP_DB := (Options.MAX_VOLUME_DB - Options.MIN_VOLUME_DB) / (TallyRow.STEPS - 1)
const THEME_TYPE := &"DeskPalette"

## The panel draws its own dim (the title); the pause has one already.
@export var dim: bool = true
## Where changes are saved.
var save_path: String = Options.PATH

var _options: Options = Options.new()
var _sheet: HangingSheet = null
var _speeds: Dictionary[StringName, TagButton] = {}
var _motion: TagButton = null
var _mute: TagButton = null
var _back: TagButton = null
var _tally: TallyRow = null
var _labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = SCREEN
	_sheet = HangingSheet.new()
	_sheet.name = "Sheet"
	_sheet.heading = TITLE
	_sheet.position = SHEET.position
	_sheet.size = SHEET.size
	_sheet.seed = 37
	add_child(_sheet)
	var row: int = 0
	for text: String in [SPEED_LABEL, MOTION_LABEL, VOLUME_LABEL, MUTE_LABEL]:
		_labels.append(_label(text, row))
		row += 1
	var x: float = _control_left()
	for speed: StringName in Options.SPEEDS:
		var tag: TagButton = _tag(SPEED_WORDS[speed], set_speed.bind(speed))
		tag.place(Vector2(x, _row_top(0)))
		x += tag.size.x + TAG_GAP
		_speeds[speed] = tag
	_motion = _tag(OFF_LABEL, toggle_motion)
	_motion.place(Vector2(_control_left(), _row_top(1)), TOGGLE_WIDTH)
	_tally = TallyRow.new()
	_tally.name = "Volume"
	add_child(_tally)
	_tally.position = Vector2(_control_left(), _row_top(2))
	_tally.step_chosen.connect(set_volume_step)
	_mute = _tag(OFF_LABEL, toggle_mute)
	_mute.place(Vector2(_control_left(), _row_top(3)), TOGGLE_WIDTH)
	_back = _tag(BACK_LABEL, close)
	_back.place(SHEET.position + Vector2(LABEL_LEFT, BACK_TOP))
	_show_options()
	visible = false


## The options this panel edits (the same object the desk or the title applies).
func use_options(options: Options) -> void:
	_options = options if options != null else Options.new()
	_show_options()


func options() -> Options:
	return _options


func open() -> void:
	_show_options()
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func set_speed(speed: StringName) -> void:
	if not Options.SPEEDS.has(speed):
		return
	_options.text_speed = speed
	_apply()


func toggle_motion() -> void:
	_options.reduce_motion = not _options.reduce_motion
	_apply()


func toggle_mute() -> void:
	_options.muted = not _options.muted
	_apply()


## Sets the volume to `step` (0 to TallyRow.STEPS - 1).
func set_volume_step(step: int) -> void:
	_options.volume_db = step_db(clampi(step, 0, TallyRow.STEPS - 1))
	_apply()


## The decibels of volume step `step`.
static func step_db(step: int) -> float:
	return Options.MIN_VOLUME_DB + STEP_DB * step


## The step nearest `volume_db`.
static func volume_step(volume_db: float) -> int:
	return clampi(roundi((volume_db - Options.MIN_VOLUME_DB) / STEP_DB), 0, TallyRow.STEPS - 1)


func speed_button(speed: StringName) -> TagButton:
	return _speeds.get(speed, null)


func motion_button() -> TagButton:
	return _motion


func mute_button() -> TagButton:
	return _mute


func back_button() -> TagButton:
	return _back


## Every tag on the panel.
func tags() -> Array[TagButton]:
	var all: Array[TagButton] = []
	all.assign(_speeds.values())
	all.append_array([_motion, _mute, _back])
	return all


func tally() -> TallyRow:
	return _tally


## The sheet's rect in screen pixels.
func sheet_rect() -> Rect2:
	return SHEET


func sheet() -> HangingSheet:
	return _sheet


func _apply() -> void:
	_options.save(save_path)
	_show_options()
	changed.emit(_options)


## Shows the options as they are: the chosen speed pinned, the toggles' words, the tally.
func _show_options() -> void:
	if _back == null:
		return
	for speed: StringName in _speeds:
		_speeds[speed].pin = (
			TagButton.Pin.CHOSEN if speed == _options.text_speed else TagButton.Pin.NONE
		)
	_motion.text = ON_LABEL if _options.reduce_motion else OFF_LABEL
	_mute.text = ON_LABEL if _options.muted else OFF_LABEL
	_tally.step = volume_step(_options.volume_db)
	for tag: TagButton in tags():
		tag.reduce_motion = _options.reduce_motion


func _tag(text: String, action: Callable) -> TagButton:
	var tag := TagButton.new()
	tag.name = text
	tag.text = text
	tag.pressed.connect(action)
	add_child(tag)
	return tag


func _label(text: String, row: int) -> Label:
	var label := Label.new()
	label.name = text
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", get_theme_color(&"ink", THEME_TYPE))
	label.position = Vector2(SHEET.position.x + LABEL_LEFT, _row_top(row) - LABEL_RISE)
	add_child(label)
	return label


func _row_top(row: int) -> float:
	return SHEET.position.y + FIRST_ROW + row * ROW_PITCH


func _control_left() -> float:
	return SHEET.position.x + CONTROL_LEFT


func _draw() -> void:
	if dim:
		var shade: Color = get_theme_color(&"ink", THEME_TYPE)
		shade.a = 0.7
		draw_rect(Rect2(Vector2.ZERO, size), shade)
