extends GutTest
## The mentor's bubble (D18, D43): a drawn parchment bubble with a tail toward her portrait, wide
## enough that "Stamp him." never breaks; her words written at 60 cps (a second at most); a
## blinking arrow while a click will advance; the first click finishes the writing, a later
## deliberate click acknowledges; no "Next" button.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const SIZE := Vector2(94, 40)
const STAMP_HIM := "The Law agrees. Stamp him."
const LONGEST := "Bodies don't lie. Decree II takes liars."


func test_stamp_him_stays_on_one_line() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	bubble.show_step(STAMP_HIM, false)
	assert_eq(bubble.line_count(), 2, "never one word per line (the WP2 critic's case)")
	var text_width: int = MentorBubble.text_width_for(int(SIZE.x))
	# A line's width counts its trailing space when the text wraps after it.
	assert_true(PaperLine.width_of(bubble, "The Law agrees. ") < text_width, "the first line")
	assert_true(PaperLine.width_of(bubble, "Stamp him.") < text_width, "the second line")


func test_her_words_are_written_at_60_cps_and_the_first_click_finishes_them() -> void:
	var bubble: MentorBubble = _bubble()
	watch_signals(bubble)
	bubble.show_step(STAMP_HIM, true)
	assert_true(bubble.is_revealing(), "written out, not shown at once")
	assert_false(bubble.shows_arrow(), "no arrow while she writes")
	bubble.teller()._process(0.1)
	assert_eq(_text(bubble).visible_characters, 6, "60 cps")
	bubble.press()
	assert_false(bubble.is_revealing(), "the first click finishes the writing")
	assert_eq(_text(bubble).visible_characters, -1)
	assert_signal_not_emitted(bubble, "acknowledged", "and does nothing else")
	assert_signal_emit_count(bubble, "reveal_finished", 1)
	assert_true(bubble.shows_arrow(), "the arrow comes once she is done")
	bubble.press()
	assert_signal_not_emitted(bubble, "acknowledged", "a click hard on its heels is ignored")
	bubble.arm_now()
	bubble.press()
	assert_signal_emit_count(bubble, "acknowledged", 1, "a later deliberate click advances")


func test_a_long_comment_takes_a_second_at_most() -> void:
	var bubble: MentorBubble = _bubble()
	var long_text: String = "word ".repeat(30).strip_edges()
	bubble.show_step(long_text, true)
	bubble.teller()._process(MentorBubble.MAX_WRITE_SECONDS + 0.01)
	assert_false(bubble.is_revealing(), "D43: a second at most")


func test_the_second_press_of_a_double_click_never_advances() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	bubble.show_step(STAMP_HIM, true)
	bubble.arm_now()
	watch_signals(bubble)
	var double := InputEventMouseButton.new()
	double.button_index = MOUSE_BUTTON_LEFT
	double.pressed = true
	double.double_click = true
	bubble._gui_input(double)
	assert_signal_not_emitted(bubble, "acknowledged")
	var single := InputEventMouseButton.new()
	single.button_index = MOUSE_BUTTON_LEFT
	single.pressed = true
	bubble._gui_input(single)
	assert_signal_emit_count(bubble, "acknowledged", 1)


func test_a_step_that_waits_for_a_pin_has_no_arrow_and_no_click() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	bubble.show_step("Click one, then the other.", false)
	bubble.arm_now()
	watch_signals(bubble)
	bubble.press()
	assert_signal_not_emitted(bubble, "acknowledged")
	assert_false(bubble.shows_arrow())
	await wait_process_frames(2)
	assert_false(_painted_in(bubble, bubble.arrow_rect(), _ink()), "no arrow drawn")


func test_there_is_no_next_button() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.show_step(STAMP_HIM, true)
	var buttons: int = 0
	for child: Node in bubble.get_children():
		buttons += 1 if child is BaseButton else 0
	assert_eq(buttons, 0, "the critic's case: a click on the bubble, no Next button")


func test_the_arrow_blinks_and_holds_still_under_reduce_motion() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	bubble.show_step(STAMP_HIM, true)
	await wait_process_frames(1)
	assert_true(_painted_in(bubble, bubble.arrow_rect(), _ink()), "lit at first")
	bubble._process(MentorBubble.BLINK_SECONDS + 0.01)
	await wait_process_frames(1)
	assert_false(_painted_in(bubble, bubble.arrow_rect(), _ink()), "then dark")
	bubble.reduce_motion = true
	bubble.queue_redraw()
	bubble._process(MentorBubble.BLINK_SECONDS)
	await wait_process_frames(1)
	assert_true(_painted_in(bubble, bubble.arrow_rect(), _ink()), "D37: steady")


