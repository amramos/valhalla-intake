class_name Teller
extends Node
## Tells a Label's text line by line at a steady pace (D4): each "\n"-separated line is revealed
## one character at a time through `Label.visible_characters`, with a pause between lines and a
## voice blip every few non-space characters (D41). It is driven by `_process` alone, never by a
## timer, so a pause stops it exactly and a test can step it with fixed deltas. The pace depends
## only on the text, the speed, the pause and the voice: nothing about who is speaking can change
## it (D1).

## Emitted when line `index` begins to show (its hit area may be used from then on); every line
## gets exactly one, in order, before `finished`.
signal line_shown(index: int)
## A voice blip at `pitch_scale` (the same for every blip of one voice).
signal blip(pitch_scale: float)
## Emitted once when the whole text shows, by pace or by `finish()`.
signal finished

## One blip per this many revealed non-space characters.
const CHARACTERS_PER_BLIP := 3
## The shortest gap between blips at every speed: about 13 a second (D41), set to three
## characters at the normal 40 cps so the cap never thins the normal voice.
const MIN_BLIP_GAP := 0.075
## Absorbs float error so a delta of exactly 1/cps reveals exactly one character.
const EPSILON := 0.000001

## The label each line is told on, the line's start index in that label's text, and its text.
var _line_labels: Array[Label] = []
var _line_starts: Array[int] = []
var _line_texts: Array[String] = []
var _cps: float = 40.0
var _line_pause: float = 0.25
var _pitch: float = 1.0
var _line: int = 0
## Characters of the current line already revealed.
var _revealed: int = 0
## Seconds left of the pause before the next line; 0 when not pausing.
var _pause_left: float = 0.0
## Unspent seconds carried to the next step.
var _carry: float = 0.0
## Presentation seconds consumed since `start`, and when the last blip sounded.
var _elapsed: float = 0.0
var _last_blip_at: float = -INF
var _since_blip: int = 0
var _telling: bool = false
var _paused: bool = false
## At infinite speed `finished` waits for the next frame.
var _finish_pending: bool = false


## The blip pitch for a voice: 0.75 to 1.25, from a hash of `voice` alone.
static func pitch_for(voice: int) -> float:
	return 0.75 + 0.5 * float(posmod(hash(voice), 1000)) / 1000.0


## Tells `text` on `label` at `cps` characters a second, pausing `line_pause` seconds between
## lines; `voice` (the caller passes `hash(soul_name)`) sets the blip pitch. An infinite `cps`
## (or an empty text) shows everything at once, emits every `line_shown` now and `finished` on
## the next frame, and never blips (D37, D41); `is_telling()` is then already false. Starting
## again replaces the telling in progress without emitting its `finished`. `visible_characters`
## counts indices into `label.text` (newlines included), as `VC_CHARS_BEFORE_SHAPING` does.
func start(label: Label, text: String, cps: float, line_pause: float, voice: int) -> void:
	label.text = text
	_line_labels.clear()
	_line_starts.clear()
	_line_texts.clear()
	var start_index: int = 0
	for line: String in text.split("\n"):
		_line_labels.append(label)
		_line_starts.append(start_index)
		_line_texts.append(line)
		start_index += line.length() + 1
	_begin(cps, line_pause, voice)


## Tells several labels in order as one text, each label one line (its text already set), with
## the same pace, pauses and signals as `start`; a label not yet begun shows nothing.
func start_labels(labels: Array[Label], cps: float, line_pause: float, voice: int) -> void:
	_line_labels.clear()
	_line_starts.clear()
	_line_texts.clear()
	for label: Label in labels:
		_line_labels.append(label)
		_line_starts.append(0)
		_line_texts.append(label.text)
	_begin(cps, line_pause, voice)


