class_name DeskSystem
extends Node
## Connects the desk's entities to DeskCommands, the only command layer (D13). It turns clicks into
## selections, pins and stamps, redraws what the commands show, and runs the clock while a soul is
## at the desk. It reads nothing but DeskCommands' getters and signals.
##
## After a stamp that draws a citation (or a day-1 warning), the stamped soul stays on the desk with
## the cited pair lit and the black feather showing; "Next soul" seats the next one (D48).

const NO_SEAM_TEXT := "No seam."
const NO_SEAM_COST_FORMAT := "No seam. -%d s"
const HORN_TEXT := "The horn. The day is over."

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
@export var stamp_prompt: StampPrompt
@export var ask_huginn: Button
@export var phase_card: PhaseCard
@export var feather: BlackFeather
@export var next_soul_button: Button

var commands: DeskCommands = null
var selection := PinSelection.new()
## Draws the threads; built in bind() from the panels.
var threads_board: ThreadBoard = null
## The grey thread whose knot is selected for Huginn; -1 for none.
var huginn_thread: int = -1

var _shown_encounter: Encounter = null
var _lit: Array[String] = []
## The last stamp's citation (or day-1 warning) and its pair, while the soul waits (D48).
var _citation: String = ""
var _cited_pair: Array[String] = []
## Said when the desk empties (the horn); outlives the soul it ended.
var _announcement: String = ""


func bind(p_commands: DeskCommands) -> void:
	commands = p_commands
	threads_board = ThreadBoard.new(body_chart, claim_panel, witness_panel, law_panel, thread_layer)
	commands.desk_changed.connect(refresh)
	commands.stamped.connect(_on_stamped)
	commands.horn.connect(_on_horn)
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
		door.door_clicked.connect(_on_door_clicked)
		door.hover_started.connect(func(text: String, at: Rect2) -> void: _show_hover(text, at))
		door.hover_ended.connect(hover_label.hide_label)
	soul.plate_hover_started.connect(func(text: String, at: Rect2) -> void: _show_hover(text, at))
	soul.plate_hover_ended.connect(hover_label.hide_label)
	stamp_prompt.confirmed.connect(_on_stamp_confirmed)
	stamp_prompt.cancelled.connect(_clear_door_selection)
	ask_huginn.pressed.connect(_on_ask_huginn)
	phase_card.advanced.connect(func() -> void: PhaseFlow.advance(commands))
	feather.clicked.connect(_on_feather_clicked)
	feather.hover_started.connect(func(text: String, at: Rect2) -> void: _show_hover(text, at))
	feather.hover_ended.connect(hover_label.hide_label)
	next_soul_button.pressed.connect(func() -> void: commands.next_soul())
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
	var encounter: Encounter = commands.current_encounter()
	if encounter != _shown_encounter:
		_shown_encounter = encounter
		_show_encounter(encounter)
	_rebuild_threads()
	_refresh_doors()
	_refresh_hud()
	PhaseFlow.show_card(phase_card, commands)
	var waiting: bool = commands.phase() == RunState.DESK and commands.awaiting_next()
	next_soul_button.visible = waiting
	feather.visible = waiting and _citation != ""
	_apply_highlights()


func cancel_selection() -> void:
	selection.cancel()
	_apply_highlights()


func _show_encounter(encounter: Encounter) -> void:
	selection.cancel()
	huginn_thread = -1
	_lit.clear()
	stamp_prompt.withdraw()
	hover_label.hide_label()
	caption_strip.clear()
	if _announcement != "":
		caption_strip.take_over(_announcement)
		_announcement = ""
	_citation = ""
	_cited_pair.clear()
	soul.show_soul(encounter)
	var witness: Array[EvidenceItem] = _items_in(EvidenceItem.Group.WITNESS)
	body_chart.show_facts(_items_in(EvidenceItem.Group.BODY))
	claim_panel.show_lines(
		_items_in(EvidenceItem.Group.CLAIM), "CLAIM" if encounter != null else ""
	)
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
	var answered: Array[bool] = []
	for index: int in range(commands.threads().size()):
		answered.append(commands.thread_answer(index) != "")
	var lines: Array[ThreadLine] = threads_board.rebuild(
		commands.threads(), commands.visible_items(), answered, huginn_thread
	)
	for line: ThreadLine in lines:
		line.knot_clicked.connect(_on_knot_clicked)
		line.knot_hover_started.connect(
			func(text: String, at: Rect2) -> void: _show_hover(text, at)
		)
		line.knot_hover_ended.connect(hover_label.hide_label)


