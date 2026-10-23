class_name DeskTelling
extends RefCounted
## The soul's tale told at the desk (D4, D5, D7): the claim's sheet first, then the witness's, each
## written out by its panel's Teller while the presentation gate holds a TELLING consumer. The
## witness's sheet waits, headed but blank, until the claim is told. One consumed click finishes
## both: a witness that follows a finished claim is told at once. At an infinite pace (the
## "instant" text speed, D37) nothing is gated and no click is consumed.
##
## The pace is the same for every soul; only the voice (a hash of the name) differs (D1).

## The whole tale shows: by pace or by a consumed click.
signal finished

enum Stage { IDLE, CLAIM, WITNESS }

## The pause between two lines of one sheet (D4).
const LINE_PAUSE := 0.25

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


func _init(claim: EvidencePanel, witness: EvidencePanel, gate: PresentationGate) -> void:
	_claim = claim
	_witness = witness
	_gate = gate
	_claim.telling_finished.connect(_on_told.bind(Stage.CLAIM))
	_witness.telling_finished.connect(_on_told.bind(Stage.WITNESS))
	_gate.register_teller(_claim.teller())
	_gate.register_teller(_witness.teller())


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


func is_telling() -> bool:
	return _stage != Stage.IDLE


## Shows the whole tale now (the gate's consumed click, or a tool); emits `finished` once.
func finish() -> void:
	if _stage == Stage.IDLE:
		return
	_skipping = true
	_end_token()
	if _stage == Stage.CLAIM:
		_claim.finish_telling()
	if _stage == Stage.WITNESS:
		_witness.finish_telling()


## Drops the tale without finishing it (a new soul or a restart); the panels' own `show_lines`
## stops their tellers.
func stop() -> void:
	_end_token()
	_stage = Stage.IDLE
	_skipping = false


func _tell(panel: EvidencePanel, stage: Stage) -> void:
	_stage = stage
	panel.tell(_voice, INF if _skipping else _cps, LINE_PAUSE)
	if panel.is_telling():
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
	finished.emit()


func _end_token() -> void:
	if _token >= 0:
		_gate.end(_token)
	_token = -1
