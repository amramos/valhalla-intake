# gdlint: disable=max-public-methods
class_name StampPrompt
extends Control
## The writ and the stamp under the doors (D9, D14, D15, D54-D56). The writ always carries the name
## of the soul at the desk. Asking raises the stamp (a 28×28 block on its handle) 8 px over the
## writ, its 1 px shadow on the paper below and its top over the foot of the door behind, with
## "<Realm>?" beside it, and the desk dims (0.25) under everything but the writ, the stamp and the
## doors; the stamp is the guarded confirm (a double-click or a press before it arms does nothing),
## and it commits on the press. A right-click on it withdraws it (the desk's stamp flow also
## withdraws it on any click elsewhere). The slam squashes the stamp, presses its 2× glyph into the
## writ, which dents and flashes with the stamp (the brightest instant) before the veil darkens to
## 0.55, bursts ink outward from the block and, as the stamp lifts, sends a shockwave round the ink;
## all timed, never counted in frames. The sweep slides the writ off the desk edge, and the next
## soul's writ comes up in its place. Nothing here reads anything but a name and a realm: no slam
## can tell a liar from a hero.

signal confirmed(realm: StringName)
signal cancelled
## The held writ was clicked: send the stamped soul on (D15).
signal send_on_requested
signal hover_started(text: String, area: Rect2)
signal hover_ended

enum State { IDLE, ASKING, PRESSED, INKED }

## The stamp's top when raised and when on the paper (its face on the ink box), in this node's
## pixels; it rises 8 px from the paper over RISE_SECONDS when asked. Raised, its click target
## stands over the doors' feet by 24 px at most (22 px: D54's rule, widened for the 28 px block).
const RAISED_Y := -10.0
const CONTACT_Y := -2.0
## The ink box's centre in this node's pixels (the writ sits at (90, 15)): the shockwave's centre.
const INK_CENTER := Vector2(162.5, 24.5)
## The veil (D56): while the stamp is raised, and from the impact until the lift.
const CHOICE_DIM := 0.25
const IMPACT_DIM := 0.55
const RISE_SECONDS := 0.08
## From the impact (D54-D56), in seconds, never frames: the flash's end (the veil deepens), the
## burst's middle and far stages and its end, the squash and the writ's dent, the lift (the veil
## goes, the shockwave starts), the shockwave's wide stage and its end.
const FLASH_SECONDS := 0.03
const BURST_MID_SECONDS := 0.03
const BURST_FAR_SECONDS := 0.06
const BURST_SECONDS := 0.09
const SQUASH_SECONDS := 0.06
const DENT_SECONDS := 0.06
const LIFT_SECONDS := 0.15
const WAVE_WIDE_SECONDS := 0.2
const WAVE_SECONDS := 0.25
## The writ slides down off the desk edge, then the next one slides up.
const SWEEP_SECONDS := 0.2
const COME_UP_SECONDS := 0.15
## Columns between the stamp's block and its question: 3 empty columns, so the first letter never
## reads as clipped by the block; "Fólkvangr?" (55 px) then ends 2 px inside the prompt's edge.
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
## The impact's ring and yield (ImpactMarks); built in _ready.
var _impact: ImpactMarks = null

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
	var lifted: Array[CanvasItem] = [_slot, _face, _question, _stamp]
	var block := Rect2i(
		Vector2i(_face.position.x, int(CONTACT_Y) + StampFace.HANDLE_HEIGHT),
		Vector2i(StampFace.SIZE.x, StampFace.BLOCK_HEIGHT)
	)
	_impact = ImpactMarks.new(self, INK_CENTER, block, lifted)


## Raises the stamp for `p_realm` over the writ of `soul_name`. Returns the rise's tween, for the
## presentation gate's pause (null when it rises at once).
func ask(soul_name: String, p_realm: StringName) -> Tween:
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
	_choice_veil()
	_face.position.y = CONTACT_Y
	if not reduce_motion and is_inside_tree():
		_motion = create_tween()
		_motion.tween_property(_face, "position:y", RAISED_Y, RISE_SECONDS)
	else:
		_face.position.y = RAISED_Y
	# Asking again (another door) restarts the arm time, as a fresh stamp would.
	_stamp.rearm()
	return _motion


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
	_face.position.y = CONTACT_Y
	# The choice is made but the stamp has not landed: the desk stays dimmed for the hold.
	_choice_veil()


## The impact: the stamp squashes on the paper, the glyph is inked on the writ in Ink and the writ
## dents; then the stamp lifts away and the ink rings. The same for every soul and realm but its
## glyph (D14). Returns the lift's tween (null when there is no tree to run it).
func slam(p_realm: StringName) -> Tween:
	if _state != State.PRESSED:
		stamp_down(p_realm)
	_state = State.INKED
	_stop_motion()
	_writ.set_ink(GLYPHS.get(p_realm, &""))
	if not is_inside_tree():
		_face.visible = false
		return null
	_face.set_squashed(true)
	_writ.set_dented(true)
	# The hit is the brightest instant: the writ and the stamp flash while the doors yield to the
	# choice's veil, which deepens only as the flash ends. Under reduce motion there is no flash and
	# no veil (D37, D55); the squash, the ink, the dent, the burst and the shockwave stay as cues.
	_set_flash(not reduce_motion)
	_impact.set_veil(0.0 if reduce_motion else CHOICE_DIM)
	_impact.set_burst(1)
	_motion = _timeline(
		[
			[FLASH_SECONDS, _end_flash],
			[BURST_MID_SECONDS, _impact.set_burst.bind(2)],
			[SQUASH_SECONDS, _face.set_squashed.bind(false)],
			[DENT_SECONDS, _writ.set_dented.bind(false)],
			[BURST_FAR_SECONDS, _impact.set_burst.bind(3)],
			[BURST_SECONDS, _impact.set_burst.bind(0)],
			[LIFT_SECONDS, _lift],
			[WAVE_WIDE_SECONDS, _impact.set_ring.bind(2)],
			[WAVE_SECONDS, _impact.set_ring.bind(0)],
		]
	)
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


