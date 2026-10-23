class_name Options
extends RefCounted
## The player's options (D37): text speed, reduce motion, master volume and mute, kept in
## user://options.cfg. Every value read back is validated; a missing, unreadable or malformed file
## (or a blocked browser store on the web) falls back to the defaults and never stops the game.

const PATH := "user://options.cfg"
const SECTION := "options"
const NORMAL := &"normal"
const FAST := &"fast"
const INSTANT := &"instant"
const SPEEDS: Array[StringName] = [NORMAL, FAST, INSTANT]
## Characters a second per text speed; "instant" shows the whole text at once.
const NORMAL_CPS := 40.0
const FAST_CPS := 80.0
const MIN_VOLUME_DB := -40.0
const MAX_VOLUME_DB := 0.0

var text_speed: StringName = NORMAL
var reduce_motion: bool = false
## Master volume, MIN_VOLUME_DB to MAX_VOLUME_DB.
var volume_db: float = 0.0
var muted: bool = false


## The options saved at `path`, each invalid or missing value replaced by its default.
static func load(path: String = PATH) -> Options:
	var options := Options.new()
	var file := ConfigFile.new()
	if not FileAccess.file_exists(path):
		return options
	var error: Error = file.load(path)
	if error != OK:
		push_warning(
			"Options: %s is unreadable (%s); using the defaults" % [path, error_string(error)]
		)
		return options
	var speed: Variant = file.get_value(SECTION, "text_speed", String(NORMAL))
	if speed is String or speed is StringName:
		if SPEEDS.has(StringName(speed)):
			options.text_speed = StringName(speed)
	var reduce: Variant = file.get_value(SECTION, "reduce_motion", false)
	if reduce is bool:
		options.reduce_motion = reduce
	var volume: Variant = file.get_value(SECTION, "volume_db", 0.0)
	if (volume is float or volume is int) and _valid_volume(float(volume)):
		options.volume_db = float(volume)
	var mute: Variant = file.get_value(SECTION, "muted", false)
	if mute is bool:
		options.muted = mute
	return options


## Characters a second for the telling and written reveals; INF at "instant".
func cps() -> float:
	match text_speed:
		FAST:
			return FAST_CPS
		INSTANT:
			return INF
	return NORMAL_CPS


## Writes the options to `path`; false (with a warning) when the file can't be written.
func save(path: String = PATH) -> bool:
	var file := ConfigFile.new()
	file.set_value(SECTION, "text_speed", String(text_speed if SPEEDS.has(text_speed) else NORMAL))
	file.set_value(SECTION, "reduce_motion", reduce_motion)
	file.set_value(SECTION, "volume_db", volume_db if _valid_volume(volume_db) else 0.0)
	file.set_value(SECTION, "muted", muted)
	var error: Error = file.save(path)
	if error != OK:
		push_warning("Options: can't write %s (%s)" % [path, error_string(error)])
		return false
	return true


static func _valid_volume(volume: float) -> bool:
	return not is_nan(volume) and volume >= MIN_VOLUME_DB and volume <= MAX_VOLUME_DB
