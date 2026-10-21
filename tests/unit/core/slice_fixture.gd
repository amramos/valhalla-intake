extends RefCounted
## A synthetic three-day slice for the rules tests, built in code from the evidence matrix's souls
## (trimmed to what the rules need). Test fixture only, never shipped content.

const RED := Seam.Kind.RED
const GREY := Seam.Kind.GREY
const LAW := Seam.Kind.LAW
const CLAIM := Seam.Liar.CLAIM
const NONE := Seam.Liar.NONE

const LIE := "the body gives the lie."
const ONE_LIES := "one of them lies."


static func rules() -> SliceRules:
	return SliceRules.new()


static func decrees(count: int) -> Array[EvidenceItem]:
	var texts: Array[String] = [
		"Valhalla takes only those slain by a weapon in battle.",
		"Whoever lies to the Gate goes to Hel, whatever else the Law says.",
		"Even so, a warrior without a weapon in hand goes to Hel.",
		"Even so, those who fled the battle go to Hel.",
		"Those who fell defending hearth and kin go to Fólkvangr.",
	]
	var items: Array[EvidenceItem] = []
	for index: int in count:
		items.append(EvidenceItem.make("L%d" % (index + 1), EvidenceItem.Group.LAW, texts[index]))
	return items


static func day(
	number: int, quota: int, seconds: float, doors: Array[StringName], decree_count: int
) -> DayRules:
	var rules_of_day := DayRules.new()
	rules_of_day.day = number
	rules_of_day.quota = quota
	rules_of_day.clock_seconds = seconds
	rules_of_day.doors_open = doors
	rules_of_day.decrees = decrees(decree_count)
	rules_of_day.citations = number >= 2
	rules_of_day.huginn_answers = 2 if number == 3 else 0
	return rules_of_day


## body: "B1|label|view"; claim and witness: the lines in order.
static func encounter(
	id: StringName,
	soul_name: String,
	legal: StringName,
	worthy: StringName,
	body: Array[String],
	claim: Array[String],
	witness: Array[String],
	seams: Array[Seam]
) -> Encounter:
	var result := Encounter.new()
	result.id = id
	result.soul_name = soul_name
	result.legal_realm = legal
	result.worthy_realm = worthy
	result.truth = "The truth about %s." % soul_name
	for fact: String in body:
		var parts: PackedStringArray = fact.split("|")
		result.items.append(
			EvidenceItem.make(parts[0], EvidenceItem.Group.BODY, parts[1], StringName(parts[2]))
		)
	for index: int in claim.size():
		result.items.append(
			EvidenceItem.make("C%d" % (index + 1), EvidenceItem.Group.CLAIM, claim[index])
		)
	for index: int in witness.size():
		result.items.append(
			EvidenceItem.make("W%d" % (index + 1), EvidenceItem.Group.WITNESS, witness[index])
		)
	if not witness.is_empty():
		result.witness_name = "a witness"
	result.seams = seams
	result.liar = legal != worthy or seams.any(func(s: Seam) -> bool: return s.liar == CLAIM)
	return result


static func ulf() -> Encounter:
	return encounter(
		&"ulf",
		"Ulf",
		Realm.VALHALLA,
		Realm.VALHALLA,
		["B1|wound, front|front", "B2|no wound, back|back", "B3|sword, gripped|front"],
		["Axed, in battle.", "Took it in the chest.", "Sword up to the end."],
		[],
		[Seam.make("C1", "L1", LAW, NONE, Realm.VALHALLA, "the saga is true. L1: Valhalla.")]
	)


static func kolbeinn() -> Encounter:
	return encounter(
		&"kolbeinn",
		"Kolbeinn",
		Realm.HEL,
		Realm.HEL,
		["B1|no wound, front|front", "B3|nothing in hand|front", "B4|night-shirt|front"],
		["Danes axed my chest.", "Mail on. Shield up.", "Died sword in hand."],
		[],
		[
			Seam.make("B1", "C1", RED, CLAIM, &"", LIE),
			Seam.make("B4", "C2", RED, CLAIM, &"", LIE),
			Seam.make("B3", "L3", LAW, NONE, Realm.HEL, "L3 sends him to Hel."),
		]
	)


static func asa() -> Encounter:
	var result: Encounter = encounter(
		&"asa",
		"Asa",
		Realm.HEL,
		Realm.VALHALLA,
		["B1|wound, front|front", "B3|nothing in hand|front"],
		["Danes on the beach.", "Spear in my two hands.", "It snapped. I kept on."],
		[],
		[Seam.make("B3", "L3", LAW, NONE, Realm.HEL, "the saga is true. L3: Hel.")]
	)
	result.pronoun = "her"
	return result


static func sigvaldi() -> Encounter:
	return encounter(
		&"sigvaldi",
		"Sigvaldi",
		Realm.VALHALLA,
		Realm.VALHALLA,
		["B2|wound, back|back", "B3|sword, gripped|front"],
		["Fell in battle. Ness.", "Sword broke on a helm."],
		["The wall broke behind."],
		[Seam.make("C1", "L1", LAW, NONE, Realm.VALHALLA, "the saga is true. L1: Valhalla.")]
	)


