class_name DeskSystem
extends Node
## Connects the desk's entities to DeskCommands, the only command layer (D13). It seats each soul,
## redraws what the commands show (the soul, the threads, the doors, the HUD, the mentor's guided
## step) and runs the clock while a soul is at the desk. Its helpers own the rest: DeskPins the pin
## gesture and its threads, DeskHighlights what is lit, DeskHuginn the knots and Huginn, DeskMentor
## her step and comments; the stamp itself is StampFlow's. It reads nothing but DeskCommands'
## getters and signals.
##
## Each soul's tale is told first (DeskTelling, D4, D7): the clock and the mentor's guided step wait
## for it (D5). Captions go to the clerk's note as Captions with their speaker mark and quoted pair
## (D10, D28); a written caption holds the presentation gate until its quill is done (D43).

const HORN_TEXT := "The horn. The day is over."
const LAW_HEADING := "Odin's Law"

@export var body_chart: BodyChart
@export var claim_panel: EvidencePanel
@export var witness_panel: EvidencePanel
@export var law_panel: EvidencePanel
@export var doors: Array[Door] = []
@export var thread_layer: Control
@export var caption_strip: CaptionStrip
@export var hover_label: HoverLabel
@export var soul: WaitingSoul
@export var hud: Hud
@export var ask_huginn: Button
@export var huginn: Control
@export var phase_card: PhaseCard
@export var feather: ClickableSprite
@export var mentor_portrait: ClickableSprite
@export var mentor_bubble: MentorBubble
@export var stamp_flow: StampFlow
@export var seam_player: AudioStreamPlayer
@export var ledger_tray: LedgerTray
@export var gate: PresentationGate
@export var blip_player: AudioStreamPlayer
@export var tack_player: AudioStreamPlayer
@export var pull_player: AudioStreamPlayer
@export var tick_player: AudioStreamPlayer
@export var horn_player: AudioStreamPlayer

var commands: DeskCommands = null
## The player's options (D37); the desk hands them in before bind().
var options: Options = Options.new()
## Draws the threads; built in bind() from the panels.
var threads_board: ThreadBoard = null
## The half-made pin (DeskHighlights'); null before bind().
var selection: PinSelection:
	get:
		return _highlights.selection if _highlights != null else null
## The grey thread whose knot is selected for Huginn (DeskHuginn's); -1 for none.
var huginn_thread: int:
	get:
		return _huginn.thread if _huginn != null else -1

var _shown_encounter: Encounter = null
## The lit pair (DeskHighlights'), read by tests.
var _lit: Array[String]:
	get:
		return _highlights.lit if _highlights != null else ([] as Array[String])
## Said when the desk empties (the horn); outlives the soul it ended.
var _announcement: String = ""
var _warned: bool = false
## The seated soul's evidence waits for the slam to release; the stamped soul's stays meanwhile.
var _evidence_waits: bool = false
var _phases := PhaseFlow.new()
var _telling: DeskTelling = null
var _note: DeskNote = null
var _sounds: DeskSounds = null
var _highlights: DeskHighlights = null
var _huginn: DeskHuginn = null
var _pins: DeskPins = null
var _mentor: DeskMentor = null


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	threads_board = ThreadBoard.new(body_chart, claim_panel, witness_panel, law_panel, thread_layer)
	# A slack thread never falls onto the note either (D36).
	threads_board.note = caption_strip
	_telling = DeskTelling.new(claim_panel, witness_panel, gate)
	# The soul speaks while its tale is told: its plate lights and it bobs on each blip (D4, D17).
	_telling.soul = soul
	_telling.finished.connect(_on_tale_told)
	_telling.silenced.connect(_on_tale_silenced)
	_note = DeskNote.new(caption_strip, gate)
	_mentor = DeskMentor.new(
		commands, mentor_bubble, doors, caption_strip, _note, stamp_flow, _step_waits, _input_held
	)
	_highlights = DeskHighlights.new(commands, body_chart, _panels(), _mentor.guided_step)
	_note.pair_shown.connect(_highlights.light)
	_note.pair_dropped.connect(_highlights.drop)
	_huginn = DeskHuginn.new(
		commands, _note, caption_strip, ask_huginn, huginn, hover_label, _input_held
	)
	_huginn.thread_selected.connect(refresh)
	_sounds = DeskSounds.new(_sound_players(), gate)
	_pins = DeskPins.new(
		commands,
		threads_board,
		_highlights,
		_huginn,
		caption_strip,
		_note,
		_sounds,
		hud,
		gate,
		_input_held
	)
	for panel: EvidencePanel in [claim_panel, witness_panel]:
		panel.teller().blip.connect(_on_blip)
	# The note's hold and the doors' flares keep their own clocks; the gate's pause stops them.
	gate.pause_changed.connect(caption_strip.set_paused)
	for door: Door in doors:
		gate.pause_changed.connect(door.set_paused)
	gate.pause_changed.connect(hud.set_paused)
	use_options(options)
	# The stamp's slam window and its refusal while a tale is told are the gate's (D4, D27).
	stamp_flow.gate = gate
	stamp_flow.bind(commands)
	stamp_flow.stamp_prompt.hover_started.connect(hover_label.show_for)
	stamp_flow.stamp_prompt.hover_ended.connect(hover_label.hide_label)
	stamp_flow.pair_lit.connect(_light_held)
	stamp_flow.selection_cleared.connect(cancel_selection)
	stamp_flow.slam_released.connect(_on_slam_released)
	commands.desk_changed.connect(refresh)
	commands.horn.connect(_on_horn)
	commands.clock_warning.connect(_on_clock_warning)
	body_chart.item_clicked.connect(_pins.click)
	body_chart.cancel_requested.connect(cancel_selection)
	body_chart.item_hover_started.connect(_on_hover_started)
	body_chart.item_hover_ended.connect(_on_hover_ended)
	for panel: EvidencePanel in _panels():
		panel.item_clicked.connect(_pins.click)
		panel.cancel_requested.connect(cancel_selection)
		panel.item_hover_started.connect(_on_hover_started)
		panel.item_hover_ended.connect(_on_hover_ended)
	for door: Door in doors:
		door.hover_started.connect(hover_label.show_for)
		door.hover_ended.connect(hover_label.hide_label)
	for sprite: ClickableSprite in [feather, mentor_portrait]:
		sprite.hover_started.connect(hover_label.show_for)
		sprite.hover_ended.connect(hover_label.hide_label)
	soul.plate_hover_started.connect(hover_label.show_for)
	soul.plate_hover_ended.connect(hover_label.hide_label)
	mentor_portrait.clicked.connect(_mentor.clicked)
	mentor_bubble.acknowledged.connect(_mentor.acknowledged)
	ask_huginn.pressed.connect(_huginn.ask)
	_phases.on_restart = restart
	phase_card.advanced.connect(_on_phase_advanced)
	phase_card.skipped.connect(_on_phase_skipped)
	ask_huginn.mouse_entered.connect(_on_ask_huginn_hovered)
	ask_huginn.mouse_exited.connect(hover_label.hide_label)
	refresh()


