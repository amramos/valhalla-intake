class_name PinSelection
extends RefCounted
## The desk's two-click pin gesture (D8): the first click selects an item, a click on the same
## item (or a cancel) clears it, and a click on another item completes the pair.

var selected_id: String = ""


## Returns the completed pair [first, second], or an empty array while a pin is still open.
func click(item_id: String) -> Array[String]:
	if item_id == "":
		return []
	if selected_id == "":
		selected_id = item_id
		return []
	if selected_id == item_id:
		selected_id = ""
		return []
	var pair: Array[String] = [selected_id, item_id]
	selected_id = ""
	return pair


func cancel() -> void:
	selected_id = ""


func has_selection() -> bool:
	return selected_id != ""