func _begin(cps: float, line_pause: float, voice: int) -> void:
	_cps = cps
	_line_pause = maxf(line_pause, 0.0)
	_pitch = pitch_for(voice)
	_line = 0
	_revealed = 0
	_pause_left = 0.0
	_carry = 0.0
	_elapsed = 0.0
	_last_blip_at = -INF
	_since_blip = 0
	_finish_pending = false
	if is_inf(cps) or cps <= 0.0 or _is_blank():
		_telling = false
		_show_all()
		for index: int in range(_line_labels.size()):
			line_shown.emit(index)
		_finish_pending = true
		return
	_telling = true
	for label: Label in _line_labels:
		label.visible_characters = 0
	_begin_line()


## Shows the whole text at once and emits `finished` once; does nothing when nothing is told.
func finish() -> void:
	if _telling:
		_telling = false
		_show_all()
		for index: int in range(_line + 1, _line_labels.size()):
			line_shown.emit(index)
		finished.emit()
	elif _finish_pending:
		_finish_pending = false
		finished.emit()


## Changes the pace of the telling in progress to `cps` from the next character on, keeping what
## is shown, the line it is on and any pause (the text speed changed mid-telling, D37). An
## infinite (or non-positive) `cps` shows the rest at once and emits `finished` now. Nothing is
## told: nothing changes (the next `start` takes its own pace).
func set_cps(cps: float) -> void:
	if not _telling:
		return
	if is_inf(cps) or cps <= 0.0:
		finish()
		return
	_cps = cps


## The pace of the telling in progress (or the last one), in characters a second.
func pace() -> float:
	return _cps


## Stops the telling where it is, without showing the rest or emitting `finished` (a restart).
func stop() -> void:
	_telling = false
	_finish_pending = false


func is_telling() -> bool:
	return _telling


## A paused teller neither reveals, blips nor finishes until unpaused.
func set_paused(paused: bool) -> void:
	_paused = paused


func is_paused() -> bool:
	return _paused


func _process(delta: float) -> void:
	if _paused:
		return
	if _finish_pending:
		_finish_pending = false
		finished.emit()
		return
	if not _telling:
		return
	_carry += delta
	_advance()


## Spends `_carry` on pauses and characters, in order, until it runs out or the text ends.
func _advance() -> void:
	var step: float = 1.0 / _cps
	while _telling:
		if _pause_left > 0.0:
			if _carry + EPSILON < _pause_left:
				_pause_left -= _carry
				_elapsed += _carry
				_carry = 0.0
				return
			_carry = maxf(_carry - _pause_left, 0.0)
			_elapsed += _pause_left
			_pause_left = 0.0
			_line += 1
			_begin_line()
			continue
		if _revealed >= _line_texts[_line].length():
			_end_line()
			continue
		if _carry + EPSILON < step:
			return
		_carry = maxf(_carry - step, 0.0)
		_elapsed += step
		_reveal_one()


func _begin_line() -> void:
	_revealed = 0
	_line_labels[_line].visible_characters = _line_starts[_line]
	line_shown.emit(_line)
	if _line_texts[_line].is_empty():
		_end_line()


## The current line is out: pause before the next one, or finish after the last.
func _end_line() -> void:
	if _line + 1 >= _line_labels.size():
		_telling = false
		_show_all()
		finished.emit()
		return
	if _line_pause <= 0.0:
		_line += 1
		_begin_line()
		return
	_pause_left = _line_pause


func _reveal_one() -> void:
	var character: String = _line_texts[_line][_revealed]
	_revealed += 1
	_line_labels[_line].visible_characters = _line_starts[_line] + _revealed
	if character.strip_edges() == "":
		return
	_since_blip += 1
	if _since_blip < CHARACTERS_PER_BLIP:
		return
	if _elapsed - _last_blip_at + EPSILON < MIN_BLIP_GAP:
		return
	_since_blip = 0
	_last_blip_at = _elapsed
	blip.emit(_pitch)


## Nothing to reveal: told like an infinite speed, so `finished` never fires inside `start`.
func _is_blank() -> bool:
	for line: String in _line_texts:
		if not line.is_empty():
			return false
	return true


func _show_all() -> void:
	for label: Label in _line_labels:
		if is_instance_valid(label):
			label.visible_characters = -1
