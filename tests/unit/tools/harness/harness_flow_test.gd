extends GutTest
## The harness's flow screens (D13, D15, D31; matrix A5-A8): title, dawn, the dusk cards with
## Next and Skip all, the ending and the pause menu, with the same text the desk draws
## (ScreenText, DeskText). Full runs through the harness end on the right souls, and no screen
## shows a destination, the seam list or a truth before its day is over.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")
const Harness := preload("res://tools/harness/harness.gd")
## Words that would name hidden fields; none may appear before dusk as a whole word. "liar" and
## "worthy" are not among them, because the desk says them: the mentor asks "Where does a liar
## go?", and day 1's dawn card says "Send a worthy soul to Hel" (D53). The worthy realm itself
## would read "worthy realm" or "worthy destination".
const HIDDEN_WORDS: Array[String] = [
	"legal", "worthy realm", "worthy destination", "deserved", "truth", "seams"
]

var _checked: int = 0
var _leaks: Array[String] = []


## Every truth line in the run, by the first day it can be told (the slot-10 souls on day 3).
func _truths_by_day(queues: Array, variants: Array) -> Dictionary:
	var truths: Dictionary = {}
	for index: int in queues.size():
		for soul: Encounter in queues[index]:
			truths[soul.truth] = mini(truths.get(soul.truth, 99), index + 1)
	for soul: Encounter in variants:
		truths[soul.truth] = mini(truths.get(soul.truth, 99), 3)
	return truths


func _check(harness: Harness, truths: Dictionary) -> void:
	var text: String = harness.describe()
	var phase: StringName = harness.desk.phase()
	var over_the_run: bool = harness.view.screen != &""
	_checked += 1
	if phase in [&"dawn", &"desk"] or over_the_run:
		for word: String in HIDDEN_WORDS:
			if RegEx.create_from_string("\\b%s\\b" % word).search(text.to_lower()) != null:
				_leaks.append("%s: '%s'" % [phase, word])
	# A truth is told only at the dusk of its own day, or later (D15).
	var day: int = harness.desk.day_number()
	for truth: String in truths:
		var told: bool = phase == &"ending" or (phase == &"dusk" and truths[truth] <= day)
		told = told and not over_the_run
		if not told and text.contains(truth):
			_leaks.append("%s day %d: truth of a soul not yet recapped" % [phase, day])
	if phase != &"desk":
		return
	var soul: Encounter = harness.desk.current_encounter()
	var shown: Array[String] = []
	for seam: Seam in harness.desk.threads():
		shown.append(seam.caption)
	for seam: Seam in soul.seams:
		if not shown.has(seam.caption) and text.contains(seam.caption):
			_leaks.append("%s: unthreaded caption %s-%s" % [soul.soul_name, seam.a, seam.b])


## Plays the run through harness commands, day 3's dusk included, to the ending. choose(soul)
## picks the door; with `thread`, every seam is pinned first and a grey one asked of Huginn. Pauses
## and resumes once a day, to check the menu. Stops early when stop(harness) is true.
func _play(
	harness: Harness,
	choose: Callable,
	thread: bool,
	truths: Dictionary = {},
	stop: Callable = Callable()
) -> void:
	var desk: DeskCommands = harness.desk
	var paused_on: int = 0
	for _step: int in range(300):
		if not truths.is_empty():
			_check(harness, truths)
		if stop.is_valid() and stop.call(harness):
			return
		match desk.phase():
			&"dawn":
				harness.act("begin")
			&"dusk":
				harness.act("next")
			&"desk":
				if paused_on < desk.day_number():
					paused_on = desk.day_number()
					harness.act("pause")
					if not truths.is_empty():
						_check(harness, truths)
					harness.act("resume")
				if desk.awaiting_next():
					harness.act("next")
					continue
				var soul: Encounter = desk.current_encounter()
				if thread:
					for seam: Seam in soul.seams:
						harness.act("pin %s %s" % [seam.a, seam.b])
						if seam.kind == Seam.Kind.GREY and desk.day_rules().huginn_answers > 0:
							harness.act("huginn %d" % desk.threads().size())
				harness.act("stamp %s" % choose.call(soul))
			&"ending":
				# Day 3's dusk cards come first; "next" is refused once the ending shows.
				harness.act("next")
				if not harness.last_ok:
					return
			_:
				return


func _at_day_threes_end(harness: Harness) -> bool:
	return harness.desk.phase() == &"ending"


func _at_day_threes_desk(harness: Harness) -> bool:
	return harness.desk.phase() == &"desk" and harness.desk.day_number() == 3


