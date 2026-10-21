class_name PixelFont
extends RefCounted
## Crisp rendering for the pixel font (ADR-0008). `*.import` files are not committed, so the import
## options would be lost on a fresh checkout; the settings are applied at runtime instead.

## The size at which one font pixel is one screen pixel.
const SIZE := 16


static func configure(font: Font) -> void:
	var file: FontFile = font as FontFile
	if file == null:
		return
	file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	file.hinting = TextServer.HINTING_NONE
	file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	file.multichannel_signed_distance_field = false
	file.generate_mipmaps = false