func test_the_bubble_is_rounded_with_a_tail_toward_her_and_the_arrow_clear_of_the_text() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	bubble.reduce_motion = true
	bubble.show_step(LONGEST, true)
	await wait_process_frames(2)
	var rects: Array[Rect2] = bubble.drawn_rects()
	var colors: Array[Color] = bubble.drawn_colors()
	var none := Color(0, 0, 0, 0)
	assert_eq(bubble.line_count(), 3, "her longest step fills the bubble")
	assert_eq(MentorBubble.lines_for(int(SIZE.y)), 3)
	var right: int = int(SIZE.x) - 2
	var bottom: int = int(SIZE.y) - 2
	var corners: Array[Color] = []
	for corner: Vector2i in [
		Vector2i(0, 0), Vector2i(right, 0), Vector2i(0, bottom), Vector2i(right, bottom)
	]:
		corners.append(Palette.color_at(rects, colors, corner))
	assert_eq(corners, [none, none, none, none] as Array[Color], "four corner pixels cut")
	var tip := Vector2i(-MentorBubble.TAIL, MentorBubble.TAIL_Y + MentorBubble.TAIL - 1)
	assert_ne(Palette.color_at(rects, colors, tip), none, "the tail's tip, 3 px left")
	assert_eq(Palette.color_at(rects, colors, tip + Vector2i.LEFT), none)
	assert_false(bubble.arrow_rect().intersects(bubble.text_rect()), "the arrow is under the text")
	assert_true(Rect2(Vector2.ZERO, SIZE).encloses(bubble.arrow_rect()))
	assert_eq(Palette.strays(colors), [] as Array[String])
	# Only the ground lies under her words.
	var ground: Color = THEME.get_color(&"parchment", &"DeskPalette")
	var text: Rect2 = bubble.text_rect()
	var others: int = 0
	for y: int in range(int(text.position.y), int(text.end.y)):
		for x: int in range(int(text.position.x), int(text.end.x)):
			others += 0 if Palette.color_at(rects, colors, Vector2i(x, y)) == ground else 1
	assert_eq(others, 0, "plain parchment under the text")


func test_an_instant_speed_shows_her_words_at_once() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.write_cps = INF
	watch_signals(bubble)
	bubble.show_step(STAMP_HIM, true)
	assert_false(bubble.is_revealing())
	assert_signal_not_emitted(bubble, "reveal_started", "nothing for the gate to hold")
	assert_true(bubble.shows_arrow())


func test_the_same_step_again_does_not_restart_her_writing() -> void:
	var bubble: MentorBubble = _bubble()
	bubble.show_step(STAMP_HIM, true)
	bubble.finish_reveal()
	bubble.show_step(STAMP_HIM, true)
	assert_false(bubble.is_revealing(), "a refresh leaves her words as they are")
	bubble.hide_step()
	assert_eq(bubble.shown_text(), "")


func test_a_new_pace_reaches_her_words_mid_writing_and_instant_finishes_them() -> void:
	# A review finding: the text speed changed in the options did not reach a writing under way.
	var bubble: MentorBubble = _bubble()
	watch_signals(bubble)
	bubble.show_step(STAMP_HIM, true)
	bubble.teller()._process(0.1)
	bubble.write_cps = 120.0
	assert_eq(_text(bubble).visible_characters, 6, "the writing goes on from where it was")
	bubble.teller()._process(0.05)
	assert_eq(_text(bubble).visible_characters, 12, "at the new pace")
	bubble.write_cps = INF
	assert_false(bubble.is_revealing(), "instant writes the rest at once")
	assert_eq(_text(bubble).visible_characters, -1)
	assert_signal_emit_count(bubble, "reveal_finished", 1, "and finishes once")
	bubble.write_cps = 60.0
	assert_signal_emit_count(bubble, "reveal_finished", 1, "a new pace after it changes nothing")


func _painted_in(bubble: MentorBubble, area: Rect2, color: Color) -> bool:
	var rects: Array[Rect2] = bubble.drawn_rects()
	for index: int in range(rects.size()):
		if bubble.drawn_colors()[index] == color and rects[index].intersects(area):
			return true
	return false


func _ink() -> Color:
	return THEME.get_color(&"ink", &"DeskPalette")


func _text(bubble: MentorBubble) -> Label:
	return bubble.get_node(^"Text") as Label


func _bubble() -> MentorBubble:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var bubble := MentorBubble.new()
	bubble.position = Vector2(70, 204)
	bubble.size = SIZE
	host.add_child(bubble)
	return bubble
