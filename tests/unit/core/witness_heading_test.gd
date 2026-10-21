extends GutTest
## D52: the witness panel's heading shows only the witness's name, the part before the first
## comma; the rest is the role, and the whole description is its hover label.

const Fixture := preload("res://tests/unit/core/slice_fixture.gd")


func _soul(witness_name: String) -> Encounter:
	var soul: Encounter = Fixture.sigvaldi()
	soul.witness_name = witness_name
	return soul


func test_the_heading_name_is_the_part_before_the_first_comma() -> void:
	var names: Array = []
	for witness_name: String in [
		"Bjorn, his shield-brother", "Ivar", "Skeggi, one of the raiders, too", ""
	]:
		var soul: Encounter = _soul(witness_name)
		names.append([soul.witness_heading_name(), soul.witness_role()])
	assert_eq(
		names,
		[
			["Bjorn", "his shield-brother"],
			["Ivar", ""],
			["Skeggi", "one of the raiders, too"],
			["", ""],
		]
	)
