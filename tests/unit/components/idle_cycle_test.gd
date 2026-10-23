extends GutTest
## IdleCycle (D17, D19): a seeded rest between two bounds, then each other frame for its hold,
## then rest again; the same seed always gives the same waits.


func test_it_rests_then_shows_each_frame_for_its_hold() -> void:
	var cycle := IdleCycle.new(3, 0.7, 0.7, 0.7)
	assert_eq(cycle.frame(), 0, "it starts at rest")
	assert_false(cycle.advance(0.69))
	assert_true(cycle.advance(0.02), "0.7 s on, the next frame")
	assert_eq(cycle.frame(), 1)
	cycle.advance(0.7)
	assert_eq(cycle.frame(), 2)
	cycle.advance(0.7)
	assert_eq(cycle.frame(), 0, "and back to rest")


func test_its_rests_fall_between_the_bounds_and_repeat_with_the_seed() -> void:
	var waits: Array[float] = _rests(IdleCycle.new(2, 3.0, 5.0, 0.5, 42), 20)
	var again: Array[float] = _rests(IdleCycle.new(2, 3.0, 5.0, 0.5, 42), 20)
	var other: Array[float] = _rests(IdleCycle.new(2, 3.0, 5.0, 0.5, 43), 20)
	var outside: Array[float] = waits.filter(
		func(wait: float) -> bool: return wait < 3.0 or wait > 5.0
	)
	assert_eq(outside, [] as Array[float], "every rest is 3 to 5 s")
	assert_eq(waits, again, "the same seed, the same rests")
	assert_ne(waits, other, "another seed, other rests")
	assert_gt(waits.max() - waits.min(), 0.5, "the rests vary")


func test_reset_returns_to_rest_and_repeats_the_first_wait() -> void:
	var cycle := IdleCycle.new(2, 3.0, 5.0, 0.5, 7)
	var first: float = cycle.time_left()
	cycle.advance(first + 0.1)
	assert_eq(cycle.frame(), 1)
	cycle.reset()
	assert_eq(cycle.frame(), 0)
	assert_eq(cycle.time_left(), first)


func test_a_long_step_lands_on_the_right_frame() -> void:
	var cycle := IdleCycle.new(2, 1.0, 1.0, 0.25)
	cycle.advance(1.1)
	assert_eq(cycle.frame(), 1, "1.1 s: inside the hold")
	cycle.advance(1.0)
	assert_eq(cycle.frame(), 0, "2.1 s: resting again since 1.25")
	cycle.advance(0.2)
	assert_eq(cycle.frame(), 1, "2.3 s: the second idle, from 2.25")


## The rest before each of `count` idles, measured by stepping the cycle.
func _rests(cycle: IdleCycle, count: int) -> Array[float]:
	var rests: Array[float] = []
	for _index: int in range(count):
		rests.append(cycle.time_left())
		cycle.advance(cycle.time_left())
		cycle.advance(cycle.time_left())
	return rests
