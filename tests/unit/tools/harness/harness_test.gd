extends GutTest
## The text harness at the desk (D13): it drives the same commands as the desk and describes only
## what the desk shows. The flow screens and full runs are in harness_flow_test.gd.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")
const Harness := preload("res://tools/harness/harness.gd")


func test_the_returned_soul_and_the_empty_witness_panel_show() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 3 2")
	var text: String = harness.describe()
	assert_string_contains(text, "At the desk: Hakon (frost-burned name plate)")
	assert_string_contains(text, "Witness: No witness came back.")


func test_the_witness_heading_shows_the_name_and_then_who_they_are() -> void:
	# D52: the heading is the name; the harness prints the role after it (the desk hovers the
	# whole description).
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("jump 2 1")
	assert_string_contains(harness.describe(), "WITNESS Bjorn (his shield-brother)")


func test_a_session_plays_ulf_through_the_commands() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	assert_string_contains(harness.describe(), "== Day 1, dawn ==")
	harness.act("begin")
	var pinned: String = harness.act("pin C1 L1")
	assert_true(harness.last_ok)
	assert_eq(pinned, "A law thread. C1 against L1: the saga is true. L1 sends him to Valhalla.")
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
	assert_string_contains(harness.describe(), "== Dusk, day 2. Card 1 of")


func test_a_citation_drops_a_black_feather_on_the_desk() -> void:
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	var result: String = harness.act("stamp valhalla")
	assert_string_contains(result, "A black feather drops (-2): Citation: L2.")


func test_huginns_answer_is_printed_once_without_a_doubled_prefix() -> void:
	# The WP4 report's case: "Huginn, on thread 1: Huginn: the claim lies."
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("jump 3 4")
	assert_false(harness.actions().contains("huginn"))
	harness.act("pin C2 W1")
	assert_string_contains(harness.actions(), "huginn <thread>       ask about grey thread 1")
	assert_eq(harness.act("huginn 1"), "Thread 1. Huginn: the claim lies.")
	assert_string_contains(
		harness.describe(), "(knot): one of them lies. [Huginn: the claim lies.]"
	)


func test_the_ledger_names_hels_ask_after_dusk_is_skipped() -> void:
	# The review's case: skipping day-2 dusk must not hide the promise (D3, D15).
	var harness := Harness.new(Fixture.desk())
	harness.act("jump 2 3")
	harness.act("stamp hel")
	harness.act("skip")
	assert_string_contains(harness.describe(), "Ledger: Hel: send Ragna to Hel. 4 feathers.")
	harness.act("jump 3 3")
	harness.act("stamp hel")
	assert_string_contains(
		harness.describe(), "Ledger: Kept. Ragna went to Hel. Hel paid 4 feathers."
	)


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


func test_the_mentor_guides_ulf_and_ack_finishes_her_read_steps() -> void:
	var harness := Harness.new(SliceLoader.load_slice())
	harness.act("begin")
	var first: MentorStep = harness.desk.mentor_step()
	assert_string_contains(
		harness.describe(), "The mentor: %s [lit: B1, B2, B3] (ack to go on)" % first.text
	)
	assert_string_contains(harness.actions(), "ack")
	assert_eq(harness.act("ack"), "You nod to the mentor.")
	assert_string_contains(harness.describe(), "[lit: C1, L1] (ack to go on)")
	harness.act("ack")
	assert_string_contains(harness.describe(), "[lit: C1, L1] (pin the lit pair)")
	harness.act("ack")
	assert_false(harness.last_ok, "a pin step isn't acknowledged away")
	harness.act("pin C1 L1")
	assert_string_contains(harness.describe(), "[points at the Valhalla door] (stamp)")
