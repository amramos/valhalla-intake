class_name PhaseFlow
extends RefCounted
## The screens between souls (D15, D21, D22, D23, D34): the dawn, the dusk day-book's spreads with
## "Next" and "Skip all", and the slice's ending after day 3's dusk. ScreenText composes every
## word; this keeps the place in the sequence and turns a button into the next command. Skipping
## hides nothing with consequences: the ledger is written in core before the first spread shows.
## It holds no node, so the text harness walks the same sequence (D13, D44): card() says what
## shows, one card per spread, and show_screens() draws it on Odin's writ and the day-book.

## What "Play again" does (the desk system's full restart).
var on_restart: Callable = Callable()

## The dusk being shown (its day), its spreads, and the spread on screen.
var _dusk_day: int = -1
var _spreads: Array[DuskSpread] = []
var _index: int = 0
var _ending: bool = false


## One card as it shows: a title line ("" for none) over its body, the main button's label and the
## "Skip all" label ("" for no second button).
class Card:
	extends RefCounted
	var title: String = ""
	var body: String = ""
	var next_label: String = ""
	var skip_label: String = ""

	func text() -> String:
		return body if title == "" else title + "\n" + body


## Forgets the sequence (a restart).
func reset() -> void:
	_dusk_day = -1
	_spreads.clear()
	_index = 0
	_ending = false


## Keeps the place in step with the commands' phase: a dawn forgets the last dusk, and a new dusk
## starts at its first card.
func sync(commands: DeskCommands) -> void:
	match commands.phase():
		RunState.DAWN:
			reset()
		RunState.DUSK, RunState.ENDING:
			_start_dusk(commands)


## The card for the commands' phase, or null while a soul is at the desk.
func card(commands: DeskCommands) -> Card:
	sync(commands)
	var rules: SliceRules = commands.slice_rules()
	var text: DeskText = rules.text
	var shown := Card.new()
	match commands.phase():
		RunState.DAWN:
			shown.body = "\n".join(ScreenText.dawn_lines(commands.day_rules()))
			shown.next_label = text.begin_label
		RunState.DUSK, RunState.ENDING:
			if _ending:
				shown.body = ending_text(commands.ending(), rules)
				shown.next_label = text.play_again
			else:
				var last: bool = _index >= _spreads.size() - 1
				shown.title = _spreads[_index].title
				shown.body = _spreads[_index].body()
				shown.next_label = _finish_label(commands) if last else text.next_label
				shown.skip_label = "" if last else text.skip_all_label
		_:
			return null
	return shown


## Draws the phase on the desk's screens: the dawn on Odin's writ, dusk's spread and the ending in
## the day-book; whichever is not the phase's closes, and both close while a soul is at the desk.
func show_screens(writ: DawnWrit, book: DayBook, commands: DeskCommands) -> void:
	sync(commands)
	if commands.phase() == RunState.DAWN:
		book.close()
		var day: DayRules = commands.day_rules()
		var begin: String = commands.slice_rules().text.begin_label
		writ.show_dawn(day.day, ScreenText.dawn_lines(day), begin)
		return
	writ.close()
	show_book(book, commands)


## Draws dusk's spread on show, or the ending (its tableau, then the last spread), in the
## day-book; closes the book in any other phase.
func show_book(book: DayBook, commands: DeskCommands) -> void:
	var shown: Card = card(commands)
	if shown == null or commands.phase() == RunState.DAWN:
		book.close()
		return
	if not _ending:
		book.show_spread(_spreads[_index], shown.next_label, shown.skip_label)
		return
	var report: EndingReport = commands.ending()
	var rules: SliceRules = commands.slice_rules()
	var lines: Array[String] = ScreenText.ending_lines(report, rules)
	var outcome: Array[String] = [lines[1]]
	book.show_ending(
		tableau_for(report.outcome),
		ScreenText.ending_rows(report, rules),
		lines[0],
		outcome,
		report.promise_line,
		lines[-1],
		shown.next_label,
		ScreenText.ending_headers(rules)
	)


## The ending's tableau on the gate band for an outcome (D23).
static func tableau_for(outcome: StringName) -> StringName:
	match outcome:
		EndingReport.TIDE:
			return DayBook.TIDE
		EndingReport.HOLLOW:
			return DayBook.HOLLOW
	return DayBook.HOLDS


## The card's main button: begin the day, the next dusk card, the next day, or play again. The
## card on screen is then card(); a command that changes the desk also redraws it.
func advance(commands: DeskCommands) -> void:
	sync(commands)
	match commands.phase():
		RunState.DAWN:
			commands.begin_day()
		RunState.DUSK, RunState.ENDING:
			if _ending:
				reset()
				if on_restart.is_valid():
					on_restart.call()
				else:
					commands.restart_run()
			elif _index < _spreads.size() - 1:
				_index += 1
			else:
				_finish(commands)


## "Skip all": straight to the end of the dusk (the ledger is already written).
func skip(commands: DeskCommands) -> void:
	sync(commands)
	if commands.phase() == RunState.DUSK or (commands.phase() == RunState.ENDING and not _ending):
		_finish(commands)


## The ending with one blank line between the sections ScreenText composes: the outcome, the
## rows, the ledger's line (when Hel made an offer), the standing.
static func ending_text(report: EndingReport, rules: SliceRules) -> String:
	return "\n\n".join(ScreenText.ending_sections(report, rules))


## Which spread shows: its index within the dusk, or -1 on the ending (tests, the harness).
func card_index() -> int:
	return -1 if _ending else _index


func card_count() -> int:
	return _spreads.size()


## Whether the slice's ending shows (after day 3's dusk), with only "Play again".
func showing_ending() -> bool:
	return _ending


func _start_dusk(commands: DeskCommands) -> void:
	var report: DuskReport = commands.dusk_report()
	if report.day == _dusk_day:
		return
	_dusk_day = report.day
	_spreads = ScreenText.dusk_spreads(report, commands.slice_rules())
	_index = 0
	_ending = false


func _finish(commands: DeskCommands) -> void:
	if commands.phase() == RunState.ENDING:
		_ending = true
	else:
		commands.next_day()


func _finish_label(commands: DeskCommands) -> String:
	var text: DeskText = commands.slice_rules().text
	return text.next_label if commands.phase() == RunState.ENDING else text.next_day_label
