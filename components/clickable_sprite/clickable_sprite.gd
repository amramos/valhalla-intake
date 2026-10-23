class_name ClickableSprite
extends Control
## A sprite the player can click and hover: the black feather, the mentor's portrait. It draws
## its texture at its own size and emits; its owner decides what a click means. `drift_in` carries
## the texture into place from beside it (the feather drifting in from the left, D16) while the
## node itself, and so its click target, stays where it rests.

signal clicked
signal hover_started(text: String, area: Rect2)
signal hover_ended

## A drift sways down and back this many times on its way in.
const SWAYS := 2

@export var texture: Texture2D = null:
	set(value):
		texture = value
		queue_redraw()
@export var hover_text: String = ""

## Where the texture is drawn now, relative to its place, in whole pixels; zero at rest.
var _offset := Vector2i.ZERO
var _drifting: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hover_started.emit(hover_text, get_global_rect()))
	mouse_exited.connect(func() -> void: hover_ended.emit())


## Simulates the player's click (tests and tools).
func press() -> void:
	clicked.emit()


## Carries the texture into its place: drawn `from_x` pixels beside it (negative is left), it
## drifts there easing out over `seconds`, swaying up to `sway_px` down and back. It never rises
## above its place, so a feather drifting in at its resting height crosses nothing above it. Only
## the drawing moves: the click target is live at the resting place from the first frame. No time
## (or no tree) places it at once (reduce motion, D37). Hiding the sprite ends a drift. Returns
## the tween, or null when placed at once.
func drift_in(from_x: float, seconds: float, sway_px: int = 0) -> Tween:
	_stop_drift()
	if seconds <= 0.0 or not is_inside_tree():
		return null
	_drift_at(0.0, from_x, sway_px)
	_drifting = create_tween()
	_drifting.tween_method(_drift_at.bind(from_x, sway_px), 0.0, 1.0, seconds)
	_drifting.tween_callback(_landed)
	return _drifting


## True while a drift is under way.
func is_drifting() -> bool:
	return _drifting != null and _drifting.is_valid()


## Where the texture is drawn now, relative to its place (tests): zero at rest.
func drift_offset() -> Vector2i:
	return _offset


func _notification(what: int) -> void:
	# A hidden sprite (sent on, a restart) is at rest when it shows again.
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_stop_drift()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if not button.double_click:
			clicked.emit()


func _draw() -> void:
	if texture != null:
		draw_texture(texture, Vector2(_offset))


## The drift at `progress` (0 to 1): eased out along x, swaying down and back `SWAYS` times.
func _drift_at(progress: float, from_x: float, sway_px: int) -> void:
	var eased: float = 1.0 - (1.0 - progress) * (1.0 - progress)
	var sway: float = sway_px * (1.0 - cos(TAU * SWAYS * progress)) / 2.0
	_offset = Vector2i(roundi(from_x * (1.0 - eased)), roundi(sway))
	queue_redraw()


func _landed() -> void:
	_drifting = null
	_offset = Vector2i.ZERO
	queue_redraw()


func _stop_drift() -> void:
	if _drifting != null and _drifting.is_valid():
		_drifting.kill()
	_drifting = null
	_offset = Vector2i.ZERO
	queue_redraw()
