extends GutTest
## A thread's caption names the pair by its words, never its ids (D6, D44): body facts by their
## label, decrees by their numeral, lines by an excerpt cut to width and extended until unique, and
## a grey thread by both speakers.

const BODY := EvidenceItem.Group.BODY
const CLAIM := EvidenceItem.Group.CLAIM
const WITNESS := EvidenceItem.Group.WITNESS
const LAW := EvidenceItem.Group.LAW
const THEME := "res://scenes/desk/desk_theme.tres"
const NOTE_WIDTH := 340

var _font: Font = null
var _size: int = 16


func before_all() -> void:
	var theme: Theme = load(THEME) as Theme
	_font = theme.default_font
	_size = theme.default_font_size
	PixelFont.configure(_font)


func _formatter(excerpt_px: int = -1) -> CaptionFormatter:
	var formatter := CaptionFormatter.new(_font, _size, NOTE_WIDTH)
	if excerpt_px >= 0:
		formatter.excerpt_px = excerpt_px
	return formatter


## Grim's desk: two claim lines begin "Never", the witness differs.
func _grim() -> Array[EvidenceItem]:
	return [
		EvidenceItem.make("B4", BODY, "wet to the knee"),
		EvidenceItem.make("C1", CLAIM, "Never left the hill."),
		EvidenceItem.make("C2", CLAIM, "Dry when I fell."),
		EvidenceItem.make("C4", CLAIM, "Never in the water."),
		EvidenceItem.make("W1", WITNESS, "He ran off the hill."),
		EvidenceItem.make("L3", LAW, "Even so, a warrior without a weapon in hand goes to Hel."),
	]


func _item(items: Array[EvidenceItem], id: String) -> EvidenceItem:
	for item: EvidenceItem in items:
		if item.id == id:
			return item
	return null


func test_the_excerpt_budget_is_a_share_of_the_note_line() -> void:
	assert_eq(_formatter().excerpt_px, floori(NOTE_WIDTH / float(CaptionFormatter.EXCERPT_SHARE)))


func test_a_body_fact_is_its_label_and_a_decree_its_numeral() -> void:
	var seam := Seam.make("B4", "L3", Seam.Kind.LAW, Seam.Liar.NONE, Realm.HEL, "Decree III.")
	assert_eq(
		_formatter().thread_caption(seam, _grim()),
		"Wet to the knee against decree III: Decree III."
	)


func test_a_long_line_is_cut_to_the_widest_word_count_that_fits() -> void:
	var formatter: CaptionFormatter = _formatter()
	var line := EvidenceItem.make(
		"C1", CLAIM, "Thirty winters rowing the long ship through the ice."
	)
	var items: Array[EvidenceItem] = [line]
	var excerpt: String = formatter.excerpt(line, items)
	assert_true(excerpt.ends_with('..."'), excerpt)
	assert_lte(formatter.width_of(excerpt), formatter.excerpt_px, "the cut fits its budget")
	var words: int = excerpt.trim_suffix('..."').trim_prefix('"').split(" ").size()
	var one_more: String = '"%s..."' % " ".join(line.text.split(" ").slice(0, words + 1))
	assert_gt(formatter.width_of(one_more), formatter.excerpt_px, "one more word would not fit")


func test_a_line_that_fits_is_quoted_whole_without_its_stop() -> void:
	var line := EvidenceItem.make("C2", CLAIM, "Took it in the chest.")
	var items: Array[EvidenceItem] = [line]
	assert_eq(_formatter(1000).excerpt(line, items), '"Took it in the chest"')


func test_the_cut_drops_the_punctuation_before_the_dots() -> void:
	var line := EvidenceItem.make("C1", CLAIM, "Speared, in battle.")
	var items: Array[EvidenceItem] = [line]
	assert_eq(_formatter(0).excerpt(line, items), '"Speared..."')


func test_an_excerpt_grows_until_no_other_line_begins_the_same() -> void:
	# A budget of 0 keeps one word: "Never" is shared by two of Grim's lines, "Dry" by none.
	var formatter: CaptionFormatter = _formatter(0)
	var items: Array[EvidenceItem] = _grim()
	assert_eq(
		[
			formatter.excerpt(_item(items, "C1"), items),
			formatter.excerpt(_item(items, "C4"), items),
			formatter.excerpt(_item(items, "C2"), items),
		],
		['"Never left..."', '"Never in..."', '"Dry..."']
	)


func test_identical_lines_extend_to_the_whole_line() -> void:
	var items: Array[EvidenceItem] = [
		EvidenceItem.make("C1", CLAIM, "I held the door."),
		EvidenceItem.make("W1", WITNESS, "I held the door."),
	]
	assert_eq(_formatter(0).excerpt(items[0], items), '"I held the door"')


func test_a_grey_thread_names_both_speakers() -> void:
	var items: Array[EvidenceItem] = [
		EvidenceItem.make("C2", CLAIM, "Took it in the chest."),
		EvidenceItem.make("W1", WITNESS, "He ran off the hill."),
	]
	var formatter: CaptionFormatter = _formatter()
	formatter.excerpt_px = formatter.width_of('"Took it..."')
	var seam := Seam.make("C2", "W1", Seam.Kind.GREY, Seam.Liar.CLAIM, &"", "one of them lies.")
	assert_eq(
		formatter.thread_caption(seam, items, "Ulf", "Bersi"),
		'Ulf\'s "Took it..." against Bersi\'s "He ran...": one of them lies.'
	)


func test_a_red_thread_names_no_speaker() -> void:
	var seam := Seam.make(
		"B4", "C2", Seam.Kind.RED, Seam.Liar.CLAIM, &"", "the body gives the lie."
	)
	assert_eq(
		_formatter(0).thread_caption(seam, _grim(), "Grim", "Orm"),
		'Wet to the knee against "Dry...": the body gives the lie.'
	)


func test_a_decree_missing_from_the_items_is_still_named_by_its_numeral() -> void:
	var seam := Seam.make("C2", "L5", Seam.Kind.LAW, Seam.Liar.NONE, Realm.FOLKVANGR, "Decree V.")
	var caption: String = _formatter(0).thread_caption(seam, _grim())
	assert_eq(caption, '"Dry..." against decree V: Decree V.')
