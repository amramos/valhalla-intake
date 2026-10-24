extends GutTest
## Decrees are named by roman numerals on the desk; data and commands keep the ids (D6).


func test_the_five_decree_ids_read_as_roman_numerals() -> void:
	var numerals: Array[String] = []
	for id: String in ["L1", "L2", "L3", "L4", "L5"]:
		numerals.append(DecreeNumeral.roman(id))
	assert_eq(numerals, ["I", "II", "III", "IV", "V"] as Array[String])


func test_larger_numbers_read_as_roman_too() -> void:
	assert_eq(
		[DecreeNumeral.roman("L9"), DecreeNumeral.roman("L14"), DecreeNumeral.roman("L40")],
		["IX", "XIV", "XL"]
	)


func test_only_l_and_a_positive_number_is_a_decree_id() -> void:
	var accepted: Array[String] = []
	for id: String in ["L1", "L12", "C1", "W2", "B3", "L", "L0", "L01", "L-1", "L+2", "l1", ""]:
		if DecreeNumeral.is_decree_id(id):
			accepted.append(id)
	assert_eq(accepted, ["L1", "L12"] as Array[String])


func test_anything_else_comes_back_unchanged() -> void:
	assert_eq([DecreeNumeral.roman("C1"), DecreeNumeral.roman("")], ["C1", ""])


func test_a_caption_names_a_decree_by_its_numeral() -> void:
	assert_eq(DecreeNumeral.label("L3"), "decree III")
