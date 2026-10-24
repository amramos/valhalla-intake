class_name PauseOverlay
extends Control
## The pause (D42): the whole desk dims and a parchment hangs from two pin heads, "PAUSED" in the
## carved capitals over a column of tags: Resume, Options, Restart the run and Quit. Restart and
## Quit each ask once more: the question is written under the column and its Yes / No tags sit at
## least CONFIRM_GAP below the tag that asked, guarded and armed anew, while the four openers are
## disabled; so the second press of a double-click on an opener can never land on Yes. Options
## opens the options panel over the dim (the parchment steps aside); Esc closes the panel first,
## then resumes. While it is open nothing under it takes a click. Its words come from DeskText;
## `configure` sets them.

signal resumed
signal restart_confirmed
signal quit_confirmed
## An option changed on the panel; the desk applies it.
signal options_changed(options: Options)

const SCREEN := Vector2(480, 270)
const OPTIONS_SCENE := preload("res://entities/options_panel/options_panel.tscn")
## The parchment's width and top, and where its column of tags starts inside it.
const SHEET_WIDTH := 170
const SHEET_TOP := 36
const FIRST_TAG := 26
const TAG_PITCH := 17
const BOTTOM_PAD := 8
## The question's first row below the column, and the confirm row's least distance below the tag
## that asked (D42).
const QUESTION_GAP := 7
const CONFIRM_GAP := 40
const CONFIRM_TAG_GAP := 8
const SIDE_PAD := 10
## A label's first ink row sits this far below its top (ADR-0008); a tag's text sits 2 px lower.
const LABEL_RISE := 2
## m5x7's line pitch (ADR-0008).
const LINE_PITCH := 10
const THEME_TYPE := &"DeskPalette"

var _sheet: HangingSheet = null
var _question: Label = null
var _openers: Array[TagButton] = []
var _resume: TagButton = null
var _options: TagButton = null
var _restart: TagButton = null
var _quit: TagButton = null
var _yes: TagButton = null
var _no: TagButton = null
var _panel: OptionsPanel = null
var _sheet_rect := Rect2()
## &"restart" or &"quit" while a confirmation is asked; &"" otherwise.
var _asking: StringName = &""
var _text: DeskText = DeskText.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = SCREEN
	_sheet = HangingSheet.new()
	_sheet.name = "Sheet"
	_sheet.seed = 42
	add_child(_sheet)
	_question = Label.new()
	_question.name = "Question"
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD
	_question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_question.add_theme_color_override(&"font_color", get_theme_color(&"ink", THEME_TYPE))
	add_child(_question)
	_resume = _tag("Resume", func() -> void: close())
	_options = _tag("Options", _show_options)
	_restart = _tag("Restart", func() -> void: _ask(&"restart"))
	_quit = _tag("Quit", func() -> void: _ask(&"quit"))
	_openers.assign([_resume, _options, _restart, _quit])
	_yes = _tag("Yes", _on_yes)
	_no = _tag("No", func() -> void: _ask(&""))
	_panel = OPTIONS_SCENE.instantiate() as OptionsPanel
	_panel.dim = false
	add_child(_panel)
	_panel.changed.connect(_on_options_changed)
	_panel.closed.connect(_on_options_closed)
	visible = false
	_layout()


func configure(text: DeskText) -> void:
	_text = text
	_layout()


## The options the panel edits (the desk's own object).
func use_options(options: Options) -> void:
	_panel.use_options(options)
	_still_tags(options)


func open() -> void:
	_asking = &""
	visible = true
	_panel.visible = false
	_layout()
	for button: TagButton in _all_tags():
		button.rearm()


func close() -> void:
	if not visible:
		return
	visible = false
	_asking = &""
	_panel.visible = false
	resumed.emit()


## Esc: the options panel closes first; otherwise the pause resumes.
func escape() -> void:
	if _panel.is_open():
		_panel.close()
	else:
		close()


func is_open() -> bool:
	return visible


## The question shown now ("" while the choices show).
func question() -> String:
	return _question.text if _asking != &"" else ""


func resume_button() -> TagButton:
	return _resume


func options_button() -> TagButton:
	return _options


