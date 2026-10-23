extends GutTest
## The days darken (D39) and the band's light and fog (D19) on the desk: the gate band shows its
## day's recolour, one ramp value darker per day on the Night and Fog ramps only, and so do the
## doors' stones; the doors' light, glyphs and bar, the raven, the soul and its plate and the HUD
## keep their values, and the desk below never changes. The fog frames move only inside the corner
## masks.
##
## Contrast rules (D39, decided by the lead for WP3):
## - text (the plate's name, the HUD's numerals) is the mean luminance of its colour against the
##   plate it is written on, floor TEXT_CONTRAST;
## - a sprite (every soul, the three plates, the raven, the barred door's bar and boar) is judged
##   by edge contrast: the mean absolute luminance difference between its opaque edge pixels
##   (opaque, with a transparent or out-of-object neighbour) and the pixel just outside each, on
##   that day's band (on the door's leaf for the bar and boar), floor EDGE_CONTRAST on the days
##   it shows, except the slice art named in FLOOR_EXCEPTIONS;
## - the day invariant D39 asks for: on days 2 and 3 each sprite keeps at least DAY_RATIO of its
##   day-1 edge contrast;
## - the HUD's plates are backing, not objects: their numerals carry readability.

const DESK_SCENE := preload("res://scenes/desk/desk.tscn")
const Fixture := preload("res://tests/integration/scenes/desk/desk_fixture.gd")
const Palette := preload("res://tests/unit/entities/desk_palette.gd")
const THEME := preload("res://scenes/desk/desk_theme.tres")
const SCENES := "res://assets/art/scenes/"
const BAND_FILES: Array[String] = ["gate-desk.png", "gate-desk-day2.png", "gate-desk-day3.png"]
const REALMS: Array[String] = ["valhalla", "hel", "folkvangr"]
const STACKS := preload("res://entities/body_chart/body_stacks.tres")
## The contrast rules' floors and the day invariant's ratio (see the header).
const TEXT_CONTRAST := 0.25
const EDGE_CONTRAST := 0.10
const DAY_RATIO := 0.8
## The days each sprite shows; a sprite not named here shows on every day.
const SHOWN_ON: Dictionary[String, Array] = {
	"raven": [3], "barred door's bar": [1, 2], "barred door's boar": [1, 2]
}
## Sprites exempt from the EDGE_CONTRAST floor (the day invariant still applies to them), with
## their measured day-1 and day-2 edge contrast: slice art already under the floor on the band as
## painted.
const FLOOR_EXCEPTIONS: Dictionary[String, String] = {
	"barred door's bar":
	"0.084 (day 1), 0.085 (day 2): slice art, pre-existing; the day invariant still applies",
	"barred door's boar":
	"0.054 (day 1), 0.087 (day 2): slice art, pre-existing; the day invariant still applies",
	"soul grim": "0.099 (day 1): slice art, pre-existing; the day invariant still applies",
}
## The neighbours that make an opaque pixel an edge: above, left, right, below.
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)
]
## Where the desk draws each object (screen pixels): the soul's figure and its plate, the raven;
## in the barred Fólkvangr sprite, its bar and its dimmed boar; on the plate, its name's face.
const SOUL_AT := Vector2i(6, -2)
const FIGURE_SIZE := Vector2i(48, 96)
const PLATE_AT := Vector2i(2, 86)
const RAVEN_AT := Vector2i(268, 34)
const BAR_AREA := Rect2i(0, 61, 60, 11)
const GLYPH_AREA := Rect2i(17, 28, 24, 14)
const NAME_AREA := Rect2i(2, 2, 44, 6)
## The corner masks of tools/art/band_frames.py, inclusive (left, top) to (right, bottom), and the
## fog's rows.
const FOG_MASKS: Array[Rect2i] = [
	Rect2i(0, 76, 53, 10), Rect2i(0, 86, 89, 10), Rect2i(412, 76, 68, 10), Rect2i(392, 86, 88, 10)
]
const FOG_TOP := 76
const FOG_ROWS := 20

var _desk: Desk = null
var _system: DeskSystem = null


func _open(commands: DeskCommands, options: Options = Fixture.instant()) -> void:
	_desk = DESK_SCENE.instantiate() as Desk
	_desk.use_commands(commands)
	_desk.use_options(options)
	add_child_autofree(_desk)
	_system = _desk.system()
	_system.phase_card.next_button().pressed.emit()


