extends GutTest
## The day-book (D22, D23, D34, D37, D43, D47): the dimmed desk, the spread written in ink at
## 60 cps for at most a second, a press that only finishes the ink, the dog-ear and the tags,
## the page turn, the ending's tableau and its last spread with a row per soul, and the words the
## text harness prints (D44). Driven through PhaseFlow on the real slice where it matters.

const BOOK_SCENE := preload("res://entities/day_book/day_book.tscn")
const WRIT_SCENE := preload("res://entities/phase_card/dawn_writ.tscn")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const Fixture := preload("res://tests/unit/core/slice_fixture.gd")
const Harness := preload("res://tools/harness/harness.gd")
## The ember ramp: on the book only the standing's wax seal carries it, and the candle's flame.
const EMBER_NAMES: Array[StringName] = [&"seal_wax", &"pin_selected", &"pin_selected_shadow"]

var _viewport: SubViewport = null
var _book: DayBook = null
var _rules: SliceRules = Fixture.rules()


func before_each() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(480, 270)
	add_child_autofree(_viewport)
	var host := Control.new()
	host.theme = THEME
	host.size = Vector2(480, 270)
	_viewport.add_child(host)
	_book = BOOK_SCENE.instantiate() as DayBook
	host.add_child(_book)


func test_the_book_opens_on_the_dimmed_desk_with_the_spreads_words() -> void:
	watch_signals(_book)
	var spread: DuskSpread = _spreads(2)[0]
	_book.show_spread(spread, "Next", "Skip all")
	assert_true(_book.visible)
	assert_signal_emit_count(_book, "opened", 1)
	assert_eq(_book.shown_text(), spread.text(), "the harness's words")
	assert_eq(_texts(_book.left_page().labels()), spread.left.slice(1), "citations and quota")
	assert_eq(_book.left_page().shown_marks().count(&"heading"), 1, "the title, carved (D3)")
	assert_eq(_texts(_book.right_page().labels()), spread.right, "the recap")
	assert_almost_eq(_book.dim_color().a, 0.0, 0.01, "the dim fades in")
	_book._process(DayBook.DIM_SECONDS)
	assert_almost_eq(_book.dim_color().a, DayBook.DIM_ALPHA, 0.01, "Night 0 at 0.6 under the book")
	assert_eq(_book.dim_color().r8, 11, "Night 0")
	assert_eq(_book.book_rect().size, Vector2i(300, 170), "the open book, 300×170")
	assert_eq(_book.book_rect().get_center().x, 240, "centred")


func test_reduce_motion_dims_at_once_and_turns_no_leaf() -> void:
	_book.reduce_motion = true
	watch_signals(_book)
	var spreads: Array[DuskSpread] = _spreads(2)
	_book.show_spread(_spread_or(spreads, 0), "Next", "Skip all")
	assert_almost_eq(_book.dim_color().a, DayBook.DIM_ALPHA, 0.01, "no fade (D37)")
	_book.show_spread(_spread_or(spreads, 1), "Next day", "")
	assert_signal_emit_count(_book, "page_turned", 1, "the page sound still plays")
	assert_false(_book.is_turning(), "no leaf turns")


func test_the_ink_writes_at_60_cps_for_at_most_a_second_and_then_the_buttons_show() -> void:
	watch_signals(_book)
	var spread: DuskSpread = _spreads(2)[0]
	_book.show_spread(spread, "Next", "Skip all")
	assert_true(_book.is_writing())
	assert_signal_emit_count(_book, "writing_started", 1)
	assert_false(_book.next_button().visible, "no dog-ear to press while the ink runs")
	assert_false(_book.skip_button().visible)
	assert_gt(spread.text().length(), 60, "more than a second's worth at 60 cps")
	_tell(0.9)
	assert_true(_book.is_writing(), "longer text writes faster, still under a second")
	_tell(0.15)
	assert_false(_book.is_writing(), "done within a second (D43)")
	assert_signal_emit_count(_book, "writing_finished", 1)
	assert_true(_book.next_button().visible)
	assert_true(_book.skip_button().visible)


func test_a_short_spread_writes_at_60_cps() -> void:
	var spread := DuskSpread.make("Dusk, day 1.", ["No citations today."], [])
	_book.show_spread(spread, "Next day", "")
	var characters: int = spread.left[1].length()
	_tell((characters - 2) / 60.0)
	assert_true(_book.is_writing(), "%d characters at 60 a second" % characters)
	_tell(0.1)
	assert_false(_book.is_writing())
	assert_false(_book.skip_button().visible, "no Skip all on the last spread")


