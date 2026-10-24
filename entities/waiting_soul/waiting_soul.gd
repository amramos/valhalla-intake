class_name WaitingSoul
extends Control
## The soul waiting at the gate, with its name plate (D4, D21). The figure is identity only: its
## layers are the chart's front view cropped (BodyStacks), so it shows nothing the chart doesn't.
## It can be dragged onto a door (D9). The plate is plain, frost-burned for a returned soul, or
## carries Hel's mark; it hovers the encounter's plate label. A soul shown after `prepare_arrival`
## waits off-screen to the left, its name off the plate, until `arrive` walks it in (D15). While
## it tells its tale it speaks (D4, D17): the plate lights and the figure dips 1 px on each voice
## blip; otherwise it is still. A returned soul's frost glints now and then (D17): three rime pixels
## on the plate, never on evidence; reduce motion and the gate's pause hold it.

signal plate_hover_started(text: String, area: Rect2)
signal plate_hover_ended
## The mouse is over the figure (the cursor shows the grab hand, D13), and has left it.
signal figure_hover_started
signal figure_hover_ended

const PLATE_HEIGHT := 10
## The figure's top-left inside this node; the node sits at (2, 0), so the figure is at (6, -2).
const FIGURE_AT := Vector2(4, -2)
const FIGURE_SIZE := Vector2(48, 96)
## Where an arriving figure waits, off the left edge of the screen, and its walk in.
const ARRIVE_FROM_X := -60.0
const ARRIVE_SECONDS := 0.3
## A speaking soul's dip on each blip, and how long it stays down (blips come at most ~13 a second).
const BOB_PX := 1
const BOB_SECONDS := 0.05
## The frost's glint: these rime pixels of the frost plate (Fog 2) turn Parchment 2 for GLINT_HOLD
## seconds every GLINT_EVERY seconds.
const GLINT_PIXELS: Array[Vector2i] = [Vector2i(56, 1), Vector2i(57, 1), Vector2i(57, 2)]
const GLINT_EVERY := 2.0
const GLINT_HOLD := 0.2

@export var stacks: BodyStacks = null
@export var plate_plain: Texture2D = null
@export var plate_frost: Texture2D = null
@export var plate_hel: Texture2D = null
## Shown when an encounter has no stack (a development stand-in).
@export var placeholder_path: String = "res://docs/art/frames/soul.png"

## Set by `prepare_arrival`: the next soul shown waits off-screen until `arrive`.
var arrive_pending: bool = false
## Reduce motion (D37): a speaking soul's plate still lights, but it never bobs.
var reduce_motion: bool = false

var _figure: DragSource = null
var _plate: Control = null
var _name: Label = null
var _plate_label: String = ""
var _plate_texture: Texture2D = null
var _arrival: Tween = null
var _speaking: bool = false
var _bob: Tween = null
var _glint := IdleCycle.new(2, GLINT_EVERY - GLINT_HOLD, GLINT_EVERY - GLINT_HOLD, GLINT_HOLD)
var _paused: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure = DragSource.new()
	_figure.name = "Figure"
	_figure.kind = &"soul"
	_figure.position = FIGURE_AT
	_figure.size = FIGURE_SIZE
	_figure.mouse_entered.connect(func() -> void: figure_hover_started.emit())
	_figure.mouse_exited.connect(func() -> void: figure_hover_ended.emit())
	add_child(_figure)
	_plate = Control.new()
	_plate.name = "Plate"
	_plate.mouse_filter = Control.MOUSE_FILTER_STOP
	_plate.position = Vector2(0, size.y - PLATE_HEIGHT)
	_plate.size = Vector2(size.x, PLATE_HEIGHT)
	_plate.draw.connect(_draw_plate)
	_plate.mouse_entered.connect(_on_plate_entered)
	_plate.mouse_exited.connect(func() -> void: plate_hover_ended.emit())
	add_child(_plate)
	_name = Label.new()
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.position = Vector2(3, -3)
	_name.add_theme_color_override(&"font_color", get_theme_color(&"text_light", &"DeskPalette"))
	_plate.add_child(_name)
	show_soul(null)


## Shows the soul at the desk; null empties the gate.
func show_soul(encounter: Encounter) -> void:
	_stop_arrival()
	visible = encounter != null
	if encounter == null:
		arrive_pending = false
		_figure.layers = []
		_figure.position = FIGURE_AT
		return
	_figure.position = Vector2(ARRIVE_FROM_X, FIGURE_AT.y) if arrive_pending else FIGURE_AT
	_name.visible = not arrive_pending
	_name.text = encounter.soul_name
	_plate_label = encounter.plate_label
	var layers: Array[Texture2D] = []
	if stacks != null:
		layers = stacks.soul_layers(encounter.id)
	if layers.is_empty():
		var stand_in: Texture2D = PlaceholderArt.load_texture(placeholder_path)
		if stand_in != null:
			layers = [stand_in]
	_figure.layers = layers
	_plate_texture = plate_plain
	if encounter.hel_marked:
		_plate_texture = plate_hel
	elif encounter.returned:
		_plate_texture = plate_frost
	_glint.reset()
	_plate.queue_redraw()


