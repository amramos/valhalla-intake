class_name Door
extends Control
## One realm door in the gate band (D4, D9, D21). The door's art belongs to the backdrop; this
## node is its hit area. On hover, or while selected, it shows a tag with its carved glyph and
## its name. A locked door shows a bar and a dimmed glyph, and says when it opens. Clicking a door
## only selects it: the stamp itself waits for the separate confirm (D9), which sits below the
## doors' hit areas so a fast second click can never land on it.

signal door_clicked(realm: StringName)
signal hover_started(text: String, area: Rect2)
signal hover_ended

@export var realm: StringName = &""
@export var glyph: StringName = &"spear"

var is_open: bool = true
## The first day the door opens, for "Closed until day N"; 0 when it never opens.
var open_day: int = 0
var is_new: bool = false
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()

var _hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_state(p_open: bool, p_open_day: int, p_new: bool) -> void:
	is_open = p_open
	open_day = p_open_day
	is_new = p_new
	queue_redraw()


func display_name() -> String:
	return Realm.display_name(realm)


## The hover text: the name, and when a locked door opens.
func hover_text() -> String:
	if is_open:
		return display_name() + (" (NEW)" if is_new else "")
	if open_day > 0:
		return "%s: closed until day %d" % [display_name(), open_day]
	return "%s: closed" % display_name()


## Simulates the player's click (tests and tools).
func press() -> void:
	door_clicked.emit(realm)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	# The second press of a double-click is not a second choice (D9).
	if not button.double_click:
		door_clicked.emit(realm)


func _draw() -> void:
	var tag_at := Vector2(floorf((size.x - PixelGlyph.SIZE) / 2.0), 4)
	if not is_open:
		var bar := Rect2(0, floorf(size.y * 0.45), size.x, 3)
		draw_rect(bar, get_theme_color(&"lock_bar", &"DeskPalette"))
		draw_rect(Rect2(bar.position, Vector2(size.x, 1)), get_theme_color(&"ink", &"DeskPalette"))
		var dim_at := Vector2(tag_at.x, bar.position.y - PixelGlyph.SIZE - 2)
		PixelGlyph.draw(self, glyph, dim_at, get_theme_color(&"glyph_dim", &"DeskPalette"))
	if _hovered or selected:
		var plate := Rect2(tag_at - Vector2(2, 2), Vector2.ONE * (PixelGlyph.SIZE + 4))
		draw_rect(plate, get_theme_color(&"night", &"DeskPalette"))
		PixelGlyph.draw(self, glyph, tag_at, get_theme_color(&"glyph", &"DeskPalette"))
	if selected:
		var frame: Color = get_theme_color(&"glyph", &"DeskPalette")
		draw_rect(Rect2(Vector2.ZERO, size).grow(-0.5), frame, false, 1.0)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	hover_started.emit(hover_text(), get_global_rect())


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	hover_ended.emit()