func test_instant_writes_at_once() -> void:
	watch_signals(_book)
	_book.write_cps = INF
	_book.show_spread(_spreads(2)[0], "Next", "Skip all")
	assert_false(_book.is_writing())
	assert_signal_not_emitted(_book, "writing_started", "nothing for the gate to hold")
	assert_true(_book.next_button().visible)


## Instant ink never hides the buttons, so each new spread re-arms them itself (D9).
func test_a_new_spread_rearms_its_buttons_even_at_instant_speed() -> void:
	_book.write_cps = INF
	var spreads: Array[DuskSpread] = _spreads(2)
	_book.show_spread(spreads[0], "Next", "Skip all")
	_book.next_button().arm_now()
	_book.skip_button().arm_now()
	_book.show_spread(spreads[1], "Next day", "")
	assert_true(_book.next_button().visible)
	assert_false(_book.next_button().is_armed(), "the next page's dog-ear waits its arm time")
	_book.next_button().arm_now()
	_show_ending(_ending_desk())
	_book.finish_writing()
	assert_false(_book.next_button().is_armed(), "and so does Play again")


## The options' text speed reaches the ink already running (D37, D43): instant finishes it.
func test_a_new_text_speed_reaches_the_running_ink() -> void:
	_book.show_spread(_spreads(2)[0], "Next", "Skip all")
	_tell(0.3)
	var label: Label = _book.left_page().labels()[0]
	var written: int = label.visible_characters
	assert_gt(written, 0)
	_book.write_cps = 600.0
	assert_true(_book.is_writing(), "a faster pace goes on from where the ink is")
	assert_gte(label.visible_characters, written, "nothing written is taken back")
	if _book.teller().has_method(&"set_cps"):
		_tell(0.5)
		assert_false(_book.is_writing(), "and finishes sooner than the second")
	_book.write_cps = INF
	assert_false(_book.is_writing(), "instant finishes it at once")
	assert_true(_book.next_button().visible)


## Reduce motion turned on mid-turn (D37): the leaf is gone, the dim full, the page final.
func test_reduce_motion_mid_turn_settles_the_leaf_and_the_dim() -> void:
	var spreads: Array[DuskSpread] = _spreads(2)
	_book.show_spread(spreads[0], "Next", "Skip all")
	_book.show_spread(spreads[1], "Next day", "")
	assert_true(_book.is_turning(), "a leaf is turning")
	assert_lt(_book.dim_color().a, DayBook.DIM_ALPHA, "and the dim still fading")
	_book.reduce_motion = true
	assert_false(_book.is_turning(), "the leaf is gone")
	assert_almost_eq(_book.dim_color().a, DayBook.DIM_ALPHA, 0.01, "the dim at its end")
	assert_eq(_book.shown_text(), spreads[1].text(), "the turned page is the one on show")
	assert_eq(_texts(_book.right_page().labels()), spreads[1].right)


## A press while the ink runs finishes it and does nothing else (D27), even on the dog-ear.
func test_a_press_finishes_the_ink_and_never_turns_the_page() -> void:
	watch_signals(_book)
	_book.show_spread(_spreads(2)[0], "Next", "Skip all")
	var corner: Vector2 = Vector2(DayBookLayout.dog_ear(_book.book_rect()).get_center())
	_click(corner)
	assert_false(_book.is_writing(), "the ink is finished")
	assert_signal_not_emitted(_book, "advanced", "and the page is not turned")
	assert_true(_book.next_button().visible)
	_book.next_button().arm_now()
	_click(_book.next_button().get_global_rect().get_center())
	assert_signal_emit_count(_book, "advanced", 1, "the dog-ear turns the page")


func test_the_skip_all_tag_skips_all() -> void:
	watch_signals(_book)
	_book.write_cps = INF
	_book.show_spread(_spreads(2)[0], "Next", "Skip all")
	assert_eq(_book.skip_button().text, "Skip all")
	assert_true(_book.skip_button() is TagButton, "a nailed paper tag")
	assert_true((_book.skip_button() as TagButton).dark, "with the darker face")
	assert_false(_book.next_button() is TagButton, "Next is the dog-ear")
	_book.skip_button().arm_now()
	_click(_book.skip_button().get_global_rect().get_center())
	assert_signal_emit_count(_book, "skipped", 1)
	assert_signal_not_emitted(_book, "advanced")