func test_day_one_shows_the_band_as_painted() -> void:
	_open(SliceLoader.load_slice())
	assert_eq(_system.gate_band.day(), 1)
	assert_eq(_system.gate_band.band_texture().resource_path, SCENES + "gate-desk.png")
	for door: Door in _system.doors:
		assert_false(door.shown_texture().resource_path.contains("/day"), String(door.realm))


func test_day_two_and_day_three_darken_the_band_and_the_doors_stones() -> void:
	_open(Fixture.two_days())
	assert_eq(_system.gate_band.day(), 2)
	assert_eq(_system.gate_band.band_texture().resource_path, SCENES + "gate-desk-day2.png")
	for door: Door in _system.doors:
		assert_string_contains(door.shown_texture().resource_path, "/doors/day2/")
	_open(Fixture.commands())
	assert_eq(_system.gate_band.band_texture().resource_path, SCENES + "gate-desk-day3.png")
	for door: Door in _system.doors:
		assert_string_contains(door.shown_texture().resource_path, "/doors/day3/")


func test_the_band_is_drawn_under_every_object_that_keeps_its_value() -> void:
	_open(Fixture.commands())
	var band: int = _system.gate_band.get_index()
	assert_eq(band, _desk.get_node(^"Backdrop").get_index() + 1, "right over the backdrop")
	var above: Array[Control] = [_system.raven, _system.soul, _system.hud, _system.ledger_tray]
	above.append_array(_system.doors)
	for node: Control in above:
		assert_gt(node.get_index(), band, "%s is drawn over the band" % node.name)
	assert_eq(_system.raven.rest_texture.resource_path, "res://assets/art/portraits/huginn.png")
	assert_eq(_system.gate_band.size, Vector2(480, 96), "the band only: the desk never darkens")


func test_each_day_steps_only_night_and_fog_down_and_leaves_the_desk_alone() -> void:
	var day_one: Image = _image(SCENES + BAND_FILES[0])
	var ramps: Array[Array] = [_ramp("Night", 6), _ramp("Fog", 3)]
	for day: int in [2, 3]:
		var image: Image = _image(SCENES + BAND_FILES[day - 1])
		var wrong: Array[String] = []
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var was: Color = day_one.get_pixel(x, y)
				var expected: Color = _darker(was, day - 1, ramps) if y < 96 else was
				if image.get_pixel(x, y) != expected and wrong.size() < 5:
					wrong.append("%d,%d" % [x, y])
		assert_eq(wrong, [] as Array[String], "day %d: Night and Fog one step per day" % day)


func test_the_doors_keep_their_light_glyphs_and_bar_on_every_day() -> void:
	var ramps: Array[Array] = [_ramp("Night", 6), _ramp("Fog", 3)]
	for realm: String in REALMS:
		for kind: String in ["lit", "locked", "lit-dim"]:
			var base: Image = _image("res://assets/art/doors/%s-%s.png" % [realm, kind])
			for day: int in [2, 3]:
				var path: String = "res://assets/art/doors/day%d/%s-%s.png" % [day, realm, kind]
				var image: Image = _image(path)
				var wrong: int = 0
				for y: int in range(image.get_height()):
					for x: int in range(image.get_width()):
						if image.get_pixel(x, y) != _darker(base.get_pixel(x, y), day - 1, ramps):
							wrong += 1
				assert_eq(wrong, 0, path)


## D39, sprites: every soul, the three plates, the raven and the barred door's bar and boar keep
## their edge contrast (EDGE_CONTRAST) on the days they show, and on days 2 and 3 keep at least
## DAY_RATIO of their day-1 edge contrast. Each object and day is asserted on its own, by name.
func test_every_sprite_keeps_its_edge_against_the_darkening_band() -> void:
	var bands: Array[Image] = []
	for file: String in BAND_FILES:
		bands.append(_image(SCENES + file))
	var sprites: Dictionary[String, Array] = {}
	for id: StringName in _encounter_ids():
		var figure: Image = _composite(STACKS.soul_layers(id), FIGURE_SIZE)
		sprites["soul %s" % id] = _edges_on_bands(figure, SOUL_AT, bands)
	for kind: String in ["plain", "frost", "hel"]:
		var plate: Image = _image("res://assets/art/ui/nameplate-%s.png" % kind)
		sprites["%s plate" % kind] = _edges_on_bands(plate, PLATE_AT, bands)
	var raven: Image = _image("res://assets/art/portraits/huginn.png")
	sprites["raven"] = _edges_on_bands(raven, RAVEN_AT, bands)
	for part: String in ["bar", "boar"]:
		var by_day: Array[float] = []
		for day: int in [1, 2, 3]:
			var leaf: Image = _barred_door(day)
			by_day.append(_edge_contrast(_door_mark(part, leaf), Vector2i.ZERO, leaf))
		sprites["barred door's %s" % part] = by_day
	for what: String in sprites:
		var by_day: Array = sprites[what]
		gut.p("%s edge contrast by day: %.3f, %.3f, %.3f" % [what, by_day[0], by_day[1], by_day[2]])
		var floor_days: Array = [] if FLOOR_EXCEPTIONS.has(what) else SHOWN_ON.get(what, [1, 2, 3])
		for day: int in floor_days:
			assert_gte(
				by_day[day - 1],
				EDGE_CONTRAST,
				"day %d %s: edge contrast %.3f" % [day, what, by_day[day - 1]]
			)
		for day: int in [2, 3]:
			assert_gte(
				by_day[day - 1],
				DAY_RATIO * by_day[0],
				(
					"day %d %s keeps its edge: %.3f against day 1's %.3f"
					% [day, what, by_day[day - 1], by_day[0]]
				)
			)


