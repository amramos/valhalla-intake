class_name DeskSystem
extends Node
## Connects the desk's entities to DeskCommands, the only command layer (D13). It turns clicks into
## selections and pins, redraws what the commands show (the soul, the threads, the doors, the HUD,
## the mentor's guided step) and runs the clock while a soul is at the desk. The stamp itself is
## StampFlow's. It reads nothing but DeskCommands' getters and signals.
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
var selection := PinSelection.new()
## Draws the threads; built in bind() from the panels.
var threads_board: ThreadBoard = null
## The grey thread whose knot is selected for Huginn; -1 for none.
var huginn_thread: int = -1

var _shown_encounter: Encounter = null
var _lit: Array[String] = []
## Said when the desk empties (the horn); outlives the soul it ended.
var _announcement: String = ""
var _warned: bool = false
var _phases := PhaseFlow.new()
var _telling: DeskTelling = null
var _note: DeskNote = null
var _sounds: DeskSounds = null
## The drawn thread lines, from the last rebuild.
var _lines: Array[ThreadLine] = []


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	threads_board = ThreadBoard.new(body_chart, claim_panel, witness_panel, law_panel, thread_layer)
	_telling = DeskTelling.new(claim_panel, witness_panel, gate)
	_telling.finished.connect(_on_tale_told)
	_note = DeskNote.new(caption_strip, gate)
	_note.pair_shown.connect(_light)
	_note.pair_dropped.connect(_on_pair_dropped)
	_sounds = DeskSounds.new(_sound_players(), gate)
	for panel: EvidencePanel in [claim_panel, witness_panel]:
		panel.teller().blip.connect(_on_blip)
	use_options(options)
	# The stamp's slam window and its refusal while a tale is told are the gate's (D4, D27).
	stamp_flow.gate = gate
	stamp_flow.bind(commands)
	stamp_flow.stamp_prompt.hover_started.connect(_show_hover)
	stamp_flow.stamp_prompt.hover_ended.connect(hover_label.hide_label)
	stamp_flow.pair_lit.connect(_light_held)
	stamp_flow.selection_cleared.connect(cancel_selection)
	commands.desk_changed.connect(refresh)
	commands.horn.connect(_on_horn)
	commands.clock_warning.connect(_on_clock_warning)
	body_chart.item_clicked.connect(_on_item_clicked)
	body_chart.cancel_requested.connect(cancel_selection)
	body_chart.item_hover_started.connect(_on_hover_started)
	body_chart.item_hover_ended.connect(_on_hover_ended)
	for panel: EvidencePanel in _panels():
		panel.item_clicked.connect(_on_item_clicked)
		panel.cancel_requested.connect(cancel_selection)
		panel.item_hover_started.connect(_on_hover_started)
		panel.item_hover_ended.connect(_on_hover_ended)
	for door: Door in doors:
		door.hover_started.connect(hover_label.show_for)
		door.hover_ended.connect(hover_label.hide_label)
	for sprite: ClickableSprite in [feather, mentor_portrait]:
		sprite.hover_started.connect(_show_hover)
		sprite.hover_ended.connect(hover_label.hide_label)
	soul.plate_hover_started.connect(_show_hover)
	soul.plate_hover_ended.connect(hover_label.hide_label)
	mentor_portrait.clicked.connect(_on_mentor_clicked)
	mentor_bubble.acknowledged.connect(_on_mentor_acknowledged)
	ask_huginn.pressed.connect(_on_ask_huginn)
	_phases.on_restart = restart
	phase_card.advanced.connect(_on_phase_advanced)
	phase_card.skipped.connect(_on_phase_skipped)
	ask_huginn.mouse_entered.connect(_on_ask_huginn_hovered)
	ask_huginn.mouse_exited.connect(hover_label.hide_label)
	refresh()


func _process(delta: float) -> void:
	if commands == null or commands.phase() != RunState.DESK or commands.is_paused():
		return
	if commands.awaiting_next() or is_telling():
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
	_rebuild_threads()
	DeskReadouts.show_doors(doors, commands)
	_refresh_hud()
	law_panel.set_new(DeskReadouts.new_decrees(commands))
	_phases.show(phase_card, commands)
	ledger_tray.set_line(commands.ledger_line(), _text().ledger_empty)
	stamp_flow.refresh()
	_show_mentor_step()
	_apply_highlights()


## Applies the player's options: the telling's and the quill's pace (D37, D43).
func use_options(p_options: Options) -> void:
	options = p_options
	stamp_flow.options = options
	if _telling != null:
		_telling.set_cps(options.cps())
		_note.use_options(options)
		_sounds.use_options(options)


## True while the soul's tale is being told: the clock waits (D5) and so does the stamp (D4).
func is_telling() -> bool:
	return _telling != null and _telling.is_telling()