func test_turning_writes_the_next_spread_and_a_redraw_changes_nothing() -> void:
	watch_signals(_book)
	var spreads: Array[DuskSpread] = _spreads(2)
	_book.show_spread(spreads[0], "Next", "Skip all")
	_book.show_spread(spreads[0], "Next", "Skip all")
	assert_signal_emit_count(_book, "writing_started", 1, "the same spread is not rewritten")
	assert_signal_not_emitted(_book, "page_turned")
	_book.show_spread(spreads[1], "Next day", "")
	assert_signal_emit_count(_book, "page_turned", 1)
	assert_true(_book.is_turning(), "a leaf turns over the spine")
	_book._process(DayBook.TURN_SECONDS)
	assert_false(_book.is_turning())
	assert_eq(_book.shown_text(), spreads[1].text())
	_book.close()
	assert_signal_emit_count(_book, "closed", 1, "the drone stops")
	assert_false(_book.visible)
	assert_eq(_book.shown_text(), "")


func test_the_pause_holds_the_ink_and_the_tableau() -> void:
	_book.show_spread(_spreads(2)[0], "Next", "Skip all")
	_book.set_paused(true)
	_tell(5.0)
	assert_true(_book.is_writing(), "the pause holds the ink")
	_book.set_paused(false)
	_tell(1.1)
	assert_false(_book.is_writing())


func test_the_ending_shows_its_tableau_then_the_last_spread() -> void:
	watch_signals(_book)
	var desk: DeskCommands = _ending_desk()
	_show_ending(desk)
	assert_eq(_book.tableau(), DayBook.TIDE, "Hel's tide marches first")
	assert_true(_book.is_writing(), "the tableau holds the gate like the ink")
	assert_false(_book.left_page().visible, "no page under the tableau")
	assert_false(_book.next_button().visible, "no Play again yet")
	assert_eq(_book.dim_color().a, 1.0, "the desk below the band is covered whole")
	assert_eq(_book.dim_color().r8, 11, "in Night 0")
	assert_eq(_book.next_button().text, _rules.text.play_again)
	_book._process(DayBook.TABLEAU_SECONDS - 0.1)
	assert_eq(_book.tableau(), DayBook.TIDE)
	_book._process(0.1)
	assert_eq(_book.tableau(), &"", "1.5 s of tableau")
	assert_true(_book.left_page().visible)
	_tell(1.05)
	assert_false(_book.is_writing())
	assert_true(_book.next_button().visible, "Play again shows once the ink is dry")
	assert_true(_book.next_button() is TagButton, "on a nailed paper tag")
	assert_true((_book.next_button() as TagButton).dark, "darker than the page under it")
	var page: Rect2 = _book.right_page().get_global_rect()
	assert_true(page.encloses(_book.next_button().get_global_rect()), "on the right page")
	assert_false(_book.skip_button().visible, "nothing to skip at the ending")
	assert_signal_emit_count(_book, "writing_finished", 1, "one presentation, tableau and ink")
	assert_eq(
		_book.shown_text(), PhaseFlow.ending_text(desk.ending(), _rules), "the harness's words"
	)
	assert_true(_book.fits())


func test_a_press_on_the_tableau_lands_on_the_finished_page() -> void:
	watch_signals(_book)
	_show_ending(_ending_desk())
	_click(Vector2(240, 40))
	assert_eq(_book.tableau(), &"")
	assert_false(_book.is_writing(), "the page is written at once")
	assert_signal_not_emitted(_book, "advanced", "Play again is not pressed")
	assert_true(_book.next_button().visible)


