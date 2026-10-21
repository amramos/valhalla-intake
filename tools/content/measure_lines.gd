extends SceneTree
## Development only: measures every claim and witness line of the evidence matrix in m5x7, prefix
## included, against the D50 cap (132 px). Prints each line over the cap and the widest line, and
## exits 1 when any line runs over. With a second argument, it measures that file's lines instead
## (one candidate per line, written with its prefix, for example "C1 Danes axed my chest.").
##
##   godot --headless --path . -s tools/content/measure_lines.gd -- [matrix.md] [candidates.txt]

const FONT_PATH := "res://assets/fonts/m5x7.ttf"
const FONT_SIZE := 16
const CAP_PX := 132
const DEFAULT_MATRIX := "res://docs/plans/vertical-slice-matrix.md"

var _font: FontFile = null


func _initialize() -> void:
	# Read the font file directly, so the tool also runs in a checkout with no import cache.
	_font = FontFile.new()
	var error: Error = _font.load_dynamic_font(ProjectSettings.globalize_path(FONT_PATH))
	if error != OK:
		push_error("can't load %s (error %d)" % [FONT_PATH, error])
		quit(2)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var matrix_path: String = args[0] if args.size() > 0 else DEFAULT_MATRIX
	var rows: Array[PackedStringArray] = []
	if args.size() > 1:
		rows = _candidate_rows(args[1])
	else:
		rows = _matrix_rows(matrix_path)
	var over: int = 0
	var widest: int = 0
	var widest_text: String = ""
	for row: PackedStringArray in rows:
		var text: String = row[1]
		var width: int = width_of(text)
		if width > widest:
			widest = width
			widest_text = text
		if width > CAP_PX:
			over += 1
			print("OVER %3d px  [%s] %s" % [width, row[0], text])
		elif args.size() > 1:
			print("ok   %3d px  %s" % [width, text])
	print(
		(
			"lines: %d, over %d px: %d, widest: %d px (%s)"
			% [rows.size(), CAP_PX, over, widest, widest_text]
		)
	)
	quit(1 if over > 0 else 0)


## The width the text needs on one line, measured the way the evidence panel measures it.
func width_of(text: String) -> int:
	return int(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x) - 1


## Every claim and witness line in the matrix, as [section heading, "C1 text"].
func _matrix_rows(path: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var line_pattern: RegEx = RegEx.create_from_string('^\\| ([CW][0-9]) \\| (?:♥ )?"([^"]*)" \\|')
	var section: String = ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("can't open %s" % path)
		return rows
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.begins_with("### "):
			section = line.substr(4)
		var found: RegExMatch = line_pattern.search(line)
		if found != null:
			rows.append(
				PackedStringArray([section, "%s %s" % [found.get_string(1), found.get_string(2)]])
			)
	return rows


func _candidate_rows(path: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("can't open %s" % path)
		return rows
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if not line.is_empty():
			rows.append(PackedStringArray(["candidate", line]))
	return rows