## Shows the whole tale now, as a consumed click would (tests and tools).
func finish_tellings() -> void:
	if _telling != null:
		_telling.finish()


## The width of one line of the clerk's note, which captions are cut against.
func note_width() -> int:
	return _note.line_width()


func cancel_selection() -> void:
	selection.cancel()
	_apply_highlights()


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


## Empties the desk outright: the soul, its evidence, the caption strip, the stamp preview and door
## selection, the half-made pin, the lit pair and Huginn's thread. A restart from a soul at the desk
## needs it because refresh() redraws a soul only when it changes, and none is seated before or
## after the restart.
func _clear_desk() -> void:
	_shown_encounter = commands.current_encounter()
	_show_encounter(_shown_encounter)
	refresh()


func _show_encounter(encounter: Encounter) -> void:
	selection.cancel()
	huginn_thread = -1
	_lit.clear()
	hover_label.hide_label()
	_telling.stop()
	caption_strip.clear()
	_note.reset()
	if _announcement != "":
		caption_strip.take_over(_announcement)
		_announcement = ""
	stamp_flow.reset()
	# The new soul walks in when the slam lets it (StampFlow), from off the desk's left.
	soul.prepare_arrival()
	soul.show_soul(encounter)
	body_chart.show_body(encounter.id if encounter != null else &"")
	body_chart.show_facts(_items_in(EvidenceItem.Group.BODY))
	# D6: the sheets are headed by their speakers.
	claim_panel.show_lines(
		_items_in(EvidenceItem.Group.CLAIM), encounter.soul_name if encounter != null else ""
	)
	var witness: Array[EvidenceItem] = _items_in(EvidenceItem.Group.WITNESS)
	var witness_title: String = ""
	var witness_hover: String = ""
	var note: String = ""
	if encounter != null:
		# D52: the heading names the witness; the full authored description is its hover.
		witness_title = encounter.witness_heading_name()
		witness_hover = encounter.witness_name
		note = encounter.witness_note
	var show_witness: Callable = witness_panel.show_lines.bind(
		witness, witness_title, note, witness_hover
	)
	witness_panel.visible = not witness.is_empty() or note != ""
	law_panel.show_lines(_items_in(EvidenceItem.Group.LAW), LAW_HEADING)
	if encounter == null:
		show_witness.call()
		return
	# D7: the witness's sheet waits, headed but blank, while the claim is told.
	witness_panel.show_lines([] as Array[EvidenceItem], witness_title, "", witness_hover)
	_telling.begin(hash(encounter.soul_name), show_witness)


func _items_in(group: EvidenceItem.Group) -> Array[EvidenceItem]:
	var found: Array[EvidenceItem] = []
	for item: EvidenceItem in commands.visible_items():
		if item.group == group:
			found.append(item)
	return found


func _panels() -> Array[EvidencePanel]:
	return [claim_panel, witness_panel, law_panel]


func _rebuild_threads() -> void:
	var answers: Array[String] = []
	for index: int in range(commands.threads().size()):
		answers.append(commands.thread_answer(index))
	_lines = threads_board.rebuild(
		commands.threads(), commands.visible_items(), answers, huginn_thread
	)
	for line: ThreadLine in _lines:
		line.knot_clicked.connect(_on_knot_clicked)
		line.knot_hover_started.connect(_show_hover)
		line.knot_hover_ended.connect(hover_label.hide_label)


func _on_item_clicked(item_id: String) -> void:
	if _input_held():
		return
	_lit.clear()
	var pair: Array[String] = selection.click(item_id)
	if selection.has_selection():
		_sounds.play(&"tack")
	_apply_highlights()
	if pair.size() == 2:
		_pin(pair[0], pair[1])


func _pin(a: String, b: String) -> void:
	var before: int = commands.threads().size()
	var result: PinResult = commands.pin(a, b)
	if commands.phase() != RunState.DESK:
		# The pin's cost ended the day: the horn's announcement stands.
		_apply_highlights()
		return
	match result.kind:
		PinResult.Kind.THREAD:
			caption_strip.post_caption(_caption(result.seam))
			_sounds.play(&"seam")
			_sounds.play(&"pull")
			if commands.threads().size() > before:
				_draw_in(before)
		PinResult.Kind.ALREADY:
			_lit = [a, b] as Array[String]
			caption_strip.take_over_caption(_caption(result.seam))
		PinResult.Kind.NO_SEAM:
			var text: String = _text().no_seam_line
			if result.seconds_lost > 0.0:
				text = _text().no_seam_timed_format % roundi(result.seconds_lost)
			caption_strip.take_over_caption(Caption.make(text, CaptionStrip.Priority.THREAD))
			_sounds.play(&"tick")
	_apply_highlights()


