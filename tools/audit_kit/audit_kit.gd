extends SceneTree
## Development only, never shipped: the evidence auditor's kit (D26). For every authored encounter
## (the twelve roster souls, Egil and both returned Hakons) it seats that soul alone on its day's
## desk, with the real art and that day's Law, its tale told in full, no threads pinned, and
## writes:
##
## - `<id>.png`: the desk at 1:1 (480×270);
## - `<id>.txt`: only what the player can read on that screen, taken from the rendered desk: every
##   body hit area with its hover label and pixel rect, the claim and witness headings and lines,
##   the decrees, the name plate and its hover, the mentor's bubble, the raven's hover, the doors
##   and the HUD.
##
## Nothing the player cannot see is written: no seams, destinations, truth or data ids.
## Run it in a window at the base resolution:
##
##   godot --path . --resolution 480x270 -s tools/audit_kit/audit_kit.gd -- [output-folder]

const SLICE_PATH := "res://data/slice.tres"
const DESK_SCENE := "res://scenes/desk/desk.tscn"
const RETURN_DAY := 3

var _out: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir().path_join("audit")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var slice: SliceData = load(SLICE_PATH) as SliceData
	var rules: SliceRules = slice.rules_to_core()
	var written: Array[String] = []
	for day: DayData in slice.days:
		for encounter: EncounterData in day.encounters:
			written.append(await _audit(day, encounter, rules))
	var day_three: DayData = null
	for day: DayData in slice.days:
		if day.day == RETURN_DAY:
			day_three = day
	for extra: EncounterData in [slice.returned_ignored, slice.returned_missed, slice.fallback]:
		if extra != null and day_three != null:
			written.append(await _audit(day_three, extra, rules))
	print("AUDIT KIT: %d encounters written to %s" % [written.size(), _out])
	for id: String in written:
		print("  " + id)
	quit()


## Seats `data` alone on `day`'s desk and writes its screenshot and its readable text.
func _audit(day: DayData, data: EncounterData, rules: SliceRules) -> String:
	var encounter: Encounter = data.to_core()
	var commands := DeskCommands.new()
	var days: Array[DayRules] = [day.to_core()]
	commands.start_run(days, [[encounter]], rules, {})
	commands.begin_day()
	commands.set_paused(true)
	var desk: Desk = (load(DESK_SCENE) as PackedScene).instantiate() as Desk
	desk.use_commands(commands)
	root.add_child(desk)
	await _frames(3)
	# The tale is told line by line (D4); the auditor reads it whole, as a click would show it.
	desk.system().finish_tellings()
	# The soul stands at the gate, its walk-in done.
	desk.system().soul.finish_arrival()
	desk.system().hover_label.hide_label()
	await _frames(2)
	await RenderingServer.frame_post_draw
	var id: String = String(encounter.id)
	root.get_texture().get_image().save_png(_out.path_join(id + ".png"))
	var text: String = _readable(desk, commands)
	var file: FileAccess = FileAccess.open(_out.path_join(id + ".txt"), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	desk.queue_free()
	await _frames(2)
	return id


## What the player can read on the seated desk, in screen order.
func _readable(desk: Desk, commands: DeskCommands) -> String:
	var system: DeskSystem = desk.system()
	var lines: Array[String] = []
	lines.append("DAY %d" % commands.day_number())
	lines.append(
		(
			"HUD: clock %s; feathers %d; quota %d/%d"
			% [
				system.hud.shown_time(),
				commands.feathers(),
				commands.quota_progress().x,
				commands.quota_progress().y
			]
		)
	)
	lines.append("DOORS (hover text):")
	for door: Door in system.doors:
		lines.append("  %s" % door.hover_text())
	lines.append("")
	lines.append("NAME PLATE: %s (%s plate)" % [system.soul.soul_name(), _plate_kind(system.soul)])
	var plate_hover: String = system.soul._plate_label
	lines.append("  hover: %s" % (plate_hover if plate_hover != "" else "(none)"))
	lines.append("")
	lines.append("BODY CHART (hit areas: hover label, rect x,y,w,h in screen pixels):")
	for item: EvidenceItem in commands.visible_items():
		var area: PinSelectable = system.body_chart.area(item.id)
		if area == null:
			continue
		var rect: Rect2 = area.get_global_rect()
		lines.append(
			(
				"  %s  %s  [%d,%d %dx%d]"
				% [
					item.id,
					area.hover_text,
					rect.position.x,
					rect.position.y,
					rect.size.x,
					rect.size.y
				]
			)
		)
	for panel: EvidencePanel in [system.claim_panel, system.witness_panel, system.law_panel]:
		lines.append("")
		lines.append_array(_panel_lines(panel, commands))
	lines.append("")
	var bubble: String = system.mentor_bubble.shown_text()
	lines.append("MENTOR BUBBLE: %s" % (bubble if bubble != "" else "(none)"))
	# Huginn on his post is a hit area on the days he is at the desk (D40).
	if system.raven.visible:
		lines.append("RAVEN (hover): %s" % system.raven.hover_text())
	return "\n".join(lines) + "\n"


func _panel_lines(panel: EvidencePanel, commands: DeskCommands) -> Array[String]:
	var lines: Array[String] = []
	if not panel.visible:
		lines.append("%s: (not shown)" % panel.name)
		return lines
	var heading: String = panel.heading_text()
	lines.append("%s: %s" % [panel.name, heading if heading != "" else "(no heading)"])
	if panel._heading_hover != "":
		lines.append("  heading hover: %s" % panel._heading_hover)
	if panel._note_label.visible:
		lines.append("  %s" % panel._note_label.text)
	for item: EvidenceItem in commands.visible_items():
		var area: PinSelectable = panel.area(item.id)
		if area == null:
			continue
		# A decree's line holds its numeral beside its "Text" label, whose indent clears it.
		var numeral: Label = area.get_node_or_null(^"Numeral") as Label
		var lead: String = numeral.text + " " if numeral != null else ""
		# A new decree carries the wax seal by its numeral (D9, D33).
		if panel.seal_rect(item.id).has_area():
			lead = "[seal] " + lead
		var label: Label = PaperLine.text_label(area)
		lines.append("  %s%s" % [lead, label.text.strip_edges().replace("\n", " ")])
	return lines


func _plate_kind(soul: WaitingSoul) -> String:
	var texture: Texture2D = soul.plate_texture()
	if texture == null:
		return "plain"
	return texture.resource_path.get_file().get_basename().trim_prefix("nameplate-")


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
