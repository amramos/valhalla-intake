extends GutTest
## The dawn (D21, D27, D37): the dark falls over 0.2 s, "DAY N" holds the card for 1.5 s at most
## with the horn, then the dark lifts on Odin's writ; a press during the card skips to the writ
## and does nothing else; nothing under the writ takes a click; the tab begins the day once and
## the writ slides away; reduce motion keeps the card's time but drops every movement. The writ
## is stepped with fixed deltas and clicked with real mouse events through its own viewport.

const WRIT_SCENE := preload("res://entities/phase_card/dawn_writ.tscn")
const THEME_PATH := "res://scenes/desk/desk_theme.tres"
const SLICE_PATH := "res://data/slice.tres"
const LINES: Array[String] = [
	"Day 2.",
	"Odin wants 1 soul for Valhalla.",
	"The clock: 5:00. It runs while a soul is at the desk.",
	"NEW IV: Even so, those who fled the battle go to Hel.",
	"Witnesses arrive. Claim against witness makes a grey thread.",
	"Citations begin today: 2 feathers for any stamp against what the desk can show you.",
]
## A point on the desk outside the writ, and one on the writ's text.
const OFF_WRIT := Vector2(40, 240)
const ON_WRIT := Vector2(200, 60)

var _viewport: SubViewport = null
var _writ: DawnWrit = null
## A button covering the whole desk under the dawn: what a stray click would reach.
var _under: Button = null
var _under_presses: int = 0
var _events: Array[String] = []


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	var desk := Control.new()
	desk.size = Vector2(480, 270)
	desk.theme = load(THEME_PATH)
	_viewport.add_child(desk)
	_under = Button.new()
	_under.size = Vector2(480, 270)
	_under_presses = 0
	_under.pressed.connect(func() -> void: _under_presses += 1)
	desk.add_child(_under)
	_writ = WRIT_SCENE.instantiate() as DawnWrit
	desk.add_child(_writ)
	# Stepped by hand, so nothing depends on the frame rate.
	_writ.set_process(false)
	_events.clear()
	for signal_name: String in ["advanced", "card_started", "card_finished", "horn_requested"]:
		_writ.connect(signal_name, func() -> void: _events.append(signal_name))


func test_the_dark_falls_holds_the_day_then_lifts_on_the_writ_by_elapsed_time() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	assert_eq(_events, ["card_started", "horn_requested"], "the card starts with the horn")
	assert_true(_writ.is_showing_card())
	assert_false(_sheet().visible, "the writ waits under the dark")
	assert_eq(_dark().size.y, 0.0, "the dark starts at the top")
	_step(0.1)
	assert_eq(_dark().size.y, 135.0, "and falls in whole pixels")
	_step(0.1)
	assert_eq(_dark().size.y, 270.0, "the screen is Night 0 after 0.2 s")
	_step(1.29)
	assert_true(_writ.is_showing_card(), "the card holds until 1.5 s")
	assert_false(_events.has("card_finished"))
	_step(0.02)
	assert_false(_writ.is_showing_card(), "and no longer")
	assert_eq(_events.count("card_finished"), 1)
	assert_true(_sheet().visible, "the writ hangs under the lifting dark")
	_step(0.1)
	assert_eq(_dark().size.y, 135.0, "the dark lifts")
	_step(0.11)
	assert_false(_dark().visible, "and is gone after 0.2 s")
	assert_eq(_writ.shown_text(), "\n".join(LINES))
	assert_eq(_events.count("horn_requested"), 1, "one horn")


func test_a_press_during_the_card_skips_to_the_writ_and_does_nothing_else() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	_step(0.5)
	_click(ON_WRIT)
	assert_false(_writ.is_showing_card(), "the press skipped the card")
	assert_eq(_events, ["card_started", "horn_requested", "card_finished"], "and began nothing")
	assert_eq(_under_presses, 0, "nothing under the dark took it")
	assert_true(_sheet().visible)
	# The gate's consumer finishes the card the same way.
	_writ.cancel()
	_events.clear()
	_writ.show_dawn(3, LINES, "Begin")
	_writ.finish_card()
	assert_eq(_events, ["card_started", "horn_requested", "card_finished"])
	_writ.finish_card()
	assert_eq(_events.count("card_finished"), 1, "a card finishes once")


func test_nothing_under_the_writ_takes_a_click_while_it_shows() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	_writ.finish_card()
	_step(0.3)
	for at: Vector2 in [OFF_WRIT, ON_WRIT, Vector2(470, 10), Vector2(5, 265)]:
		_click(at)
	assert_eq(_under_presses, 0, "the dawn is a mouse stop over the whole desk")
	assert_false(_events.has("advanced"), "only the tab begins the day")
	_writ.next_button().arm_now()
	_click(_writ.next_button().get_global_rect().get_center())
	_step(0.21)
	_click(OFF_WRIT)
	assert_eq(_under_presses, 1, "once the writ is gone the desk takes clicks again")


