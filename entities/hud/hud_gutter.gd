class_name HudGutter
extends RefCounted
## The candle's gutter after a no-seam pin that charged time (D36): for 0.6 s the flame flickers
## between two frames and "-m:ss" shows on the stone beside the candle, stepping its ink down the
## Fog ramp. The label never moves, so it is the same under reduce motion (D37), where only the
## flicker, a decorative movement, is left out.

const SECONDS := 0.6
const FLICKER_SECONDS := 0.1

var reduce_motion: bool = false
var _label: String = ""
var _age: float = 0.0


func start(label_text: String) -> void:
	_label = label_text
	_age = 0.0


## Ends the gutter at once (a restarted run).
func clear() -> void:
	_label = ""
	_age = 0.0


## Ages the gutter; true while it was showing, so the HUD redraws.
func advance(delta: float) -> bool:
	if _label == "":
		return false
	_age += delta
	if _age >= SECONDS:
		_label = ""
	return true


## The label while it shows ("-0:10"), else "".
func label() -> String:
	return _label


## 0 for the steady flame, else one of the gutter's two frames (1 or 2).
func flame_frame() -> int:
	if reduce_motion or _label == "":
		return 0
	return 1 + floori(_age / FLICKER_SECONDS) % 2


## The DeskPalette name of the label's ink: Parchment 2, then Fog 2, then Fog 1.
func ink() -> StringName:
	if _age < SECONDS * 0.5:
		return &"text_light"
	return &"text_muted" if _age < SECONDS * 0.75 else &"glyph_dim"
