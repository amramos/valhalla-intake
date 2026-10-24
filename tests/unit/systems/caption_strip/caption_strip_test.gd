extends GutTest
## The clerk's note (D10, D28, D43): captions carry a speaker mark and a quoted pair; a thread's
## caption shows at once, a written one is written by the quill in at most a second and holds for
## 3 s from when the writing ends; marks stay in their 8 px column.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const MENTOR_LINE := "Read the Law before you stamp."


func test_a_caption_is_announced_with_its_mark_and_pair() -> void:
	var strip: CaptionStrip = _strip()
	watch_signals(strip)
	var pair: Array[String] = ["C1", "L1"]
	var caption: Caption = Caption.make(
		'"Speared..." against decree I', CaptionStrip.Priority.THREAD, &"pin_law", pair
	)
	strip.post_caption(caption)
	assert_signal_emitted_with_parameters(strip, "caption_shown", [caption])
	assert_signal_emitted_with_parameters(strip, "text_shown", [caption.text])
	assert_eq(strip.shown_caption().pair, pair, "D28: the pair to light")
	assert_false(strip.is_writing(), "a thread's caption shows at once")


func test_plain_posts_still_work_and_carry_no_mark() -> void:
	var strip: CaptionStrip = _strip()
	strip.post("first", CaptionStrip.Priority.MENTOR)
	strip.post("second", CaptionStrip.Priority.THREAD)
	strip.post("third", CaptionStrip.Priority.CITATION)
	assert_eq(strip.shown_caption().mark, &"none")
	strip._process(strip.hold_seconds)
	assert_eq(strip.shown_text(), "third", "a citation comes first (D33)")
	strip.take_over("clicked")
	assert_eq(strip.shown_text(), "clicked")


func test_an_unknown_mark_draws_nothing() -> void:
	assert_eq(Caption.make("x", 0, &"dragon").mark, &"none")


func test_a_written_caption_holds_three_seconds_from_when_the_writing_ends() -> void:
	var strip: CaptionStrip = _strip()
	watch_signals(strip)
	strip.post_caption(_mentor())
	strip.post("a thread", CaptionStrip.Priority.THREAD)
	assert_true(strip.is_writing(), "D43: the quill writes it")
	assert_eq(strip.shown_text(), MENTOR_LINE)
	strip._process(5.0)
	assert_eq(strip.shown_text(), MENTOR_LINE, "no hold runs while the quill writes")
	strip.teller()._process(MENTOR_LINE.length() / 60.0 + 0.001)
	assert_false(strip.is_writing())
	assert_signal_emit_count(strip, "writing_finished", 1)
	strip._process(strip.hold_seconds - 0.1)
	assert_eq(strip.shown_text(), MENTOR_LINE, "the 3 s hold starts when the writing ends")
	strip._process(0.2)
	assert_eq(strip.shown_text(), "a thread")


func test_the_quill_never_takes_longer_than_a_second() -> void:
	var strip: CaptionStrip = _strip()
	var long_text: String = "word ".repeat(30).strip_edges()
	strip.post_caption(
		Caption.make(long_text, CaptionStrip.Priority.CITATION, &"feather", [], true)
	)
	strip.teller()._process(0.5)
	assert_true(strip.is_writing())
	strip.teller()._process(0.5 + 0.001)
	assert_false(strip.is_writing(), "D43: at most 1 s")


func test_a_finishing_click_writes_the_rest_at_once() -> void:
	var strip: CaptionStrip = _strip()
	strip.post_caption(_mentor())
	strip.finish_writing()
	assert_false(strip.is_writing())
	assert_eq(strip.get_node(^"Text").get(&"visible_characters"), -1, "all of it shows")


func test_instant_text_writes_nothing_out() -> void:
	var strip: CaptionStrip = _strip()
	strip.write_cps = INF
	strip.post_caption(_mentor())
	assert_false(strip.is_writing(), "D37: instant")


func test_a_take_over_replaces_a_caption_being_written() -> void:
	var strip: CaptionStrip = _strip()
	strip.post_caption(_mentor())
	strip.take_over("clicked")
	assert_false(strip.is_writing())
	assert_eq(strip.get_node(^"Text").get(&"visible_characters"), -1)


func test_the_note_takes_two_lines_for_a_long_caption() -> void:
	var strip: CaptionStrip = _strip()
	strip.take_over(
		'Bersi\'s "She went over first." against Ulf\'s "Speared, in battle.": one of them lies.'
	)
	assert_eq(strip.line_count(), 2)


func test_every_mark_stays_in_its_column_left_of_the_text() -> void:
	var outside: Array[String] = []
	for mark: StringName in Caption.MARKS:
		for pixel: Vector2i in NoteMarks.pixels(mark):
			var at: Vector2i = CaptionStrip.MARK_AT + pixel
			if at.x < 0 or at.x >= CaptionStrip.RULE_X or at.y < 0 or at.y >= 22:
				outside.append("%s %s" % [mark, at])
	assert_eq(outside, [] as Array[String])
	assert_true(CaptionStrip.TEXT_LEFT > CaptionStrip.RULE_X, "the text starts right of the rule")
	assert_true(CaptionStrip.RULE_X <= 9, "an 8 px mark column")


func test_the_marks_use_palette_colours() -> void:
	var canvas := Palette.new()
	var colors: Dictionary[StringName, Color] = {
		&"ink": THEME.get_color(&"ink", &"DeskPalette"),
		&"second": THEME.get_color(&"ink_soft", &"DeskPalette"),
		&"highlight": THEME.get_color(&"pin_highlight", &"DeskPalette"),
		&"pin_red": THEME.get_color(&"thread_red", &"DeskPalette"),
		&"pin_grey": THEME.get_color(&"thread_grey", &"DeskPalette"),
		&"pin_law": THEME.get_color(&"thread_law", &"DeskPalette"),
	}
	for mark: StringName in Caption.MARKS:
		NoteMarks.draw(canvas.paint, mark, Vector2i.ZERO, colors)
	assert_gt(canvas.rects.size(), 100, "every mark but none drew")
	assert_eq(Palette.strays(canvas.colors), [] as Array[String])
	assert_true(Palette.bounds(canvas.rects).size <= Vector2(7, 7), "7x7 at most")


func _mentor() -> Caption:
	return Caption.make(MENTOR_LINE, CaptionStrip.Priority.MENTOR, &"mentor", [], true)


func _strip() -> CaptionStrip:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var strip := CaptionStrip.new()
	strip.size = Vector2(344, 22)
	host.add_child(strip)
	return strip