func _process(delta: float) -> void:
	if commands == null or commands.phase() != RunState.DESK or commands.is_paused():
		return
	# The clock waits for the tale (D5), and through a slam for the next soul's evidence to come in.
	if commands.awaiting_next() or _step_waits():
		return
	commands.advance_time(delta)
	_refresh_hud()


## Redraws everything the commands show.
func refresh() -> void:
	if commands.phase() == RunState.DAWN:
		_warned = false
	var encounter: Encounter = commands.current_encounter()
	if encounter != _shown_encounter:
		_shown_encounter = encounter
		_show_encounter(encounter)
	# While the stamped soul's evidence waits out the slam, its threads and lit pair stay drawn.
	if not _evidence_waits:
		_pins.rebuild()
	# A pending stamp's new tide figure waits for the slam's impact (D38).
	DeskReadouts.show_doors(doors, commands, stamp_flow.displayed_tide())
	_refresh_hud()
	law_panel.set_new(DeskReadouts.new_decrees(commands))
	_phases.show(phase_card, commands)
	ledger_tray.set_line(commands.ledger_line(), _text().ledger_empty)
	stamp_flow.refresh()
	# While evidence waits there is no guided step: her bubble and its pair clear (_step_waits).
	_mentor.show_step()
	_highlights.apply()


## Applies the player's options: the telling's and the quill's pace (D37, D43).
func use_options(p_options: Options) -> void:
	options = p_options
	stamp_flow.options = options
	soul.reduce_motion = options.reduce_motion
	hud.reduce_motion = options.reduce_motion
	if _telling != null:
		_pins.options = options
		_telling.set_cps(options.cps())
		_note.use_options(options)
		_sounds.use_options(options)


## True while the soul's tale is being told: the clock waits (D5) and so does the stamp (D4).
func is_telling() -> bool:
	return _telling != null and _telling.is_telling()


## The mentor's guided step waits for the tale (D5), and for the next soul's evidence to reach the
## desk after a slam: its pair names lines the stamped soul's sheets still show.
func _step_waits() -> bool:
	return is_telling() or _evidence_waits


## Shows the whole tale now, as a consumed click would (tests and tools).
func finish_tellings() -> void:
	if _telling != null:
		_telling.finish()


## The width of one line of the clerk's note, which captions are cut against.
func note_width() -> int:
	return _note.line_width()


func cancel_selection() -> void:
	_highlights.cancel()


## A restarted run (D31): every trace of the old one leaves the desk.
func restart() -> void:
	_phases.reset()
	_announcement = ""
	_warned = false
	# Every presentation of the old run ends unfinished (D27).
	_telling.stop()
	gate.cancel_all()
	_note.forget()
	commands.restart_run()
	# Pause's Restart and Play again both land here: the last run's comments stay with it.
	stamp_flow.forget_run()
	_clear_desk()
	hud.clear_gutter()


