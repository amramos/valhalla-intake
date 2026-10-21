class_name BodyStacks
extends Resource
## Which art layers make each soul's body (D5, D40): a base, a left hand, the overlays for its
## facts and an identity head, bottom to top, by encounter id. The chart uses the 128×100 layers;
## the standing soul uses the same names cropped to 48×96, minus layers the front view can't show.
## Mirrors `docs/art/slice-asset-manifest.json` (a test keeps them equal).

@export var stacks: Dictionary[StringName, PackedStringArray] = {}
@export var chart_folder: String = "res://assets/art/body"
@export var soul_folder: String = "res://assets/art/souls"


## The stack key for an encounter id: the id itself, or the longest key the id starts with once
## "_" reads as "-" (returned Hakon's variants share the "hakon-returned" stack). &"" if none.
func key_for(encounter_id: StringName) -> StringName:
	var wanted: String = String(encounter_id).replace("_", "-")
	if stacks.has(StringName(wanted)):
		return StringName(wanted)
	var best: String = ""
	for key: StringName in stacks:
		var name: String = String(key)
		if wanted.begins_with(name + "-") and name.length() > best.length():
			best = name
	return StringName(best)


func chart_layers(encounter_id: StringName) -> Array[Texture2D]:
	return _layers(encounter_id, chart_folder)


func soul_layers(encounter_id: StringName) -> Array[Texture2D]:
	return _layers(encounter_id, soul_folder)


func _layers(encounter_id: StringName, folder: String) -> Array[Texture2D]:
	var layers: Array[Texture2D] = []
	var key: StringName = key_for(encounter_id)
	if key == &"":
		return layers
	for layer: String in stacks[key]:
		var path: String = "%s/%s.png" % [folder, layer]
		if ResourceLoader.exists(path):
			layers.append(load(path) as Texture2D)
	return layers