func test_the_tab_begins_the_day_once_and_the_writ_slides_up_and_away() -> void:
	_writ.show_dawn(1, LINES, "Begin")
	_writ.finish_card()
	_step(0.21)
	var tab: GuardedButton = _writ.next_button()
	assert_eq(tab.text, "Begin")
	_click(tab.get_global_rect().get_center())
	assert_false(_events.has("advanced"), "the tab is not armed the moment the writ appears")
	tab.arm_now()
	_click(tab.get_global_rect().get_center())
	assert_eq(_events.count("advanced"), 1, "one click on the armed tab begins the day")
	assert_eq(_writ.shown_text(), "", "the writ is taken down")
	tab.pressed.emit()
	assert_eq(_events.count("advanced"), 1, "a writ already going begins nothing more")
	var top: float = _writ.get_node("Writ").position.y
	_step(0.1)
	var halfway: float = _writ.get_node("Writ").position.y
	assert_lt(halfway, top, "it slides up")
	assert_eq(halfway, roundf(halfway), "in whole pixels")
	_step(0.11)
	assert_false(_writ.visible, "and is gone after 0.2 s")


func test_the_tab_pressed_during_the_card_ends_the_card_and_begins_the_day() -> void:
	# The desk's tests press the button's own signal at dawn without waiting out the card.
	_writ.show_dawn(1, LINES, "Begin")
	_writ.next_button().pressed.emit()
	assert_eq(_events, ["card_started", "horn_requested", "card_finished", "advanced"])


func test_the_writ_lists_each_line_as_its_own_paragraph_inside_the_sheet() -> void:
	var slice: SliceData = load(SLICE_PATH)
	var faults: Array[String] = []
	for day: DayData in slice.days:
		var lines: Array[String] = ScreenText.dawn_lines(day.to_core())
		_writ.show_dawn(day.day, lines, "Begin")
		_writ.finish_card()
		var labels: Array[Label] = _writ.line_labels()
		var texts: Array[String] = []
		var bottom: float = -INF
		for label: Label in labels:
			texts.append(label.text)
			var rect := Rect2(label.position, label.size)
			if rect.position.y <= bottom:
				faults.append("day %d: '%s' overlaps the line above" % [day.day, label.text])
			bottom = rect.position.y + label.get_line_count() * WritLines.LINE_PITCH
			if bottom > WritLines.TEXT_ROOM or rect.size.x > WritLines.TEXT_WIDTH:
				faults.append("day %d: '%s' runs off the sheet" % [day.day, label.text])
		assert_eq(texts, lines, "day %d's lines, one paragraph each" % day.day)
		assert_eq(_writ.shown_text(), "\n".join(lines))
		_writ.cancel()
	assert_eq(faults, [] as Array[String])
	var sheet: Control = _writ.get_node("Writ/Sheet")
	assert_eq(Rect2(_sheet().position, sheet.size), DawnWrit.WRIT_RECT, "x 120-360, y 20-150")


## A critic's finding: the writ read as an unsigned notice. Odin's mark sits right-aligned in soft
## ink under the last line, on its row when it fits (day 2's sheet is full), never past the sheet
## and never over the words.
func test_odins_mark_signs_every_days_writ_inside_the_sheet() -> void:
	var slice: SliceData = load(SLICE_PATH)
	var soft: Color = (load(THEME_PATH) as Theme).get_color(&"ink_soft", &"DeskPalette")
	var faults: Array[String] = []
	var rows_shared: Array[bool] = []
	for day: DayData in slice.days:
		_writ.show_dawn(day.day, ScreenText.dawn_lines(day.to_core()), "Begin")
		var mark: Rect2 = _writ.signature_rect()
		var labels: Array[Label] = _writ.line_labels()
		var last: Label = labels[labels.size() - 1]
		var last_row_y: float = last.position.y + (last.get_line_count() - 1) * WritLines.LINE_PITCH
		rows_shared.append(mark.position.y == last_row_y)
		if mark.end.y > WritLines.TEXT_ROOM or mark.end.x != WritLines.TEXT_WIDTH:
			faults.append("day %d: the mark %s leaves the text column" % [day.day, mark])
		var font: Font = last.get_theme_font(&"font")
		var size: int = last.get_theme_font_size(&"font_size")
		var words_end: int = WritLines.last_row_width(last.text, font, size)
		if mark.position.y == last_row_y and mark.position.x < words_end + WritLines.SIGNATURE_GAP:
			faults.append("day %d: the mark crowds the last words" % day.day)
		if mark.position.y < last_row_y:
			faults.append("day %d: the mark is above the last line" % day.day)
		var label: Label = _writ.get_node("Writ/Lines/Signature") as Label
		assert_eq(label.text, WritLines.SIGNATURE)
		assert_eq(label.get_theme_color(&"font_color"), soft, "in soft ink")
		assert_false(_writ.shown_text().contains("Odin's"), "the harness's words are the lines")
		_writ.cancel()
	assert_eq(faults, [] as Array[String])
	assert_true(rows_shared[1], "day 2's full sheet keeps the mark on its last row")


