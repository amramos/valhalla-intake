class_name PixelCapitals
extends RefCounted
## The carved capitals for titles (D3): "DAY II", "Dusk", the game's name, the endings' names.
## Hand-placed in code, never a second font file and never on pinnable text. Each letter is a
## 6×9 face of 2 px stems and 1 px bars in Parchment 2 (or the colour given), ringed by a 1 px Ink
## outline (8×11 with it), with a 1 px Night 1 shadow one pixel right and down. Lower case is drawn
## as capitals; a letter with an accent falls back to its base letter (titles avoid them). Whole-
## pixel rects only, in palette colours. A title card may draw them at `scale` 2 (each pixel a
## 2×2 block: 16×22 letters); everything else draws them 1:1.

enum Code { NONE, FACE, OUTLINE, SHADOW }

## The drawn height, the shadow's row included; a letter's outline is 11 px tall.
const HEIGHT := 12
## The advance of a space, and the clear column between two characters (so the outlines of
## neighbours never merge on parchment).
const SPACE := 4
const GAP := 1
## Palette fallbacks (docs/art/palette.gpl) for a target outside the desk theme.
const PARCHMENT_2 := Color8(246, 238, 210)
const NIGHT_0 := Color8(11, 23, 34)
const NIGHT_1 := Color8(15, 37, 48)
const THEME_TYPE := &"DeskPalette"