## Day 3's dusk as the desk shows it (PhaseFlow, ScreenText): each card with Next, Skip all until
## the last, then the ending with Play again and nothing else.
func _assert_day_threes_dusk_then_the_ending(harness: Harness) -> void:
	var rules: SliceRules = harness.desk.slice_rules()
	var cards: Array[String] = ScreenText.dusk_cards(harness.desk.dusk_report(), rules)
	assert_gt(cards.size(), 1, "day 3's dusk has several cards")
	for index: int in cards.size():
		var shown: String = harness.describe()
		var title: String = rules.text.dusk_title_format % 3
		var heading: String = "== %s Card %d of %d ==\n" % [title, index + 1, cards.size()]
		assert_true(shown.begins_with(heading), shown)
		assert_string_contains(shown, cards[index])
		var last: bool = index == cards.size() - 1
		assert_string_contains(
			harness.actions(), "next                  %s" % rules.text.next_label
		)
		assert_eq(harness.actions().contains(rules.text.skip_all_label), not last, "Skip all")
		assert_false(harness.actions().contains(rules.text.play_again), "no Play again at dusk")
		harness.act("next")
		assert_true(harness.last_ok, "next turns card %d" % (index + 1))
	assert_eq(harness.describe(), PhaseFlow.ending_text(harness.desk.ending(), rules))
	assert_string_contains(harness.actions(), rules.text.play_again)
	harness.act("next")
	assert_false(harness.last_ok, "the ending has only Play again")


func _legal(soul: Encounter) -> StringName:
	return soul.legal_realm


func _worthy(soul: Encounter) -> StringName:
	return soul.worthy_realm


func _keep_the_promise(soul: Encounter) -> StringName:
	return Realm.HEL if soul.hel_marked else soul.legal_realm


func test_no_screen_shows_destinations_seams_or_truth_before_its_day_is_over() -> void:
	var queues: Array = Fixture.queues()
	var variants: Array = Fixture.variants().values()
	var truths: Dictionary = _truths_by_day(queues, variants)
	for choose: Callable in [_legal, _worthy]:
		var desk := DeskCommands.new()
		desk.start_run(Fixture.days(), Fixture.queues(), Fixture.rules(), Fixture.variants())
		_play(Harness.new(desk), choose, choose == _legal, truths)
	var slice: SliceData = load("res://data/slice.tres") as SliceData
	var data_queues: Array = []
	for day: DayData in slice.days:
		data_queues.append(day.encounters_to_core())
	var data_variants: Array = [
		slice.returned_ignored.to_core(), slice.returned_missed.to_core(), slice.fallback.to_core()
	]
	var data_truths: Dictionary = _truths_by_day(data_queues, data_variants)
	var title := Harness.new(SliceLoader.load_slice(), true)
	_check(title, data_truths)
	title.act("start")
	_play(title, _legal, true, data_truths)
	assert_gt(_checked, 80, "every screen of every run was described")
	assert_eq(_leaks, [] as Array[String])


func test_strict_obedience_through_the_harness_ends_on_hels_tide() -> void:
	var harness := Harness.new(SliceLoader.load_slice(), true)
	harness.act("start")
	_play(harness, _legal, true)
	var ending: String = harness.describe()
	assert_true(ending.begins_with("Hel's tide\n"), ending)
	assert_string_contains(ending, "break the line: Asa, Hakon, Hakon (returned).")
	assert_string_contains(ending, "Hakon (returned): Hel. Truth: Valhalla. Ignored.")
	assert_string_contains(ending, "Broken. Ragna went to Fólkvangr.")
	assert_string_contains(ending, "Feathers: 13. Rank: Chooser of the Slain.")
	assert_string_contains(harness.actions(), "Play again")


func test_keeping_hels_promise_through_the_harness_adds_ragna_to_the_tide() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	_play(harness, _keep_the_promise, true)
	var ending: String = harness.describe()
	assert_string_contains(ending, "break the line: Asa, Hakon, Hakon (returned), Ragna.")
	assert_string_contains(ending, "Kept. Ragna went to Hel. Hel paid 4 feathers.")
	assert_string_contains(ending, "Feathers: 15.")


func test_mercy_through_the_harness_holds_the_hall() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	_play(harness, _worthy, false)
	var ending: String = harness.describe()
	assert_true(ending.begins_with("The Hall holds\n"), ending)
	assert_string_contains(ending, "Egil: Fólkvangr. Truth: Fólkvangr.")
	assert_string_contains(ending, "Asa: Valhalla. Truth: Valhalla.")
	assert_false(ending.contains("(returned)"), "Hakon was spared, so Egil came instead")


func test_the_title_starts_the_run_and_quit_asks_first() -> void:
	var harness := Harness.new(SliceLoader.load_slice(), true)
	assert_eq(harness.describe(), "== Valhalla Intake ==\n  Start\n  Quit")
	harness.act("begin")
	assert_false(harness.last_ok, "the title comes first")
	harness.act("quit")
	assert_string_contains(harness.describe(), "Quit the game?\n  Yes / No")
	harness.act("no")
	assert_string_contains(harness.describe(), "== Valhalla Intake ==")
	assert_eq(harness.act("start"), "Day 1 dawns.")
	assert_string_contains(harness.describe(), "== Day 1, dawn ==\nDay 1.\n")


func test_the_dawn_card_reads_the_days_lines_with_its_clock() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("jump 2 1")
	harness.act("restart")
	harness.act("yes")
	harness.act("jump 1 4")
	harness.act("stamp hel")
	harness.act("skip")
	assert_string_contains(
		harness.describe(), "The clock: 5:00. It runs while a soul is at the desk."
	)