func test_each_soul_has_a_row_with_its_glyphs_marks_and_feather() -> void:
	var desk: DeskCommands = _ending_desk()
	_show_ending(desk)
	_book.finish_writing()
	var rows: Array[EndingRow] = ScreenText.ending_rows(desk.ending(), _rules)
	var left: DayBookPage = _book.left_page()
	var right: DayBookPage = _book.right_page()
	var cited: int = 0
	var marked: Dictionary = {}
	for row: EndingRow in rows:
		cited += 1 if row.cited != &"" else 0
		marked[row.mark] = int(marked.get(row.mark, 0)) + 1
	assert_eq(right.mark_positions(&"feather").size(), cited, "a black feather per citation")
	for mark: StringName in [EndingRow.TICK, EndingRow.FROST, EndingRow.HOLLOW]:
		assert_eq(right.mark_positions(mark).size(), int(marked.get(mark, 0)), String(mark))
	var headers: Array[String] = _texts(left.labels()).filter(
		func(t: String) -> bool: return t == "Sent"
	)
	assert_eq(headers.size(), 1, "Sent over the stamped realm")
	assert_false(_texts(left.labels()).has("Truth:"), "the header names the column, not each row")
	for header: String in ["Truth", "Record", "Cited"]:
		assert_true(_texts(right.labels()).has(header), header + " over its column")
	var glyphs: int = 0
	for glyph: StringName in [&"spear", &"serpent", &"boar", &"wave"]:
		glyphs += left.mark_positions(glyph).size() + right.mark_positions(glyph).size()
	assert_eq(glyphs, 2 * rows.size(), "the stamped realm's glyph and the truth's, per row")
	assert_eq(left.shown_marks().count(&"heading"), 1, "the carved heading")
	assert_eq(right.mark_positions(&"seal").size(), 1, "the standing's wax seal")


func test_the_tableaux_march_stand_and_hold() -> void:
	var hel := Rect2(196, 9, 60, 87)
	var early: Array[Vector2i] = DayBookArt.tide_figures(0.2, 4, hel)
	var late: Array[Vector2i] = DayBookArt.tide_figures(1.0, 4, hel)
	assert_eq(late.size(), 4, "every marcher has set out by the end")
	assert_lt(early.size(), 4, "they set out one after another")
	assert_lt(late[0].x, early[0].x, "marching left from Hel's door")
	assert_lte(early[0].x, int(hel.get_center().x), "from the door")
	var benches: Array[Rect2i] = DayBookArt.benches(Rect2(89, 9, 60, 87))
	assert_eq(benches.size(), 3, "three empty benches")
	for bench: Rect2i in benches:
		assert_eq(bench.size, Vector2i(12, 4))
		assert_true(bench.position.x >= 89 and bench.end.x <= 149, "under Valhalla's door")
	var painted: Array[Rect2] = []
	var paint: Callable = func(rect: Rect2, _color: Color) -> void: painted.append(rect)
	var colors: Dictionary = DayBookArt.theme_colors(_book)
	var doors: Array[Rect2] = [Rect2(89, 9, 60, 87), hel]
	DayBookArt.tableau(paint, DayBook.HOLDS, 0.5, 4, doors, colors)
	assert_eq(painted.size(), 0, "the Hall holds: nothing but the doors")


func test_reduce_motion_stands_the_marchers_where_their_march_ends() -> void:
	_book.reduce_motion = true
	_show_ending(_ending_desk())
	assert_eq(_book.tableau(), DayBook.TIDE, "the tableau still shows for its time")
	_book._process(DayBook.TABLEAU_SECONDS)
	assert_eq(_book.tableau(), &"")


