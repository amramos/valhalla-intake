class_name GuardedButton
extends Button
## A button for a final act (the stamp, D9): it ignores the second press of a double-click, and
## any press in the first moments after it appears, so a fast double-click on a door can never
## carry through to a commit.

## Presses within this time of becoming visible are ignored.
@export var arm_seconds: float = 0.3

var _armed_at_msec: int = 0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


## True when a press now would count.
func is_armed() -> bool:
	return is_visible_in_tree() and Time.get_ticks_msec() >= _armed_at_msec


## Restarts the arm time, as if the button had just appeared.
func rearm() -> void:
	_armed_at_msec = Time.get_ticks_msec() + int(arm_seconds * 1000.0)


## Arms the button immediately (tests and tools; players wait the arm time).
func arm_now() -> void:
	_armed_at_msec = 0


## True when the button must swallow this event instead of pressing: the second press of a
## double-click, or any press before the button is armed.
func blocks(event: InputEvent) -> bool:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed:
		return false
	return button.double_click or not is_armed()


func _gui_input(event: InputEvent) -> void:
	if blocks(event):
		accept_event()


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		rearm()
