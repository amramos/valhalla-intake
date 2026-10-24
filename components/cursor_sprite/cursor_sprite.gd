class_name CursorSprite
extends CanvasLayer
## The in-scene cursor (D13, D48): a pixel pointer on a top canvas layer that follows the mouse in
## whole pixels, so it stays pixel-consistent at every integer scale with no OS cursor sizing. It
## carries a pin while an item is selected and becomes a grab hand over the waiting soul and while
## anything is dragged. The OS cursor is hidden while the mouse moves inside the window and comes
## back when the mouse leaves it or the window loses focus, and stays back until the mouse comes
## in again (or the window is focused again): an event that arrives meanwhile (a drag's capture),
## or one outside the viewport, never claims it.
##
## It never takes input: its sprite ignores the mouse and no event is marked handled, so a press
## lands on whatever lies under the hotspot pixel. Reduce motion does not apply (it is a cursor).

enum Shape { POINTER, PIN, GRAB }

## Above every other layer of the game.
const LAYER := 100
## The shapes row by row: "#" ink, "o" fill, "s" shadow. The hotspot is the pixel the mouse is on.
## The ink is 2 px on the right and bottom and a Night 1 shadow lines the fill inside it, so the
## shape reads both on the parchment sheets (where the fill vanishes) and on the dark band.
const POINTER: Array[String] = [
	"#......",
	"##.....",
	"#o##...",
	"#os##..",
	"#oos##.",
	"#ooos##",
	"#ss####",
	"#######",
	"####...",
]
const GRAB: Array[String] = [
	".#.#.#...",
	"#o#o#o##.",
	"#o#o#o###",
	"#oooos###",
	"#ooooos##",
	"#ssssss##",
	"#########",
	".#######.",
	"..#####..",
]
const POINTER_HOTSPOT := Vector2i(0, 0)
## A hand grabs with its palm.
const GRAB_HOTSPOT := Vector2i(4, 4)
## The carried pin's 5×5 head nestles under the pointer's base, clear of its tip.
const PIN_AT := Vector2i(4, 7)
## The sprite's box holds every shape; it ignores the mouse, so presses fall through it.
const BOX := Vector2(9, 12)

## Night 0, the darkest ink.
@export var ink: Color = Color(0.0431, 0.0902, 0.1333, 1)
## Parchment 2.
@export var fill: Color = Color(0.9647, 0.9333, 0.8235, 1)
## Night 1, the inner shadow along the fill's right and bottom.
@export var shadow: Color = Color(0.0588, 0.1451, 0.1882, 1)
## The carried pin: Ember 2 head, a Parchment 2 highlight and an Ember 0 shadow, as the stuck pin.
@export var pin_color: Color = Color(0.8784, 0.5412, 0.2902, 1)
@export var pin_highlight: Color = Color(0.9647, 0.9333, 0.8235, 1)
@export var pin_shadow: Color = Color(0.4196, 0.1843, 0.1176, 1)

var _sprite: Control = null
var _tip := Vector2i.ZERO
var _carrying_pin: bool = false
var _grab: bool = false
var _dragging: bool = false
## True while this cursor keeps the OS cursor hidden (the mouse is inside the window).
var _hiding_os: bool = false
## The mouse left the window and has not come back in.
var _outside: bool = false
## The window lost focus and has not got it back.
var _unfocused: bool = false


func _init() -> void:
	layer = LAYER
	name = "Cursor"
	_sprite = Control.new()
	_sprite.name = "Sprite"
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.size = BOX
	_sprite.visible = false
	_sprite.draw.connect(_draw_sprite)
	add_child(_sprite)


func _ready() -> void:
	# A real mouse already inside the window (the scene was just changed under it) takes the
	# cursor at once; a headless run has no mouse and waits for the first event.
	if DisplayServer.get_name() == "headless" or not get_window().has_focus():
		return
	var at: Vector2 = _sprite.get_viewport().get_mouse_position()
	if _sprite.get_viewport_rect().has_point(at):
		move_to(at)


func _exit_tree() -> void:
	_release()


## Puts the hotspot on the pixel under `at` (viewport pixels) and shows the cursor, while the
## mouse is in the focused window and `at` is inside the viewport; otherwise the OS cursor stays.
func move_to(at: Vector2) -> void:
	if _outside or _unfocused or not is_inside_tree():
		return
	if not _sprite.get_viewport_rect().has_point(at):
		_release()
		return
	_tip = Vector2i(floori(at.x), floori(at.y))
	_place()
	_sprite.visible = true
	if not _hiding_os:
		_hiding_os = true
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## An item is selected (the pin gesture is half made): the pointer carries a pin.
func set_carrying_pin(on: bool) -> void:
	_carrying_pin = on
	_place()


## Over something that can be picked up (the waiting soul): the grab hand.
func set_grab(on: bool) -> void:
	_grab = on
	_place()


func is_dragging() -> bool:
	return _dragging


func shape() -> Shape:
	if _grab or _dragging:
		return Shape.GRAB
	return Shape.PIN if _carrying_pin else Shape.POINTER


func hotspot() -> Vector2i:
	return GRAB_HOTSPOT if shape() == Shape.GRAB else POINTER_HOTSPOT


## The pixel the mouse is on, which the hotspot covers (viewport pixels).
func tip() -> Vector2i:
	return _tip


func sprite() -> Control:
	return _sprite


func is_shown() -> bool:
	return _sprite.visible


## Whether this cursor keeps the OS cursor hidden now.
func hides_os_cursor() -> bool:
	return _hiding_os


## The shape drawn now, pixel by pixel in the sprite's own pixels (the hotspot at `hotspot()`).
func pixels() -> Dictionary[Vector2i, Color]:
	var out: Dictionary[Vector2i, Color] = {}
	var rows: Array[String] = GRAB if shape() == Shape.GRAB else POINTER
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			match rows[y][x]:
				"#":
					out[Vector2i(x, y)] = ink
				"o":
					out[Vector2i(x, y)] = fill
				"s":
					out[Vector2i(x, y)] = shadow
	if shape() == Shape.PIN:
		var paint: Callable = func(rect: Rect2, color: Color) -> void:
			for py: int in range(int(rect.size.y)):
				for px: int in range(int(rect.size.x)):
					out[Vector2i(rect.position) + Vector2i(px, py)] = color
		PinSelectable.draw_pin_head(paint, PIN_AT, pin_color, pin_highlight, pin_shadow)
	return out


func _input(event: InputEvent) -> void:
	var mouse: InputEventMouse = event as InputEventMouse
	if mouse != null:
		move_to(mouse.position)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			_dragging = true
			_place()
		NOTIFICATION_DRAG_END:
			_dragging = false
			_place()
		NOTIFICATION_WM_MOUSE_EXIT:
			_outside = true
			_release()
		NOTIFICATION_WM_MOUSE_ENTER:
			_outside = false
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_unfocused = true
			_release()
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_IN:
			_unfocused = false


## The hotspot stays on the mouse's pixel whatever the shape: a change of shape (the hand's
## hotspot is its palm) moves the sprite at once, with no mouse event needed.
func _place() -> void:
	_sprite.position = Vector2(_tip - hotspot())
	_sprite.queue_redraw()


## The mouse left the window or the window lost focus: the OS cursor comes back, ours hides until
## the mouse moves inside again.
func _release() -> void:
	_sprite.visible = false
	if not _hiding_os:
		return
	_hiding_os = false
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _draw_sprite() -> void:
	var drawn: Dictionary[Vector2i, Color] = pixels()
	for at: Vector2i in drawn:
		_sprite.draw_rect(Rect2(Vector2(at), Vector2.ONE), drawn[at])
