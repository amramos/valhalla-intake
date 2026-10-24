class_name Door
extends Control
## One realm door in the gate band (D4, D9, D21): its lit or locked sprite (by the day the door
## opens), its hit area, and its hover label with the carved glyph and the name ("Closed until
## day N" while locked). Clicking only selects the door: the stamp waits for the separate confirm
## (D9), which sits below the doors' hit areas so a fast second click can never land on it. A soul
## dragged onto an open door previews the stamp, and dropping it there commits. Hel's door also
## carries Hel's tide: 6 px figures with empty slots up to the threshold (D21, D23). A refresh
## sets the tide as it is (`set_tide`, never animated); the slam that adds a figure steps it in
## from below (`step_tide`, D38).

signal door_clicked(realm: StringName)
signal hover_started(text: String, area: Rect2, glyph: StringName)
signal hover_ended
## A dragged soul is over this open door (preview the stamp).
signal drag_hovered(realm: StringName)
## A dragged soul was dropped on this open door (commit the stamp).
signal dropped(realm: StringName)

const FLARE_SECONDS := 0.4
const TIDE_FIGURE := Vector2i(3, 6)
const TIDE_STEP := 5
## A new tide figure steps up into its slot from this far below (D38).
const TIDE_RISE_PX := 2
const TIDE_RISE_SECONDS := 0.3

@export var realm: StringName = &""
@export var glyph: StringName = &"spear"
@export var lit_texture: Texture2D = null
@export var locked_texture: Texture2D = null

var is_open: bool = true
## The first day the door opens, for "Closed until day N"; 0 when it never opens.
var open_day: int = 0
var is_new: bool = false
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## The mentor points at this door (a guided step, D16).
var pointed: bool = false:
	set(value):
		if pointed != value:
			pointed = value
			queue_redraw()
## Hel's tide: souls counted so far, and the slots drawn (the threshold); (0, 0) draws nothing.
var tide := Vector2i.ZERO
## How many times the tide has stepped (tests: one per stamp that adds a figure, none per refresh).
var tide_steps: int = 0

var _hovered: bool = false
var _flare_left: float = 0.0
## The pause holds the flare where it is (the gate's pause_changed).
var _paused: bool = false
## How far below its slot the newest tide figure is drawn now, in whole pixels; 0 at rest.
var _rise: int = 0
var _step: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_state(p_open: bool, p_open_day: int, p_new: bool) -> void:
	is_open = p_open
	open_day = p_open_day
	is_new = p_new
	queue_redraw()


## The tide as a refresh shows it, never animated. A step under way for the same count goes on; a
## different count (or a step that was cut off) puts every figure in its slot at once.
func set_tide(count: int, threshold: int) -> void:
	if count != tide.x or _step == null or not _step.is_valid():
		_stop_step()
	tide = Vector2i(count, threshold)
	queue_redraw()


## The slam added a figure (D38): the tide shows `count` figures, the newest stepping up from
## `TIDE_RISE_PX` below over `seconds` (0, or outside the tree: at once, reduce motion). Called
## once per stamp whose tide grew, never by a refresh. Returns the tween, or null when at once.
func step_tide(count: int, threshold: int, seconds: float = TIDE_RISE_SECONDS) -> Tween:
	_stop_step()
	tide = Vector2i(count, threshold)
	tide_steps += 1
	queue_redraw()
	if seconds <= 0.0 or count <= 0 or not is_inside_tree():
		return null
	_set_rise(float(TIDE_RISE_PX))
	_step = create_tween()
	_step.tween_method(_set_rise, float(TIDE_RISE_PX), 0.0, seconds)
	return _step


## How far below its slot the newest figure is drawn now (tests).
func tide_rise() -> int:
	return _rise


## The stamp's door flare (D9): the lit door brightens for a moment.
func flare() -> void:
	_flare_left = FLARE_SECONDS
	queue_redraw()


func is_flaring() -> bool:
	return _flare_left > 0.0


## A paused door keeps its flare as it is until resumed (the pause, focus loss).
func set_paused(paused: bool) -> void:
	_paused = paused


