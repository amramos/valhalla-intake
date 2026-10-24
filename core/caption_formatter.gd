class_name CaptionFormatter
extends RefCounted
## A thread's caption as the clerk's note writes it (D6, D44): the two pinned pieces of evidence
## named by their words, never their ids, then the seam's own caption. The desk and the text
## harness both build captions here, so they say the same words.
##
## A claim or witness line is named by an excerpt: its first words in straight quotes, cut with
## ASCII "..." to fit `excerpt_px`, then extended word by word until no other line on the desk
## begins with the same words. A grey thread names both speakers before their excerpts. A body
## fact is named by its label, a decree by its numeral ("decree III").

const CAPTION_FORMAT := "%s against %s: %s"
const SPEAKER_FORMAT := "%s's %s"
const QUOTE_FORMAT := '"%s"'
const CUT := "..."
## Punctuation dropped from the end of an excerpt's last word, before "..." or the closing quote.
const TRAILING := ".,;:"
## The share of the note's line an excerpt may take before it is cut.
const EXCERPT_SHARE := 4

## The width of one line of the clerk's note's text on the desk (x 11-341 of the strip, D10).
## The desk measures it from the strip; the harness takes this constant so both cut the same
## excerpts (D44), and a test holds them equal.
const NOTE_LINE_PX := 330

## The widest an excerpt is cut to, in pixels; uniqueness may extend it past this.
var excerpt_px: int = 0

var _font: Font = null
var _font_size: int = 16


## font and font_size are the note's; max_px is the width of one line of the note.
func _init(font: Font, font_size: int, max_px: int) -> void:
	_font = font
	_font_size = font_size
	excerpt_px = floori(max_px / float(EXCERPT_SHARE))


## "<excerpt a> against <excerpt b>: <seam.caption>", in the seam's own order. items: everything
## on the desk (the soul's evidence and the day's decrees), to find the two ends and to keep each
## excerpt unique. The speakers name a grey thread's two sides: the soul (claim lines) and the
## witness (witness lines, the heading name).
func thread_caption(
	seam: Seam, items: Array[EvidenceItem], claim_speaker: String = "", witness_speaker: String = ""
) -> String:
	var speakers: Dictionary = {}
	if seam.kind == Seam.Kind.GREY:
		speakers = {
			EvidenceItem.Group.CLAIM: claim_speaker,
			EvidenceItem.Group.WITNESS: witness_speaker,
		}
	var first: String = _name_of(seam.a, items, speakers)
	var second: String = _name_of(seam.b, items, speakers)
	var caption: String = CAPTION_FORMAT % [first, second, seam.caption]
	return caption.left(1).to_upper() + caption.substr(1)


## How a caption names one piece of evidence, without a speaker: the quoted excerpt of a line,
## the label of a body fact, "decree III" for a decree.
func excerpt(item: EvidenceItem, items: Array[EvidenceItem]) -> String:
	match item.group:
		EvidenceItem.Group.BODY:
			return item.text
		EvidenceItem.Group.LAW:
			return DecreeNumeral.label(item.id)
	return QUOTE_FORMAT % _words(item, items)


## The width of `text` in the note's font, as a Label draws it; without a font, 6 px a character.
func width_of(text: String) -> int:
	if _font == null:
		return text.length() * 6
	return int(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x)


func _name_of(item_id: String, items: Array[EvidenceItem], speakers: Dictionary) -> String:
	var item: EvidenceItem = _find(item_id, items)
	if item == null:
		# Never an id on the note: a decree is still named by its numeral.
		return DecreeNumeral.label(item_id) if DecreeNumeral.is_decree_id(item_id) else item_id
	var name: String = excerpt(item, items)
	var speaker: String = speakers.get(item.group, "")
	return SPEAKER_FORMAT % [speaker, name] if speaker != "" else name


## The line's first words: as many as fit excerpt_px with the cut, at least one, then more until
## no other line on the desk starts with the same words. The whole line drops its last stop.
func _words(item: EvidenceItem, items: Array[EvidenceItem]) -> String:
	var words: PackedStringArray = item.text.split(" ", false)
	if words.is_empty():
		return ""
	var count: int = 1
	while count < words.size() and _fits(_cut(words, count + 1)):
		count += 1
	while count < words.size() and not _unique(words, count, item, items):
		count += 1
	if count >= words.size():
		return _trimmed(item.text.strip_edges())
	return _cut(words, count)


func _cut(words: PackedStringArray, count: int) -> String:
	if count >= words.size():
		return _trimmed(" ".join(words))
	return _trimmed(" ".join(words.slice(0, count))) + CUT


func _fits(words_text: String) -> bool:
	return width_of(QUOTE_FORMAT % words_text) <= excerpt_px


## True when no other claim or witness line on the desk begins with the same first `count` words.
func _unique(
	words: PackedStringArray, count: int, item: EvidenceItem, items: Array[EvidenceItem]
) -> bool:
	var prefix: PackedStringArray = words.slice(0, count)
	for other: EvidenceItem in items:
		if other == item or other.id == item.id or not _is_line(other):
			continue
		var other_words: PackedStringArray = other.text.split(" ", false)
		if other_words.size() >= count and other_words.slice(0, count) == prefix:
			return false
	return true


func _trimmed(text: String) -> String:
	var end: int = text.length()
	while end > 1 and TRAILING.contains(text[end - 1]):
		end -= 1
	return text.left(end)


static func _is_line(item: EvidenceItem) -> bool:
	return item.group == EvidenceItem.Group.CLAIM or item.group == EvidenceItem.Group.WITNESS


static func _find(item_id: String, items: Array[EvidenceItem]) -> EvidenceItem:
	for item: EvidenceItem in items:
		if item.id == item_id:
			return item
	return null
