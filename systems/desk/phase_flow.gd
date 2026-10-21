class_name PhaseFlow
extends RefCounted
## The cards between souls (D15, D23, D34): the dawn card, the dusk sequence with "Next" and
## "Skip all", and the slice's ending after day 3's dusk. ScreenText composes every word; this
## keeps the place in the sequence and turns a button into the next command. Skipping hides
## nothing with consequences: the ledger is written in core before the first card shows.

const CARD_WIDTH := 320.0
const ENDING_WIDTH := 470.0

## What "Play again" does (the desk system's full restart).
var on_restart: Callable = Callable()

## The dusk being shown (its day), its cards, and the card on screen.
var _dusk_day: int = -1
var _cards: Array[String] = []
var _index: int = 0
var _ending: bool = false


## Forgets the sequence (a restart).
func reset() -> void:
	_dusk_day = -1
	_cards.clear()
	_index = 0
	_ending = false


## Shows the card for the commands' phase, or hides it while a soul is at the desk.
func show(card: PhaseCard, commands: DeskCommands) -> void:
	var rules: SliceRules = commands.slice_rules()
	var text: DeskText = rules.text
	match commands.phase():
		RunState.DAWN:
			reset()
			var dawn: String = "\n".join(ScreenText.dawn_lines(commands.day_rules()))
			card.show_card(dawn, text.begin_label)
		RunState.DUSK, RunState.ENDING:
			_start_dusk(commands)
			if _ending:
				var lines: String = ending_text(commands.ending(), rules)
				card.show_card(lines, text.play_again, "", ENDING_WIDTH)
			else:
				var last: bool = _index >= _cards.size() - 1
				var next: String = _finish_label(commands) if last else text.next_label
				var title: String = text.dusk_title_format % commands.dusk_report().day
				var body: String = title + "\n" + _cards[_index]
				card.show_card(body, next, "" if last else text.skip_all_label)
		_:
			card.visible = false


## The card's main button: begin the day, the next dusk card, the next day, or play again.
func advance(card: PhaseCard, commands: DeskCommands) -> void:
	match commands.phase():
		RunState.DAWN:
			commands.begin_day()
			return
		RunState.DUSK, RunState.ENDING:
			if _ending:
				reset()
				if on_restart.is_valid():
					on_restart.call()
				else:
					commands.restart_run()
				return
			if _index < _cards.size() - 1:
				_index += 1
				show(card, commands)
				return
			_finish(card, commands)


## "Skip all": straight to the end of the dusk (the ledger is already written).
func skip(card: PhaseCard, commands: DeskCommands) -> void:
	if commands.phase() == RunState.DUSK or (commands.phase() == RunState.ENDING and not _ending):
		_finish(card, commands)


## The ending with one blank line between the sections ScreenText composes (D53): the outcome,
## the rows, the ledger's line, the last day's feathers, the standing.
static func ending_text(report: EndingReport, rules: SliceRules) -> String:
	return "\n\n".join(ScreenText.ending_sections(report, rules))


## Which card shows: its index within the dusk, or -1 on the ending (tests).
func card_index() -> int:
	return -1 if _ending else _index


func card_count() -> int:
	return _cards.size()


func _start_dusk(commands: DeskCommands) -> void:
	var report: DuskReport = commands.dusk_report()
	if report.day == _dusk_day:
		return
	_dusk_day = report.day
	_cards = ScreenText.dusk_cards(report, commands.slice_rules())
	_index = 0
	_ending = false
	if _cards.is_empty():
		_ending = commands.phase() == RunState.ENDING
		if not _ending:
			_cards = [""]


func _finish(card: PhaseCard, commands: DeskCommands) -> void:
	if commands.phase() == RunState.ENDING:
		_ending = true
		show(card, commands)
	else:
		commands.next_day()


func _finish_label(commands: DeskCommands) -> String:
	var text: DeskText = commands.slice_rules().text
	return text.next_label if commands.phase() == RunState.ENDING else text.next_day_label
