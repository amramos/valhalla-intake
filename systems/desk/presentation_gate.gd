class_name PresentationGate
extends Node
## The one owner of "a presentation is in progress" (ADR-0009, D27, D51). Consumers (a telling, a
## written reveal, the dawn card) begin with a finish callback; every mouse press reaches
## `on_press` first and is decided exactly one way:
## - consumed: a consumer is active; every consumer is finished and ended, and nothing else
##   happens (no pin, select, stamp, advance or acknowledge); its release is swallowed too;
## - ignored: the slam window is open; nothing is finished and the press does nothing;
## - passed: otherwise; the press goes on to the desk's controls.
## It also pauses and resumes the presentation clocks it watches (tellers, tweens, players)
## without `SceneTree.paused` or `Engine.time_scale`, and cancels them all on a restart.

## A press finished the consumers; `kind` is the oldest of them.
signal consumed(kind: StringName)
## The slam lock opened (by `slam_release` or `cancel_all`).
signal released
## The presentation clocks stopped (true) or resumed (false): anything that keeps its own clock (the
## note's hold, a door's flare) follows it, so the pause and focus loss stop every one.
signal pause_changed(paused: bool)

const TELLING := &"telling"
const WRITTEN := &"written"
const DAWN := &"dawn"
const KINDS: Array[StringName] = [TELLING, WRITTEN, DAWN]
## Finishing a consumer may begin another (the claim's end starts the witness's telling); a
## press finishes those too, up to this many rounds.
const MAX_FINISH_ROUNDS := 8
const WHEEL_BUTTONS: Array[int] = [
	MOUSE_BUTTON_WHEEL_UP,
	MOUSE_BUTTON_WHEEL_DOWN,
	MOUSE_BUTTON_WHEEL_LEFT,
	MOUSE_BUTTON_WHEEL_RIGHT
]

var _next_token: int = 1
## Active consumers in begin order: token -> {kind, finish}.
var _consumers: Dictionary[int, Dictionary] = {}
var _slamming: bool = false
var _paused: bool = false
## Mouse buttons whose release belongs to a press the gate took.
var _swallow: Dictionary[int, bool] = {}
var _tweens: Array[Tween] = []
var _players: Array[AudioStreamPlayer] = []
var _tellers: Array[Teller] = []
## What `set_paused(true)` actually paused, so a resume restarts only those.
var _paused_tweens: Array[Tween] = []
var _paused_players: Array[AudioStreamPlayer] = []
var _gated_seconds: float = 0.0


## Starts a consuming presentation of `kind` (TELLING, WRITTEN or DAWN); a consumed press calls
## `finish` once. Returns the token that ends it.
func begin(kind: StringName, finish: Callable) -> int:
	if not KINDS.has(kind):
		push_warning("PresentationGate: unknown consumer kind %s" % kind)
	var token: int = _next_token
	_next_token += 1
	_consumers[token] = {"kind": kind, "finish": finish}
	return token


## Ends a consumer without finishing it (it finished by itself); an ended token is ignored.
func end(token: int) -> void:
	_consumers.erase(token)


func is_consuming() -> bool:
	return not _consumers.is_empty()


## Opens the slam window: every press is ignored until `slam_release`.
func slam_lock() -> void:
	_slamming = true


func slam_release() -> void:
	if not _slamming:
		return
	_slamming = false
	released.emit()


func is_slamming() -> bool:
	return _slamming


## Decides a mouse button event; true means the caller must mark it handled (consumed, ignored
## or a swallowed release). The wheel is never a press and always passes.
func on_press(event: InputEventMouseButton) -> bool:
	if WHEEL_BUTTONS.has(event.button_index):
		return false
	if not event.pressed:
		return _swallow.erase(event.button_index)
	# A press means any earlier release of this button already came (or was lost).
	_swallow.erase(event.button_index)
	if _slamming:
		_swallow[event.button_index] = true
		return true
	if _consumers.is_empty():
		return false
	_swallow[event.button_index] = true
	var kind: StringName = _consumers[_consumers.keys()[0]]["kind"]
	_finish_all()
	consumed.emit(kind)
	return true


