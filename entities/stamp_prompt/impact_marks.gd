class_name ImpactMarks
extends RefCounted
## The stamp prompt's transient marks (D55, D56), built as children of the prompt and timed by it:
## - the veil: Night 0 over the whole screen at a given alpha (0.25 while the stamp is raised, 0.55
##   at the impact), the one allowed transient tint, a state cue. While it shows, the writ, the
##   stamp, its label and the marks are lifted above it, and the companions (the three doors) with
##   them for the choice only, never the impact; and only then, so the pause and the cards still
##   cover them the rest of the time;
## - the burst: eight short light streaks radiating 3 px from the block's corners and mid-edges at
##   the impact in Parchment 2, then the same at 6 px in Fog 2 (light, to read on the dark band);
## - the shockwave: an ink outline 21×21 round the ink box as the stamp lifts, then 27×27 in Fog 2.
## Everything is whole pixels in palette colours; nothing here knows the soul (D14).

## The veil's z above everything at z 0; the lifted items go one higher while it shows.
const VEIL_Z := 10
## The burst's reach per stage (stage 1 near in Parchment 2, stage 2 far in Fog 2); each streak is
## 2 px.
const BURST_REACH: Array[int] = [0, 3, 6]
## The shockwave's sizes per stage (stage 1 in ink, stage 2 in Fog 2).
const RING_SIZES: Array[int] = [0, 21, 27]
const THEME_TYPE := &"DeskPalette"
## Palette fallbacks (docs/art/palette.gpl): Night 0, Parchment 2, Fog 2.
const NIGHT_0 := Color8(11, 23, 34)
const PARCHMENT_2 := Color8(246, 238, 210)
const FOG_2 := Color8(163, 174, 176)

var _host: Control = null
var _veil: ColorRect = null
var _ring: Control = null
var _burst: Control = null
var _lifted: Array[CanvasItem] = []
var _companions: Array[CanvasItem] = []
var _veil_alpha: float = 0.0
var _with_companions: bool = false
var _suspended: bool = false
var _ring_stage: int = 0
var _burst_stage: int = 0
## The stamp's block on the paper, in the host's pixels: the burst radiates from it.
var _block: Rect2i = Rect2i()


## `ring_center` is the ink box's centre and `block` the stamp's block on the paper, both in
## `host`'s pixels; `lifted` go above the veil while it shows.
func _init(host: Control, ring_center: Vector2, block: Rect2i, lifted: Array[CanvasItem]) -> void:
	_host = host
	_block = block
	var wide: int = RING_SIZES[2]
	_ring = _mark(
		"Ring", Rect2(ring_center - Vector2(wide, wide) / 2.0, Vector2(wide, wide)), _draw_ring
	)
	var reach: int = BURST_REACH[2] + 1
	_burst = _mark("Burst", Rect2(block).grow(reach), _draw_burst)
	_veil = ColorRect.new()
	_veil.name = "Dim"
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.z_index = VEIL_Z
	_veil.visible = false
	host.add_child(_veil)
	_lifted = lifted.duplicate()
	_lifted.append_array([_ring, _burst])


## Items lifted above the veil with the writ and the stamp (the doors, D56).
func set_companions(items: Array[CanvasItem]) -> void:
	_companions = items.duplicate()
	_apply_veil()


## Veils the screen at `alpha` (0 lifts it); `with_companions` lifts the doors above it too (the
## choice), else they yield with the desk (the impact).
func set_veil(alpha: float, with_companions: bool = false) -> void:
	_veil_alpha = alpha
	_with_companions = with_companions
	_apply_veil()


func veil_alpha() -> float:
	return _veil_alpha


## The pause covers the desk: the veil and the lifted items step back under it until it closes.
func set_suspended(on: bool) -> void:
	_suspended = on
	_apply_veil()


func is_dimming() -> bool:
	return _veil.visible


## 0 none, 1 the near Parchment 2 burst, 2 the far Fog 2 burst.
func set_burst(stage: int) -> void:
	_burst_stage = stage
	_burst.queue_redraw()


func burst_stage() -> int:
	return _burst_stage