## The new thread is drawn taut from its first end (D12); the others stay as they are.
func _draw_in(thread_index: int) -> void:
	for line: ThreadLine in _lines:
		if is_instance_valid(line) and line.thread_index == thread_index:
			gate.watch_tween(line.draw_in())


## A thread's caption on the note, quoting the pair it lights while it shows (D6, D28).
func _caption(seam: Seam) -> Caption:
	return _note.thread(seam, commands.current_encounter(), commands.visible_items())


func _text() -> DeskText:
	return commands.slice_rules().text


## Lights a pair (a held citation, the feather); the mentor's highlight shows when nothing is lit.
func _light(pair: Array[String]) -> void:
	_lit = pair
	_apply_highlights()


func _apply_highlights() -> void:
	var chosen: String = selection.selected_id
	var lit: Array[String] = _lit
	var step: MentorStep = _guided_step()
	if lit.is_empty() and step != null:
		lit = step.highlight
	body_chart.set_selected(chosen)
	body_chart.set_lit(lit)
	for panel: EvidencePanel in _panels():
		panel.set_selected(chosen)
		panel.set_lit(lit)


func _on_hover_started(_item_id: String, text: String, area: Rect2) -> void:
	_show_hover(text, area)


func _on_hover_ended(_item_id: String) -> void:
	hover_label.hide_label()


func _show_hover(text: String, area: Rect2) -> void:
	hover_label.show_for(text, area)


## The mentor's guided step, once the tale is told (D5); null before.
func _guided_step() -> MentorStep:
	return null if is_telling() else commands.mentor_step()


func _show_mentor_step() -> void:
	var step: MentorStep = _guided_step()
	if step == null or commands.phase() != RunState.DESK:
		mentor_bubble.hide_step()
	else:
		mentor_bubble.show_step(step.text, step.until == MentorStep.Until.READ)
	for door: Door in doors:
		door.pointed = step != null and step.door == door.realm


func _on_mentor_clicked() -> void:
	# A deliberate click on her shows her last comment again (D33), but only at the desk: never
	# over the horn's announcement or under a card.
	if commands.phase() != RunState.DESK:
		return
	if stamp_flow.mentor_line() != "":
		caption_strip.take_over_caption(_note.mentor(stamp_flow.mentor_line()))


## The bubble's "Next" finishes a READ step, but never under a pending stamp (D9, D48).
func _on_mentor_acknowledged() -> void:
	if _input_held():
		return
	commands.mentor_ack()


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


## A click on a knot or bead shows its thread's caption again (D33); a grey knot also selects
## the thread for Huginn, and shows his answer once given.
func _on_knot_clicked(thread_index: int) -> void:
	if _input_held():
		return
	var threads: Array[Seam] = commands.threads()
	if thread_index < 0 or thread_index >= threads.size():
		return
	var answer: String = commands.thread_answer(thread_index)
	if answer != "":
		caption_strip.take_over_caption(_note.raven(answer, threads[thread_index]))
	else:
		caption_strip.take_over_caption(_caption(threads[thread_index]))
	if threads[thread_index].kind == Seam.Kind.GREY:
		huginn_thread = -1 if huginn_thread == thread_index else thread_index
		refresh()


func _on_ask_huginn() -> void:
	if _input_held() or huginn_thread < 0:
		return
	var answer: String = HuginnAsk.ask(commands, huginn_thread)
	# An answer whose cost ended the day is not queued over the horn's announcement.
	if answer != "" and commands.phase() == RunState.DESK:
		caption_strip.post_caption(_note.raven(answer, commands.threads()[huginn_thread]))


func _on_ask_huginn_hovered() -> void:
	_show_hover(HuginnAsk.hover_text(commands, huginn_thread), ask_huginn.get_global_rect())


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
	}


## A voice blip of the tale (D41), at the pitch of the soul's voice.
func _on_blip(pitch_scale: float) -> void:
	_sounds.play(&"blip", pitch_scale)


## The tale is told: the mentor's guided step and its highlight may show now (D5).
func _on_tale_told() -> void:
	_show_mentor_step()
	_apply_highlights()


## A held citation (or the feather) lights its pair; no caption may darken it (D28, D48).
func _light_held(pair: Array[String]) -> void:
	_note.release_pair()
	_light(pair)


## The caption that quoted `pair` gave way to one that quotes nothing: its pair goes dark, but a
## pair lit by something else since (a held citation, a click) stays (D28).
func _on_pair_dropped(pair: Array[String]) -> void:
	if _lit == pair:
		_light([] as Array[String])


func _refresh_hud() -> void:
	var readout: HudReadout = DeskReadouts.hud(commands)
	readout.warning = _warned and commands.day_rules().is_timed()
	hud.refresh(readout)
	ask_huginn.visible = readout.huginn_on and commands.phase() == RunState.DESK
	ask_huginn.disabled = huginn_thread < 0
	huginn.visible = readout.huginn_on
