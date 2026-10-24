extends GutTest
## The Teller's pace (D4, D41): characters at a fixed rate, a pause between lines, one blip per
## three non-space characters capped at 13 a second, finish-now, pause, and the instant speed.
## The teller stays out of the tree and is stepped with fixed deltas, so nothing depends on the
## frame rate.

const CPS := 40.0
const STEP := 1.0 / CPS
const PAUSE := 0.25

var _teller: Teller = null
var _label: Label = null
var _events: Array[String] = []


func before_each() -> void:
	_teller = autofree(Teller.new())
	_label = autofree(Label.new())
	_events.clear()
	_teller.line_shown.connect(func(index: int) -> void: _events.append("line %d" % index))
	_teller.blip.connect(func(_pitch: float) -> void: _events.append("blip"))
	_teller.finished.connect(func() -> void: _events.append("finished"))


func test_lines_are_revealed_at_the_pace_with_a_pause_between_them() -> void:
	_teller.start(_label, "abcd\nef", CPS, PAUSE, 7)
	var shown: Array[int] = [_label.visible_characters]
	for _frame: int in range(4):
		_teller._process(STEP)
		shown.append(_label.visible_characters)
	_teller._process(PAUSE - 0.01)
	shown.append(_label.visible_characters)
	_teller._process(0.01)
	shown.append(_label.visible_characters)
	_teller._process(STEP)
	shown.append(_label.visible_characters)
	_teller._process(STEP)
	shown.append(_label.visible_characters)
	assert_eq(shown, [0, 1, 2, 3, 4, 4, 5, 6, -1], "one character a step; line two after the pause")
	assert_eq(_label.text, "abcd\nef")
	assert_eq(_events, ["line 0", "blip", "line 1", "blip", "finished"])
	assert_false(_teller.is_telling())


func test_a_big_delta_spends_itself_across_lines_and_finishes_once() -> void:
	_teller.start(_label, "one\ntwo\nthree", CPS, PAUSE, 7)
	_teller._process(10.0)
	_teller._process(10.0)
	assert_eq(_label.visible_characters, -1)
	assert_eq(_events.filter(func(event: String) -> bool: return event == "finished").size(), 1)
	assert_eq(
		_events.filter(func(event: String) -> bool: return event.begins_with("line")),
		["line 0", "line 1", "line 2"]
	)


func test_the_whole_telling_takes_characters_over_cps_plus_the_pauses() -> void:
	var text: String = "Took it from him.\nHe ran.\nI stood."
	_teller.start(_label, text, CPS, PAUSE, 7)
	var characters: int = text.length() - 2
	var expected: float = characters / CPS + 2 * PAUSE
	var elapsed: float = 0.0
	while _teller.is_telling() and elapsed < 10.0:
		_teller._process(0.01)
		elapsed += 0.01
	assert_almost_eq(elapsed, expected, 0.011)


func test_finish_shows_everything_and_emits_the_rest_once() -> void:
	_teller.start(_label, "abc\ndef\nghi", CPS, PAUSE, 7)
	_teller._process(STEP)
	_teller.finish()
	_teller.finish()
	_teller._process(1.0)
	assert_eq(_label.visible_characters, -1)
	assert_false(_teller.is_telling())
	assert_eq(_events, ["line 0", "line 1", "line 2", "finished"])


func test_a_paused_teller_reveals_nothing_until_resumed() -> void:
	_teller.start(_label, "abcdef", CPS, PAUSE, 7)
	_teller._process(STEP)
	_teller.set_paused(true)
	_teller._process(5.0)
	var while_paused: int = _label.visible_characters
	_teller.set_paused(false)
	_teller._process(STEP)
	assert_eq([while_paused, _label.visible_characters], [1, 2])
	assert_true(_teller.is_telling())


func test_instant_shows_all_now_and_finishes_on_the_next_frame_without_blips() -> void:
	_teller.start(_label, "abcdef\nghijkl", INF, PAUSE, 7)
	var before: Array[String] = _events.duplicate()
	var telling: bool = _teller.is_telling()
	_teller._process(0.016)
	_teller._process(0.016)
	assert_eq(_label.visible_characters, -1)
	assert_false(telling, "instant is never a telling a click could consume (D37)")
	assert_eq(before, ["line 0", "line 1"])
	assert_eq(_events, ["line 0", "line 1", "finished"], "instant never blips (D41)")


func test_blips_come_every_three_non_space_characters() -> void:
	_teller.start(_label, "abc def ghi", 10.0, PAUSE, 7)
	_teller._process(10.0)
	assert_eq(_events.filter(func(event: String) -> bool: return event == "blip").size(), 3)


func test_the_cap_never_thins_the_normal_voice() -> void:
	_teller.start(_label, "x".repeat(30), CPS, PAUSE, 7)
	_teller._process(10.0)
	assert_eq(_events.filter(func(event: String) -> bool: return event == "blip").size(), 10)


