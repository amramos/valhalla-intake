class_name SoulWalk
extends RefCounted
## One stamped soul leaving the desk (D14, D15): what it looked like and where it stood, captured
## before core seats the next soul, and the copy of its figure that stands on the walk layer during
## the slam and walks through its door after it. The copy is decoration: it never takes the mouse,
## and it is freed when its walk ends or is stopped.

var realm: StringName = &""
var layers: Array[Texture2D] = []
var from: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO
## The figure on the walk layer; null until `stand`, and again once ended.
var walker: DragSource = null


## The soul at the desk as it is now, about to be stamped to `p_realm`.
static func capture(figure: DragSource, p_realm: StringName) -> SoulWalk:
	var walk := SoulWalk.new()
	walk.realm = p_realm
	walk.layers = figure.layers
	walk.from = figure.global_position
	walk.size = figure.size
	return walk


## Puts the copy on `layer` where the soul stood.
func stand(layer: Control) -> void:
	if layer == null or layers.is_empty() or walker != null:
		return
	walker = DragSource.new()
	walker.name = "Walker"
	walker.layers = layers
	walker.enabled = false
	walker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(walker)
	walker.size = size
	walker.global_position = from


## Appends the walk to `tween`: through `door` and fading over `seconds`.
func walk_into(tween: Tween, door: Door, seconds: float) -> void:
	if walker == null or door == null:
		return
	var target := Vector2(door.get_global_rect().get_center().x - size.x / 2.0, from.y)
	tween.tween_property(walker, "global_position", target, seconds)
	tween.parallel().tween_property(walker, "modulate:a", 0.0, seconds)


## Frees the copy, if any; safe to call more than once.
func end() -> void:
	if is_instance_valid(walker):
		walker.queue_free()
	walker = null
