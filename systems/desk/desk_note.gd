class_name DeskNote
extends RefCounted
## The desk's side of the clerk's note (D10, D28, D43): it builds the Captions the desk posts (a
## thread's quoted pair under the pin in its colour, Huginn's answer under the raven, the mentor's
## written comment), lights the pair a caption quotes while it shows, and holds the presentation
## gate while a written caption's quill is at work, so a click finishes the writing and nothing
## else (D27). A law thread's caption that names a realm lights that door's glyph until the next
## caption shows; a caption naming no realm lights none.

## A caption that quotes `pair` reached the note: light it.
signal pair_shown(pair: Array[String])
## The next caption replaced the one that quoted `pair`: drop it, if it is still what is lit.
signal pair_dropped(pair: Array[String])

## The note's font size (ADR-0008).
const FONT_SIZE := 16
## The speaker mark of each thread kind's caption, in Seam.Kind order (red, grey, law).
const THREAD_MARKS: Array[StringName] = [&"pin_red", &"pin_grey", &"pin_law"]
## The quill writes half again as fast as the telling at each text speed (D43: 60 cps at normal).
const WRITE_PACE := 1.5

## The realm doors whose glyphs a law caption lights (DeskSystem hands them in).
var doors: Array[Door] = []

var _strip: CaptionStrip = null
var _gate: PresentationGate = null
var _formatter: CaptionFormatter = null
## The pair the shown caption quotes; empty for none.
var _pair: Array[String] = []
## The gate's token for the written caption in progress; -1 for none.
var _written_token: int = -1
## The realm each law caption built here names, until it shows.
var _realms: Dictionary[Caption, StringName] = {}


func _init(strip: CaptionStrip, gate: PresentationGate) -> void:
	_strip = strip
	_gate = gate
	var font: Font = strip.get_theme_font(&"font", &"Label")
	_formatter = CaptionFormatter.new(font, FONT_SIZE, line_width())
	_gate.register_teller(strip.teller())
	strip.caption_shown.connect(_on_caption_shown)
	strip.writing_finished.connect(_end_written)


## The width of one line of the note's text, which excerpts are cut against.
func line_width() -> int:
	return int(_strip.size.x) - CaptionStrip.TEXT_LEFT - CaptionStrip.TEXT_RIGHT


## The quill's pace follows the text speed: INF at "instant" writes at once (D37, D43). A caption
## being written takes the new pace now (never longer than the strip's second); "instant" writes
## the rest at once, and its `writing_finished` releases the gate.
func use_options(options: Options) -> void:
	var cps: float = options.cps() * WRITE_PACE
	_strip.write_cps = cps
	if not _strip.is_writing():
		return
	if not is_inf(cps) and cps > 0.0:
		cps = maxf(cps, _strip.shown_text().length() / CaptionStrip.MAX_WRITE_SECONDS)
	_strip.teller().set_cps(cps)


## A thread's caption: the pair named by its words (D6), both speakers on a grey thread.
func thread(seam: Seam, encounter: Encounter, items: Array[EvidenceItem]) -> Caption:
	var soul_name: String = encounter.soul_name if encounter != null else ""
	var witness: String = encounter.witness_heading_name() if encounter != null else ""
	var text: String = _formatter.thread_caption(seam, items, soul_name, witness)
	var pair: Array[String] = [seam.a, seam.b]
	var caption: Caption = Caption.make(
		text, CaptionStrip.Priority.THREAD, THREAD_MARKS[seam.kind], pair
	)
	if seam.kind == Seam.Kind.LAW and seam.destination != &"":
		_realms[caption] = seam.destination
	return caption


## Huginn's answer on a thread, quoting the thread's pair.
func raven(answer: String, seam: Seam) -> Caption:
	var pair: Array[String] = [seam.a, seam.b]
	return Caption.make(answer, CaptionStrip.Priority.HUGINN, &"raven", pair)


## The mentor's comment, written out by the quill.
func mentor(text: String) -> Caption:
	return Caption.make(text, CaptionStrip.Priority.MENTOR, &"mentor", [], true)


## The note was cleared (a new soul): no pair and no writing are left to track.
func reset() -> void:
	_end_written()
	_pair.clear()
	_realms.clear()
	_light_glyph(&"")


## Something else lit a pair (a held citation): the next caption leaves it lit.
func release_pair() -> void:
	_pair.clear()


## Ends every gate hold without touching the gate (the gate was cancelled: a restart).
func forget() -> void:
	_written_token = -1
	_pair.clear()
	_realms.clear()
	_light_glyph(&"")


## The realm whose door's glyph is lit now; &"" for none (tests).
func lit_glyph() -> StringName:
	for door: Door in doors:
		if door.glyph_lit():
			return door.realm
	return &""


func _on_caption_shown(caption: Caption) -> void:
	_end_written()
	_light_glyph(_realms.get(caption, &""))
	_realms.erase(caption)
	if caption.written and _strip.is_writing():
		_written_token = _gate.begin(PresentationGate.WRITTEN, _strip.finish_writing)
	if not caption.pair.is_empty():
		_pair = caption.pair.duplicate()
		pair_shown.emit(caption.pair.duplicate())
	elif not _pair.is_empty():
		var dropped: Array[String] = _pair.duplicate()
		_pair.clear()
		pair_dropped.emit(dropped)


func _end_written() -> void:
	if _written_token >= 0:
		_gate.end(_written_token)
	_written_token = -1


## Lights the glyph of `realm`'s door and darkens every other; &"" darkens them all.
func _light_glyph(realm: StringName) -> void:
	for door: Door in doors:
		door.set_glyph_lit(realm != &"" and door.realm == realm)
