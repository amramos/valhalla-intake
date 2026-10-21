class_name PhaseFlow
extends RefCounted
## WP1's minimal dawn, dusk and ending cards: what they say, built from what DeskCommands shows,
## and what their button does. The full cards (D15, D34) replace this in WP5.


## Shows the card for the commands' phase, or hides it while a soul is at the desk.
static func show_card(card: PhaseCard, commands: DeskCommands) -> void:
	match commands.phase():
		RunState.DAWN:
			card.show_card(dawn(commands), "Begin")
		RunState.DUSK:
			card.show_card(dusk(commands.dusk_report()), "Next day")
		RunState.ENDING:
			card.show_card(ending(commands.ending()), "Play again")
		_:
			card.visible = false


## The card's button: begin the day, go on to the next, or play again.
static func advance(commands: DeskCommands) -> void:
	match commands.phase():
		RunState.DAWN:
			commands.begin_day()
		RunState.DUSK:
			commands.next_day()
		RunState.ENDING:
			commands.restart_run()


static func dawn(commands: DeskCommands) -> String:
	var rules: DayRules = commands.day_rules()
	var lines: Array[String] = ["Day %d." % rules.day]
	lines.append("Quota: %d to Valhalla." % rules.quota)
	if rules.is_timed():
		lines.append("Clock: %s." % Hud.format_time(rules.clock_seconds))
	else:
		lines.append("Untimed.")
	if commands.shows_new_marks():
		for decree_id: String in rules.new_decree_ids:
			lines.append("NEW: %s." % decree_id)
		for realm: StringName in rules.new_doors:
			lines.append("NEW door: %s." % Realm.display_name(realm))
	return "\n".join(lines)


static func dusk(report: DuskReport) -> String:
	var lines: Array[String] = ["Dusk, day %d." % report.day]
	lines.append("Valhalla: %d of %d." % [report.admitted, report.quota])
	lines.append_array(report.citations)
	lines.append_array(report.requests)
	if report.returned_line != "":
		lines.append(report.returned_line)
	lines.append("Feathers: %d. %s." % [report.feathers, report.rank_name])
	return "\n".join(lines)


static func ending(report: EndingReport) -> String:
	var lines: Array[String] = ["The slice ends."]
	match report.outcome:
		EndingReport.TIDE:
			lines.append("Hel's tide: " + ", ".join(report.tide_names))
		EndingReport.HOLLOW:
			lines.append("The hollow hall: " + ", ".join(report.hollow_names))
		_:
			lines.append("The Hall holds.")
	lines.append("Feathers: %d. %s." % [report.feathers, report.rank_name])
	return "\n".join(lines)
