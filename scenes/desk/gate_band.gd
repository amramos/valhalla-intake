class_name GateBand
extends Control
## The gate band's light (D39) and its corner fog (D19), drawn over the backdrop's band rows. Each
## day shows its own recolour of the band, one ramp value darker on the Night and Fog ramps per day
## (day 1 is the backdrop as painted; a later day past the last frame keeps the darkest). The
## doors, the raven, the soul and its plate, the bar and the HUD are separate nodes above it, so
## they keep their values; the desk below the band never changes.
##
## The fog in the band's two corners drifts through three frames, FOG_FRAME_SECONDS each, as
## palette-safe frames from tools/art/band_frames.py (never an alpha tint). Frame 0 is the band as
## painted, so reduce motion (D37) simply holds it; the gate's pause holds the drift's clock.

## The band's height and the fog sheets' layout: FOG_FRAMES frames of FOG_ROWS rows stacked, for
## the band's rows from FOG_TOP.
const BAND_HEIGHT := 96
const FOG_TOP := 76
const FOG_ROWS := 20
const FOG_FRAMES := 3
const FOG_FRAME_SECONDS := 0.7

## The band by day, day 1 first: full backdrop frames, of which the band's rows are drawn.
@export var day_textures: Array[Texture2D] = []
## The fog sheets by day, day 1 first, matching each day's band.
@export var fog_sheets: Array[Texture2D] = []

## Reduce motion (D37): the fog holds still on the band as painted.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_fog.reset()
		queue_redraw()

var _day: int = 1
var _fog := IdleCycle.new(FOG_FRAMES, FOG_FRAME_SECONDS, FOG_FRAME_SECONDS, FOG_FRAME_SECONDS)
var _paused: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows day `day`'s band (days before 1 show day 1's).
func set_day(day: int) -> void:
	var clamped: int = maxi(1, day)
	if clamped != _day:
		_day = clamped
		queue_redraw()


func day() -> int:
	return _day


## The backdrop frame whose band rows are drawn today.
func band_texture() -> Texture2D:
	return _for_day(day_textures)


## Today's fog sheet.
func fog_sheet() -> Texture2D:
	return _for_day(fog_sheets)


## The fog frame drawn now: 0 is the band as painted.
func fog_frame() -> int:
	return 0 if reduce_motion else _fog.frame()


## The gate's pause holds the drift where it is.
func set_paused(paused: bool) -> void:
	_paused = paused


func _process(delta: float) -> void:
	if _paused or reduce_motion or not is_visible_in_tree():
		return
	if _fog.advance(delta):
		queue_redraw()


func _draw() -> void:
	var band: Texture2D = band_texture()
	if band != null:
		var rows := Rect2(0, 0, band.get_width(), BAND_HEIGHT)
		draw_texture_rect_region(band, rows, rows)
	var sheet: Texture2D = fog_sheet()
	var frame: int = fog_frame()
	if sheet != null and frame > 0:
		var source := Rect2(0, frame * FOG_ROWS, sheet.get_width(), FOG_ROWS)
		draw_texture_rect_region(sheet, Rect2(0, FOG_TOP, sheet.get_width(), FOG_ROWS), source)


func _for_day(textures: Array[Texture2D]) -> Texture2D:
	if textures.is_empty():
		return null
	return textures[mini(_day, textures.size()) - 1]
