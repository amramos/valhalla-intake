class_name LedgerTray
extends Control
## The ledger's tray (D3, D29): a click on the HUD's ledger icon opens a one-line view of Hel's
## promise in whatever state it is (open, kept, broken, lapsed), or the empty ledger; another click
## closes it. The HUD draws the icon and its badge; this is the click area and the view.

signal toggled(open: bool)

const PADDING := Vector2(3, 1)
## The view's right edge and top, in this node's parent's pixels.
const VIEW_RIGHT := 478.0
const VIEW_TOP := 62.0

var _line: String = ""
var _open: bool = false
var _back: Control = null
var _view: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The view's plate is its own node under the label, so the text draws over it.
	_back = Control.new()
	_back.name = "View"
	_back.top_level = true
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.draw.connect(_draw_view_back)
	_back.visible = false
	add_child(_back)
	_view = Label.new()
	_view.name = "Line"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.position = PADDING - Vector2(0, 3)
	_view.add_theme_color_override(&"font_color", get_theme_color(&"text_light", &"DeskPalette"))
	_back.add_child(_view)


## The ledger's one line ("" for the empty ledger's text, given in `empty`).
func set_line(line: String, empty: String) -> void:
	_line = line if line != "" else empty
	if _open:
		_show_view()


func is_open() -> bool:
	return _open


func shown_line() -> String:
	return _view.text if _open else ""


## Simulates the player's click (tests and tools).
func press() -> void:
	_toggle()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if not button.double_click:
			_toggle()


func _toggle() -> void:
	_open = not _open
	if _open:
		_show_view()
	else:
		_back.visible = false
	toggled.emit(_open)


func _show_view() -> void:
	_view.text = _line
	_view.size = Vector2.ZERO
	var width: float = _view.get_minimum_size().x
	_back.size = Vector2(width, 9) + PADDING * 2
	_back.global_position = Vector2(VIEW_RIGHT - _back.size.x, VIEW_TOP)
	_back.visible = true
	_back.queue_redraw()


func _draw_view_back() -> void:
	var area := Rect2(Vector2.ZERO, _back.size)
	_back.draw_rect(area, get_theme_color(&"night", &"DeskPalette"))
	_back.draw_rect(area.grow(-0.5), get_theme_color(&"frame", &"DeskPalette"), false, 1.0)
