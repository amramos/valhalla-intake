class_name PauseOverlay
extends Control
## The pause (D31): it dims the whole desk and offers Resume, Restart the run and Quit. Restart and
## Quit each ask once more before they act. While it is open nothing under it takes a click. Its
## words come from DeskText; `configure` sets them.

signal resumed
signal restart_confirmed
signal quit_confirmed

const PANEL_WIDTH := 200.0
const PADDING := 6
const ROW := 16
const SCREEN := Vector2(480, 270)

var _title: Label = null
var _buttons: Array[GuardedButton] = []
var _resume: GuardedButton = null
var _restart: GuardedButton = null
var _quit: GuardedButton = null
var _yes: GuardedButton = null
var _no: GuardedButton = null
var _panel := Rect2()
## &"restart" or &"quit" while a confirmation is asked; &"" otherwise.
var _asking: StringName = &""
var _text: DeskText = DeskText.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = SCREEN
	_title = Label.new()
	_title.name = "Title"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_color_override(&"font_color", get_theme_color(&"text_light", &"DeskPalette"))
	add_child(_title)
	_resume = _button("Resume", func() -> void: close())
	_restart = _button("Restart", func() -> void: _ask(&"restart"))
	_quit = _button("Quit", func() -> void: _ask(&"quit"))
	_yes = _button("Yes", _on_yes)
	_no = _button("No", func() -> void: _ask(&""))
	visible = false


func configure(text: DeskText) -> void:
	_text = text
	_layout()


func open() -> void:
	_asking = &""
	visible = true
	_layout()
	for button: GuardedButton in _buttons:
		button.rearm()


func close() -> void:
	if not visible:
		return
	visible = false
	_asking = &""
	resumed.emit()


func is_open() -> bool:
	return visible


## The question shown now ("" while the three choices show).
func question() -> String:
	return _title.text if _asking != &"" else ""


func resume_button() -> GuardedButton:
	return _resume


func restart_button() -> GuardedButton:
	return _restart


func quit_button() -> GuardedButton:
	return _quit


func yes_button() -> GuardedButton:
	return _yes


func no_button() -> GuardedButton:
	return _no


func _button(label: String, action: Callable) -> GuardedButton:
	var button := GuardedButton.new()
	button.name = label
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	add_child(button)
	_buttons.append(button)
	return button


func _ask(what: StringName) -> void:
	_asking = what
	_layout()
	_yes.rearm()
	_no.rearm()


func _on_yes() -> void:
	var what: StringName = _asking
	visible = false
	_asking = &""
	if what == &"restart":
		restart_confirmed.emit()
	elif what == &"quit":
		quit_confirmed.emit()


func _layout() -> void:
	if _title == null:
		return
	var asking: bool = _asking != &""
	_title.text = _text.pause_title
	if _asking == &"restart":
		_title.text = _text.restart_confirm
	elif _asking == &"quit":
		_title.text = _text.quit_confirm
	_title.position = Vector2(0, -3)
	_title.size = Vector2(PANEL_WIDTH - PADDING * 2, 0)
	var title_height: float = maxi(1, _title.get_line_count()) * 10.0
	var shown: Array[GuardedButton] = []
	if asking:
		shown.append_array([_yes, _no])
	else:
		shown.append_array([_resume, _restart, _quit])
	_resume.text = _text.resume_label
	_restart.text = _text.restart_label
	_quit.text = _text.quit_label
	_yes.text = _text.confirm_yes
	_no.text = _text.confirm_no
	var height: float = PADDING * 2 + title_height + shown.size() * ROW + 2
	_panel = Rect2(
		((SCREEN - Vector2(PANEL_WIDTH, height)) / 2.0).floor(), Vector2(PANEL_WIDTH, height)
	)
	_title.position = _panel.position + Vector2(PADDING, PADDING - 3)
	var y: float = _panel.position.y + PADDING + title_height + 2
	for button: GuardedButton in _buttons:
		button.visible = shown.has(button)
		if button.visible:
			button.size = Vector2(PANEL_WIDTH - PADDING * 2, 14)
			button.position = Vector2(_panel.position.x + PADDING, y)
			y += ROW
	queue_redraw()


func _draw() -> void:
	var dim: Color = get_theme_color(&"ink", &"DeskPalette")
	dim.a = 0.7
	draw_rect(Rect2(Vector2.ZERO, size), dim)
	draw_rect(_panel, get_theme_color(&"night", &"DeskPalette"))
	draw_rect(_panel.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
