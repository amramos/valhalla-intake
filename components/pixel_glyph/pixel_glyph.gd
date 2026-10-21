class_name PixelGlyph
extends RefCounted
## Small marks under 32 px, placed pixel by pixel in code and never generated (art direction):
## the realm glyphs carved on the doors and the HUD icons. Each glyph is 7×7; "#" is ink.

const SIZE := 7
const GLYPHS: Dictionary = {
	&"spear": ["...#...", "..###..", ".#.#.#.", "...#...", "...#...", "...#...", "...#..."],
	&"serpent": ["..###..", ".#...#.", ".#.....", "..###..", ".....#.", "#....#.", ".####.."],
	&"boar": [".......", "##.....", "######.", "#######", "######.", ".#..#..", ".#..#.."],
	&"wave": [".......", "..##...", ".#..#..", "#....#.", ".....#.", "......#", "......."],
	&"clock": [".#####.", "#..#..#", "#..#..#", "#..##.#", "#.....#", "#.....#", ".#####."],
	&"feather": ["....###", "...###.", "..###..", ".#.#...", ".##....", "#......", "......."],
	&"quota": ["#######", "#.....#", "#.#.#.#", "#.#.#.#", "#.#.#.#", "#.....#", "#######"],
	&"raven": ["..##...", ".####..", "######.", ".#####.", "..####.", "...#.#.", "......."],
	&"ledger": ["######.", "#....#.", "#.##.#.", "#....#.", "#.##.#.", "#....#.", "######."],
}


## Draws `glyph` on `canvas` with its top-left corner at `at` (canvas pixels).
static func draw(canvas: CanvasItem, glyph: StringName, at: Vector2, color: Color) -> void:
	var rows: Array = GLYPHS.get(glyph, [])
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] == "#":
				canvas.draw_rect(Rect2(at + Vector2(x, y), Vector2.ONE), color)