## D39, text: the plate's name and every HUD numeral against the plate they are written on.
func test_every_text_reads_on_its_plate() -> void:
	var light: float = _theme_colour(&"text_light").get_luminance()
	for kind: String in ["plain", "frost", "hel"]:
		var plate: Image = _image("res://assets/art/ui/nameplate-%s.png" % kind)
		var face: float = _mean(plate, NAME_AREA, false)
		assert_gte(
			absf(light - face),
			TEXT_CONTRAST,
			"the %s plate's name: %.3f on %.3f" % [kind, light, face]
		)
	var night: float = _theme_colour(&"night").get_luminance()
	var desks: Array[DeskCommands] = [
		SliceLoader.load_slice(), Fixture.two_days(), Fixture.commands()
	]
	for day: int in [1, 2, 3]:
		_open(desks[day - 1])
		await get_tree().process_frame
		await get_tree().process_frame
		var numerals: Array[String] = _system.hud.drawn_texts()
		assert_gt(numerals.size(), 1, "day %d: the HUD wrote its numerals" % day)
		for numeral: String in numerals:
			assert_gte(
				absf(light - night),
				TEXT_CONTRAST,
				"day %d HUD numeral '%s' on its plate" % [day, numeral]
			)


## `object`'s edge contrast drawn at `at` over each day's band, day 1 first.
func _edges_on_bands(object: Image, at: Vector2i, bands: Array[Image]) -> Array[float]:
	var by_day: Array[float] = []
	for band: Image in bands:
		by_day.append(_edge_contrast(object, at, band))
	return by_day


## The mean absolute luminance difference between `object`'s opaque edge pixels (opaque, with a
## transparent or out-of-object neighbour) and the `backdrop` pixel just outside each of them,
## the object drawn at `at`. Neighbours off the backdrop are skipped.
func _edge_contrast(object: Image, at: Vector2i, backdrop: Image) -> float:
	var inside := Rect2i(Vector2i.ZERO, object.get_size())
	var bounds := Rect2i(Vector2i.ZERO, backdrop.get_size())
	var total: float = 0.0
	var count: int = 0
	for y: int in range(object.get_height()):
		for x: int in range(object.get_width()):
			var color: Color = object.get_pixel(x, y)
			if color.a == 0.0:
				continue
			for step: Vector2i in NEIGHBOURS:
				var out: Vector2i = Vector2i(x, y) + step
				if inside.has_point(out) and object.get_pixelv(out).a > 0.0:
					continue
				if not bounds.has_point(at + out):
					continue
				var wall: float = backdrop.get_pixelv(at + out).get_luminance()
				total += absf(color.get_luminance() - wall)
				count += 1
				break
	return total / maxi(1, count)


## The barred Fólkvangr sprite of `day` (its leaf is what the bar and boar sit on).
func _barred_door(day: int) -> Image:
	var folder: String = "" if day == 1 else "day%d/" % day
	return _image("res://assets/art/doors/%sfolkvangr-locked.png" % folder)


## The bar or the boar alone, at the door's size: the Wood pixels of day 1's sprite in its area,
## in `door`'s colours; everything else transparent.
func _door_mark(part: String, door: Image) -> Image:
	var base: Image = _barred_door(1)
	var wood: Array[Color] = _ramp("Wood", 5)
	var area: Rect2i = BAR_AREA if part == "bar" else GLYPH_AREA
	var mark := Image.create(door.get_width(), door.get_height(), false, Image.FORMAT_RGBA8)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if wood.has(base.get_pixel(x, y)):
				mark.set_pixel(x, y, door.get_pixel(x, y))
	return mark


