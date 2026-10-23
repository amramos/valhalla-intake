extends GutTest
## The HUD as objects (D11, D33, D36, D37): the candle burns down with the clock and its m:ss is
## always drawn on timed days, day 1's candle is unlit and "untimed", the slate tallies the souls
## admitted in fives against faint target marks, the book carries a wax dot while a promise is
## open, the gutter's label shows 0.6 s on the stone left of the candle and never over a number,
## pausing with the gate, and every drawn rect is whole, inside the node and on the palette, with
## ember only in the flame and the dot.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
## The Hud node: screen (352, 0) to (478, 25).
const SIZE := Vector2(126, 25)
const CLOCK := 300.0
## The candle's middle column, which only the wax paints.
const WAX_COLUMN := 35
## The gutter label's plate: screen x 359-385, y 0-8.
const GUTTER_PLATE := Rect2(7, 0, 27, 9)
## The NEW tag over the Folkvangr door ends at screen x 358 (here 6) and runs to y 8.
const NEW_TAG_END_X := 7.0
## More frames than a 0.6 s gutter at 0.05 s a frame.
const MAX_GUTTER_FRAMES := 20
const RESERVED: Array[String] = [
	"Ember 0", "Ember 1", "Ember 2", "Bile 0", "Bile 1", "Bile 2", "Blood 0", "Blood 1"
]


func test_the_wax_falls_with_the_clock() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	for case: Array in [[CLOCK, 14], [CLOCK / 2.0, 7], [0.0, 0]]:
		hud.set_clock(case[0], CLOCK, false)
		await wait_process_frames(1)
		assert_eq(hud.wax_height(), case[1], "wax at %s s left" % case[0])
		assert_eq(_wax_pixels(hud), case[1], "drawn wax at %s s left" % case[0])
	assert_eq(HudMarks.wax_height(CLOCK * 0.25, CLOCK), 4, "round(14 x 0.25) = round(3.5)")


func test_the_flame_sits_on_the_wax_while_time_is_left() -> void:
	var hud: Hud = await _hud(_readout(CLOCK / 2.0))
	var flame: Array[Rect2] = hud.ember_rects()
	assert_false(flame.is_empty(), "lit on a timed day")
	var wax_top: int = _wax_top(hud)
	var lowest: float = Palette.bounds(flame).end.y
	assert_eq(int(lowest), wax_top, "the flame's foot touches the wax")
	hud.set_clock(0.0, CLOCK, false)
	await wait_process_frames(1)
	assert_eq(hud.ember_rects(), [] as Array[Rect2], "a burnt-out candle has no flame")


func test_day_one_shows_an_unlit_full_candle_and_untimed() -> void:
	var readout: HudReadout = _readout(INF)
	readout.clock_seconds = 0.0
	var hud: Hud = await _hud(readout)
	assert_false(hud.is_lit())
	assert_eq(hud.ember_rects(), [] as Array[Rect2], "no flame on an untimed day")
	assert_eq(hud.wax_height(), 14, "full")
	assert_eq(hud.shown_time(), "untimed")
	assert_has(hud.drawn_texts(), "untimed")


func test_the_numeral_is_drawn_in_every_blink_phase() -> void:
	var readout: HudReadout = _readout(25.0)
	readout.warning = true
	var hud: Hud = await _hud(readout)
	var seen: Array[bool] = []
	for phase: int in range(4):
		hud._process(Hud.BLINK_SECONDS)
		await wait_process_frames(1)
		seen.append(hud.drawn_texts().has("0:25"))
	assert_eq(seen, [true, true, true, true] as Array[bool], "never blank, never hover-only (D11)")
	assert_true(hud.is_warning())


func test_no_clock_is_drawn_once_the_day_has_ended() -> void:
	var readout: HudReadout = _readout(40.0)
	readout.clock_shown = false
	var hud: Hud = await _hud(readout)
	assert_eq(hud.shown_time(), "")
	assert_does_not_have(hud.drawn_texts(), "0:40", "nothing stale at dusk")


func test_tally_marks_group_in_fives() -> void:
	var marks: Array[Rect2i] = HudMarks.tally_rects(7)
	assert_eq(marks.size(), 7)
	assert_eq(
		marks.slice(0, 4).map(func(m: Rect2i) -> Vector2i: return m.size),
		[Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 3)]
	)
	assert_eq(marks[4], Rect2i(2, 2, 9, 1), "the fifth strikes across the four")
	assert_eq(marks[5], Rect2i(3, 5, 1, 3), "the sixth starts the second group")
	assert_eq(HudMarks.tally_rects(14).size(), HudMarks.TALLY_CAPACITY, "the slate holds ten")
	for mark: Rect2i in HudMarks.tally_rects(HudMarks.TALLY_CAPACITY):
		var inside := Rect2i(Vector2i.ONE, HudMarks.SLATE_SIZE - 2 * Vector2i.ONE)
		assert_true(inside.encloses(mark), "on the slate, inside its frame")