func soul_name() -> String:
	return _name.text if visible else ""


func figure() -> DragSource:
	return _figure


## The plate drawn now (tests).
func plate_texture() -> Texture2D:
	return _plate_texture


## The next soul shown waits off-screen for `arrive` (the walk-in after a stamp, D15).
func prepare_arrival() -> void:
	arrive_pending = true


## Walks the waiting figure in from the left over `seconds` (0 places it at once) and puts its
## name on the plate. Returns the walk's tween, or null when there was nothing to walk or no time.
func arrive(seconds: float = ARRIVE_SECONDS) -> Tween:
	if not arrive_pending:
		return null
	arrive_pending = false
	_name.visible = true
	_stop_arrival()
	if seconds <= 0.0 or not is_inside_tree():
		_figure.position = FIGURE_AT
		return null
	_arrival = create_tween()
	_arrival.tween_property(_figure, "position", FIGURE_AT, seconds)
	return _arrival


func is_arriving() -> bool:
	return arrive_pending or (_arrival != null and _arrival.is_valid())


## The walk-in skipped: the figure stands in its place at once.
func finish_arrival() -> void:
	arrive_pending = false
	_name.visible = true
	_stop_arrival()
	_figure.position = FIGURE_AT


## Whether the figure can be picked up (not while a stamped soul waits, D48).
func set_draggable(on: bool) -> void:
	_figure.enabled = on


## The soul tells its tale (on) or has finished (off): while on, the plate lights, its name in
## text_light on a select_light backing (D4). Off also ends a bob under way.
func set_speaking(on: bool) -> void:
	_speaking = on
	if not on:
		_stop_bob()
	_plate.queue_redraw()


func is_speaking() -> bool:
	return _speaking


## One voice blip while speaking: the figure dips `BOB_PX` and comes back after `BOB_SECONDS`
## (D17). Only its height moves, so a walk-in under way keeps its course. Nothing while silent,
## under reduce motion or outside the tree. Returns the bob's tween, or null.
func bob() -> Tween:
	if not _speaking or reduce_motion or not is_inside_tree():
		return null
	_stop_bob()
	_figure.position.y = FIGURE_AT.y + BOB_PX
	_bob = create_tween()
	_bob.tween_interval(BOB_SECONDS)
	_bob.tween_callback(_lift)
	return _bob


## True while the frost plate's glint shows (never while speaking or under reduce motion).
func is_glinting() -> bool:
	return (
		_plate_texture != null
		and _plate_texture == plate_frost
		and not _speaking
		and not reduce_motion
		and _glint.frame() == 1
	)


## The gate's pause holds the glint where it is.
func set_paused(paused: bool) -> void:
	_paused = paused


func _process(delta: float) -> void:
	if _paused or reduce_motion or _plate_texture != plate_frost or not is_visible_in_tree():
		return
	if _glint.advance(delta):
		_plate.queue_redraw()


## The lit plate's backing inside the plate's 1 px rim, in the plate's pixels (tests).
func speaking_backing() -> Rect2:
	return Rect2(Vector2.ONE, _plate.size - Vector2(2, 2))


func _draw_plate() -> void:
	if _plate_texture != null:
		_plate.draw_texture(_plate_texture, Vector2.ZERO)
	else:
		_plate.draw_rect(
			Rect2(Vector2.ZERO, _plate.size), get_theme_color(&"plate", &"DeskPalette")
		)
	if _speaking:
		_plate.draw_rect(speaking_backing(), get_theme_color(&"select_light", &"DeskPalette"))
	elif is_glinting():
		var glint: Color = get_theme_color(&"parchment_light", &"DeskPalette")
		for at: Vector2i in GLINT_PIXELS:
			_plate.draw_rect(Rect2(Vector2(at), Vector2.ONE), glint)


func _stop_bob() -> void:
	if _bob != null and _bob.is_valid():
		_bob.kill()
	_bob = null
	_lift()


func _lift() -> void:
	_figure.position.y = FIGURE_AT.y


func _on_plate_entered() -> void:
	plate_hover_started.emit(_plate_label, _plate.get_global_rect())


func _stop_arrival() -> void:
	if _arrival != null and _arrival.is_valid():
		_arrival.kill()
	_arrival = null
