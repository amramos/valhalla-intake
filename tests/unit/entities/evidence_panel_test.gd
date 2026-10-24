extends GutTest
## The saga sheet and the Law scroll (D6-D9): speaker headings in ink, a straight quote opening
## every sheet line and no ids, roman numerals right-aligned in their own column, knotwork rods
## in the Wood ramp, parchment that never paints over a hit area, and the telling (D4): lines told
## in order, pinnable as they appear, a click on an unshown line ignored.

const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const SHEET_SIZE := Vector2(136, 54)
const SCROLL_SIZE := Vector2(204, 144)
const CLAIM: Array[String] = [
	"Speared, in battle.", "Took it in the chest.", "Sword up to the end.", "Sif gets the goat."
]


func test_sheet_lines_open_with_a_quote_mark_and_show_no_id() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines(_claim(), "Ulf")
	assert_eq(_text(panel, "C1"), '"Speared, in battle.', "D8: a hanging straight quote, no C1")
	assert_eq(panel.heading_text(), "Ulf", "D6: the speaker heads the sheet")
	var heading: Label = panel.heading_hover_area() as Label
	assert_eq(
		heading.get_theme_color(&"font_color"),
		THEME.get_color(&"ink", &"DeskPalette"),
		"D33: the heading in full ink"
	)


func test_the_quote_mark_counts_toward_the_line_cap() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines(_claim(), "Ulf")
	var bare: int = PaperLine.width_of(panel, CLAIM[0])
	assert_gt(panel.text_width("C1"), bare, "the mark is measured with the line")
	assert_eq(panel.inner_width(), 132, "the 132 px cap (slice D50)")


func test_show_ids_brings_the_ids_back_for_tools() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_ids = true
	panel.show_lines(_claim(), "Ulf")
	assert_eq(_text(panel, "C2"), "C2 Took it in the chest.")


func test_decrees_carry_roman_numerals_right_aligned_in_their_own_column() -> void:
	var panel: EvidencePanel = _scroll()
	panel.show_lines(_decrees(5), "Odin's Law")
	var column: int = PaperLine.numeral_column(panel, false)
	var numerals: Array[String] = []
	var right_edges: Array[int] = []
	var text_starts: Array[int] = []
	for index: int in range(5):
		var hit: PinSelectable = panel.area("L%d" % (index + 1))
		var numeral: Label = hit.get_node(^"Numeral") as Label
		numerals.append(numeral.text)
		right_edges.append(int(numeral.position.x) + PaperLine.width_of(panel, numeral.text))
		text_starts.append(PaperLine.text_start(hit.get_node(^"Text") as Label, panel))
	assert_eq(numerals, ["I", "II", "III", "IV", "V"] as Array[String], "D6")
	assert_eq(right_edges, [column, column, column, column, column] as Array[int], "right-aligned")
	var start: int = text_starts[0]
	assert_eq(text_starts, [start, start, start, start, start] as Array[int], "one column")
	assert_true(start >= column + PaperLine.NUMERAL_GAP, "the text starts after the numeral")
	assert_true(start <= column + PaperLine.NUMERAL_GAP + 3, "and close to it")
	assert_false(_text(panel, "L5").contains("L1"), "the decree text names no id")


func test_every_decree_wraps_to_at_most_three_lines_and_the_day_three_scroll_fits() -> void:
	var panel: EvidencePanel = _scroll()
	panel.show_lines(_decrees(5), "Odin's Law")
	var counts: Array[int] = []
	for index: int in range(5):
		counts.append(panel.line_count("L%d" % (index + 1)))
	gut.p("decree lines %s, content bottom %d" % [counts, panel.content_bottom()])
	assert_true(counts.max() <= 3, "slice D49: %s" % [counts])
	assert_false(panel.overflows(), "five decrees fit between the rods")


func test_the_scroll_hangs_between_rods_and_grows_with_the_decrees_in_force() -> void:
	var panel: EvidencePanel = _scroll()
	panel.show_lines(_decrees(3), "Odin's Law")
	var paper: Control = panel.get_node(^"Paper") as Control
	var day_one: float = paper.size.y
	assert_eq(paper.position.y, float(ScrollRod.HEIGHT), "the parchment starts under the top rod")
	panel.show_lines(_decrees(5), "Odin's Law")
	assert_gt(paper.size.y, day_one, "D9: more decrees, more parchment")
	assert_true(paper.position.y + paper.size.y + ScrollRod.HEIGHT <= SCROLL_SIZE.y)


func test_the_rod_is_knotwork_in_the_wood_ramp() -> void:
	var canvas := Palette.new()
	var named: Dictionary[String, Color] = Palette.by_name()
	var wood: Array[Color] = [named["Wood 2"], named["Wood 3"], named["Wood 4"]]
	ScrollRod.draw(canvas.paint, Vector2i(0, 0), 24, wood)
	assert_eq(Palette.bounds(canvas.rects), Rect2(0, 0, 24, 4), "4 px tall, full width")
	var row_one: Array[Color] = []
	for x: int in range(1, 9):
		row_one.append(Palette.color_at(canvas.rects, canvas.colors, Vector2i(x, 1)))
	var expected: Array[Color] = []
	for x: int in range(1, 9):
		expected.append(wood[ScrollRod.shade_at(x, 1, 24)])
	assert_eq(row_one, expected, "a 2 px braid of light and mid wood")
	assert_eq(Palette.color_at(canvas.rects, canvas.colors, Vector2i(5, 0)), wood[0], "dark edge")
	for color: Color in canvas.colors:
		assert_true(wood.has(color), "%s is Wood 2-4" % color.to_html(false))


