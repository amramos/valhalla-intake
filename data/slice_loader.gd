class_name SliceLoader
extends RefCounted
## Loads the slice's data and returns a DeskCommands at day-1 dawn, in one call.

const SLICE_PATH := "res://data/slice.tres"


static func load_slice(path: String = SLICE_PATH) -> DeskCommands:
	var desk := DeskCommands.new()
	var slice: SliceData = load(path) as SliceData
	if slice == null:
		push_error("SliceLoader: no SliceData at %s" % path)
		return desk
	slice.start(desk)
	return desk
