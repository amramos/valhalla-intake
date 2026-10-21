class_name PhaseFlow
extends RefCounted
## The cards between souls (D15, D23, D34): the dawn card, the dusk sequence with "Next" and
## "Skip all", and the slice's ending after day 3's dusk. ScreenText composes every word; this
## keeps the place in the sequence and turns a button into the next command. Skipping hides
## nothing with consequences: the ledger is written in core before the first card shows. It holds
## no card node, so the text harness walks the same sequence (D13): card() says what shows, and
## show() draws it on the desk's PhaseCard.

const CARD_WIDTH := 320.0
const ENDING_WIDTH := 470.0

## What "Play again" does (the desk system's full restart).
var on_restart: Callable = Callable()

## The dusk being shown (its day), its cards, and the card on screen.
var _dusk_day: int = -1
var _cards: Array[String] = []
var _index: int = 0
var _ending: bool = false


## One card as it shows: a title line ("" for none) over its body, the main button's label, the
## "Skip all" label ("" for no second button) and the card's width.
class Card:
	extends RefCounted
	var title: String = ""
	var body: String = ""
	var next_label: String = ""
	var skip_label: String = ""
	var width: float = CARD_WIDTH

	func text() -> String:
		return body if title == "" else title + "\n" + body


## Forgets the sequence (a restart).
func reset() -> void:
	_dusk_day = -1
	_cards.clear()
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
				shown.width = ENDING_WIDTH
			else:
				var last: bool = _index >= _cards.size() - 1
				shown.title = text.dusk_title_format % commands.dusk_report().day
				shown.body = _cards[_index]
				shown.next_label = _finish_label(commands) if last else text.next_label
				shown.skip_label = "" if last else text.skip_all_label
		_:
			return null
	return shown


## Draws the card for the commands' phase, or hides it while a soul is at the desk.
func show(card_node: PhaseCard, commands: DeskCommands) -> void:
	var shown: Card = card(commands)
	if shown == null:
		card_node.visible = false
		return
	card_node.show_card(shown.text(), shown.next_label, shown.skip_label, shown.width)


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
			elif _index < _cards.size() - 1:
				_index += 1
			else:
				_finish(commands)


## "Skip all": straight to the end of the dusk (the ledger is already written).
func skip(commands: DeskCommands) -> void:
	sync(commands)
	if commands.phase() == RunState.DUSK or (commands.phase() == RunState.ENDING and not _ending):
		_finish(commands)


## The ending's lines with one blank line between its sections: the outcome (title and text), the
## rows, the ledger's line (when Hel made an offer), the standing.
static func ending_text(report: EndingReport, rules: SliceRules) -> String:
	var lines: Array[String] = ScreenText.ending_lines(report, rules)
	var rows_end: int = mini(2 + report.entries.size(), lines.size())
	var sections: Array[String] = [
		"\n".join(lines.slice(0, 2)), "\n".join(lines.slice(2, rows_end))
	]
	for line: String in lines.slice(rows_end):
		sections.append(line)
	return "\n\n".join(sections)


## Which card shows: its index within the dusk, or -1 on the ending (tests, the harness).
func card_index() -> int:
	return -1 if _ending else _index


func card_count() -> int:
	return _cards.size()


## Whether the slice's ending shows (after day 3's dusk), with only "Play again".
func showing_ending() -> bool:
	return _ending


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


func _finish(commands: DeskCommands) -> void:
	if commands.phase() == RunState.ENDING:
		_ending = true
	else:
		commands.next_day()


func _finish_label(commands: DeskCommands) -> String:
	var text: DeskText = commands.slice_rules().text
	return text.next_label if commands.phase() == RunState.ENDING else text.next_day_label
