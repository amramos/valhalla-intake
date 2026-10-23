class_name StampConsequences
extends RefCounted
## What a stamp leaves on the desk (D10, D15, D16, D33, D38), for StampFlow. A stamp with a
## citation (or a day-1 warning) writes the citation on the note with its pair lit and her
## comment after it; an unheld stamp's comment waits for the next soul. The black feather drifts
## in from the left to its place beside the mentor with a dry caw, and a stamp that grew Hel's
## tide steps its new figure in: both land at the slam's impact, once per stamp, from the
## StampResult in hand (never a refresh). Until the impact the desk shows the tide as it was:
## `displayed_tide` is what every refresh draws. A click on the feather shows its citation again.

## The cited pair to light (or [] to clear), for the desk system that owns highlights.
signal pair_lit(pair: Array[String])
## Any half-made pin must be dropped (a stamp just happened).
signal selection_cleared

## The feather's drift (D16): from this x on screen (off the left edge) to its place beside the
## mentor, at its resting height, this long, swaying this far down and back. Its path crosses no
## evidence: it stays below the slab, left of the sheets.
const FEATHER_DRIFT_FROM_X := -32
const FEATHER_DRIFT_SECONDS := 0.5
const FEATHER_SWAY_PX := 2

var _commands: DeskCommands = null
var _gate: PresentationGate = null
var _feather: ClickableSprite = null
var _caw: AudioStreamPlayer = null
var _strip: CaptionStrip = null
var _doors: Array[Door] = []

var _citation: String = ""
var _cited_pair: Array[String] = []
## The committed stamp's consequences, waiting for its impact: the feather's fall, the tide's step.
var _feather_due: bool = false
var _tide_due: bool = false
## The mentor's comment on the last stamp: shown over the next soul, and again on a click on her.
var _mentor_line: String = ""
var _carry_mentor: bool = false
## Her comment on a held stamp waits behind the citation's hold; true until the strip shows it.
var _mentor_unseen: bool = false


## `caw` and `gate` are optional (a desk without a caw lets the feather fall silently).
func bind(
	commands: DeskCommands,
	gate: PresentationGate,
	feather: ClickableSprite,
	caw: AudioStreamPlayer,
	strip: CaptionStrip,
	doors: Array[Door]
) -> void:
	_commands = commands
	_gate = gate
	_feather = feather
	_caw = caw
	_strip = strip
	_doors = doors
	_commands.stamped.connect(_on_stamped)
	_feather.clicked.connect(_on_feather_clicked)
	_strip.text_shown.connect(_on_caption_shown)


func citation() -> String:
	return _citation


func mentor_line() -> String:
	return _mentor_line


## The feather shows while a cited soul is held, unless it is still waiting to drift in.
func show_feather(waiting: bool) -> void:
	_feather.visible = waiting and _citation != "" and not _feather_due


## A new soul (or an empty desk): the last soul's citation is gone; her comment on the stamp that
## seated it goes to the (freshly cleared) note, unless the horn's announcement already holds it:
## her comment never queues behind the horn.
func reset() -> void:
	_citation = ""
	_cited_pair.clear()
	_mentor_unseen = false
	if _carry_mentor and _strip.shown_text() == "":
		_strip.post_caption(_mentor_caption())
	_carry_mentor = false


## A new run: nothing the mentor said in the last run is shown or replayed.
func forget_run() -> void:
	_mentor_line = ""
	_carry_mentor = false
	_mentor_unseen = false


## "Send it on" inside the citation's hold would clear her waiting comment with the strip; it goes
## to the next soul instead, as an unheld stamp's does.
func send_on() -> void:
	if _mentor_unseen:
		_carry_mentor = true


## At the commit: the refresh inside `commands.stamp` already showed the feather and the grown
## tide; both wait, hidden, for the impact. From here until the impact (or a cancel) every
## refresh draws the tide as it was before this stamp (`displayed_tide`).
func hold(held: bool, tide_grew: bool) -> void:
	_feather_due = held and _citation != ""
	_tide_due = tide_grew
	if _feather_due:
		_feather.visible = false
	var hel: Door = _hel()
	if _tide_due and hel != null:
		hel.set_tide(displayed_tide(), _commands.slice_rules().tide_threshold)


## The tide the desk shows: the committed count, less the figure a pending stamp has yet to step
## in at its impact.
func displayed_tide() -> int:
	return _commands.hel_tide() - (1 if _tide_due else 0)


## At the impact: the feather drifts in to its place with its caw, its click target live there at
## once (D16); Hel's new figure steps in (D38). `still` (reduce motion): both at once, in place
## (D37). The pending state is released here exactly once.
func land(still: bool) -> void:
	if _tide_due:
		_tide_due = false
		var hel: Door = _hel()
		if hel != null:
			var threshold: int = _commands.slice_rules().tide_threshold
			var rise: float = 0.0 if still else Door.TIDE_RISE_SECONDS
			_watch(hel.step_tide(_commands.hel_tide(), threshold, rise))
	if _feather_due:
		_feather_due = false
		# Shown only if the soul is still held at the desk (a restart or the horn may have cleared it).
		_feather.visible = (
			_commands.phase() == RunState.DESK and _commands.awaiting_next() and _citation != ""
		)
		if not _feather.visible:
			return
		var drift: float = 0.0 if still else FEATHER_DRIFT_SECONDS
		var from_x: float = FEATHER_DRIFT_FROM_X - _feather.global_position.x
		_watch(_feather.drift_in(from_x, drift, FEATHER_SWAY_PX))
		if _caw != null and _caw.stream != null and _caw.is_inside_tree():
			_caw.play()
			if _gate != null:
				_gate.watch_player(_caw)


## A slam cut off before its impact lands nothing; the next refresh shows the desk as it is
## (the committed tide).
func cancel() -> void:
	_feather_due = false
	_tide_due = false


func _on_stamped(result: StampResult) -> void:
	selection_cleared.emit()
	var held: bool = result.citation or result.warning
	if held:
		# The citation takes the strip first (D33); her comment waits behind it.
		_citation = result.citation_text
		_cited_pair = [result.citation_a, result.citation_b] as Array[String]
		pair_lit.emit(_cited_pair.duplicate())
		_strip.post_caption(_citation_caption())
	if result.mentor_line != "":
		_mentor_line = result.mentor_line
		# A held soul shows her comment after the citation; otherwise the next soul's arrival does.
		_carry_mentor = not held
		if held:
			_mentor_unseen = true
			_strip.post_caption(_mentor_caption())


func _on_caption_shown(text: String) -> void:
	if text == _mentor_line:
		_mentor_unseen = false


## A deliberate click on the feather shows its citation again and lights the pair (D33).
func _on_feather_clicked() -> void:
	_strip.take_over_caption(_citation_caption())
	pair_lit.emit(_cited_pair.duplicate())


## The citation as the note shows it: the black feather's mark, written out, its pair lit (D10).
func _citation_caption() -> Caption:
	return Caption.make(
		_citation, CaptionStrip.Priority.CITATION, &"feather", _cited_pair.duplicate(), true
	)


## Her comment as the note shows it: her face as the mark, written out (D10).
func _mentor_caption() -> Caption:
	return Caption.make(_mentor_line, CaptionStrip.Priority.MENTOR, &"mentor", [], true)


func _hel() -> Door:
	for door: Door in _doors:
		if door.realm == Realm.HEL:
			return door
	return null


func _watch(tween: Tween) -> void:
	if _gate != null and tween != null:
		_gate.watch_tween(tween)
