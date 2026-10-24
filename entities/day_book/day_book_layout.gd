class_name DayBookLayout
extends RefCounted
## Where everything sits in the day-book (D22, D23): the open book on the screen, its two pages,
## the lines on them, the ending's rows ruled across both pages, and the buttons drawn as the
## dog-ear and the paper tags. Whole pixels only. A dusk spread opens at 300×170; one whose lines
## don't fit widens, and at the widest grows taller, so the longest dusk the slice can write still
## fits (the fit test measures it). The ending's spread is wider: a row runs across the spine
## under its column headers, the name, the stamped realm and "Truth:" on the left page, the truth,
## the record (mark and word) and the citation on the right.

const SPINE := 4
const MARGIN_X := 7
const TOP := 6
## Below the last line of a dusk page: the dog-ear's row.
const BOTTOM := 14
const PARAGRAPH_GAP := 2
const TITLE_GAP := 3
const SPREAD_HEIGHT := 170
const SPREAD_WIDTHS: Array[int] = [300, 340, 380, 420, 440]
const MAX_HEIGHT := 250
const CENTRE_Y := 150
## The book's top leaves room above it for the "Skip all" tag; its bottom stays clear of the
## screen's edge.
const HIGHEST := 14
const LOWEST := 266
const ENDING_WIDTH := 470
const ENDING_BOTTOM := 7
const ENDING_LOWEST := 264
## The ending's book may rise this high: it needs no "Skip all" label above it.
const ENDING_HIGHEST := 6
const HEADING_GAP := 3
const ROWS_GAP := 5
## Below the column headers, before the first row.
const HEADER_GAP := 1
## A row's mark column, and the gaps between the columns.
const MARK_COLUMN := 10
const GLYPH_COLUMN := 9
const COLUMN_GAP := 5
const FEATHER_COLUMN := 7
## The "Skip all" tag is nailed this far above the book's top edge.
const SKIP_ABOVE := 7
const DOG_EAR := 9
const SKIP_FROM_SPINE := 60
const SCREEN_WIDTH := 480
const GLYPHS: Dictionary = {
	&"valhalla": &"spear", &"hel": &"serpent", &"folkvangr": &"boar", &"ran": &"wave"
}


## Lays `spread` out on the pages and returns the open book's rect on the screen.
static func spread(left: DayBookPage, right: DayBookPage, shown: DuskSpread) -> Rect2i:
	var book := Rect2i()
	var needed: int = 0
	for width: int in SPREAD_WIDTHS:
		book = _book_rect(width, SPREAD_HEIGHT, CENTRE_Y)
		_place_pages(left, right, book, SPREAD_HEIGHT - BOTTOM)
		needed = _write_spread(left, right, shown, _page_width(width), PARAGRAPH_GAP) + BOTTOM
		if needed <= SPREAD_HEIGHT:
			return book
	# The longest dusks: at the widest the book grows taller; past its tallest the paragraphs
	# close up, and past that the left page's last lines run on at the top of the right page.
	var page_width: int = _page_width(SPREAD_WIDTHS[-1])
	if needed > MAX_HEIGHT:
		needed = _write_spread(left, right, shown, page_width, 0) + BOTTOM
	if needed > MAX_HEIGHT:
		needed = _write_spread(left, right, shown, page_width, 0, MAX_HEIGHT - BOTTOM) + BOTTOM
	var height: int = clampi(needed, SPREAD_HEIGHT, MAX_HEIGHT)
	book = _book_rect(SPREAD_WIDTHS[-1], height, CENTRE_Y)
	_place_pages(left, right, book, height - BOTTOM)
	return book


## Lays the ending's last spread out and returns the open book's rect, bottom-anchored so the
## gate stays in sight above it when the rows allow.
static func ending(left: DayBookPage, right: DayBookPage, shown: DayBookEnding) -> Rect2i:
	var text_width: int = _page_width(ENDING_WIDTH) - 2 * MARGIN_X
	left.clear()
	right.clear()
	shown.order.clear()
	left.heading(shown.heading, Vector2i(MARGIN_X, TOP))
	var y: int = TOP + PixelCapitals.HEIGHT + HEADING_GAP
	for line: String in shown.outcome_lines:
		y = _paragraph(left, line, y, MARGIN_X, text_width, shown.order)
	var left_end: int = y
	y = TOP
	if shown.ledger_line != "":
		y = _paragraph(right, shown.ledger_line, y, MARGIN_X, text_width, shown.order)
	var seal_x: int = MARGIN_X + 10
	var standing: Label = right.write(shown.standing, Vector2i(seal_x, y), text_width - 10)
	shown.order.append(standing)
	right.mark(&"seal", Vector2i(MARGIN_X, y), standing)
	y += right.lines_of(standing) * DayBookPage.LINE_PITCH + PARAGRAPH_GAP
	shown.play_again_y = y
	y += TagButton.HEIGHT
	var rows_y: int = maxi(left_end, y) + ROWS_GAP + DayBookPage.LINE_PITCH + HEADER_GAP
	_write_rows(left, right, shown, rows_y)
	var height: int = rows_y + shown.rows.size() * DayBookPage.LINE_PITCH + ENDING_BOTTOM
	var book: Rect2i = _book_rect(ENDING_WIDTH, height, ENDING_LOWEST - height / 2, ENDING_HIGHEST)
	_place_pages(left, right, book, height - 4)
	return book