func test_dusk_turns_its_cards_with_next_and_skip_all_goes_to_dawn() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("jump 2 4")
	harness.act("stamp valhalla")
	harness.act("next")
	var cards: Array[String] = harness.view.dusk_cards()
	assert_string_contains(harness.describe(), "== Dusk, day 2. Card 1 of %d ==" % cards.size())
	assert_string_contains(harness.describe(), "Citations today: 1.")
	harness.act("next")
	var quota: String = harness.describe()
	assert_string_contains(quota, "Card 2 of")
	assert_string_contains(quota, "Feathers: 12 at dawn, 12 now.")
	assert_string_contains(quota, "Citation (Brand): -2.")
	assert_string_contains(quota, "Quota: +2.")
	assert_string_contains(harness.actions(), "Next")
	for _card: int in cards.size() - 2:
		harness.act("next")
	assert_string_contains(harness.describe(), "Hakon is back.")
	assert_string_contains(harness.actions(), "Next day")
	harness.act("next")
	assert_string_contains(harness.describe(), "== Day 3, dawn ==")


func test_skip_all_leaves_dusk_at_once() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	harness.act("stamp hel")
	assert_eq(harness.act("skip"), "Dawn of day 3.")


func test_pause_stops_the_desk_and_restart_asks_first() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 2")
	assert_eq(harness.act("pause"), "Paused")
	assert_eq(harness.describe(), "== Paused ==\n  Resume\n  Restart the run\n  Quit")
	assert_true(harness.desk.is_paused())
	harness.act("stamp hel")
	assert_false(harness.last_ok, "nothing moves under the pause menu")
	harness.act("restart")
	assert_string_contains(
		harness.describe(), "Restart the run from day 1? Everything since is lost."
	)
	harness.act("no")
	harness.act("resume")
	assert_false(harness.desk.is_paused())
	assert_string_contains(harness.describe(), "At the desk: Hakon")
	harness.act("restart")
	harness.act("yes")
	assert_string_contains(harness.describe(), "== Day 1, dawn ==")
	assert_false(harness.desk.is_paused())


func test_play_again_at_the_ending_needs_no_confirm() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 4")
	harness.act("stamp hel")
	assert_eq(harness.desk.phase(), &"ending")
	harness.act("skip")
	harness.act("restart")
	assert_string_contains(harness.describe(), "== Day 1, dawn ==")


## The review's case: Esc opens the pause on the desk's ending card, so the harness pauses there
## too (D13, D31), and Resume returns to the ending.
func test_pause_opens_at_the_ending_as_on_the_desk() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 4")
	harness.act("stamp hel")
	harness.act("skip")
	var rules: SliceRules = harness.desk.slice_rules()
	var ending: String = PhaseFlow.ending_text(harness.desk.ending(), rules)
	assert_eq(harness.describe(), ending, "the ending shows")
	assert_string_contains(harness.actions(), "pause")
	assert_eq(harness.act("pause"), rules.text.pause_title)
	assert_true(harness.last_ok, "the pause opens at the ending")
	assert_eq(harness.describe(), "== Paused ==\n  Resume\n  Restart the run\n  Quit")
	harness.act("resume")
	assert_eq(harness.describe(), ending, "Resume returns to the ending")
	harness.act("pause")
	harness.act("restart")
	harness.act("yes")
	assert_string_contains(harness.describe(), "== Day 1, dawn ==", "Restart from the pause")


## The review's case: day 3's last stamp shows day 3's dusk, as the desk does (D13), and only
## then the ending.
func test_day_threes_last_stamp_shows_its_dusk_and_then_the_ending() -> void:
	var harness := Harness.new(SliceLoader.load_slice(), true)
	harness.act("start")
	_play(harness, _legal, true, {}, _at_day_threes_end)
	assert_eq(harness.desk.phase(), &"ending")
	assert_gt(harness.desk.time_left(), 0.0, "the last stamp ended the day, not the horn")
	_assert_day_threes_dusk_then_the_ending(harness)
	assert_true(harness.describe().begins_with("Hel's tide\n"), harness.describe())


func test_day_threes_horn_shows_its_dusk_and_then_the_ending() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	_play(harness, _worthy, false, {}, _at_day_threes_desk)
	assert_string_contains(harness.act("wait 400"), "The horn sounds.")
	assert_eq(harness.desk.phase(), &"ending")
	_assert_day_threes_dusk_then_the_ending(harness)


func test_skip_all_on_day_threes_dusk_shows_the_ending() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 4")
	harness.act("stamp hel")
	assert_string_contains(harness.describe(), "Card 1 of")
	harness.act("skip")
	assert_true(harness.last_ok)
	var rules: SliceRules = harness.desk.slice_rules()
	assert_eq(harness.describe(), PhaseFlow.ending_text(harness.desk.ending(), rules))
	assert_string_contains(harness.actions(), rules.text.play_again)