static func hakon() -> Encounter:
	var result: Encounter = encounter(
		&"hakon",
		"Hakon",
		Realm.HEL,
		Realm.VALHALLA,
		["B1|no wound, front|front", "B2|wound, back|back", "B3|sword, gripped|front"],
		["Ivar owed me a knife.", "He fell. I lifted him.", "Left the fight."],
		["Carried me out of it."],
		[
			Seam.make("C3", "L4", LAW, NONE, Realm.HEL, "the saga is true. L4: Hel."),
			Seam.make("W1", "L4", LAW, NONE, Realm.HEL, "the saga is true. L4: Hel."),
		]
	)
	result.return_eligible = true
	return result


static func grim() -> Encounter:
	return encounter(
		&"grim",
		"Grim",
		Realm.HEL,
		Realm.HEL,
		["B2|wound, back|back", "B3|nothing in hand|front", "B4|wet to the knee|front"],
		["Never left the hill.", "High and dry, all day."],
		["Grim ran for the ford."],
		[
			Seam.make("B4", "C1", RED, CLAIM, &"", LIE),
			Seam.make("C1", "W1", GREY, CLAIM, &"", ONE_LIES),
		]
	)


static func freydis() -> Encounter:
	var result: Encounter = encounter(
		&"freydis",
		"Freydis",
		Realm.VALHALLA,
		Realm.VALHALLA,
		["B2|wound, back|back", "B3|sword, gripped|front"],
		["Slain in a sea-battle."],
		["She went over first."],
		[Seam.make("C1", "L1", LAW, NONE, Realm.VALHALLA, "the saga is true. L1: Valhalla.")]
	)
	result.pronoun = "her"
	return result


static func returned_hakon(variant: String) -> Encounter:
	var result: Encounter = encounter(
		StringName("hakon_" + variant),
		"Hakon",
		Realm.HEL,
		Realm.VALHALLA,
		["B1|no wound, front|front", "B2|wound, back|back"],
		["%s line." % variant, "Hel taught me better.", "One wound: the chest."],
		[],
		[Seam.make("B1", "C3", RED, CLAIM, &"", LIE)]
	)
	result.returned = true
	result.witness_note = "No witness came back."
	result.plate_label = "Back from Hel. His saga was true."
	return result


static func egil() -> Encounter:
	return encounter(
		&"egil",
		"Egil",
		Realm.HEL,
		Realm.FOLKVANGR,
		["B3|sword, gripped|front", "B4|night-shirt|front"],
		["Raiders, in the night.", "I held our door.", "In my mail, of course."],
		["Nice shirt, though."],
		[
			Seam.make("B4", "C3", RED, CLAIM, &"", LIE),
			Seam.make("C2", "L5", LAW, NONE, Realm.FOLKVANGR, "L5 sends him to Fólkvangr."),
		]
	)


static func ragna() -> Encounter:
	var result: Encounter = encounter(
		&"ragna",
		"Ragna",
		Realm.FOLKVANGR,
		Realm.FOLKVANGR,
		["B1|no wound, front|front", "B5|night-shirt|front"],
		["They came at night.", "I held the door."],
		["She held that door."],
		[Seam.make("C2", "L5", LAW, NONE, Realm.FOLKVANGR, "the saga is true. L5: Fólkvangr.")]
	)
	result.hel_marked = true
	result.plate_label = "Hel asked for her"
	result.pronoun = "her"
	return result


static func ketil() -> Encounter:
	return encounter(
		&"ketil",
		"Ketil",
		Realm.HEL,
		Realm.HEL,
		["B1|wound, front|front", "B3|sword, gripped|front", "B4|wet to the knee|front"],
		["Raiders at the ford.", "I held it. Alone."],
		["Ketil ran first."],
		[Seam.make("C2", "W1", GREY, CLAIM, &"", ONE_LIES)]
	)


static func days() -> Array[DayRules]:
	var two: Array[StringName] = [Realm.VALHALLA, Realm.HEL]
	var three: Array[StringName] = [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR]
	var day_3: DayRules = day(3, 2, 300.0, three, 5)
	day_3.return_slot = 1
	day_3.new_decree_ids = ["L5"]
	day_3.new_doors = [Realm.FOLKVANGR]
	var day_2: DayRules = day(2, 1, 300.0, two, 4)
	day_2.dusk_story = "Eyvind prays."
	return [day(1, 1, 0.0, two, 3), day_2, day_3]


static func queues() -> Array:
	var one: Array[Encounter] = [ulf(), kolbeinn(), asa()]
	var two: Array[Encounter] = [sigvaldi(), hakon(), grim()]
	var three: Array[Encounter] = [freydis(), ragna(), ketil()]
	return [one, two, three]


static func variants() -> Dictionary:
	return {
		&"ignored": returned_hakon("ignored"),
		&"missed": returned_hakon("missed"),
		&"fallback": egil(),
	}


## A desk at day-1 dawn on the whole synthetic slice.
static func desk(slice_rules: SliceRules = null) -> DeskCommands:
	var commands := DeskCommands.new()
	commands.start_run(
		days(), queues(), slice_rules if slice_rules != null else rules(), variants()
	)
	return commands


## A record of `encounter` on a day, for VerdictRules tests.
static func record(soul: Encounter, day_number: int = 2) -> VerdictRecord:
	return VerdictRecord.make(soul, day_number)
