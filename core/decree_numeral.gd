class_name DecreeNumeral
extends RefCounted
## How a decree is named on the desk (D6): its roman numeral, never its id. Data, tests and the
## harness's commands keep the ids ("L1".."L5"); everything a player reads says "I".."V".

## How a caption or a citation names a decree: "decree III".
const LABEL_FORMAT := "decree %s"
const _NUMERALS: Array[Array] = [
	[1000, "M"],
	[900, "CM"],
	[500, "D"],
	[400, "CD"],
	[100, "C"],
	[90, "XC"],
	[50, "L"],
	[40, "XL"],
	[10, "X"],
	[9, "IX"],
	[5, "V"],
	[4, "IV"],
	[1, "I"],
]


## "L" followed by a positive number: "L1", "L5", "L12".
static func is_decree_id(id: String) -> bool:
	if id.length() < 2 or not id.begins_with("L"):
		return false
	var number: String = id.substr(1)
	# Digits only, no sign and no leading zero.
	return number.is_valid_int() and "123456789".contains(number[0])


## "L3" reads "III". Anything that is not a decree id comes back unchanged.
static func roman(id: String) -> String:
	if not is_decree_id(id):
		return id
	var left: int = id.substr(1).to_int()
	var numeral: String = ""
	for pair: Array in _NUMERALS:
		while left >= int(pair[0]):
			numeral += String(pair[1])
			left -= int(pair[0])
	return numeral


## "L3" reads "decree III" (a caption's or a citation's name for it).
static func label(id: String) -> String:
	return LABEL_FORMAT % roman(id)
