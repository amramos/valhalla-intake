class_name Realm
extends RefCounted
## The realm doors, as StringName ids. Constants and display names only.

const VALHALLA := &"valhalla"
const FOLKVANGR := &"folkvangr"
const HEL := &"hel"
const RAN := &"ran"


## The name a door shows on hover; "" for an unknown id.
static func display_name(realm: StringName) -> String:
	match realm:
		VALHALLA:
			return "Valhalla"
		FOLKVANGR:
			return "Fólkvangr"
		HEL:
			return "Hel"
		RAN:
			return "Rán"
	return ""