func test_the_slate_chalks_each_soul_over_faint_quota_marks() -> void:
	var readout: HudReadout = _readout(CLOCK)
	readout.quota = Vector2i(2, 4)
	var hud: Hud = await _hud(readout)
	var named: Dictionary[String, Color] = Palette.by_name()
	assert_eq(_count(hud, named["Fog 2"]), 2, "two chalk marks for two souls admitted")
	assert_eq(_count(hud, named["Fog 1"]), 4, "a faint target mark for each of the quota")
	assert_eq(_count(hud, named["Night 2"]), 1, "one slate")
	assert_has(hud.drawn_texts(), "2/4", "the numeral stays for readability")


func test_the_book_carries_a_wax_dot_while_a_promise_is_open() -> void:
	var readout: HudReadout = _readout(INF)
	readout.promise_open = true
	var hud: Hud = await _hud(readout)
	var dot := Rect2(Vector2(Hud.BOOK_AT + HudMarks.WAX_DOT.position), Vector2(3, 3))
	assert_eq(hud.ember_rects(), [dot] as Array[Rect2], "the dot is the only ember (unlit candle)")
	var ember: Color = Palette.by_name()["Ember 2"]
	var drawn: Color = _at(hud, Vector2i(dot.position) + Vector2i(1, 1))
	assert_eq(drawn.to_rgba32(), ember.to_rgba32(), "Ember 2")
	var tray := Rect2(115, 11, 10, 10)
	assert_true(
		tray.encloses(Rect2(Vector2(Hud.BOOK_AT), Vector2(8, 8))), "inside the tray's click"
	)
	readout.promise_open = false
	hud.refresh(readout)
	await wait_process_frames(1)
	assert_eq(hud.ember_rects(), [] as Array[Rect2], "no dot without a promise")


func test_ember_appears_only_in_the_flame_and_the_wax_dot() -> void:
	var hud: Hud = await _hud(_busy())
	var named: Dictionary[String, Color] = Palette.by_name()
	var reserved: Array[int] = []
	for name: String in RESERVED:
		reserved.append(named[name].to_rgba32())
	var allowed: Array[Rect2] = hud.ember_rects()
	var rects: Array[Rect2] = hud.drawn_rects()
	var colors: Array[Color] = hud.drawn_colors()
	var misplaced: Array[Rect2] = []
	for index: int in range(rects.size()):
		if reserved.has(colors[index].to_rgba32()) and not allowed.has(rects[index]):
			misplaced.append(rects[index])
	assert_eq(misplaced, [] as Array[Rect2], "reserved colours outside the flame and the dot")
	assert_eq(allowed.size(), 5 + 1, "the steady flame's five pixels and the dot")
	assert_eq(Palette.strays(colors), [] as Array[String], "palette colours only")


func test_every_rect_is_whole_and_inside_the_node() -> void:
	var hud: Hud = await _hud(_busy())
	hud.gutter(10)
	hud._process(0.3)
	await wait_process_frames(1)
	var bad: Array[Rect2] = []
	var node := Rect2(Vector2.ZERO, SIZE)
	for rect: Rect2 in hud.drawn_rects():
		var whole: bool = rect.position == rect.position.floor() and rect.size == rect.size.floor()
		if not whole or not node.encloses(rect):
			bad.append(rect)
	assert_eq(bad, [] as Array[Rect2])


func test_each_object_has_its_own_plate_on_day_one() -> void:
	var readout: HudReadout = _readout(INF)
	readout.clock_seconds = 0.0
	readout.feathers = 10
	readout.quota = Vector2i(0, 1)
	var hud: Hud = await _hud(readout)
	var plates: Array[Rect2] = _plates(hud)
	assert_eq(plates.size(), 5, "candle, clock, quill, slate, book")
	for a: int in range(plates.size()):
		for b: int in range(a + 1, plates.size()):
			assert_false(
				plates[a].intersects(plates[b], true), "%s and %s" % [plates[a], plates[b]]
			)