## The sprite drawn now (tests).
func shown_texture() -> Texture2D:
	return lit_texture if is_open else locked_texture


func display_name() -> String:
	return Realm.display_name(realm)


## The hover text: the name, and when a locked door opens.
func hover_text() -> String:
	if is_open:
		return display_name() + (" (NEW)" if is_new else "")
	if open_day > 0:
		return "%s: Closed until day %d" % [display_name(), open_day]
	return "%s: Closed" % display_name()


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


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var payload: Dictionary = data as Dictionary if data is Dictionary else {}
	if not is_open or payload.get("kind", &"") != &"soul":
		return false
	drag_hovered.emit(realm)
	return true


func _drop_data(_at: Vector2, _data: Variant) -> void:
	dropped.emit(realm)


func _process(delta: float) -> void:
	if _flare_left <= 0.0 or _paused:
		return
	_flare_left = maxf(0.0, _flare_left - delta)
	queue_redraw()


func _draw() -> void:
	var sprite: Texture2D = shown_texture()
	if sprite != null:
		var bright: float = 1.0 + 0.6 * (_flare_left / FLARE_SECONDS)
		draw_texture(sprite, Vector2.ZERO, Color(bright, bright, bright, 1))
	if selected or pointed:
		var frame: Color = get_theme_color(&"glyph", &"DeskPalette")
		draw_rect(Rect2(Vector2.ZERO, size).grow(-0.5), frame, false, 1.0)
		if pointed and not selected:
			draw_rect(Rect2(Vector2.ZERO, size).grow(-1.5), frame, false, 1.0)
	if is_new:
		_draw_new_tag()
	if tide.y > 0:
		_draw_tide()


func _draw_new_tag() -> void:
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size("NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
	var tag := Rect2(floorf((size.x - width) / 2.0) - 2, -9, width + 3, 9)
	draw_rect(tag, get_theme_color(&"parchment", &"DeskPalette"))
	draw_string(
		font,
		tag.position + Vector2(2, 8),
		"NEW",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		PixelFont.SIZE,
		get_theme_color(&"ink", &"DeskPalette")
	)


## Figures along the lower leaf: filled for each soul counted, outlined slots up to the threshold.
func _draw_tide() -> void:
	var slots: int = maxi(tide.x, tide.y)
	var left: float = floorf((size.x - (slots * TIDE_STEP - 2)) / 2.0)
	var top: float = size.y - TIDE_FIGURE.y - 3
	var backing := Rect2(left - 2, top - 2, slots * TIDE_STEP + 2, TIDE_FIGURE.y + 4)
	draw_rect(backing, get_theme_color(&"night", &"DeskPalette"))
	var color: Color = get_theme_color(&"glyph", &"DeskPalette")
	for index: int in range(slots):
		var at := Vector2(left + index * TIDE_STEP, top)
		if index == tide.x - 1:
			at.y += _rise
		var head := Rect2(at + Vector2(1, 0), Vector2(1, 1))
		var body := Rect2(at + Vector2(0, 2), Vector2(TIDE_FIGURE.x, TIDE_FIGURE.y - 2))
		if index < tide.x:
			draw_rect(head, color)
			draw_rect(body, color)
		else:
			draw_rect(body.grow(-0.5), get_theme_color(&"glyph_dim", &"DeskPalette"), false, 1.0)


## The tide figures' rectangles in this door's pixels (tests).
func tide_rect() -> Rect2:
	var slots: int = maxi(tide.x, tide.y)
	var left: float = floorf((size.x - (slots * TIDE_STEP - 2)) / 2.0)
	return Rect2(left, size.y - TIDE_FIGURE.y - 3, slots * TIDE_STEP - 2, TIDE_FIGURE.y)


func _set_rise(pixels_below: float) -> void:
	_rise = roundi(pixels_below)
	queue_redraw()


func _stop_step() -> void:
	if _step != null and _step.is_valid():
		_step.kill()
	_step = null
	_rise = 0


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()
	hover_started.emit(hover_text(), get_global_rect(), glyph)


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
	hover_ended.emit()