func restart_button() -> TagButton:
	return _restart


func quit_button() -> TagButton:
	return _quit


func yes_button() -> TagButton:
	return _yes


func no_button() -> TagButton:
	return _no


func options_panel() -> OptionsPanel:
	return _panel


## The hanging parchment in screen pixels.
func sheet_rect() -> Rect2:
	return _sheet_rect


func sheet() -> HangingSheet:
	return _sheet


func _tag(label: String, action: Callable) -> TagButton:
	var button := TagButton.new()
	button.name = label
	button.text = label
	button.pressed.connect(action)
	add_child(button)
	return button


func _all_tags() -> Array[TagButton]:
	var tags: Array[TagButton] = _openers.duplicate()
	tags.append_array([_yes, _no])
	return tags


func _ask(what: StringName) -> void:
	_asking = what
	_layout()
	_yes.rearm()
	_no.rearm()


func _on_yes() -> void:
	var what: StringName = _asking
	visible = false
	_asking = &""
	_layout()
	if what == &"restart":
		restart_confirmed.emit()
	elif what == &"quit":
		quit_confirmed.emit()


func _on_options_changed(options: Options) -> void:
	_still_tags(options)
	options_changed.emit(options)


## Reduce motion (D37): a hovered tag is rimmed but does not lift.
func _still_tags(options: Options) -> void:
	for tag: TagButton in _all_tags():
		tag.reduce_motion = options.reduce_motion


func _show_options() -> void:
	_asking = &""
	_panel.open()
	_layout()


func _on_options_closed() -> void:
	_layout()
	for button: TagButton in _openers:
		button.rearm()


func _layout() -> void:
	if _sheet == null:
		return
	var showing_options: bool = _panel.is_open()
	var asking: bool = _asking != &""
	_sheet.heading = _text.pause_title
	_resume.text = _text.resume_label
	_options.text = OptionsPanel.OPENER_LABEL
	_restart.text = _text.restart_label
	_quit.text = _text.quit_label
	_yes.text = _text.confirm_yes
	_no.text = _text.confirm_no
	var left: float = floorf((SCREEN.x - SHEET_WIDTH) / 2.0)
	var column: int = 0
	for button: TagButton in _openers:
		column = maxi(column, button.fit_width())
	var tag_left: float = left + floorf((SHEET_WIDTH - column) / 2.0)
	var y: float = SHEET_TOP + FIRST_TAG
	for button: TagButton in _openers:
		button.place(Vector2(tag_left, y), column)
		button.disabled = asking
		button.visible = not showing_options
		y += TAG_PITCH
	var bottom: float = y - TAG_PITCH + TagButton.HEIGHT
	_question.visible = asking and not showing_options
	_yes.visible = _question.visible
	_no.visible = _question.visible
	if asking:
		_question.text = _text.restart_confirm if _asking == &"restart" else _text.quit_confirm
		_question.size = Vector2(SHEET_WIDTH - SIDE_PAD * 2, 0)
		var question_top: float = bottom + QUESTION_GAP
		_question.position = Vector2(left + SIDE_PAD, question_top - LABEL_RISE)
		var lines: int = maxi(1, _question.get_line_count())
		var opener: TagButton = _restart if _asking == &"restart" else _quit
		var row: float = maxf(
			opener.position.y + CONFIRM_GAP, question_top + lines * LINE_PITCH + 3
		)
		_yes.place(Vector2(tag_left, row))
		_no.place(Vector2(tag_left + _yes.size.x + CONFIRM_TAG_GAP, row))
		bottom = row + TagButton.HEIGHT
	else:
		_question.text = ""
	_sheet_rect = Rect2(left, SHEET_TOP, SHEET_WIDTH, bottom + BOTTOM_PAD - SHEET_TOP)
	_sheet.position = _sheet_rect.position
	_sheet.size = _sheet_rect.size
	_sheet.visible = not showing_options
	queue_redraw()


func _draw() -> void:
	var dim: Color = get_theme_color(&"ink", THEME_TYPE)
	dim.a = 0.7
	draw_rect(Rect2(Vector2.ZERO, size), dim)
