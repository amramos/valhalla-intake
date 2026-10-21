class_name PlaceholderArt
extends RefCounted
## Loads a style frame from `docs/art/frames/` as development placeholder art. `docs/art/` is not
## imported by Godot (it carries a .gdignore) and is not exported, so the file is read from disk
## and a missing file yields null instead of an error. Final art goes into each entity's texture
## slot, and this helper then has nothing left to load.


static func load_texture(res_path: String, region: Rect2i = Rect2i()) -> Texture2D:
	if res_path == "":
		return null
	var path: String = ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	if region.has_area():
		image = image.get_region(region)
	return ImageTexture.create_from_image(image)
