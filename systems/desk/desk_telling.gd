class_name DeskTelling
extends RefCounted
## The soul's tale told at the desk (D4, D5, D7): the claim's sheet first, then the witness's, each
## written out by its panel's Teller while the presentation gate holds a TELLING consumer. The
## witness's sheet waits, headed but blank, until the claim is told. One consumed click finishes
## both: a witness that follows a finished claim is told at once. At an infinite pace (the
## "instant" text speed, D37) nothing is gated and no click is consumed.
##
## The pace is the same for every soul; only the voice (a hash of the name) differs (D1). While
## a tale is told the soul speaks: its plate lights and it bobs on each voice blip (D4, D17), each
## bob watched by the gate so the pause holds it. After a slam the new sheets slide up into place
## with the soul's walk-in (D15).

## The whole tale shows: by pace or by a consumed click.
signal finished
## The tale was cut short (a consumed click, a new soul, a restart): its voice must stop now.
signal silenced

enum Stage { IDLE, CLAIM, WITNESS }

## The pause between two lines of one sheet (D4).
const LINE_PAUSE := 0.25
## The new sheets rise into place from this far below, as long as the soul's walk-in (D15).
const SLIDE_PX := 6
const SLIDE_SECONDS := 0.3

## The soul whose tale is told; optional (a desk without one tells the tale all the same).
var soul: WaitingSoul = null

var _claim: EvidencePanel = null
var _witness: EvidencePanel = null
var _gate: PresentationGate = null
var _cps: float = Options.NORMAL_CPS
var _voice: int = 0
var _stage: Stage = Stage.IDLE
## Puts the witness's lines on its sheet, just before they are told.
var _show_witness: Callable = Callable()
var _token: int = -1
## A consumed click finished the tale: what is still to tell shows at once.
var _skipping: bool = false
## The sheets' places, kept while they slide so a slide cut off puts them back; empty otherwise.
var _homes: Array[Vector2] = []
var _slide: Tween = null


func _init(claim: EvidencePanel, witness: EvidencePanel, gate: PresentationGate) -> void:
	_claim = claim
	_witness = witness
	_gate = gate
	_claim.telling_finished.connect(_on_told.bind(Stage.CLAIM))
	_witness.telling_finished.connect(_on_told.bind(Stage.WITNESS))
	_gate.register_teller(_claim.teller())
	_gate.register_teller(_witness.teller())
	for panel: EvidencePanel in [_claim, _witness]:
		panel.teller().blip.connect(_on_blip)


## Characters a second for the next tale (Options.cps(): INF tells at once).
func set_cps(cps: float) -> void:
	_cps = cps


## Tells the shown claim from its first line, then calls `show_witness` (which puts the witness's
## lines on its blank sheet) and tells those; `voice` is `hash(soul_name)`.
func begin(voice: int, show_witness: Callable) -> void:
	stop()
	_voice = voice
	_skipping = false
	_show_witness = show_witness
	_tell(_claim, Stage.CLAIM)


## Seats a soul's sheets and tells its tale (D6, D7, D52): the claim headed by the soul, the
## witness headed by its witness's name (the full description is its hover) and blank until the
## claim is told. The witness's sheet shows only with lines or a note; no soul empties both.
func show_sheets(
	encounter: Encounter, claim: Array[EvidenceItem], witness: Array[EvidenceItem]
) -> void:
	_claim.show_lines(claim, encounter.soul_name if encounter != null else "")
	var title: String = ""
	var hover: String = ""
	var note: String = ""
	if encounter != null:
		title = encounter.witness_heading_name()
		hover = encounter.witness_name
		note = encounter.witness_note
	var show_witness: Callable = _witness.show_lines.bind(witness, title, note, hover)
	_witness.visible = not witness.is_empty() or note != ""
	if encounter == null:
		show_witness.call()
		return
	_witness.show_lines([] as Array[EvidenceItem], title, "", hover)
	begin(hash(encounter.soul_name), show_witness)


## Slides the claim and witness sheets up into place over `seconds` (0, or outside the tree: they
## are in place at once, reduce motion). Only their drawing position moves; their lines and hit
## areas go with them. Returns the tween (watched by the gate), or null.
func slide_in(seconds: float = SLIDE_SECONDS) -> Tween:
	_end_slide()
	if seconds <= 0.0 or not _claim.is_inside_tree():
		return null
	for sheet: EvidencePanel in [_claim, _witness]:
		_homes.append(sheet.position)
	_lower(float(SLIDE_PX))
	# Stepped in whole pixels, like the desk's jolt: a sheet never sits off the pixel grid.
	_slide = _claim.create_tween()
	_slide.tween_method(_lower, float(SLIDE_PX), 0.0, seconds)
	_slide.tween_callback(_slid)
	_gate.watch_tween(_slide)
	return _slide


func is_sliding() -> bool:
	return _slide != null and _slide.is_valid()


func is_telling() -> bool:
	return _stage != Stage.IDLE


## Shows the whole tale now (the gate's consumed click, or a tool); emits `finished` once.
func finish() -> void:
	if _stage == Stage.IDLE:
		return
	_skipping = true
	_end_token()
	silenced.emit()
	if _stage == Stage.CLAIM:
		_claim.finish_telling()
	if _stage == Stage.WITNESS:
		_witness.finish_telling()


## Drops the tale without finishing it (a new soul or a restart); the panels' own `show_lines`
## stops their tellers.
func stop() -> void:
	_end_slide()
	_end_token()
	if _stage != Stage.IDLE:
		silenced.emit()
	_stage = Stage.IDLE
	_skipping = false
	_speak(false)


func _tell(panel: EvidencePanel, stage: Stage) -> void:
	_stage = stage
	panel.tell(_voice, INF if _skipping else _cps, LINE_PAUSE)
	if panel.is_telling():
		_speak(true)
		_token = _gate.begin(PresentationGate.TELLING, finish)
	else:
		# Told at once: go on now; the panel's late `telling_finished` finds the stage moved on.
		_told(stage)


func _on_told(stage: Stage) -> void:
	if stage != _stage:
		return
	_end_token()
	_told(stage)


func _told(stage: Stage) -> void:
	if stage == Stage.CLAIM:
		if _show_witness.is_valid():
			_show_witness.call()
		_tell(_witness, Stage.WITNESS)
		return
	_stage = Stage.IDLE
	_skipping = false
	_speak(false)
	finished.emit()


func _speak(on: bool) -> void:
	if soul != null:
		soul.set_speaking(on)


## Each voice blip of the tale bobs the speaking soul (D17); the gate holds the bob under the
## pause like every presentation.
func _on_blip(_pitch_scale: float) -> void:
	if soul != null:
		var bob: Tween = soul.bob()
		if bob != null:
			_gate.watch_tween(bob)


## Puts the sliding sheets `pixels` below their places, rounded to whole pixels.
func _lower(pixels: float) -> void:
	var sheets: Array[EvidencePanel] = [_claim, _witness]
	for index: int in range(_homes.size()):
		sheets[index].position = _homes[index] + Vector2(0, roundi(pixels))


## The slide is over: the sheets are in their places.
func _slid() -> void:
	_slide = null
	_homes.clear()


## Ends a slide under way with the sheets in their places.
func _end_slide() -> void:
	if _slide != null and _slide.is_valid():
		_slide.kill()
	_slide = null
	var sheets: Array[EvidencePanel] = [_claim, _witness]
	for index: int in range(_homes.size()):
		sheets[index].position = _homes[index]
	_homes.clear()


func _end_token() -> void:
	if _token >= 0:
		_gate.end(_token)
	_token = -1
