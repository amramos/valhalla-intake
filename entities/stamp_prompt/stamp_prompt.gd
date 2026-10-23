class_name StampPrompt
extends Control
## The writ and the stamp under the doors (D9, D14, D15). The writ always carries the name of the
## soul at the desk. Asking raises the stamp over the writ with the realm's glyph and "<Realm>?"
## beside it; the stamp is the guarded confirm (a double-click or a press before it arms does
## nothing), and it commits on the press. A right-click on it withdraws it (the desk's stamp flow
## also withdraws it on any click elsewhere). The slam inks the glyph on the writ; the sweep slides
## the writ off the desk edge, and the next soul's writ comes up in its place. Nothing here reads
## anything but a name and a realm: no slam can tell a liar from a hero (D14).

signal confirmed(realm: StringName)
signal cancelled
## The held writ was clicked: send the stamped soul on (D15).
signal send_on_requested
signal hover_started(text: String, area: Rect2)
signal hover_ended

enum State { IDLE, ASKING, PRESSED, INKED }

## The stamp's rise when asked, and its drop onto the writ on the press, in pixels and seconds.
const RISE_PX := 2
const RISE_SECONDS := 0.08
## How long the stamp stays on the paper after the impact before it lifts away.
const LIFT_SECONDS := 0.08
## The writ slides down off the desk edge, then the next one slides up.
const SWEEP_SECONDS := 0.2
const COME_UP_SECONDS := 0.15
const GAP := 3
## The realm doors' carved glyphs (as on the doors in the desk scene).
const GLYPHS: Dictionary[StringName, StringName] = {
	&"valhalla": &"spear", &"hel": &"serpent", &"folkvangr": &"boar", &"ran": &"wave"
}

## The realm asked or being stamped; &"" otherwise.
var realm: StringName = &""
## Every movement takes its end state at once (D37); the ink and its timing stay.
var reduce_motion: bool = false

var _state: State = State.IDLE
## The name the writ takes once the stamped one is swept off, while `_name_waits`.
var _pending_name: String = ""
var _name_waits: bool = false
var _motion: Tween = null
var _sweep: Tween = null

@onready var _slot: Control = $WritSlot
@onready var _writ: Writ = $WritSlot/Writ
@onready var _stamp: GuardedButton = $Stamp
@onready var _face: StampFace = $Face
@onready var _question: Label = $Question


func _ready() -> void:
	_stamp.pressed.connect(_on_stamp_pressed)
	_stamp.gui_input.connect(_on_stamp_gui_input)
	_writ.clicked.connect(func() -> void: send_on_requested.emit())
	_writ.hover_started.connect(
		func(text: String, area: Rect2) -> void: hover_started.emit(text, area)
	)
	_writ.hover_ended.connect(func() -> void: hover_ended.emit())
	_question.add_theme_color_override(
		&"font_color", get_theme_color(&"text_light", &"DeskPalette")
	)
	_show_stamp(false)
	_slot.visible = false


## Raises the stamp for `p_realm` over the writ of `soul_name`.
func ask(soul_name: String, p_realm: StringName) -> void:
	_finish_sweep()
	if _state == State.IDLE or _state == State.ASKING:
		_set_name_now(soul_name)
	realm = p_realm
	_state = State.ASKING
	_face.glyph = GLYPHS.get(p_realm, &"")
	_question.text = question_for(p_realm)
	_arrange()
	_show_stamp(true)
	_stop_motion()
	_face.position.y = RISE_PX
	if not reduce_motion and is_inside_tree():
		_motion = create_tween()
		_motion.tween_property(_face, "position:y", 0.0, RISE_SECONDS)
	else:
		_face.position.y = 0
	# Asking again (another door) restarts the arm time, as a fresh stamp would.
	_stamp.rearm()


static func question_for(p_realm: StringName) -> String:
	return "%s?" % Realm.display_name(p_realm)


## Puts the stamp down without stamping; nothing happens unless it was raised.
func withdraw() -> void:
	if _state != State.ASKING:
		return
	_stop_motion()
	_state = State.IDLE
	realm = &""
	_show_stamp(false)
	cancelled.emit()


func is_asking() -> bool:
	return _state == State.ASKING


## "<Realm>?" while the stamp is raised, "" otherwise.
func question() -> String:
	return _question.text if is_asking() else ""


func confirm_button() -> GuardedButton:
	return _stamp


## The stamp's click target in canvas coordinates (the prop and its question).
func stamp_rect() -> Rect2:
	return _stamp.get_global_rect()


