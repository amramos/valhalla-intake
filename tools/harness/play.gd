extends SceneTree
## Plays the slice as text, one command per run:
##   godot --headless -s tools/harness/play.gd -- <session-file> [command...]
## Replays the session file's commands (one per line), runs the new command, appends it if the desk
## accepted it, then prints its result, describe() and actions(). "new" empties the session.

const Harness := preload("res://tools/harness/harness.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless -s tools/harness/play.gd -- <session-file> [command...]")
		quit(1)
		return
	var path: String = args[0]
	var command: String = " ".join(args.slice(1)).strip_edges()
	var harness: Harness = Harness.new(SliceLoader.load_slice())
	var history: Array[String] = []
	if command != "new":
		history = _read(path)
	for line: String in history:
		harness.act(line)
	var result: String = ""
	if command == "new":
		result = "A new session."
		_write(path, history)
	elif command != "":
		result = harness.act(command)
		if harness.last_ok:
			history.append(command)
			_write(path, history)
	if result != "":
		print("> %s\n%s\n" % [command, result])
	print(harness.describe())
	print("")
	print(harness.actions())
	quit()


func _read(path: String) -> Array[String]:
	var lines: Array[String] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return lines
	for line: String in file.get_as_text().split("\n", false):
		var command: String = line.strip_edges()
		if command != "" and not command.begins_with("#"):
			lines.append(command)
	return lines


func _write(path: String, history: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("play.gd: can't write the session file %s" % path)
		return
	file.store_string("\n".join(history) + ("\n" if not history.is_empty() else ""))