## Places the dusk's buttons: the dog-ear "Next" at the right page's corner (returns where its
## word is inked, ink top-left in screen pixels) and the "Skip all" tag nailed over the book's top
## edge by the spine, clear of the HUD in the screen's top-right corner however tall the book is.
static func place_dusk_buttons(next: GuardedButton, skip: TagButton, book: Rect2i) -> Vector2i:
	var ear: Rect2i = dog_ear(book)
	var next_ink := Vector2i(ear.position.x - 3 - _text_width(next, next.text), book.end.y - 12)
	next.position = Vector2(next_ink.x - 2, next_ink.y - 2)
	next.size = Vector2(ear.end.x - next_ink.x + 2, book.end.y - next_ink.y + 1)
	var skip_x: int = book.position.x + _page_width(book.size.x) - SKIP_FROM_SPINE
	skip.place(Vector2(skip_x, book.position.y - SKIP_ABOVE))
	return next_ink


## Places the "Play again" tag at the right page's top-right, on its row under the standing
## (`play_y`, right-page pixels).
static func place_play_again(play: TagButton, book: Rect2i, play_y: int) -> void:
	var width: int = play.fit_width()
	var x: int = book.end.x - MARGIN_X - width
	play.place(Vector2(x, book.position.y + play_y), width)


## The dog-eared corner of the right page (inside the page's shadow column and row).
static func dog_ear(book: Rect2i) -> Rect2i:
	return Rect2i(book.end.x - 1 - DOG_EAR, book.end.y - 1 - DOG_EAR, DOG_EAR, DOG_EAR)


