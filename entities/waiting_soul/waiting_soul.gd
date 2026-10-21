class_name WaitingSoul
extends Control
## The soul waiting at the gate, with its name plate (D4, D21). The figure is identity only: its
## layers are the chart's front view cropped (BodyStacks), so it shows nothing the chart doesn't.
## It can be dragged onto a door (D9). The plate is plain, frost-burned for a returned soul, or
## carries Hel's mark; it hovers the encounter's plate label.

signal plate_hover_started(text: String, area: Rect2)
signal plate_hover_ended

const PLATE_HEIGHT := 10
## The figure's top-left inside this node; the node sits at (2, 0), so the figure is at (6, -2).
const FIGURE_AT := Vector2(4, -2)
const FIGURE_SIZE := Vector2(48, 96)

@export var stacks: BodyStacks = null
@export var plate_plain: Texture2D = null
@export var plate_frost: Texture2D = null
@export var plate_hel: Texture2D = null
## Shown when an encounter has no stack (a development stand-in).
@export var placeholder_path: String = "res://docs/art/frames/soul.png"

var _figure: DragSource = null
var _plate: Control = null
var _name: Label = null
var _plate_label: String = ""
var _plate_texture: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure = DragSource.new()
	_figure.name = "Figure"
	_figure.kind = &"soul"
	_figure.position = FIGURE_AT
	_figure.size = FIGURE_SIZE
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
	visible = encounter != null
	if encounter == null:
		_figure.layers = []
		return
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
	_plate.queue_redraw()


func soul_name() -> String:
	return _name.text if visible else ""


func figure() -> DragSource:
	return _figure


## The plate drawn now (tests).
func plate_texture() -> Texture2D:
	return _plate_texture


## Whether the figure can be picked up (not while a stamped soul waits, D48).
func set_draggable(on: bool) -> void:
	_figure.enabled = on


func _draw_plate() -> void:
	if _plate_texture != null:
		_plate.draw_texture(_plate_texture, Vector2.ZERO)
	else:
		_plate.draw_rect(
			Rect2(Vector2.ZERO, _plate.size), get_theme_color(&"plate", &"DeskPalette")
		)


func _on_plate_entered() -> void:
	plate_hover_started.emit(_plate_label, _plate.get_global_rect())