## Palette only, and the ember ramp only in the standing's seal and the candle's flame (art
## direction; the flame is Ember 2, 2×3, like the HUD's).
func test_ember_is_only_the_wax_seal_and_the_flame() -> void:
	_show_ending(_ending_desk())
	_book.finish_writing()
	await wait_process_frames(2)
	var ember: Array[Color] = []
	for color_name: StringName in EMBER_NAMES:
		ember.append(_book.get_theme_color(color_name, &"DeskPalette"))
	var seal_at: Vector2i = _book.right_page().mark_positions(&"seal")[0]
	var seal := Rect2(Vector2(seal_at), Vector2(7, 7))
	for page: DayBookPage in [_book.left_page(), _book.right_page()]:
		var rects: Array[Rect2] = page.drawn_rects()
		var colors: Array[Color] = page.drawn_colors()
		for index: int in range(rects.size()):
			if ember.has(colors[index]):
				assert_true(seal.encloses(rects[index]), "ember inside the seal only")
	var colors: Dictionary = DayBookArt.theme_colors(_book)
	var flame_ember: Array[Color] = []
	var candle: Array[Color] = []
	var cells: Array[Rect2] = []
	var paint_candle: Callable = func(rect: Rect2, color: Color) -> void:
		candle.append(color)
		cells.append(rect)
	var flame: Array[Rect2] = DayBookArt.candle(paint_candle, colors)
	for index: int in range(candle.size()):
		if ember.has(candle[index]):
			flame_ember.append(candle[index])
			assert_true(flame.has(cells[index]), "the candle's ember is its flame")
	var flame_box := Rect2()
	for cell: Rect2 in flame:
		flame_box = cell if flame_box.size == Vector2.ZERO else flame_box.merge(cell)
	assert_eq(
		[flame.size() > 0, flame_box.size, flame_ember.count(ember[1])],
		[true, Vector2(2, 3), flame.size()],
		"the flame is lit, 2×3, every cell Ember 2"
	)
	var art: Array[Color] = []
	var paint: Callable = func(_rect: Rect2, color: Color) -> void: art.append(color)
	DayBookArt.binding(paint, _book.book_rect(), colors)
	DayBookArt.dog_ear(paint, _book.book_rect(), true, colors)
	DayBookArt.turning_leaf(paint, _book.book_rect(), 0.5, colors)
	var doors: Array[Rect2] = [_book.valhalla_door, _book.hel_door]
	DayBookArt.tableau(paint, DayBook.TIDE, 0.5, 5, doors, colors)
	DayBookArt.tableau(paint, DayBook.HOLLOW, 0.5, 5, doors, colors)
	assert_gt(art.size(), 20)
	for color: Color in art:
		assert_false(ember.has(color), "no ember on the binding, the corner or the tableaux")
		assert_true(colors.values().has(color), "palette colours only")


## PhaseFlow puts the dawn on Odin's writ and dusk and the ending in the book, with the words the
## harness prints for the same screens (D44).
func test_phase_flow_draws_dawn_on_the_writ_and_dusk_in_the_book_as_the_harness_says() -> void:
	var writ: DawnWrit = WRIT_SCENE.instantiate() as DawnWrit
	_book.get_parent().add_child(writ)
	_book.write_cps = INF
	var desk: DeskCommands = SliceLoader.load_slice()
	var harness := Harness.new(desk)
	var flow: PhaseFlow = harness.view.phases
	flow.show_screens(writ, _book, desk)
	assert_ne(writ.shown_text(), "", "the dawn on the writ")
	assert_false(_book.is_open())
	harness.act("jump 2 4")
	harness.act("stamp valhalla")
	harness.act("next")
	flow.show_screens(writ, _book, desk)
	assert_eq(writ.shown_text(), "", "the writ is taken down at dusk")
	for index: int in range(flow.card_count()):
		var card: PhaseFlow.Card = flow.card(desk)
		assert_eq(_book.shown_text(), card.text(), "spread %d" % (index + 1))
		assert_string_contains(harness.describe(), card.body)
		assert_eq(_book.skip_button().visible, card.skip_label != "")
		assert_eq(_book.next_button().text, card.next_label)
		flow.advance(desk)
		flow.show_screens(writ, _book, desk)
	assert_eq(desk.phase(), RunState.DAWN, "the last spread's Next day")
	assert_false(_book.is_open(), "the book closes at dawn")
	harness.act("jump 3 99")
	harness.act("skip")
	flow.show_screens(writ, _book, desk)
	assert_eq(_book.tableau(), PhaseFlow.tableau_for(desk.ending().outcome))
	assert_eq(_book.shown_text(), harness.describe(), "the ending, word for word")
	# The writ frees its old lines at the frame's end.
	await wait_process_frames(1)


func _spread_or(spreads: Array[DuskSpread], index: int) -> DuskSpread:
	return spreads[mini(index, spreads.size() - 1)]


func _spreads(day: int) -> Array[DuskSpread]:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(day, 3)
	desk.stamp(Realm.VALHALLA)
	desk.next_soul()
	return ScreenText.dusk_spreads(desk.dusk_report(), _rules)


func _ending_desk() -> DeskCommands:
	var desk: DeskCommands = Fixture.desk()
	desk.debug_jump(3, 4)
	desk.stamp(Realm.HEL)
	return desk


func _show_ending(desk: DeskCommands) -> void:
	var flow := PhaseFlow.new()
	flow.skip(desk)
	flow.show_book(_book, desk)


func _tell(seconds: float) -> void:
	_book.teller()._process(seconds)


func _texts(labels: Array[Label]) -> Array[String]:
	var out: Array[String] = []
	for label: Label in labels:
		out.append(label.text)
	return out


## A press and a release at `at`, pushed through the book's viewport.
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