## True while the shockwave shows round the ink box (D56).
func is_ringing() -> bool:
	return _impact.ring_stage() > 0


## True while the veil dims the desk (D55, D56).
func is_dimming() -> bool:
	return _impact.is_dimming()


## The marks (veil, burst, shockwave): the desk lifts the doors with them and suspends the veil
## under the pause (StampFlow); tests read them.
func marks() -> ImpactMarks:
	return _impact


## Simulates the player's click on the held writ (tests and tools).
func send_on() -> void:
	if is_held():
		send_on_requested.emit()


## Reduce motion turned on mid-presentation, under the pause say (D37): the rise and the sweep
## take their end states at once and the veil its reduce-motion state (none), so the raised stamp
## is the cue. A slam under way keeps its timing and its cues (the ink, the squash, the dent, the
## burst, the shockwave) and loses only its flash and veil.
func settle_motion() -> void:
	reduce_motion = true
	_finish_sweep()
	match _state:
		State.ASKING:
			if _motion != null and _motion.is_valid():
				_motion.kill()
			_motion = null
			_face.position.y = RAISED_Y
			_choice_veil()
		State.PRESSED:
			_choice_veil()
		State.INKED:
			_set_flash(false)
			_impact.set_veil(0.0)


## Every movement stopped and the writ clean, with the latest name: a restart.
func reset_writ() -> void:
	_stop_motion()
	if _sweep_running():
		_sweep.kill()
	_sweep = null
	_set_held_now(false)
	_show_stamp(false)
	_end_sweep()


## The stamp comes off the paper: it is gone, the veil lifts, and the ink it left rings for a
## moment (D54).
func _lift() -> void:
	_face.visible = false
	_impact.set_veil(0.0)
	_impact.set_ring(1)


func _set_flash(on: bool) -> void:
	_face.set_flash(on)
	_writ.set_flash(on)


## The flash ends and the desk yields under the impact's veil; none under reduce motion, read when
## the flash ends so that turning it on mid-slam holds (`settle_motion`).
func _end_flash() -> void:
	_set_flash(false)
	_impact.set_veil(0.0 if reduce_motion else IMPACT_DIM)


## The desk dims while the stamp is raised (D56); under reduce motion the raised stamp is the cue.
func _choice_veil() -> void:
	_impact.set_veil(0.0 if reduce_motion else CHOICE_DIM, true)


## A tween that calls each [seconds, callable] at its time from now, in order.
func _timeline(events: Array) -> Tween:
	events.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var tween: Tween = create_tween()
	var at: float = 0.0
	for event: Array in events:
		var when: float = event[0]
		if when > at:
			tween.tween_interval(when - at)
			at = when
		var call: Callable = event[1]
		tween.tween_callback(call)
	return tween


func _set_name_now(soul_name: String) -> void:
	_writ.set_soul_name(soul_name)
	_slot.visible = soul_name != ""


func _set_held_now(held: bool) -> void:
	_writ.set_held(held)


## The raised stamp, its question and its shadow on the writ (D37 keeps the shadow: a state cue).
func _show_stamp(shown: bool) -> void:
	_stamp.visible = shown
	_face.visible = shown
	_question.visible = shown
	_writ.set_shadow(_shadow_area() if shown else Rect2i())


## The raised stamp's shadow in the writ's pixels: 2 px narrower than the block on each side, one
## row above the row its face lands on, so a parchment row keeps it apart from the paper's own
## shadow under the writ's edge.
func _shadow_area() -> Rect2i:
	var row := Vector2(_face.position.x + 2, CONTACT_Y + StampFace.SIZE.y - 2) - _slot.position
	return Rect2i(Vector2i(row), Vector2i(StampFace.SIZE.x - 4, 1))


## The question sits right of the stamp; the click target covers both.
func _arrange() -> void:
	_question.size = Vector2.ZERO
	_question.position.x = _face.position.x + StampFace.SIZE.x + GAP
	var width: float = _question.position.x + _question.get_minimum_size().x - _face.position.x
	_stamp.position = Vector2(_face.position.x, RAISED_Y)
	_stamp.size = Vector2(width, StampFace.SIZE.y + CONTACT_Y - RAISED_Y)


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


## Stops the rise or the slam's lift under way; a squash or a ring it timed ends with it.
func _stop_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null
	_face.set_squashed(false)
	_set_flash(false)
	_writ.set_dented(false)
	_impact.set_ring(0)
	_impact.set_burst(0)
	_impact.set_veil(0.0)


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