func _on_item_clicked(item_id: String) -> void:
	if _input_held():
		return
	_lit.clear()
	var pair: Array[String] = selection.click(item_id)
	_apply_highlights()
	if pair.size() == 2:
		_pin(pair[0], pair[1])


func _pin(a: String, b: String) -> void:
	var result: PinResult = commands.pin(a, b)
	if commands.phase() != RunState.DESK:
		# The pin's cost ended the day: the horn's announcement stands.
		_apply_highlights()
		return
	match result.kind:
		PinResult.Kind.THREAD:
			caption_strip.post(result.seam.caption, CaptionStrip.Priority.THREAD)
		PinResult.Kind.ALREADY:
			_lit = [a, b] as Array[String]
			caption_strip.take_over(result.seam.caption)
		PinResult.Kind.NO_SEAM:
			var text: String = NO_SEAM_TEXT
			if result.seconds_lost > 0.0:
				text = NO_SEAM_COST_FORMAT % roundi(result.seconds_lost)
			caption_strip.take_over(text)
	_apply_highlights()


func _apply_highlights() -> void:
	var chosen: String = selection.selected_id
	body_chart.set_selected(chosen)
	body_chart.set_lit(_lit)
	for panel: EvidencePanel in _panels():
		panel.set_selected(chosen)
		panel.set_lit(_lit)


func _on_hover_started(_item_id: String, text: String, area: Rect2) -> void:
	_show_hover(text, area)


func _on_hover_ended(_item_id: String) -> void:
	hover_label.hide_label()


func _show_hover(text: String, area: Rect2) -> void:
	hover_label.show_for(text, area)


func _on_door_clicked(realm: StringName) -> void:
	var encounter: Encounter = commands.current_encounter()
	if encounter == null or commands.awaiting_next():
		return
	if not commands.day_rules().doors_open.has(realm):
		return
	for door: Door in doors:
		door.selected = door.realm == realm
	stamp_prompt.ask(encounter.soul_name, realm)


func _on_stamp_confirmed(realm: StringName) -> void:
	_clear_door_selection()
	commands.stamp(realm)


func _clear_door_selection() -> void:
	for door: Door in doors:
		door.selected = false


func _on_stamped(result: StampResult) -> void:
	if not (result.citation or result.warning):
		return
	# The held soul shows its cited pair lit, never a half-made pin.
	selection.cancel()
	_citation = result.citation_text
	_cited_pair = [result.citation_a, result.citation_b] as Array[String]
	_lit = _cited_pair.duplicate()
	caption_strip.post(_citation, CaptionStrip.Priority.CITATION)


## A deliberate click on the feather shows its citation again and lights the pair (D33).
func _on_feather_clicked() -> void:
	caption_strip.take_over(_citation)
	_lit = _cited_pair.duplicate()
	_apply_highlights()


func _on_horn() -> void:
	# The horn empties the desk; the refresh that follows shows this after clearing the strip.
	_announcement = HORN_TEXT
	caption_strip.take_over(HORN_TEXT)


func _on_knot_clicked(thread_index: int) -> void:
	if _input_held():
		return
	huginn_thread = -1 if huginn_thread == thread_index else thread_index
	var answer: String = commands.thread_answer(thread_index)
	if answer != "":
		caption_strip.take_over(answer)
	refresh()


func _on_ask_huginn() -> void:
	if _input_held():
		return
	if huginn_thread < 0:
		caption_strip.take_over("Pick a grey thread's knot first.")
		return
	var answer: String = commands.ask_huginn(huginn_thread)
	# An answer whose cost ended the day is not queued over the horn's announcement.
	if answer != "" and commands.phase() == RunState.DESK:
		caption_strip.post(answer, CaptionStrip.Priority.HUGINN)


## No pin, knot or Huginn answer while a stamped soul waits (D48) or the stamp preview is open
## (D9): nothing may change, or charge the clock, under a pending stamp.
func _input_held() -> bool:
	return commands.awaiting_next() or stamp_prompt.visible


func _refresh_doors() -> void:
	var rules: DayRules = commands.day_rules()
	var marks: bool = commands.shows_new_marks()
	for door: Door in doors:
		var is_new: bool = marks and rules.new_doors.has(door.realm)
		door.set_state(rules.doors_open.has(door.realm), commands.door_open_day(door.realm), is_new)


func _refresh_hud() -> void:
	var huginn_on: bool = commands.day_rules().huginn_answers > 0
	hud.refresh(
		commands.time_left(),
		commands.feathers(),
		commands.quota_progress(),
		huginn_on,
		commands.huginn_left(),
		commands.promise_state() == RunState.PROMISE_OPEN
	)
	ask_huginn.visible = huginn_on and commands.phase() == RunState.DESK