## "#" is the face; every row of a glyph has the same width.
const GLYPHS: Dictionary = {
	"A": [".####.", "##..##", "##..##", "##..##", "######", "##..##", "##..##", "##..##", "##..##"],
	"B": ["#####.", "##..##", "##..##", "#####.", "##..##", "##..##", "##..##", "##..##", "#####."],
	"C": [".####.", "##..##", "##....", "##....", "##....", "##....", "##....", "##..##", ".####."],
	"D": ["#####.", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "#####."],
	"E": ["######", "##....", "##....", "#####.", "##....", "##....", "##....", "##....", "######"],
	"F": ["######", "##....", "##....", "#####.", "##....", "##....", "##....", "##....", "##...."],
	"G": [".####.", "##..##", "##....", "##....", "##.###", "##..##", "##..##", "##..##", ".####."],
	"H": ["##..##", "##..##", "##..##", "##..##", "######", "##..##", "##..##", "##..##", "##..##"],
	"I": ["####", ".##.", ".##.", ".##.", ".##.", ".##.", ".##.", ".##.", "####"],
	"J": ["..####", "....##", "....##", "....##", "....##", "....##", "##..##", "##..##", ".####."],
	"K": ["##..##", "##..##", "##.##.", "####..", "###...", "####..", "##.##.", "##..##", "##..##"],
	"L": ["##....", "##....", "##....", "##....", "##....", "##....", "##....", "##....", "######"],
	"M":
	[
		"##...##",
		"###.###",
		"##.#.##",
		"##.#.##",
		"##...##",
		"##...##",
		"##...##",
		"##...##",
		"##...##",
	],
	"N": ["##..##", "###.##", "###.##", "###.##", "##.###", "##.###", "##.###", "##..##", "##..##"],
	"O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
	"P": ["#####.", "##..##", "##..##", "##..##", "#####.", "##....", "##....", "##....", "##...."],
	"Q": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", "##.###", ".####.", "....##"],
	"R": ["#####.", "##..##", "##..##", "##..##", "#####.", "####..", "##.##.", "##..##", "##..##"],
	"S": [".####.", "##..##", "##....", ".####.", "....##", "....##", "....##", "##..##", ".####."],
	"T": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##.."],
	"U": ["##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
	"V": ["##..##", "##..##", "##..##", "##..##", "##..##", "##..##", ".####.", ".####.", "..##.."],
	"W":
	[
		"##...##",
		"##...##",
		"##...##",
		"##...##",
		"##...##",
		"##.#.##",
		"##.#.##",
		"###.###",
		"##...##",
	],
	"X": ["##..##", "##..##", "##..##", ".####.", "..##..", ".####.", "##..##", "##..##", "##..##"],
	"Y": ["##..##", "##..##", "##..##", ".####.", "..##..", "..##..", "..##..", "..##..", "..##.."],
	"Z": ["######", "....##", "...##.", "...##.", "..##..", ".##...", ".##...", "##....", "######"],
	"0": [".###.", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##", ".###."],
	"1": [".##.", "###.", ".##.", ".##.", ".##.", ".##.", ".##.", ".##.", "####"],
	"2": [".####.", "##..##", "....##", "....##", "...##.", "..##..", ".##...", "##....", "######"],
	"3": [".####.", "##..##", "....##", "....##", "..###.", "....##", "....##", "##..##", ".####."],
	"4": ["...##.", "..###.", ".####.", "##.##.", "##.##.", "######", "...##.", "...##.", "...##."],
	"5": ["######", "##....", "##....", "#####.", "....##", "....##", "....##", "##..##", ".####."],
	"6": [".####.", "##....", "##....", "#####.", "##..##", "##..##", "##..##", "##..##", ".####."],
	"7": ["######", "....##", "....##", "...##.", "...##.", "..##..", "..##..", "..##..", "..##.."],
	"8": [".####.", "##..##", "##..##", "##..##", ".####.", "##..##", "##..##", "##..##", ".####."],
	"9": [".####.", "##..##", "##..##", "##..##", ".#####", "....##", "....##", "....##", ".####."],
	".": ["..", "..", "..", "..", "..", "..", "..", "##", "##"],
	",": ["..", "..", "..", "..", "..", "..", "##", "##", "#."],
	"'": ["##", "##", "#.", "..", "..", "..", "..", "..", ".."],
	":": ["..", "..", "##", "##", "..", "..", "##", "##", ".."],
	"!": ["##", "##", "##", "##", "##", "##", "..", "##", "##"],
	"-": ["....", "....", "....", "....", "####", "....", "....", "....", "...."],
	"?": [".####.", "##..##", "....##", "...##.", "..##..", "..##..", "......", "..##..", "..##.."],
}
## Letters with accents (and the two Norse ligatures) and the capitals they are drawn as.
const BASE_LETTERS: Dictionary = {
	"Á": "A",
	"À": "A",
	"Â": "A",
	"Ä": "A",
	"Ã": "A",
	"Å": "A",
	"Æ": "AE",
	"Ç": "C",
	"Ð": "D",
	"É": "E",
	"È": "E",
	"Ê": "E",
	"Ë": "E",
	"Í": "I",
	"Ì": "I",
	"Î": "I",
	"Ï": "I",
	"Ñ": "N",
	"Ó": "O",
	"Ò": "O",
	"Ô": "O",
	"Ö": "O",
	"Õ": "O",
	"Ø": "O",
	"Œ": "OE",
	"Þ": "TH",
	"Ú": "U",
	"Ù": "U",
	"Û": "U",
	"Ü": "U",
	"Ý": "Y",
}

## Roman numerals, largest first, for the titles' numbers ("DAY III").
const ROMAN_VALUES: Array[int] = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
const ROMAN_DIGITS: Array[String] = [
	"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"
]

## Each drawn character's code grid (`_shape`), built on first use.
static var _shapes: Dictionary = {}


## Draws `text` on `target` with its top-left at `at`: the face in `color` (Parchment 2 for a
## carved title), the outline in Ink and the shadow in Night 1 from the target's theme. Returns
## the width drawn, as `width(text)`.
static func draw(
	target: CanvasItem, text: String, at: Vector2, color: Color, scale: int = 1
) -> int:
	var ink: Color = _theme_color(target, &"ink", NIGHT_0)
	var shadow: Color = _theme_color(target, &"night", NIGHT_1)
	var paint: Callable = func(rect: Rect2, paint_color: Color) -> void:
		target.draw_rect(rect, paint_color)
	return paint_runs(text, Vector2i(at.floor()), paint, color, ink, shadow, scale)


## The width `draw` takes for `text`: each letter with its outline and shadow column, a space
## SPACE, and GAP between two characters; all of it times `scale`.
static func width(text: String, scale: int = 1) -> int:
	var drawn: String = base_text(text)
	var total: int = 0
	for character: String in drawn:
		total += _advance(character) + GAP
	return maxi(total - GAP, 0) * maxi(scale, 1)


## `number` in Roman numerals ("" for none below 1).
static func roman(number: int) -> String:
	var out: String = ""
	var left: int = number
	for index: int in range(ROMAN_VALUES.size()):
		while left >= ROMAN_VALUES[index]:
			out += ROMAN_DIGITS[index]
			left -= ROMAN_VALUES[index]
	return out


## `text` as it is drawn: in capitals, each accented letter as its base letter.
static func base_text(text: String) -> String:
	var out: String = ""
	for character: String in text.to_upper():
		out += BASE_LETTERS.get(character, character)
	return out


## Paints `text` with its top-left at `at` through `paint` (a `(Rect2, Color)` callable), in
## horizontal runs of one colour: the shadow first, then the outline, then the face. Returns the
## width. A character with no glyph advances as a space. At `scale` 2 every pixel is a 2×2 block.
static func paint_runs(
	text: String,
	at: Vector2i,
	paint: Callable,
	face: Color,
	ink: Color,
	shadow: Color,
	scale: int = 1
) -> int:
	var block: int = maxi(scale, 1)
	var x: int = 0
	for character: String in base_text(text):
		var shape: Array = _shape(character)
		if not shape.is_empty():
			for code: int in [Code.SHADOW, Code.OUTLINE, Code.FACE]:
				var color: Color = (
					face if code == Code.FACE else (ink if code == Code.OUTLINE else shadow)
				)
				_paint_code(shape, code, at + Vector2i(x * block, 0), paint, color, block)
		x += _advance(character) + GAP
	return maxi(x - GAP, 0) * block


static func _advance(character: String) -> int:
	var shape: Array = _shape(character)
	return SPACE if shape.is_empty() else (shape[0] as Array).size()


## The character's grid of codes (rows of Arrays, which share on write where packed arrays
## would copy), its face width plus the outline's two columns and the shadow's one, HEIGHT rows;
## empty for a character with no glyph.
static func _shape(character: String) -> Array:
	if _shapes.has(character):
		return _shapes[character]
	var rows: Array = GLYPHS.get(character, [])
	var grid: Array = []
	if not rows.is_empty():
		var face_width: int = (rows[0] as String).length()
		var columns: int = face_width + 3
		for y: int in range(HEIGHT):
			var row: Array = []
			row.resize(columns)
			row.fill(Code.NONE)
			grid.append(row)
		for y: int in range(rows.size()):
			for x: int in range(face_width):
				if (rows[y] as String)[x] == "#":
					(grid[y + 1] as Array)[x + 1] = Code.FACE
		_ring(grid, columns)
	_shapes[character] = grid
	return grid


## The outline rings the face on all eight sides; the shadow is the face and outline moved one
## pixel right and down, where nothing else is.
static func _ring(grid: Array, columns: int) -> void:
	for y: int in range(HEIGHT - 1):
		for x: int in range(columns - 1):
			if _at(grid, x, y) == Code.NONE and _touches_face(grid, x, y):
				(grid[y] as Array)[x] = Code.OUTLINE
	for y: int in range(HEIGHT - 1, 0, -1):
		for x: int in range(columns - 1, 0, -1):
			var behind: int = _at(grid, x - 1, y - 1)
			var carved: bool = behind == Code.FACE or behind == Code.OUTLINE
			if _at(grid, x, y) == Code.NONE and carved:
				(grid[y] as Array)[x] = Code.SHADOW


static func _touches_face(grid: Array, x: int, y: int) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if _at(grid, x + dx, y + dy) == Code.FACE:
				return true
	return false


static func _at(grid: Array, x: int, y: int) -> int:
	if y < 0 or y >= grid.size():
		return Code.NONE
	var row: Array = grid[y]
	if x < 0 or x >= row.size():
		return Code.NONE
	return row[x]


static func _paint_code(
	shape: Array, code: int, origin: Vector2i, paint: Callable, color: Color, block: int
) -> void:
	for y: int in range(shape.size()):
		var row: Array = shape[y]
		var x: int = 0
		while x < row.size():
			if row[x] != code:
				x += 1
				continue
			var end: int = x + 1
			while end < row.size() and row[end] == code:
				end += 1
			var from := Vector2(origin + Vector2i(x, y) * block)
			paint.call(Rect2(from, Vector2(end - x, 1) * block), color)
			x = end


static func _theme_color(target: CanvasItem, color_name: StringName, fallback: Color) -> Color:
	var control: Control = target as Control
	if control != null and control.has_theme_color(color_name, THEME_TYPE):
		return control.get_theme_color(color_name, THEME_TYPE)
	return fallback
