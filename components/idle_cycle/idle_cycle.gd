class_name IdleCycle
extends RefCounted
## The clock of a decorative idle (D17, D19): it rests on frame 0 for a wait drawn between
## `rest_min` and `rest_max` seconds, then shows frames 1.. in turn for `hold` seconds each, and
## rests again. The waits come from its own generator with a fixed seed, so a run (and a test)
## always sees the same ones. Pure: its owner advances it with its own delta, so the gate's pause
## and reduce motion stay the owner's call, and draws `frame()`.

## The shortest wait or hold it accepts; a zero would never let a frame show.
const MIN_SECONDS := 0.01

var frames: int = 2
var rest_min: float = 1.0
var rest_max: float = 1.0
var hold: float = 0.15

var _rng := RandomNumberGenerator.new()
var _seed: int = 0
var _frame: int = 0
var _left: float = 0.0


func _init(
	p_frames: int = 2,
	p_rest_min: float = 1.0,
	p_rest_max: float = 1.0,
	p_hold: float = 0.15,
	p_seed: int = 0
) -> void:
	frames = maxi(1, p_frames)
	rest_min = maxf(MIN_SECONDS, p_rest_min)
	rest_max = maxf(rest_min, p_rest_max)
	hold = maxf(MIN_SECONDS, p_hold)
	_seed = p_seed
	reset()


## Moves the clock on by `delta` seconds. Returns true when the frame shown changed.
func advance(delta: float) -> bool:
	if frames < 2 or delta <= 0.0:
		return false
	var before: int = _frame
	_left -= delta
	while _left <= 0.0:
		_frame = (_frame + 1) % frames
		_left += _next_wait()
	return _frame != before


## The frame to show now: 0 while resting.
func frame() -> int:
	return _frame


## Seconds until the frame next changes.
func time_left() -> float:
	return _left


## Back to rest with the generator restarted, so the waits repeat from the first.
func reset() -> void:
	_rng.seed = _seed
	_frame = 0
	_left = _next_wait()


func _next_wait() -> float:
	if _frame != 0:
		return hold
	return rest_min if rest_max <= rest_min else _rng.randf_range(rest_min, rest_max)