## The writ's name. During a slam (and until the sweep) the stamped soul's name stays, and this one
## waits for the next writ; "" leaves no writ.
func set_soul_name(soul_name: String) -> void:
	if _state == State.PRESSED or _state == State.INKED or _sweep_running():
		_pending_name = soul_name
		_name_waits = true
		return
	_set_name_now(soul_name)


func soul_name() -> String:
	return _writ.soul_name() if _slot.visible else ""


func writ() -> Writ:
	return _writ


## The stamp comes down on the writ for `p_realm` (the press, or a drop on a door): from here the
## writ keeps its name until it is swept.
func stamp_down(p_realm: StringName) -> void:
	_finish_sweep()
	_stop_motion()
	realm = p_realm
	_state = State.PRESSED
	_face.glyph = GLYPHS.get(p_realm, &"")
	_show_stamp(false)
	_face.visible = true
	_face.position.y = RISE_PX


## The impact: the glyph inked on the writ in Ink, the stamp lifted away. Returns the lift's tween
## (null when there is no tree to run it).
func slam(p_realm: StringName) -> Tween:
	if _state != State.PRESSED:
		stamp_down(p_realm)
	_state = State.INKED
	_writ.set_ink(GLYPHS.get(p_realm, &""))
	_stop_motion()
	if not is_inside_tree():
		_face.visible = false
		return null
	_motion = create_tween()
	_motion.tween_interval(LIFT_SECONDS)
	_motion.tween_callback(func() -> void: _face.visible = false)
	return _motion


## Slides the stamped writ off the desk edge; the next soul's writ (if any) comes up in its place.
## Returns the tween (null when the end state was taken at once).
func sweep() -> Tween:
	_set_held_now(false)
	_finish_sweep()
	if reduce_motion or not is_inside_tree():
		_end_sweep()
		return null
	_sweep = create_tween()
	_sweep.tween_property(_writ, "position:y", float(Writ.SIZE.y + 1), SWEEP_SECONDS)
	# Under the edge the stamped writ becomes the next soul's, and comes up.
	_sweep.tween_callback(_swap_writ)
	_sweep.tween_property(_writ, "position:y", 0.0, COME_UP_SECONDS)
	_sweep.tween_callback(_end_sweep)
	return _sweep


## A held writ (D15) stays inked until clicked; its hover says "Send it on".
func set_held(held: bool) -> void:
	_set_held_now(held)


func is_held() -> bool:
	return _writ.is_held()


func is_inked() -> bool:
	return _writ.inked_glyph() != &""


## Simulates the player's click on the held writ (tests and tools).
func send_on() -> void:
	if is_held():
		send_on_requested.emit()


## Every movement stopped and the writ clean, with the latest name: a restart.
func reset_writ() -> void:
	_stop_motion()
	if _sweep_running():
		_sweep.kill()
	_sweep = null
	_set_held_now(false)
	_show_stamp(false)
	_end_sweep()


func _set_name_now(soul_name: String) -> void:
	_writ.set_soul_name(soul_name)
	_slot.visible = soul_name != ""


func _set_held_now(held: bool) -> void:
	_writ.set_held(held)


func _show_stamp(shown: bool) -> void:
	_stamp.visible = shown
	_face.visible = shown
	_question.visible = shown


## The question sits right of the stamp; the click target covers both.
func _arrange() -> void:
	_question.size = Vector2.ZERO
	_question.position.x = _face.position.x + StampFace.SIZE.x + GAP
	var width: float = _question.position.x + _question.get_minimum_size().x - _face.position.x
	_stamp.position = Vector2(_face.position.x, 0)
	_stamp.size = Vector2(width, StampFace.SIZE.y + RISE_PX)


## The stamped writ is gone: a clean one with the next soul's name (or none) takes its place.
func _swap_writ() -> void:
	_state = State.IDLE
	realm = &""
	_writ.set_ink(&"")
	if _name_waits:
		_set_name_now(_pending_name)
		_name_waits = false


func _end_sweep() -> void:
	_swap_writ()
	_writ.position.y = 0


func _finish_sweep() -> void:
	if not _sweep_running():
		return
	_sweep.kill()
	_sweep = null
	_end_sweep()


func _sweep_running() -> bool:
	# A paused sweep (the pause, through the gate) is still under way.
	return _sweep != null and _sweep.is_valid()


func _stop_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null


func _on_stamp_gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_RIGHT:
		withdraw()
		_stamp.accept_event()


func _on_stamp_pressed() -> void:
	if _state != State.ASKING or realm == &"":
		return
	var chosen: StringName = realm
	stamp_down(chosen)
	confirmed.emit(chosen)