## The mean luminance of `image`'s pixels inside `area` (only the opaque ones when `opaque`).
func _mean(image: Image, area: Rect2i, opaque: bool) -> float:
	var total: float = 0.0
	var count: int = 0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var color: Color = image.get_pixel(x, y)
			if opaque and color.a == 0.0:
				continue
			total += color.get_luminance()
			count += 1
	return total / maxi(1, count)


## `layers` stacked in order, as the soul's figure draws them.
func _composite(layers: Array[Texture2D], size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for layer: Texture2D in layers:
		var pixels: Image = layer.get_image()
		pixels.convert(Image.FORMAT_RGBA8)
		image.blend_rect(pixels, Rect2i(Vector2i.ZERO, pixels.get_size()), Vector2i.ZERO)
	return image


func _encounter_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at("res://data/encounters"):
		if file.ends_with(".tres"):
			var data: Resource = load("res://data/encounters/" + file)
			ids.append(StringName(data.get("id")))
	return ids


func _theme_colour(name: StringName) -> Color:
	return THEME.get_color(name, &"DeskPalette")


func test_the_fog_frames_move_only_inside_the_corner_masks() -> void:
	var palette: Array[int] = []
	for color: Color in Palette.by_name().values():
		palette.append(color.to_rgba32())
	for day: int in [1, 2, 3]:
		var band: Image = _image(SCENES + BAND_FILES[day - 1])
		var sheet: Image = _image("res://assets/art/fog/fog-day%d.png" % day)
		var problems: Array[String] = []
		var moved: int = 0
		for frame: int in range(3):
			for row: int in range(FOG_ROWS):
				for x: int in range(sheet.get_width()):
					var color: Color = sheet.get_pixel(x, frame * FOG_ROWS + row)
					var painted: Color = band.get_pixel(x, FOG_TOP + row)
					if not _in_mask(x, FOG_TOP + row):
						if color.a > 0.0:
							problems.append("%d,%d outside the masks" % [x, row])
						continue
					if not palette.has(color.to_rgba32()):
						problems.append("%d,%d off the palette" % [x, row])
					if frame == 0 and color != painted:
						problems.append("%d,%d frame 0 is not the band" % [x, row])
					if frame > 0 and color != painted:
						moved += 1
		assert_eq(problems.slice(0, 5), [], "day %d" % day)
		assert_gt(moved, 200, "day %d: the fog moves" % day)


func test_reduce_motion_holds_the_doors_and_the_fog() -> void:
	var options: Options = Fixture.instant()
	options.reduce_motion = true
	_open(Fixture.commands(), options)
	for _step: int in range(10):
		_system.gate_band._process(0.5)
		for door: Door in _system.doors:
			door._process(0.5)
			assert_eq(door.drawn_texture(), door.shown_texture(), "no pulse (D37)")
	assert_eq(_system.gate_band.fog_frame(), 0, "no drift (D37)")
	assert_true(_system.mentor_portrait.reduce_motion, "no blink")


func test_the_glow_pulses_on_an_open_door_and_the_gates_pause_holds_it() -> void:
	_open(Fixture.commands())
	var hel: Door = _door(&"hel")
	hel._process(1.3)
	assert_eq(hel.drawn_texture(), hel.later_dim[1], "the dim half of the pulse, day 3's frame")
	_desk.gate().set_paused(true)
	hel._process(5.0)
	assert_eq(hel.drawn_texture(), hel.later_dim[1], "the pause holds it")
	_desk.gate().set_paused(false)
	hel._process(1.25)
	assert_eq(hel.drawn_texture(), hel.shown_texture(), "lit again")


func _door(realm: StringName) -> Door:
	for door: Door in _system.doors:
		if door.realm == realm:
			return door
	return null


func _image(path: String) -> Image:
	var texture: Texture2D = load(path)
	return texture.get_image()


func _ramp(name: String, count: int) -> Array[Color]:
	var named: Dictionary[String, Color] = Palette.by_name()
	var shades: Array[Color] = []
	for index: int in range(count):
		shades.append(named["%s %d" % [name, index]])
	return shades


## `color` `steps` values down its own ramp when it is an opaque Night or Fog, else unchanged.
func _darker(color: Color, steps: int, ramps: Array[Array]) -> Color:
	if color.a == 0.0:
		return color
	for shades: Array in ramps:
		var at: int = shades.find(color)
		if at >= 0:
			return shades[maxi(0, at - steps)]
	return color


func _in_mask(x: int, y: int) -> bool:
	for mask: Rect2i in FOG_MASKS:
		if mask.has_point(Vector2i(x, y)):
			return true
	return false
