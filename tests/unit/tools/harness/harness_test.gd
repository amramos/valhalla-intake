extends GutTest
## The text harness (D13): it drives the same commands as the desk and describes only what the
## desk shows: never a legal or worthy destination, the seam list, or the truth.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")
const Harness := preload("res://tools/harness/harness.gd")
## Words that would name hidden fields; none may appear at dawn or at the desk.
const HIDDEN_WORDS: Array[String] = ["legal", "worthy", "deserved", "truth", "liar", "seams"]

var _checked: int = 0
var _leaks: Array[String] = []


func _check(harness: Harness) -> void:
	var text: String = harness.describe()
	var phase: StringName = harness.desk.phase()
	_checked += 1
	for word: String in HIDDEN_WORDS:
		if phase in [&"dawn", &"desk"] and text.to_lower().contains(word):
			_leaks.append("%s: '%s'" % [phase, word])
	if phase != &"desk":
		return
	var soul: Encounter = harness.desk.current_encounter()
	if text.contains(soul.truth):
		_leaks.append("%s: truth" % soul.soul_name)
	var shown: Array[String] = []
	for seam: Seam in harness.desk.threads():
		shown.append(seam.caption)
	for seam: Seam in soul.seams:
		if not shown.has(seam.caption) and text.contains(seam.caption):
			_leaks.append("%s: unthreaded caption %s-%s" % [soul.soul_name, seam.a, seam.b])


## Plays the rest of the run: at each soul, describe; thread its first seam; describe; stamp.
func _walk(harness: Harness, merciful: bool = false) -> void:
	var desk: DeskCommands = harness.desk
	for _step: int in range(100):
		_check(harness)
		match desk.phase():
			&"dawn":
				harness.act("begin")
			&"dusk":
				harness.act("next")
			&"desk":
				if desk.awaiting_next():
					harness.act("next")
					continue
				var soul: Encounter = desk.current_encounter()
				if not soul.seams.is_empty():
					harness.act("pin %s %s" % [soul.seams[0].a, soul.seams[0].b])
					_check(harness)
				var realm: StringName = soul.worthy_realm if merciful else soul.legal_realm
				harness.act("stamp %s" % realm)
			_:
				return


func test_describe_never_shows_destinations_seams_or_truth() -> void:
	var strict := Harness.new(Fixture.desk())
	_walk(strict)
	var merciful := Harness.new(Fixture.desk())
	_walk(merciful, true)
	var returned := Harness.new(Fixture.desk())
	returned.act("jump 3 2")
	_walk(returned)
	var data := Harness.new(SliceLoader.load_slice())
	_walk(data)
	assert_gt(_checked, 60, "every phase of every fixture was described")
	assert_eq(_leaks, [] as Array[String])


func test_the_returned_soul_and_the_empty_witness_panel_show() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 2")
	var text: String = harness.describe()
	assert_string_contains(text, "At the desk: Hakon (frost-burned name plate)")
	assert_string_contains(text, "Witness: No witness came back.")


func test_a_session_plays_ulf_through_the_commands() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	assert_string_contains(harness.describe(), "== Day 1, dawn ==")
	harness.act("begin")
	var pinned: String = harness.act("pin C1 L1")
	assert_true(harness.last_ok)
	assert_eq(pinned, "A law thread: the saga is true. L1 sends him to Valhalla.")
	assert_string_contains(harness.describe(), "1. C1-L1 law thread")
	var stamped: String = harness.act("stamp valhalla")
	assert_string_contains(stamped, "Ulf goes through to Valhalla.")
	assert_string_contains(harness.describe(), "At the desk: Kolbeinn")
	harness.act("stamp ran")
	assert_false(harness.last_ok, "a closed door is refused")
	harness.act("dance")
	assert_false(harness.last_ok, "an unknown command is refused")


func test_a_stamp_costs_simulated_reading_time_and_the_horn_is_reported() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 1")
	harness.act("stamp valhalla")
	assert_eq(harness.desk.time_left(), 300.0 - Harness.STAMP_SECONDS)
	harness.act("wait 275")
	var result: String = harness.act("pin B1 C2")
	assert_string_contains(result, "No seam: those two agree. -10 s")
	assert_string_contains(result, "The horn sounds.")
	assert_string_contains(harness.describe(), "== Day 2, dusk ==")


func test_a_citation_drops_a_black_feather_on_the_desk() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	var result: String = harness.act("stamp valhalla")
	assert_string_contains(result, "A black feather drops (-2): Citation: L2.")


func test_actions_offer_huginn_only_for_an_unanswered_grey_thread() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 4")
	assert_false(harness.actions().contains("huginn"))
	harness.act("pin C2 W1")
	assert_string_contains(harness.actions(), "huginn <thread>       ask about grey thread 1")
	assert_eq(harness.act("huginn 1"), "Huginn, on thread 1: The claim lies.")
	assert_string_contains(harness.describe(), "(knot): one of them lies. Huginn: The claim lies.")


func test_the_ledger_names_hels_ask_after_dusk_is_skipped() -> void:
	# The review's case: skipping day-2 dusk must not hide the promise (D3, D15).
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	harness.act("stamp hel")
	harness.act("next")
	var dawn: String = harness.describe()
	assert_string_contains(
		dawn, "Ledger: Hel asks you to send Ragna to Hel, for 4 feathers (open)."
	)
	harness.act("jump 3 3")
	harness.act("stamp hel")
	assert_string_contains(harness.describe(), "(kept)")


func test_the_ending_lists_a_lapsed_promise() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 1")
	harness.act("wait 1000")
	assert_string_contains(harness.describe(), "Ragna to Hel, for 4 feathers (lapsed)")


func test_the_last_stamp_of_a_timed_day_costs_its_reading_time_too() -> void:
	# The review's case: the day's final stamp skipped its simulated 20 s.
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	harness.act("stamp hel")
	assert_eq(harness.desk.phase(), &"dusk")
	assert_eq(harness.desk.time_left(), 300.0 - Harness.STAMP_SECONDS)


func test_the_black_feather_shows_the_capped_citation_loss_not_the_net_change() -> void:
	# The review's case: Hel's reward made the feather read "(--2)".
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 3")
	var result: String = harness.act("stamp hel")
	assert_string_contains(result, "A black feather drops (-2): Citation: L5.")


func test_an_untimed_no_seam_pin_reads_as_on_the_desk() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("begin")
	assert_eq(harness.act("pin B1 C2"), "No seam: those two agree.")


func test_hels_tide_shows_at_her_door() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 1 3")
	assert_string_contains(harness.describe(), "Hel's tide: 0 of 3")
	harness.act("stamp hel")
	assert_string_contains(harness.describe(), "Hel's tide: 1 of 3")


func test_the_mentor_guides_ulf_and_ack_finishes_her_read_step() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("begin")
	assert_string_contains(
		harness.describe(), "The mentor: Read the body first. [lit: B1, B2, B3] (ack to go on)"
	)
	assert_string_contains(harness.actions(), "ack")
	assert_eq(harness.act("ack"), "You nod to the mentor.")
	assert_string_contains(harness.describe(), "[lit: C1, L1] (pin the lit pair)")
	harness.act("ack")
	assert_false(harness.last_ok, "a pin step isn't acknowledged away")
	harness.act("pin C1 L1")
	assert_string_contains(harness.describe(), "[points at the Valhalla door] (stamp)")