func test_reduce_motion_drops_the_fall_lift_and_slide_but_keeps_the_card() -> void:
	_writ.reduce_motion = true
	_writ.show_dawn(2, LINES, "Begin")
	assert_eq(_dark().size.y, 270.0, "no fall: the dark is there at once")
	_step(1.49)
	assert_true(_writ.is_showing_card(), "the card still holds for 1.5 s")
	_step(0.02)
	assert_false(_dark().visible, "no lift: the writ shows at once")
	assert_true(_sheet().visible)
	_writ.next_button().pressed.emit()
	assert_false(_writ.visible, "no slide: the writ is gone at once")


## A review finding: reduce motion turned on mid-dawn (the options under the pause) must settle a
## movement already under way, not finish it.
func test_reduce_motion_turned_on_mid_dawn_settles_each_movement() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	_step(0.1)
	_writ.reduce_motion = true
	assert_eq(_dark().size.y, 270.0, "a fall under way is the full dark at once")
	_step(1.39)
	assert_true(_writ.is_showing_card(), "the card keeps the rest of its 1.5 s")
	_step(0.02)
	assert_false(_dark().visible, "and ends without a lift")
	_writ.reduce_motion = false
	_writ.cancel()
	_writ.show_dawn(2, LINES, "Begin")
	_writ.finish_card()
	_step(0.1)
	assert_true(_dark().visible, "a lift under way")
	_writ.settle_motion()
	assert_false(_dark().visible, "is gone at once")
	assert_eq(_writ.shown_text(), "\n".join(LINES), "on the writ")
	_writ.next_button().pressed.emit()
	_step(0.1)
	assert_true(_writ.visible, "a slide under way")
	_writ.reduce_motion = true
	assert_false(_writ.visible, "is over at once")
	assert_eq(_events.count("advanced"), 1)


func test_the_pause_stops_the_card_and_the_movements() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	_writ.set_paused(true)
	_step(5.0)
	assert_true(_writ.is_showing_card(), "the paused card waits")
	assert_eq(_dark().size.y, 0.0, "and so does the fall")
	_writ.set_paused(false)
	_step(1.51)
	assert_false(_writ.is_showing_card())


func test_the_same_dawn_again_changes_nothing_and_close_and_cancel_end_the_card() -> void:
	_writ.show_dawn(2, LINES, "Begin")
	_step(0.5)
	_writ.show_dawn(2, LINES, "Begin")
	assert_eq(_events.count("card_started"), 1, "a redraw of the same dawn")
	assert_true(_writ.is_showing_card())
	_writ.close()
	assert_eq(_events.count("card_finished"), 1, "the day began some other way: the card ends")
	assert_false(_writ.visible)
	_writ.show_dawn(2, LINES, "Begin")
	_writ.finish_card()
	_step(0.3)
	_writ.close()
	assert_eq(_writ.shown_text(), "", "a writ on show is taken down")
	_step(0.21)
	assert_false(_writ.visible)
	_writ.show_dawn(3, LINES, "Begin")
	_writ.cancel()
	assert_false(_writ.visible, "a restart hides everything at once")
	assert_eq(_events.count("card_finished"), 3)


func test_the_title_is_the_day_in_roman_numerals_centred() -> void:
	assert_eq(DawnWrit.day_title(1), "DAY I")
	assert_eq(DawnWrit.day_title(2), "DAY II")
	assert_eq(DawnWrit.day_title(3), "DAY III")
	assert_eq(DawnWrit.day_title(4), "DAY IV")
	assert_eq(DawnWrit.day_title(9), "DAY IX")
	_writ.show_dawn(3, LINES, "Begin")
	var rect: Rect2 = _writ.title_rect()
	assert_eq(rect.size, Vector2(PixelCapitals.width("DAY III", 2), PixelCapitals.HEIGHT * 2))
	assert_eq(DawnWrit.TITLE_SCALE, 2, "the card's title at twice the capitals' size")
	assert_almost_eq(rect.get_center().x, 240.0, 1.0)
	assert_almost_eq(rect.get_center().y, 135.0, 1.0)


func _step(seconds: float) -> void:
	_writ._process(seconds)


func _dark() -> ColorRect:
	return _writ.get_node("Curtain") as ColorRect


func _sheet() -> Control:
	return _writ.get_node("Writ") as Control


## A move, a press and a release at `at`, through the writ's viewport.
func _click(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_viewport.push_input(motion)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		_viewport.push_input(event)