func test_the_paper_never_paints_over_a_line_or_its_hit_area() -> void:
	for style: StringName in [&"sheet", &"scroll"]:
		var panel: EvidencePanel = _sheet() if style == &"sheet" else _scroll()
		var items: Array[EvidenceItem] = _claim() if style == &"sheet" else _decrees(5)
		panel.show_lines(items, "Heading")
		await wait_process_frames(2)
		var paper: ParchmentFrame = panel.get_node(^"Paper") as ParchmentFrame
		var rects: Array[Rect2] = paper.drawn_rects()
		var crossings: Array[String] = []
		for item: EvidenceItem in items:
			var hit: Rect2 = panel.area(item.id).get_rect()
			for rect: Rect2 in rects.slice(1):
				if Rect2(rect.position + paper.position, rect.size).intersects(hit):
					crossings.append("%s %s" % [item.id, rect])
		assert_eq(crossings, [] as Array[String], "%s: only plain parchment under text" % style)
		assert_eq(Palette.strays(paper.drawn_colors()), [] as Array[String])


## Holes would show the desk through the text: the ground must reach under every hit area.
func test_the_parchment_ground_lies_under_every_hit_area() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines(_claim(), "Ulf")
	await wait_process_frames(2)
	var paper: ParchmentFrame = panel.get_node(^"Paper") as ParchmentFrame
	var holes: Array[Vector2i] = []
	for item: EvidenceItem in _claim():
		var hit: Rect2 = panel.area(item.id).get_rect()
		for y: int in range(int(hit.position.y), int(hit.end.y)):
			for x: int in range(int(hit.position.x), int(hit.end.x)):
				var at := Vector2i(x, y) - Vector2i(paper.position)
				var color: Color = Palette.color_at(paper.drawn_rects(), paper.drawn_colors(), at)
				if color.a == 0.0 and holes.size() < 4:
					holes.append(Vector2i(x, y))
	assert_eq(holes, [] as Array[Vector2i], "unpainted pixels under the lines")


func test_lines_are_told_in_order_and_pinnable_as_they_appear() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines(_claim(), "Ulf")
	watch_signals(panel)
	panel.tell(hash("Ulf"), 40.0, 0.25)
	assert_true(panel.is_telling())
	assert_eq(_shown(panel), [true, false, false, false], "the first line begins at once")
	panel.area("C2").press()
	assert_signal_not_emitted(panel, "item_clicked", "a click on an unshown line is ignored")
	var first: float = (CLAIM[0].length() + 1) / 40.0
	panel.teller()._process(first + 0.25 + 0.001)
	assert_eq(_shown(panel), [true, true, false, false], "then the next, after its pause")
	panel.area("C2").press()
	assert_signal_emitted_with_parameters(panel, "item_clicked", ["C2"])
	panel.finish_telling()
	assert_eq(_shown(panel), [true, true, true, true], "a finishing click shows them all")
	assert_eq(_text_label(panel, "C4").visible_characters, -1)
	assert_signal_emit_count(panel, "telling_finished", 1)
	assert_false(panel.is_telling())


func test_an_empty_sheet_finishes_its_telling_on_the_next_frame() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines([] as Array[EvidenceItem], "Bersi", "No witness came back.")
	watch_signals(panel)
	panel.tell(hash("Bersi"), 40.0, 0.25)
	await wait_process_frames(2)
	assert_signal_emit_count(panel, "telling_finished", 1)
	var note: Label = panel.get_node(^"Note") as Label
	assert_eq(note.text, "No witness came back.", "D7: unquoted")


func test_new_lines_end_a_telling_without_announcing_it() -> void:
	var panel: EvidencePanel = _sheet()
	panel.show_lines(_claim(), "Ulf")
	watch_signals(panel)
	panel.tell(hash("Ulf"), 40.0, 0.25)
	panel.show_lines(_claim(), "Kolbeinn")
	await wait_process_frames(2)
	assert_false(panel.is_telling())
	assert_signal_not_emitted(panel, "telling_finished", "a restart is not a finished telling")
	assert_eq(_shown(panel), [true, true, true, true], "the new lines show whole")


func _shown(panel: EvidencePanel) -> Array[bool]:
	var shown: Array[bool] = []
	for index: int in range(CLAIM.size()):
		shown.append(panel.area("C%d" % (index + 1)).visible)
	return shown


func _text(panel: EvidencePanel, item_id: String) -> String:
	return _text_label(panel, item_id).text


func _text_label(panel: EvidencePanel, item_id: String) -> Label:
	return panel.area(item_id).get_node(^"Text") as Label


func _claim() -> Array[EvidenceItem]:
	var items: Array[EvidenceItem] = []
	for index: int in range(CLAIM.size()):
		items.append(EvidenceItem.make("C%d" % (index + 1), EvidenceItem.Group.CLAIM, CLAIM[index]))
	return items


func _decrees(count: int) -> Array[EvidenceItem]:
	var items: Array[EvidenceItem] = []
	for index: int in range(count):
		var decree: DecreeData = load("res://data/decrees/l%d.tres" % (index + 1)) as DecreeData
		items.append(EvidenceItem.make(decree.id, EvidenceItem.Group.LAW, decree.text))
	return items


func _sheet() -> EvidencePanel:
	return _panel(&"sheet", SHEET_SIZE, false)


func _scroll() -> EvidencePanel:
	return _panel(&"scroll", SCROLL_SIZE, true)


func _panel(style: StringName, panel_size: Vector2, wrap: bool) -> EvidencePanel:
	var host := Control.new()
	host.theme = THEME
	add_child_autofree(host)
	var panel := EvidencePanel.new()
	panel.name = "ClaimPanel" if style == &"sheet" else "LawPanel"
	panel.style = style
	panel.wrap_lines = wrap
	panel.size = panel_size
	host.add_child(panel)
	return panel