## Empties the desk outright: the soul, its evidence, the caption strip, the stamp preview and door
## selection, the half-made pin, the lit pair and Huginn's thread. A restart from a soul at the desk
## needs it because refresh() redraws a soul only when it changes, and none is seated before or
## after the restart.
func _clear_desk() -> void:
	_shown_encounter = commands.current_encounter()
	_show_encounter(_shown_encounter)
	refresh()


## Seats a soul: its figure and writ now, its evidence (sheets, slab, Law, the note) now too unless
## a slam is under way. Then the stamped soul's evidence stays on the desk until the slam releases
## (D14), and the new sheets slide in with the walk-in (D15).
func _show_encounter(encounter: Encounter) -> void:
	hover_label.hide_label()
	_telling.stop()
	stamp_flow.reset()
	# The new soul walks in when the slam lets it (StampFlow), from off the desk's left.
	soul.prepare_arrival()
	soul.show_soul(encounter)
	_evidence_waits = stamp_flow.is_slamming()
	if not _evidence_waits:
		_show_evidence(encounter)


## The seated soul's evidence: the note cleared (her carried comment or the horn's announcement on
## it), the slab, the Law and the sheets, whose tale is told.
func _show_evidence(encounter: Encounter) -> void:
	_evidence_waits = false
	_highlights.forget()
	_huginn.forget()
	caption_strip.clear()
	_note.reset()
	if _announcement != "":
		caption_strip.take_over(_announcement)
		_announcement = ""
	stamp_flow.reset_note()
	body_chart.show_body(encounter.id if encounter != null else &"")
	body_chart.show_facts(_items_in(EvidenceItem.Group.BODY))
	law_panel.show_lines(_items_in(EvidenceItem.Group.LAW), LAW_HEADING)
	# The sheets are headed by their speakers and the tale is told (D6, D7).
	_telling.show_sheets(
		encounter, _items_in(EvidenceItem.Group.CLAIM), _items_in(EvidenceItem.Group.WITNESS)
	)


## The slam released: the waiting evidence comes in, its sheets sliding up with the walk-in.
func _on_slam_released() -> void:
	if not _evidence_waits:
		return
	_show_evidence(_shown_encounter)
	if not options.reduce_motion and _shown_encounter != null:
		_telling.slide_in()
	refresh()


func _items_in(group: EvidenceItem.Group) -> Array[EvidenceItem]:
	var found: Array[EvidenceItem] = []
	for item: EvidenceItem in commands.visible_items():
		if item.group == group:
			found.append(item)
	return found


func _panels() -> Array[EvidencePanel]:
	return [claim_panel, witness_panel, law_panel]


func _text() -> DeskText:
	return commands.slice_rules().text


func _on_hover_started(_item_id: String, text: String, area: Rect2) -> void:
	hover_label.show_for(text, area)


func _on_hover_ended(_item_id: String) -> void:
	hover_label.hide_label()


func _on_horn() -> void:
	# The horn empties the desk; the refresh that follows shows this after clearing the strip.
	_announcement = HORN_TEXT
	caption_strip.take_over(HORN_TEXT)
	_sounds.play(&"horn")


## A dusk card turned without a desk change (no refresh follows), so the card is drawn here.
func _on_phase_advanced() -> void:
	_phases.advance(commands)
	_phases.show(phase_card, commands)


func _on_phase_skipped() -> void:
	_phases.skip(commands)
	_phases.show(phase_card, commands)


func _on_clock_warning() -> void:
	_warned = true
	_refresh_hud()


func _on_ask_huginn_hovered() -> void:
	_huginn.hovered()


## No pin, knot or Huginn answer while a stamped soul waits (D48) or the stamp preview is open
## (D9): nothing may change, or charge the clock, under a pending stamp.
func _input_held() -> bool:
	return commands.awaiting_next() or stamp_flow.stamp_prompt.is_asking()


func _sound_players() -> Dictionary[StringName, AudioStreamPlayer]:
	return {
		&"seam": seam_player,
		&"thud": stamp_flow.thud_player,
		&"blip": blip_player,
		&"tack": tack_player,
		&"pull": pull_player,
		&"tick": tick_player,
		&"horn": horn_player,
		&"caw": stamp_flow.caw_player,
	}


## A voice blip of the tale (D41), at the pitch of the soul's voice.
func _on_blip(pitch_scale: float) -> void:
	_sounds.play(&"blip", pitch_scale)


## The tale is told: the mentor's guided step and its highlight may show now (D5).
func _on_tale_told() -> void:
	_mentor.show_step()
	_highlights.apply()


## A held citation (or the feather) lights its pair; no caption may darken it (D28, D48).
func _light_held(pair: Array[String]) -> void:
	_highlights.hold(pair)
	_note.release_pair()
	_highlights.light(pair)


## A tale cut short stops its voice at once, mid-blip (D27).
func _on_tale_silenced() -> void:
	_sounds.stop(&"blip")


func _refresh_hud() -> void:
	var readout: HudReadout = DeskReadouts.hud(commands)
	readout.warning = _warned and commands.day_rules().is_timed()
	hud.refresh(readout)
	_huginn.show(readout.huginn_on)
