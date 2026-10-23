class_name Raven
extends Control
## Huginn on his perch post in the gate band (D40): the control that asks him. A click on the bird
## or his post asks about the selected grey thread (`asked`); with nothing selected it does
## nothing at all, so it never costs anything. The hover names the count, the precondition or the
## price, and is said again when it changes under the mouse. His desk system shows him on the days
## he is at the desk; otherwise the post stands empty (it belongs to the backdrop).
##
## Presence (D17): he tilts his head now and then (two frames, a seeded wait) and ruffles when an
## answer is given. Reduce motion (D37) keeps him still on his rest frame; the gate's pause holds
## his clock.

signal asked
signal hover_started(text: String, area: Rect2)
signal hover_ended

## The bird's box and the post's in this node's pixels. The node sits at (268, 34); the sprite is
## its top 48x40 (a ruffle reaches one pixel further), the post is the backdrop's (280, 72) 19x24.
const BIRD_RECT := Rect2(6, 3, 37, 37)
const POST_RECT := Rect2(12, 38, 19, 24)
## The head tilt: a wait of 3 to 5 s, then the tilted frame for TILT_HOLD.
const TILT_EVERY := Vector2(3.0, 5.0)
const TILT_HOLD := 0.6
const TILT_SEED := 1201
const RUFFLE_SECONDS := 0.4
const LEFT_FORMAT := "Ask Huginn: %d answers left"
const LEFT_ONE := "Ask Huginn: 1 answer left"

@export var rest_texture: Texture2D = null
@export var tilt_texture: Texture2D = null
@export var ruffle_texture: Texture2D = null

## Reduce motion (D37): no tilt, no ruffle.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_idle.reset()
		_ruffle_left = 0.0
		queue_redraw()

var _answers_left: int = 0
var _has_thread: bool = false
var _extra_cost: int = 0
var _select_text: String = "Select a grey thread first."
var _extra_text: String = "Extra answer: %d feathers."
var _hovered: bool = false
var _hover_said: String = ""
var _idle := IdleCycle.new(2, TILT_EVERY.x, TILT_EVERY.y, TILT_HOLD, TILT_SEED)
var _ruffle_left: float = 0.0
var _paused: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## The words of the precondition and the price (DeskText's, so the text harness says the same).
## The price may carry a %d for the feathers.
func set_texts(select_hover: String, extra_hover: String) -> void:
	_select_text = select_hover
	_extra_text = extra_hover
	_say_hover()


func set_answers_left(answers: int) -> void:
	_answers_left = answers
	_say_hover()


## Whether a grey thread is selected for him.
func set_selected_thread(has: bool) -> void:
	_has_thread = has
	_say_hover()


## What the next answer costs in feathers; 0 when it is free.
func set_extra_cost(feathers: int) -> void:
	_extra_cost = feathers
	_say_hover()


## The hover: "Select a grey thread first." with none selected, the price when the answer is
## bought, else the answers left today.
func hover_text() -> String:
	if not _has_thread:
		return _select_text
	if _extra_cost > 0:
		return _extra_text % _extra_cost if _extra_text.contains("%d") else _extra_text
	return LEFT_ONE if _answers_left == 1 else LEFT_FORMAT % _answers_left


## Simulates the player's click (tests and tools).
func press() -> void:
	_on_click()


## An answer was given: he ruffles (nothing under reduce motion).
func ruffle() -> void:
	if reduce_motion:
		return
	_ruffle_left = RUFFLE_SECONDS
	queue_redraw()


func is_ruffling() -> bool:
	return _ruffle_left > 0.0


## The head tilt's frame now: 0 at rest, 1 tilted.
func idle_frame() -> int:
	return 0 if reduce_motion else _idle.frame()


## The sprite drawn now.
func shown_texture() -> Texture2D:
	if is_ruffling() and ruffle_texture != null:
		return ruffle_texture
	if idle_frame() == 1 and tilt_texture != null:
		return tilt_texture
	return rest_texture


## The gate's pause holds the tilt and the ruffle where they are.
func set_paused(paused: bool) -> void:
	_paused = paused


## The bird and his post together, on screen: where the hover tag keeps clear of.
func hit_rect() -> Rect2:
	var area: Rect2 = BIRD_RECT.merge(POST_RECT)
	return Rect2(area.position + global_position, area.size)


func _has_point(point: Vector2) -> bool:
	return BIRD_RECT.has_point(point) or POST_RECT.has_point(point)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	# The second press of a double-click is not a second question.
	if not button.double_click:
		_on_click()


func _on_click() -> void:
	if _has_thread:
		asked.emit()


func _process(delta: float) -> void:
	if _paused or reduce_motion or not is_visible_in_tree():
		return
	var changed: bool = _idle.advance(delta)
	if _ruffle_left > 0.0:
		_ruffle_left = maxf(0.0, _ruffle_left - delta)
		changed = changed or _ruffle_left == 0.0
	if changed:
		queue_redraw()


func _draw() -> void:
	var shown: Texture2D = shown_texture()
	if shown != null:
		draw_texture(shown, Vector2.ZERO)


## Says the hover again when its words changed under the mouse (an answer spent, a price due).
func _say_hover() -> void:
	if not _hovered:
		return
	var text: String = hover_text()
	if text != _hover_said:
		_hover_said = text
		hover_started.emit(text, hit_rect())


func _on_mouse_entered() -> void:
	_hovered = true
	_hover_said = ""
	_say_hover()


func _on_mouse_exited() -> void:
	_hovered = false
	hover_ended.emit()
