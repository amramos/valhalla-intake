extends GutTest
## The day clock (D10, D22, D36): untimed day 1, real time plus action costs, a single warning at
## 30 s, pause, and an action in progress completing before the horn.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func test_an_untimed_clock_never_runs_out() -> void:
	var clock := DayClock.new(0.0)
	clock.tick(1000.0)
	clock.charge(1000.0)
	assert_eq(clock.time_left(), INF)
	assert_false(clock.is_out())
	assert_false(clock.take_warning())


func test_pause_stops_real_time_but_not_action_costs() -> void:
	var clock := DayClock.new(100.0)
	clock.paused = true
	clock.tick(40.0)
	assert_eq(clock.time_left(), 100.0)
	clock.charge(10.0)
	assert_eq(clock.time_left(), 90.0)


func test_the_warning_comes_once_and_the_clock_stops_at_zero() -> void:
	var clock := DayClock.new(100.0, 30.0)
	clock.tick(69.0)
	assert_false(clock.take_warning(), "31 s left")
	clock.tick(1.0)
	assert_true(clock.take_warning(), "30 s left")
	assert_false(clock.take_warning(), "only once")
	clock.tick(500.0)
	assert_eq(clock.time_left(), 0.0)
	assert_true(clock.is_out())


func test_desk_time_runs_only_on_the_desk_and_not_while_paused() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(1, 3)
	desk.stamp(Realm.HEL)
	assert_eq(desk.phase(), &"dusk")
	desk.next_day()
	desk.advance_time(50.0)
	assert_eq(desk.time_left(), 300.0, "no time at dawn")
	desk.begin_day()
	desk.set_paused(true)
	desk.advance_time(50.0)
	assert_eq(desk.time_left(), 300.0, "no time while paused")
	desk.set_paused(false)
	desk.advance_time(50.0)
	assert_eq(desk.time_left(), 250.0)


func test_the_desk_warns_once_at_thirty_seconds() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	watch_signals(desk)
	desk.advance_time(260.0)
	desk.advance_time(5.0)
	desk.advance_time(5.0)
	assert_signal_emit_count(desk, "clock_warning", 1)


func test_a_pin_in_progress_completes_then_the_horn_sounds() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	desk.advance_time(297.0)
	var events: Array[String] = []
	desk.horn.connect(func() -> void: events.append("horn"))
	var result: PinResult = desk.pin("B2", "L4")
	assert_eq(result.kind, PinResult.Kind.NO_SEAM, "the pin resolved")
	assert_eq(result.seconds_lost, 10.0)
	assert_eq(events, ["horn"] as Array[String])
	assert_eq(desk.phase(), &"dusk")
	assert_eq(desk.dusk_report().never_judged, ["Sigvaldi", "Hakon", "Grim"] as Array[String])


func test_a_huginn_answer_in_progress_completes_then_the_horn_sounds() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	assert_eq(desk.current_encounter().soul_name, "Ketil")
	desk.pin("C2", "W1")
	desk.advance_time(desk.time_left() - 2.0)
	watch_signals(desk)
	var answer: String = desk.ask_huginn(0)
	assert_eq(answer, "The claim lies.", "the answer is given")
	assert_eq(desk.huginn_left(), 1, "and paid for")
	assert_signal_emitted(desk, "horn")
	assert_eq(desk.phase(), &"ending")
