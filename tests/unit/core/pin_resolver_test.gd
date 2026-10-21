extends GutTest
## Pins (D8, D24, D38): an unordered pair, a free re-pin, and "no seam" for anything else,
## red herrings included.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func _resolve(soul: Encounter, a: String, b: String, threaded: Array[Seam] = []) -> PinResult:
	return PinResolver.resolve(soul, Fixture.decrees(3), a, b, threaded)


func test_a_seam_is_an_unordered_pair() -> void:
	var soul: Encounter = Fixture.kolbeinn()
	var forward: PinResult = _resolve(soul, "B1", "C1")
	var backward: PinResult = _resolve(soul, "C1", "B1")
	assert_eq(forward.kind, PinResult.Kind.THREAD)
	assert_eq(backward.kind, PinResult.Kind.THREAD)
	assert_same(forward.seam, backward.seam, "both orders find the one seam")


func test_a_threaded_pair_pins_again_as_already() -> void:
	var soul: Encounter = Fixture.kolbeinn()
	var seam: Seam = soul.seam_between("B1", "C1")
	var result: PinResult = _resolve(soul, "C1", "B1", [seam])
	assert_eq(result.kind, PinResult.Kind.ALREADY)
	assert_same(result.seam, seam)


func test_a_red_herring_is_no_seam() -> void:
	# Asa's empty hand against "spear in my two hands": explained by her own C3.
	var result: PinResult = _resolve(Fixture.asa(), "B3", "C2")
	assert_eq(result.kind, PinResult.Kind.NO_SEAM)
	assert_null(result.seam)


func test_a_law_thread_counts_as_a_seam() -> void:
	var result: PinResult = _resolve(Fixture.ulf(), "L1", "C1")
	assert_eq(result.kind, PinResult.Kind.THREAD)
	assert_eq(result.seam.kind, Seam.Kind.LAW)
	assert_eq(result.seam.destination, Realm.VALHALLA)


func test_unknown_same_or_out_of_force_items_are_invalid() -> void:
	var soul: Encounter = Fixture.hakon()
	assert_eq(_resolve(soul, "B1", "B1").kind, PinResult.Kind.INVALID, "same item")
	assert_eq(_resolve(soul, "B1", "Z9").kind, PinResult.Kind.INVALID, "unknown id")
	# L4 is not in force with three decrees, so Hakon's law thread can't be pinned yet.
	assert_eq(_resolve(soul, "C3", "L4").kind, PinResult.Kind.INVALID, "decree not in force")


func test_desk_charges_a_no_seam_pin_and_not_a_re_pin() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(2, 1)
	var start: float = desk.time_left()
	var thread: PinResult = desk.pin("C1", "L1")
	var again: PinResult = desk.pin("L1", "C1")
	assert_eq(thread.kind, PinResult.Kind.THREAD)
	assert_eq(again.kind, PinResult.Kind.ALREADY)
	assert_eq(desk.threads().size(), 1, "a re-pin doesn't double-count")
	assert_eq(desk.time_left(), start, "threads and re-pins are free")
	# Sigvaldi's back wound against L4 looks like flight but is a red herring (D24).
	var herring: PinResult = desk.pin("B2", "L4")
	assert_eq(herring.kind, PinResult.Kind.NO_SEAM)
	assert_eq(herring.seconds_lost, 10.0)
	assert_eq(desk.time_left(), start - 10.0)


func test_untimed_day_charges_nothing_for_no_seam() -> void:
	var desk: DeskCommands = Fixture.desk()
	desk.begin_day()
	var result: PinResult = desk.pin("B1", "C2")
	assert_eq(result.kind, PinResult.Kind.NO_SEAM)
	assert_eq(result.seconds_lost, 0.0)
	assert_eq(desk.time_left(), INF)
