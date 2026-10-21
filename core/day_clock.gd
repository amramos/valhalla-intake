class_name DayClock
extends RefCounted
## The day clock (D10): real time while a soul is at the desk, plus action costs. Untimed when
## its length is 0. Pausing stops real time only; an action's cost is always charged.

var length: float = 0.0
var left: float = 0.0
var warning_at: float = 30.0
var paused: bool = false

var _warned: bool = false


func _init(seconds: float = 0.0, warning_seconds: float = 30.0) -> void:
	length = maxf(seconds, 0.0)
	left = length
	warning_at = warning_seconds


func is_timed() -> bool:
	return length > 0.0


func time_left() -> float:
	return left if is_timed() else INF


## Real time passing; ignored while paused.
func tick(seconds: float) -> void:
	if is_timed() and not paused:
		_take(seconds)


## An action's cost (a no-seam pin, a Huginn answer).
func charge(seconds: float) -> void:
	if is_timed():
		_take(seconds)


func is_out() -> bool:
	return is_timed() and left <= 0.0


## True exactly once, the first time the clock is at or under the warning mark.
func take_warning() -> bool:
	if not is_timed() or _warned or left > warning_at:
		return false
	_warned = true
	return true


func _take(seconds: float) -> void:
	left = maxf(left - maxf(seconds, 0.0), 0.0)