func test_the_gutter_label_shows_left_of_the_candle_for_six_tenths() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	hud.gutter(10)
	assert_eq(hud.gutter_label(), "-0:10")
	hud._process(0.3)
	await wait_process_frames(1)
	assert_has(hud.drawn_texts(), "-0:10")
	assert_eq(hud.gutter_plate(), GUTTER_PLATE, "screen x 359-385, y 0-8")
	assert_true(hud.gutter_plate().position.x >= NEW_TAG_END_X, "clear of the door's NEW tag")
	assert_true(hud.gutter_plate().end.y <= 9.0, "clear of the Folkvangr door, which starts at y 9")
	assert_true(hud.gutter_plate().end.x <= _candle_content_x(), "left of the candle itself")
	assert_false(hud.ember_rects().is_empty(), "the flame still burns while it gutters")
	hud._process(0.29)
	assert_eq(hud.gutter_label(), "-0:10", "still showing just before 0.6 s")
	hud._process(0.02)
	assert_eq(hud.gutter_label(), "", "gone at 0.6 s")
	await wait_process_frames(1)
	assert_does_not_have(hud.drawn_texts(), "-0:10")
	assert_eq(hud.gutter_plate(), Rect2(), "and its plate with it")


## The review's case: the label once rose over the slate and the clock, hiding numbers (D11). At
## every frame of a gutter every number is drawn and the label's plate touches no other rect, but
## for the candle plate's empty left padding (the same Night 1, holding nothing).
func test_the_gutter_label_never_covers_a_number_or_a_plate() -> void:
	var numbers: Array[String] = ["3:00", "12", "7/10", "3", "-0:10"]
	for reduce: bool in [false, true]:
		var hud: Hud = await _hud(_busy())
		hud.reduce_motion = reduce
		hud.gutter(10)
		var frames: int = 0
		var problems: Array[String] = []
		while hud.gutter_label() != "" and frames < MAX_GUTTER_FRAMES:
			await wait_process_frames(1)
			var plate: Rect2 = hud.gutter_plate()
			if not plate.has_area():
				problems.append("frame %d: no label plate" % frames)
			for rect: Rect2 in hud.drawn_rects():
				if rect == plate:
					continue
				if rect == _candle_plate():
					if rect.intersection(plate).end.x > _candle_content_x():
						problems.append("frame %d: the label reaches the candle" % frames)
					continue
				if rect.intersects(plate):
					problems.append("frame %d: %s under the label" % [frames, rect])
			for number: String in numbers:
				if not hud.drawn_texts().has(number):
					problems.append("frame %d: %s not drawn" % [frames, number])
			hud._process(0.05)
			frames += 1
		assert_eq(hud.gutter_label(), "", "the label expired within its frame budget")
		assert_between(frames, 11, 13, "about 0.6 s of 0.05 s frames")
		assert_eq(problems, [] as Array[String], "reduce motion %s" % reduce)


func test_the_gates_pause_holds_the_gutter_and_a_restart_clears_it() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	hud.gutter(10)
	hud._process(0.1)
	hud.set_paused(true)
	await wait_process_frames(1)
	var held: Array[Rect2] = hud.ember_rects()
	hud._process(5.0)
	await wait_process_frames(1)
	assert_eq(hud.gutter_label(), "-0:10", "paused, the label waits")
	assert_eq(hud.ember_rects(), held, "and the flame's frame holds")
	hud.set_paused(false)
	hud._process(0.49)
	assert_eq(hud.gutter_label(), "-0:10", "the pause took nothing off its 0.6 s")
	hud._process(0.02)
	assert_eq(hud.gutter_label(), "", "then it ends")
	hud.gutter(10)
	hud.clear_gutter()
	assert_eq(hud.gutter_label(), "", "a restart clears it at once")
	await wait_process_frames(1)
	assert_eq(hud.gutter_plate(), Rect2())


func test_reduce_motion_shows_the_label_in_place_with_a_still_flame() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	await wait_process_frames(1)
	var steady: Array[Rect2] = hud.ember_rects()
	hud.reduce_motion = true
	hud.gutter(10)
	for step: int in range(5):
		hud._process(0.1)
		await wait_process_frames(1)
		assert_eq(hud.gutter_plate(), GUTTER_PLATE, "the same place")
		assert_eq(hud.ember_rects(), steady, "no flicker")
		assert_has(hud.drawn_texts(), "-0:10", "the state cue stays (D37)")
	hud._process(0.11)
	assert_eq(hud.gutter_label(), "", "gone at 0.6 s")


