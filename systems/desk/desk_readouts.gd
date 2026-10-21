class_name DeskReadouts
extends RefCounted
## What the gate band and the HUD read from DeskCommands: door states (lit or locked by the day a
## door opens, NEW until the day's first stamp, Hel's tide), the NEW decrees and the HUD's numbers.


static func show_doors(doors: Array[Door], commands: DeskCommands) -> void:
	var rules: DayRules = commands.day_rules()
	var marks: bool = commands.shows_new_marks()
	var threshold: int = commands.slice_rules().tide_threshold
	for door: Door in doors:
		var is_new: bool = marks and rules.new_doors.has(door.realm)
		door.set_state(rules.doors_open.has(door.realm), commands.door_open_day(door.realm), is_new)
		if door.realm == Realm.HEL:
			door.set_tide(commands.hel_tide(), threshold)


## Today's new decrees, while NEW marks show (D34).
static func new_decrees(commands: DeskCommands) -> Array[String]:
	var ids: Array[String] = []
	if commands.phase() == RunState.DESK and commands.shows_new_marks():
		ids.append_array(commands.day_rules().new_decree_ids)
	return ids


static func hud(commands: DeskCommands) -> HudReadout:
	var readout := HudReadout.new()
	readout.time_left = commands.time_left()
	readout.clock_shown = commands.phase() == RunState.DAWN or commands.phase() == RunState.DESK
	readout.feathers = commands.feathers()
	readout.quota = commands.quota_progress()
	readout.huginn_on = commands.day_rules().huginn_answers > 0
	readout.huginn_left = commands.huginn_left()
	readout.promise_open = commands.promise_state() == RunState.PROMISE_OPEN
	readout.extra_cost = commands.slice_rules().huginn_extra_cost
	return readout
