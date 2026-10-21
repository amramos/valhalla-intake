extends GutTest
## The mentor's guided steps (D16): READ finishes on acknowledgement, PIN when its pair is threaded,
## STAMP at the stamp; every step change redraws the desk, and a restart starts her over.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


## The synthetic slice with Ulf guided: read, pin C1 × L1, stamp at the spear door.
func _guided_desk() -> DeskCommands:
	var queues: Array = Fixture.queues()
	var ulf: Encounter = queues[0][0]
	ulf.mentor_steps = [
		MentorStep.make("Read the body first.", MentorStep.Until.READ, ["B1", "B2", "B3"]),
		MentorStep.make("Pin them.", MentorStep.Until.PIN, ["C1", "L1"]),
		MentorStep.make("Stamp him.", MentorStep.Until.STAMP, [], Realm.VALHALLA),
	]
	var desk := DeskCommands.new()
	desk.start_run(Fixture.days(), queues, Fixture.rules(), Fixture.variants())
	desk.begin_day()
	return desk


func test_the_steps_run_read_pin_stamp() -> void:
	var desk: DeskCommands = _guided_desk()
	assert_eq(desk.mentor_step().text, "Read the body first.")
	assert_eq(desk.mentor_step().highlight, ["B1", "B2", "B3"] as Array[String])
	watch_signals(desk)
	desk.mentor_ack()
	assert_signal_emitted(desk, "desk_changed", "an advance redraws the desk")
	assert_eq(desk.mentor_step().until, MentorStep.Until.PIN)
	desk.pin("B1", "C1")
	assert_eq(desk.mentor_step().until, MentorStep.Until.PIN, "another pair doesn't finish it")
	desk.mentor_ack()
	assert_eq(desk.mentor_step().until, MentorStep.Until.PIN, "nor does an acknowledgement")
	desk.pin("L1", "C1")
	var stamp_step: MentorStep = desk.mentor_step()
	assert_eq(stamp_step.until, MentorStep.Until.STAMP)
	assert_eq(stamp_step.door, Realm.VALHALLA)
	desk.stamp(Realm.VALHALLA)
	assert_null(desk.mentor_step(), "Kolbeinn is not guided here")


func test_a_pair_threaded_early_finishes_its_pin_step_when_it_comes_up() -> void:
	var desk: DeskCommands = _guided_desk()
	desk.pin("C1", "L1")
	assert_eq(desk.mentor_step().until, MentorStep.Until.READ)
	desk.mentor_ack()
	assert_eq(desk.mentor_step().until, MentorStep.Until.STAMP)


func test_a_stamp_ends_the_guidance_on_that_soul() -> void:
	var desk: DeskCommands = _guided_desk()
	desk.stamp(Realm.HEL)
	assert_true(desk.awaiting_next(), "Ulf to Hel draws a day-1 warning")
	assert_null(desk.mentor_step(), "no bubble over a stamped soul")


func test_restart_starts_the_mentor_over() -> void:
	var desk: DeskCommands = _guided_desk()
	desk.mentor_ack()
	desk.pin("C1", "L1")
	desk.restart_run()
	desk.begin_day()
	assert_eq(desk.mentor_step().text, "Read the body first.")


func test_an_unguided_soul_has_no_step() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.begin_day()
	assert_null(desk.mentor_step())
	watch_signals(desk)
	desk.mentor_ack()
	assert_signal_not_emitted(desk, "desk_changed")