func test_the_flame_flickers_while_it_gutters() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	var steady: Array[Rect2] = hud.ember_rects()
	hud.gutter(10)
	var frames: Array[Array] = []
	for step: int in range(2):
		hud._process(0.1)
		await wait_process_frames(1)
		frames.append(hud.ember_rects())
	assert_ne(frames[0], steady, "the first gutter frame")
	assert_ne(frames[1], frames[0], "the second gutter frame")


func test_the_gutter_label_steps_down_the_fog_ramp_with_or_without_motion() -> void:
	var inks: Array[StringName] = []
	for reduce: bool in [false, true]:
		var gutter := HudGutter.new()
		gutter.reduce_motion = reduce
		gutter.start("-0:10")
		for age: float in [0.1, 0.25, 0.1]:
			gutter.advance(age)
			inks.append(gutter.ink())
	var expected: Array[StringName] = [
		&"text_light", &"text_muted", &"glyph_dim", &"text_light", &"text_muted", &"glyph_dim"
	]
	assert_eq(inks, expected, "Parchment 2, Fog 2, Fog 1; the label does not move, so the same")


func test_a_gutter_of_nothing_shows_nothing() -> void:
	var hud: Hud = await _hud(_readout(CLOCK))
	hud.gutter(0)
	assert_eq(hud.gutter_label(), "")


func test_day_three_shows_the_raven_and_answers_left() -> void:
	var hud: Hud = await _hud(_busy())
	assert_has(hud.drawn_texts(), "3", "answers left")
	assert_has(hud.drawn_texts(), "12", "feathers")


func _readout(time_left: float) -> HudReadout:
	var readout := HudReadout.new()
	readout.time_left = time_left
	readout.clock_seconds = CLOCK
	readout.feathers = 10
	readout.quota = Vector2i(0, 1)
	return readout


## Day 3 at its fullest: Huginn's answers, a promise, a two-digit quota line.
func _busy() -> HudReadout:
	var readout: HudReadout = _readout(CLOCK * 0.6)
	readout.feathers = 12
	readout.quota = Vector2i(7, 10)
	readout.huginn_on = true
	readout.huginn_left = 3
	readout.promise_open = true
	return readout


func _hud(readout: HudReadout) -> Hud:
	var host := Control.new()
	host.theme = THEME
	host.size = SIZE
	add_child_autofree(host)
	var hud := Hud.new()
	host.add_child(hud)
	hud.size = SIZE
	hud.set_process(false)
	hud.refresh(readout)
	await wait_process_frames(1)
	return hud


func _candle_plate() -> Rect2:
	return Rect2(Vector2(Hud.CANDLE_PLATE.position), Vector2(Hud.CANDLE_PLATE.size))


## Where the candle plate's left padding ends and its candle begins.
func _candle_content_x() -> float:
	return Hud.CANDLE_PLATE.position.x + Hud.PAD


func _at(hud: Hud, at: Vector2i) -> Color:
	return Palette.color_at(hud.drawn_rects(), hud.drawn_colors(), at)


## Wax pixels in the candle's middle column.
func _wax_pixels(hud: Hud) -> int:
	var night: Color = THEME.get_color(&"night", &"DeskPalette")
	var count: int = 0
	for y: int in range(Hud.CANDLE_PLATE.position.y, Hud.CANDLE_PLATE.end.y):
		var color: Color = _at(hud, Vector2i(WAX_COLUMN, y))
		count += 1 if color != night and color.a > 0.0 else 0
	return count


func _wax_top(hud: Hud) -> int:
	var night: Color = THEME.get_color(&"night", &"DeskPalette")
	for y: int in range(Hud.CANDLE_PLATE.position.y, Hud.CANDLE_PLATE.end.y):
		if _at(hud, Vector2i(WAX_COLUMN, y)) != night:
			return y
	return Hud.CANDLE_PLATE.end.y


func _count(hud: Hud, color: Color) -> int:
	var count: int = 0
	for drawn: Color in hud.drawn_colors():
		count += 1 if drawn.to_rgba32() == color.to_rgba32() else 0
	return count


## The Night 1 backing plates: the night rects larger than one pixel.
func _plates(hud: Hud) -> Array[Rect2]:
	var night: Color = THEME.get_color(&"night", &"DeskPalette")
	var out: Array[Rect2] = []
	var rects: Array[Rect2] = hud.drawn_rects()
	var colors: Array[Color] = hud.drawn_colors()
	for index: int in range(rects.size()):
		if colors[index] == night and rects[index].get_area() > 1.0:
			out.append(rects[index])
	return out