## 0 none, 1 the 21×21 ink ring, 2 the 27×27 Fog 2 ring.
func set_ring(stage: int) -> void:
	_ring_stage = stage
	_ring.queue_redraw()


func ring_stage() -> int:
	return _ring_stage


## The shockwave's outline in canvas coordinates now; empty when none shows (tests).
func ring_rect() -> Rect2:
	if _ring_stage == 0:
		return Rect2()
	var side: float = RING_SIZES[_ring_stage]
	var inset: float = (RING_SIZES[2] - side) / 2.0
	return Rect2(_ring.global_position + Vector2(inset, inset), Vector2(side, side))


## The burst's pixels in canvas coordinates now, one Rect2 each (tests).
func burst_pixels() -> Array[Rect2]:
	var pixels: Array[Rect2] = []
	for at: Vector2i in _burst_points(BURST_REACH[_burst_stage]):
		pixels.append(Rect2(_host.global_position + Vector2(at), Vector2.ONE))
	return pixels


## The colours drawn now (tests): the burst Parchment 2 then Fog 2, the ring Ink then Fog 2.
func burst_color() -> Color:
	if _burst_stage < 2:
		return _color(&"pin_highlight", PARCHMENT_2)
	return _color(&"text_muted", FOG_2)


func ring_color() -> Color:
	return _color(&"ink", NIGHT_0) if _ring_stage < 2 else _color(&"text_muted", FOG_2)


func _apply_veil() -> void:
	var on: bool = _veil_alpha > 0.0 and not _suspended
	if on and _veil.is_inside_tree():
		_veil.global_position = Vector2.ZERO
		_veil.size = _veil.get_viewport_rect().size
	_veil.color = Color(_color(&"ink", NIGHT_0), _veil_alpha)
	_veil.visible = on
	var z: int = VEIL_Z + 1 if on else 0
	for item: CanvasItem in _lifted:
		item.z_index = z
	for item: CanvasItem in _companions:
		if is_instance_valid(item):
			item.z_index = z if _with_companions else 0


func _mark(mark_name: String, area: Rect2, draw: Callable) -> Control:
	var mark := Control.new()
	mark.name = mark_name
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = area.position.floor()
	mark.size = area.size
	mark.draw.connect(draw)
	_host.add_child(mark)
	return mark


func _draw_ring() -> void:
	if _ring_stage == 0:
		return
	var local := Rect2(ring_rect().position - _ring.global_position, ring_rect().size)
	Writ.frame(_ring, local, ring_color())


## Each streak: its outer pixel `reach` px out from a corner or mid-edge, and the pixel inside it.
func _draw_burst() -> void:
	if _burst_stage == 0:
		return
	var color: Color = burst_color()
	for at: Vector2i in _burst_points(BURST_REACH[_burst_stage]):
		_burst.draw_rect(Rect2(Vector2(at) - _burst.position, Vector2.ONE), color)


## The burst's pixels in the host's pixels: for each of the block's corners and mid-edges, the
## two pixels `reach - 1` and `reach` out along its outward direction.
func _burst_points(reach: int) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	if reach <= 0:
		return points
	var left: int = _block.position.x
	var top: int = _block.position.y
	var right: int = _block.end.x - 1
	var bottom: int = _block.end.y - 1
	var mid := Vector2i(left + _block.size.x / 2, top + _block.size.y / 2)
	var origins: Array[Vector2i] = [
		Vector2i(left, top),
		Vector2i(mid.x, top),
		Vector2i(right, top),
		Vector2i(right, mid.y),
		Vector2i(right, bottom),
		Vector2i(mid.x, bottom),
		Vector2i(left, bottom),
		Vector2i(left, mid.y)
	]
	var outward: Array[Vector2i] = [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0)
	]
	for index: int in range(origins.size()):
		for step: int in [reach - 1, reach]:
			points.append(origins[index] + outward[index] * step)
	return points


func _color(color_name: StringName, fallback: Color) -> Color:
	if _host.has_theme_color(color_name, THEME_TYPE):
		return _host.get_theme_color(color_name, THEME_TYPE)
	return fallback