## Buttons keep their text and hit area but draw nothing: the book draws them as its objects.
static func hide_button_face(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	for style: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	for color: StringName in [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
		&"font_disabled_color",
		&"font_hover_pressed_color",
	]:
		button.add_theme_color_override(color, Color(0, 0, 0, 0))


## Every line of both pages within its page's text area.
static func fits(left: DayBookPage, right: DayBookPage) -> bool:
	return left.fits() and right.fits()


## Writes the spread and returns the lowest ink row. With a `room` (page pixels), a left-page
## line that would end below it runs on, with the lines after it, at the top of the right page.
static func _write_spread(
	left: DayBookPage,
	right: DayBookPage,
	shown: DuskSpread,
	page_width: int,
	gap: int,
	room: int = 0
) -> int:
	var text_width: int = page_width - 2 * MARGIN_X
	left.clear()
	right.clear()
	var y: int = TOP
	var first: int = 0
	if shown.title != "" and not shown.left.is_empty() and shown.left[0] == shown.title:
		# The title in the carved capitals (D3), as the ending's heading.
		left.heading(shown.title, Vector2i(MARGIN_X, y))
		y += PixelCapitals.HEIGHT + TITLE_GAP
		first = 1
	var run_on: Array[String] = []
	for index: int in range(first, shown.left.size()):
		var next: int = _paragraph(left, shown.left[index], y, MARGIN_X, text_width, [], gap)
		if room > 0 and next - gap > room:
			left.drop_last()
			run_on.assign(shown.left.slice(index))
			break
		y = next
	var left_end: int = y
	y = TOP
	for line: String in run_on + shown.right:
		y = _paragraph(right, line, y, MARGIN_X, text_width, [], gap)
	return maxi(left_end, y) - gap


## Writes one paragraph at `y`, wrapped at `width`; returns the next paragraph's ink top, `gap`
## below its last line.
static func _paragraph(
	page: DayBookPage,
	line: String,
	y: int,
	x: int,
	width: int,
	order: Array[Label],
	gap: int = PARAGRAPH_GAP
) -> int:
	var label: Label = page.write(line, Vector2i(x, y), width)
	order.append(label)
	return y + page.lines_of(label) * DayBookPage.LINE_PITCH + gap


## One row per soul from `rows_y`, under the column headers: on the left page the name and the
## stamped realm's glyph and word; on the right the truth's glyph and word, the record mark and
## its word, and the black feather with the citation's word (D23, D47). The headers name the
## columns, so the row's "Truth:" stays in the harness's words only. Each column is as wide as its
## widest entry.
static func _write_rows(
	left: DayBookPage, right: DayBookPage, shown: DayBookEnding, rows_y: int
) -> void:
	var verdict_x: int = MARGIN_X + _widest(left, shown.rows, &"name_text") + COLUMN_GAP
	var truth_x: int = MARGIN_X + GLYPH_COLUMN
	var record_x: int = truth_x + _widest(right, shown.rows, &"truth_text") + COLUMN_GAP
	var feather_x: int = (
		record_x + MARK_COLUMN + _widest(right, shown.rows, &"record_text") + COLUMN_GAP
	)
	var columns: Array[int] = [verdict_x, MARGIN_X, record_x, feather_x]
	_write_headers(left, right, shown, rows_y, columns)
	for index: int in range(shown.rows.size()):
		var row: EndingRow = shown.rows[index]
		var y: int = rows_y + index * DayBookPage.LINE_PITCH
		shown.order.append(left.write(row.name_text, Vector2i(MARGIN_X, y)))
		if row.verdict_text != "":
			var glyph: StringName = GLYPHS.get(row.verdict, &"")
			var x: int = verdict_x + (GLYPH_COLUMN if glyph != &"" else 0)
			var verdict: Label = left.write(row.verdict_text, Vector2i(x, y))
			shown.order.append(verdict)
			if glyph != &"":
				left.mark(glyph, Vector2i(verdict_x, y), verdict)
		if row.truth_text != "":
			var truth: Label = right.write(row.truth_text, Vector2i(truth_x, y))
			shown.order.append(truth)
			var truth_glyph: StringName = GLYPHS.get(row.worthy, &"")
			if truth_glyph != &"":
				right.mark(truth_glyph, Vector2i(MARGIN_X, y), truth)
		if row.record_text != "":
			var record: Label = right.write(row.record_text, Vector2i(record_x + MARK_COLUMN, y))
			shown.order.append(record)
			right.mark(row.mark, Vector2i(record_x, y), record)
		if row.cited_text != "":
			var cited: Label = right.write(row.cited_text, Vector2i(feather_x + FEATHER_COLUMN, y))
			shown.order.append(cited)
			right.mark(&"feather", Vector2i(feather_x, y + 1), cited)


## "Sent" over the stamped realm on the left page; "Truth", "Record" and "Cited" over theirs on
## the right; in soft ink, one row above `rows_y`. `columns` holds their x, in that order.
static func _write_headers(
	left: DayBookPage, right: DayBookPage, shown: DayBookEnding, rows_y: int, columns: Array[int]
) -> void:
	var y: int = rows_y - DayBookPage.LINE_PITCH - HEADER_GAP
	for index: int in range(mini(shown.headers.size(), columns.size())):
		var page: DayBookPage = left if index == 0 else right
		var header: Label = page.write(shown.headers[index], Vector2i(columns[index], y))
		var soft: Color = page.get_theme_color(&"ink_soft", DayBookPage.THEME_TYPE)
		header.add_theme_color_override(&"font_color", soft)
		shown.order.append(header)


## The stamped column's width: a glyph and its word, or "never judged." with no glyph.
static func _verdict_width(page: DayBookPage, rows: Array[EndingRow]) -> int:
	var widest: int = 0
	for row: EndingRow in rows:
		var glyph: int = GLYPH_COLUMN if GLYPHS.has(row.verdict) else 0
		widest = maxi(widest, glyph + page.text_width(row.verdict_text))
	return widest


static func _widest(page: DayBookPage, rows: Array[EndingRow], field: StringName) -> int:
	var widest: int = 0
	for row: EndingRow in rows:
		widest = maxi(widest, page.text_width(String(row.get(field))))
	return widest


static func _page_width(book_width: int) -> int:
	return int((book_width - SPINE) / 2.0)


## A book `width` wide and `height` tall, centred across the screen with its middle at `centre_y`,
## kept between `highest` and LOWEST.
static func _book_rect(width: int, height: int, centre_y: int, highest: int = HIGHEST) -> Rect2i:
	var y: int = mini(centre_y - height / 2, LOWEST - height)
	return Rect2i(int((SCREEN_WIDTH - width) / 2.0), maxi(highest, y), width, height)


static func _place_pages(
	left: DayBookPage, right: DayBookPage, book: Rect2i, text_bottom: int
) -> void:
	var page_width: int = _page_width(book.size.x)
	left.position = Vector2(book.position)
	left.size = Vector2(page_width, book.size.y)
	right.position = Vector2(book.position.x + page_width + SPINE, book.position.y)
	right.size = Vector2(book.size.x - page_width - SPINE, book.size.y)
	left.text_bottom = text_bottom
	right.text_bottom = text_bottom


static func _text_width(button: Button, text: String) -> int:
	var font: Font = button.get_theme_default_font()
	if font == null:
		return 0
	return ceili(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x)
