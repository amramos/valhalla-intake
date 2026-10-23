class_name DoorLight
extends RefCounted
## A door's light over the days (D19, D39): which of its sprites shows today, and its glow's slow
## pulse. A lit door alternates its lit sprite with a dim copy (the glow's core one ramp step
## smaller, from tools/art/band_frames.py) every half PULSE_SECONDS: palette-safe frames, never a
## tint. Each later day has its own copies of the sprites, their stones a ramp value darker with
## the gate band, their light, glyph and bar unchanged. Reduce motion (D37) holds the lit sprite.

const PULSE_SECONDS := 2.5

## Reduce motion (D37): no pulse.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_pulse.reset()

var _day: int = 1
var _pulse := IdleCycle.new(2, PULSE_SECONDS / 2.0, PULSE_SECONDS / 2.0, PULSE_SECONDS / 2.0)


## Today is `day` (days before 1 are day 1). Returns true when it changed.
func set_day(day: int) -> bool:
	var clamped: int = maxi(1, day)
	var changed: bool = clamped != _day
	_day = clamped
	return changed


func day() -> int:
	return _day


## Today's copy of a sprite: `base` on day 1, then `later` (day 2 first; past its end the last).
func for_day(base: Texture2D, later: Array[Texture2D]) -> Texture2D:
	if _day <= 1 or later.is_empty():
		return base
	return later[mini(_day - 2, later.size() - 1)]


## True in the pulse's dim half.
func is_dim() -> bool:
	return not reduce_motion and _pulse.frame() == 1


## Moves the pulse on (only a lit door pulses; a locked one rests). True when the frame changed.
func advance(delta: float, lit: bool) -> bool:
	if reduce_motion:
		return false
	if not lit:
		var was_dim: bool = _pulse.frame() == 1
		_pulse.reset()
		return was_dim
	return _pulse.advance(delta)