## Pauses watched tweens and players while paused, and gives the tween back to the gate's
## restart (`cancel_all`). Finished tweens are dropped on their own.
func watch_tween(tween: Tween) -> void:
	_prune()
	if tween == null or _tweens.has(tween):
		return
	_tweens.append(tween)
	if _paused and tween.is_valid() and tween.is_running():
		tween.pause()
		_paused_tweens.append(tween)


func watch_player(player: AudioStreamPlayer) -> void:
	if player == null or _players.has(player):
		return
	_players.append(player)
	if _paused and player.playing:
		player.stream_paused = true
		_paused_players.append(player)


func register_teller(teller: Teller) -> void:
	if teller == null or _tellers.has(teller):
		return
	_tellers.append(teller)
	teller.set_paused(_paused)


## Stops (true) or resumes (false) every watched tween, player and registered teller, and the
## gated-seconds count, without touching the scene tree's pause or the time scale.
func set_paused(paused: bool) -> void:
	if paused == _paused:
		return
	_paused = paused
	_prune()
	for teller: Teller in _tellers:
		teller.set_paused(paused)
	pause_changed.emit(paused)
	if paused:
		for tween: Tween in _tweens:
			if tween.is_running():
				tween.pause()
				_paused_tweens.append(tween)
		for player: AudioStreamPlayer in _players:
			if player.playing:
				player.stream_paused = true
				_paused_players.append(player)
		return
	for tween: Tween in _paused_tweens:
		if tween.is_valid():
			tween.play()
	for player: AudioStreamPlayer in _paused_players:
		player.stream_paused = false
	_paused_tweens.clear()
	_paused_players.clear()


func is_paused() -> bool:
	return _paused


## A restart: kills every watched tween, stops every player the pause holds (so a resume never
## plays the old run's sound), ends every consumer without finishing it, and opens the slam lock
## (emitting `released` if it was shut). Tellers and the pause itself stay as they are.
func cancel_all() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_paused_tweens.clear()
	_prune()
	for player: AudioStreamPlayer in _paused_players:
		player.stop()
		player.stream_paused = false
	_paused_players.clear()
	_consumers.clear()
	slam_release()


## Seconds spent consuming or slamming while not paused: the forced time desk-shots measures.
func gated_seconds() -> float:
	return _gated_seconds


func reset_gated_seconds() -> void:
	_gated_seconds = 0.0


func _process(delta: float) -> void:
	if not _paused and (is_consuming() or _slamming):
		_gated_seconds += delta


func _finish_all() -> void:
	for _round: int in range(MAX_FINISH_ROUNDS):
		if _consumers.is_empty():
			return
		var finishing: Array[Dictionary] = []
		for token: int in _consumers:
			finishing.append(_consumers[token])
		_consumers.clear()
		for consumer: Dictionary in finishing:
			var finish: Callable = consumer["finish"]
			if finish.is_valid():
				finish.call()
	_consumers.clear()


## Drops finished tweens and freed nodes. Checked by index: a freed node can't be assigned to a
## typed loop variable.
func _prune() -> void:
	for index: int in range(_tweens.size() - 1, -1, -1):
		if not _tweens[index].is_valid():
			_tweens.remove_at(index)
	for index: int in range(_players.size() - 1, -1, -1):
		if not is_instance_valid(_players[index]):
			_players.remove_at(index)
	for index: int in range(_tellers.size() - 1, -1, -1):
		if not is_instance_valid(_tellers[index]):
			_tellers.remove_at(index)
	for index: int in range(_paused_players.size() - 1, -1, -1):
		if not is_instance_valid(_paused_players[index]):
			_paused_players.remove_at(index)
