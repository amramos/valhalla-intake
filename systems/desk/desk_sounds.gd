class_name DeskSounds
extends RefCounted
## The desk's sound players by name (D25, D41): each plays only from inside the tree and with a
## stream, every one follows the player's master volume and mute (D37), and the presentation gate
## watches them so the pause stops them.

## A sound was started, at this pitch. Emitted as the call is made, so a test can follow the
## sounds step by step without reading `AudioStreamPlayer.playing`, which follows the real audio
## clock.
signal played(sound: StringName, pitch_scale: float)
## A sound was stopped.
signal stopped(sound: StringName)

## A muted player is silent at this level.
const MUTED_DB := -80.0

var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _muted: bool = false


## `players`: name -> player; a null player is left out (a desk without that sound).
func _init(players: Dictionary[StringName, AudioStreamPlayer], gate: PresentationGate) -> void:
	for sound: StringName in players:
		var player: AudioStreamPlayer = players[sound]
		if player == null:
			continue
		_players[sound] = player
		gate.watch_player(player)


func use_options(options: Options) -> void:
	_muted = options.muted
	for sound: StringName in _players:
		_players[sound].volume_db = MUTED_DB if options.muted else options.volume_db


## Plays `sound` at `pitch_scale` (a voice's blip); nothing when muted or absent.
func play(sound: StringName, pitch_scale: float = 1.0) -> void:
	var player: AudioStreamPlayer = _players.get(sound, null)
	if _muted or player == null or player.stream == null or not player.is_inside_tree():
		return
	player.pitch_scale = pitch_scale
	player.play()
	played.emit(sound, pitch_scale)


## Stops `sound` where it is (a skipped tale's blip).
func stop(sound: StringName) -> void:
	var player: AudioStreamPlayer = _players.get(sound, null)
	if player != null:
		player.stop()
		stopped.emit(sound)


func player(sound: StringName) -> AudioStreamPlayer:
	return _players.get(sound, null)
