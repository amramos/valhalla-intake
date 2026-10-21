class_name DeskSystem
extends Node
## Connects the desk's entities to DeskCommands, the only command layer (D13). It turns clicks into
## selections and pins, redraws what the commands show (the soul, the threads, the doors, the HUD,
## the mentor's guided step) and runs the clock while a soul is at the desk. The stamp itself is
## StampFlow's. It reads nothing but DeskCommands' getters and signals.

const NO_SEAM_TEXT := "No seam: those two agree."
const NO_SEAM_COST_FORMAT := "No seam: those two agree. -%d s"
const HORN_TEXT := "The horn. The day is over."
const PICK_KNOT_TEXT := "Pick a grey thread's knot first."

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

var commands: DeskCommands = null
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


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	threads_board = ThreadBoard.new(body_chart, claim_panel, witness_panel, law_panel, thread_layer)
	stamp_flow.bind(commands)
	stamp_flow.pair_lit.connect(_light)
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
	mentor_bubble.acknowledged.connect(func() -> void: commands.mentor_ack())
	ask_huginn.pressed.connect(_on_ask_huginn)
	phase_card.advanced.connect(func() -> void: PhaseFlow.advance(commands))
	refresh()


func _process(delta: float) -> void:
	if commands == null or commands.phase() != RunState.DESK or commands.is_paused():
		return
	if commands.awaiting_next():
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
	PhaseFlow.show_card(phase_card, commands)
	stamp_flow.refresh()
	_show_mentor_step()
	_apply_highlights()


func cancel_selection() -> void:
	selection.cancel()
	_apply_highlights()


func _show_encounter(encounter: Encounter) -> void:
	selection.cancel()
	huginn_thread = -1
	_lit.clear()
	hover_label.hide_label()
	caption_strip.clear()
	if _announcement != "":
		caption_strip.take_over(_announcement)
		_announcement = ""
	stamp_flow.reset()
	soul.show_soul(encounter)
	body_chart.show_body(encounter.id if encounter != null else &"")
	body_chart.show_facts(_items_in(EvidenceItem.Group.BODY))
	claim_panel.show_lines(
		_items_in(EvidenceItem.Group.CLAIM), "CLAIM" if encounter != null else ""
	)
	var witness: Array[EvidenceItem] = _items_in(EvidenceItem.Group.WITNESS)
	var witness_title: String = ""
	var note: String = ""
	if encounter != null:
		witness_title = "WITNESS " + encounter.witness_name if encounter.witness_name != "" else ""
		note = encounter.witness_note
	witness_panel.show_lines(witness, witness_title, note)
	witness_panel.visible = not witness.is_empty() or note != ""
	law_panel.show_lines(_items_in(EvidenceItem.Group.LAW), "LAW")


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
	var lines: Array[ThreadLine] = threads_board.rebuild(
		commands.threads(), commands.visible_items(), answers, huginn_thread
	)
	for line: ThreadLine in lines:
		line.knot_clicked.connect(_on_knot_clicked)
		line.knot_hover_started.connect(_show_hover)
		line.knot_hover_ended.connect(hover_label.hide_label)


func _on_item_clicked(item_id: String) -> void:
	if commands.awaiting_next():
		return
	_lit.clear()
	var pair: Array[String] = selection.click(item_id)
	_apply_highlights()
	if pair.size() == 2:
		_pin(pair[0], pair[1])


func _pin(a: String, b: String) -> void:
	var result: PinResult = commands.pin(a, b)
	match result.kind:
		PinResult.Kind.THREAD:
			caption_strip.post(result.seam.caption, CaptionStrip.Priority.THREAD)
			if seam_player != null and seam_player.stream != null and seam_player.is_inside_tree():
				seam_player.play()
		PinResult.Kind.ALREADY:
			_lit = [a, b] as Array[String]
			caption_strip.take_over(result.seam.caption)
		PinResult.Kind.NO_SEAM:
			var text: String = NO_SEAM_TEXT
			if result.seconds_lost > 0.0:
				text = NO_SEAM_COST_FORMAT % roundi(result.seconds_lost)
			caption_strip.take_over(text)
	_apply_highlights()


## Lights a pair (a held citation, the feather); the mentor's highlight shows when nothing is lit.
func _light(pair: Array[String]) -> void:
	_lit = pair
	_apply_highlights()


func _apply_highlights() -> void:
	var chosen: String = selection.selected_id
	var lit: Array[String] = _lit
	var step: MentorStep = commands.mentor_step()
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


func _show_mentor_step() -> void:
	var step: MentorStep = commands.mentor_step()
	if step == null or commands.phase() != RunState.DESK:
		mentor_bubble.hide_step()
	else:
		mentor_bubble.show_step(step.text, step.until == MentorStep.Until.READ)
	for door: Door in doors:
		door.pointed = step != null and step.door == door.realm


func _on_mentor_clicked() -> void:
	# A deliberate click on her shows her last comment again (D33).
	if stamp_flow.mentor_line() != "":
		caption_strip.take_over(stamp_flow.mentor_line())


func _on_horn() -> void:
	# The horn empties the desk; the refresh that follows shows this after clearing the strip.
	_announcement = HORN_TEXT
	caption_strip.take_over(HORN_TEXT)


func _on_clock_warning() -> void:
	_warned = true
	_refresh_hud()


## A click on a knot or bead shows its thread's caption again (D33); a grey knot also selects
## the thread for Huginn, and shows his answer once given.
func _on_knot_clicked(thread_index: int) -> void:
	if commands.awaiting_next():
		return
	var threads: Array[Seam] = commands.threads()
	if thread_index < 0 or thread_index >= threads.size():
		return
	var answer: String = commands.thread_answer(thread_index)
	caption_strip.take_over(answer if answer != "" else threads[thread_index].caption)
	if threads[thread_index].kind == Seam.Kind.GREY:
		huginn_thread = -1 if huginn_thread == thread_index else thread_index
		refresh()


func _on_ask_huginn() -> void:
	if commands.awaiting_next():
		return
	if huginn_thread < 0:
		caption_strip.take_over(PICK_KNOT_TEXT)
		return
	if commands.thread_answer(huginn_thread) == "" and commands.huginn_left() <= 0:
		# Today's answers are spent; one more costs feathers (D30).
		if not commands.buy_huginn_answer():
			return
	var answer: String = commands.ask_huginn(huginn_thread)
	if answer != "":
		caption_strip.post(answer, CaptionStrip.Priority.HUGINN)


func _refresh_hud() -> void:
	var readout: HudReadout = DeskReadouts.hud(commands)
	readout.warning = _warned and commands.day_rules().is_timed()
	hud.refresh(readout)
	ask_huginn.visible = readout.huginn_on and commands.phase() == RunState.DESK
	huginn.visible = readout.huginn_on