func test_blips_are_capped_at_about_thirteen_a_second_at_fast() -> void:
	_teller.start(_label, "x".repeat(200), 80.0, PAUSE, 7)
	for _frame: int in range(100):
		_teller._process(0.01)
	var blips: int = _events.filter(func(event: String) -> bool: return event == "blip").size()
	assert_true(blips <= 13, "%d blips in one second" % blips)
	assert_true(blips >= 12, "the cap still lets the voice speak: %d" % blips)


func test_the_pitch_is_a_pure_function_of_the_voice_within_the_octave() -> void:
	var pitches: Array[float] = []
	_teller.blip.connect(func(pitch: float) -> void: pitches.append(pitch))
	_teller.start(_label, "abcdef", CPS, PAUSE, hash("Ulf"))
	_teller._process(1.0)
	assert_eq(pitches, [Teller.pitch_for(hash("Ulf")), Teller.pitch_for(hash("Ulf"))])
	for name: String in ["Ulf", "Kolbeinn", "Bersi", "Ragna", "Eyvind"]:
		var pitch: float = Teller.pitch_for(hash(name))
		assert_true(pitch >= 0.75 and pitch < 1.25, "%s: %f" % [name, pitch])


func test_the_same_inputs_tell_the_same_way() -> void:
	_teller.start(_label, "Took it.\nHe ran.", CPS, PAUSE, hash("Ulf"))
	for _frame: int in range(60):
		_teller._process(0.016)
	var first: Array[String] = _events.duplicate()
	_events.clear()
	var other: Label = autofree(Label.new())
	_teller.start(other, "Took it.\nHe ran.", CPS, PAUSE, hash("Ulf"))
	for _frame: int in range(60):
		_teller._process(0.016)
	assert_eq(_events, first)


func test_start_labels_tells_each_label_as_one_line_in_order() -> void:
	var labels: Array[Label] = []
	for text: String in ["ab", "cd"]:
		var label: Label = autofree(Label.new())
		label.text = text
		labels.append(label)
	_teller.start_labels(labels, CPS, PAUSE, 7)
	var start: Array[int] = [labels[0].visible_characters, labels[1].visible_characters]
	_teller._process(2 * STEP)
	var after_one: Array[int] = [labels[0].visible_characters, labels[1].visible_characters]
	_teller._process(PAUSE + STEP)
	var after_two: Array[int] = [labels[0].visible_characters, labels[1].visible_characters]
	_teller._process(STEP)
	assert_eq(start, [0, 0], "nothing shows before its line begins")
	assert_eq(after_one, [2, 0])
	assert_eq(after_two, [2, 1])
	assert_eq([labels[0].visible_characters, labels[1].visible_characters], [-1, -1])
	assert_eq(_events, ["line 0", "line 1", "blip", "finished"], "a blip on the third character")


func test_starting_again_replaces_the_telling_without_finishing_it() -> void:
	_teller.start(_label, "abcdef", CPS, PAUSE, 7)
	_teller._process(STEP)
	_teller.start(_label, "gh", CPS, PAUSE, 7)
	_teller._process(1.0)
	assert_eq(_label.text, "gh")
	assert_eq(_events, ["line 0", "line 0", "finished"])


func test_a_new_pace_mid_telling_keeps_what_shows_and_tells_the_rest_at_it() -> void:
	_teller.start(_label, "abcdefgh", CPS, PAUSE, 7)
	_teller._process(2 * STEP)
	_teller.set_cps(2 * CPS)
	assert_eq(_label.visible_characters, 2, "nothing restarts")
	assert_true(_teller.is_telling())
	assert_eq(_teller.pace(), 2 * CPS)
	_teller._process(STEP)
	assert_eq(_label.visible_characters, 4, "two characters a step at the doubled pace")


func test_an_infinite_pace_mid_telling_shows_the_rest_and_finishes_now_once() -> void:
	_teller.start(_label, "abcd\nef", CPS, PAUSE, 7)
	_teller._process(STEP)
	_teller.set_cps(INF)
	assert_eq(_label.visible_characters, -1, "the whole text shows at once")
	assert_false(_teller.is_telling())
	assert_eq(_events, ["line 0", "line 1", "finished"], "finished now, not on a later frame")
	_teller._process(1.0)
	_teller.set_cps(INF)
	assert_eq(_events.count("finished"), 1, "and only once")


func test_a_new_pace_with_nothing_told_changes_nothing() -> void:
	_teller.set_cps(INF)
	assert_eq(_events, [] as Array[String])
	_teller.start(_label, "ab", CPS, PAUSE, 7)
	assert_eq(_teller.pace(), CPS, "a telling takes its own pace from start")
