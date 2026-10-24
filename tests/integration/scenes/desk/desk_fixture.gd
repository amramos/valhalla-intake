extends RefCounted
## Timed desks for the integration tests. `commands()` is day 3: one soul with every kind of
## thread (three grey seams between claim and witness, a red seam from the body to the witness,
## law threads from the body and from the claim), Huginn on the desk, citations on, L5 and
## Fólkvangr marked NEW, and a returned soul behind it. `two_days()` is the same souls over a day 2
## with Fólkvangr barred, then a day 3 that opens it. `instant()` and `normal()` are the text speeds
## a test hands the desk (`Desk.use_options`): at "instant" the tale shows at once (D37), so a test
## can press a line right after the dawn card; at "normal" it is told at 40 cps (D4).

const DECREES: Array[String] = [
	(
		"Valhalla takes only those slain by a weapon in battle. "
		+ "Death by sickness, age or accident goes to Hel."
	),
	"Whoever lies to the Gate goes to Hel, whatever else the Law says.",
	"Even so, a warrior without a weapon in hand goes to Hel.",
	"Even so, those who fled the battle go to Hel.",
	"Those who fell defending hearth and kin go to Fólkvangr, whatever I, III and IV say.",
]
const CLOCK_SECONDS := 300.0


static func commands() -> DeskCommands:
	var result := DeskCommands.new()
	var days: Array[DayRules] = [_day(3)]
	result.start_run(days, [[_first(), _second()]], SliceRules.new(), {})
	return result


## The first soul as a liar bound for Hel, or as a hero bound for Valhalla: everything else (name,
## witness, every line, every seam) the same, for the liar-and-hero leak test (D1, D45).
static func matched(liar: bool) -> DeskCommands:
	var soul: Encounter = _first()
	soul.liar = liar
	soul.legal_realm = Realm.HEL if liar else Realm.VALHALLA
	soul.worthy_realm = soul.legal_realm
	var result := DeskCommands.new()
	var days: Array[DayRules] = [_day(3)]
	result.start_run(days, [[soul]], SliceRules.new(), {})
	return result


static func instant() -> Options:
	var options := Options.new()
	options.text_speed = Options.INSTANT
	return options


static func normal() -> Options:
	return Options.new()


static func two_days() -> DeskCommands:
	var result := DeskCommands.new()
	var days: Array[DayRules] = [_day(2), _day(3)]
	result.start_run(days, [[_first()], [_second()]], SliceRules.new(), {})
	return result


static func _day(number: int) -> DayRules:
	var day := DayRules.new()
	day.day = number
	day.quota = 1
	day.clock_seconds = CLOCK_SECONDS
	day.doors_open = [Realm.VALHALLA, Realm.HEL]
	day.citations = true
	var decrees: int = 4
	if number >= 3:
		day.doors_open.append(Realm.FOLKVANGR)
		day.huginn_answers = 2
		day.new_doors = [Realm.FOLKVANGR]
		decrees = 5
	day.new_decree_ids = ["L%d" % decrees]
	for index: int in range(decrees):
		day.decrees.append(
			EvidenceItem.make("L%d" % (index + 1), EvidenceItem.Group.LAW, DECREES[index])
		)
	return day


static func _first() -> Encounter:
	var first := Encounter.new()
	first.id = &"fixture_first"
	first.soul_name = "Asgaut"
	first.witness_name = "Orm"
	first.legal_realm = Realm.HEL
	first.worthy_realm = Realm.HEL
	first.liar = true
	first.items = [
		_body("B1", "no wound, front", &"front", &"torso_front"),
		_body("B2", "no wound, back", &"back", &"torso_back"),
		_body("B3", "nothing in hand", &"front", &"hand_right"),
		_body("B4", "neck, broken", &"front", &"neck"),
		EvidenceItem.make("C1", EvidenceItem.Group.CLAIM, "Held the shield-wall."),
		EvidenceItem.make("C2", EvidenceItem.Group.CLAIM, "Held my own door."),
		EvidenceItem.make("C3", EvidenceItem.Group.CLAIM, "Fell at dawn."),
		EvidenceItem.make("W1", EvidenceItem.Group.WITNESS, "He ran at dawn."),
		EvidenceItem.make("W2", EvidenceItem.Group.WITNESS, "A spear in the chest."),
		EvidenceItem.make("W3", EvidenceItem.Group.WITNESS, "I saw it all."),
	]
	first.seams = [
		Seam.make("C1", "W1", Seam.Kind.GREY, Seam.Liar.WITNESS, &"", "one of them lies."),
		Seam.make("C3", "W3", Seam.Kind.GREY, Seam.Liar.CLAIM, &"", "one of them lies."),
		Seam.make("C3", "W2", Seam.Kind.GREY, Seam.Liar.CLAIM, &"", "one of them lies."),
		Seam.make("B1", "W2", Seam.Kind.RED, Seam.Liar.WITNESS, &"", "the body gives the lie."),
		Seam.make(
			"B3", "L3", Seam.Kind.LAW, Seam.Liar.NONE, Realm.HEL, "Decree III sends him to Hel."
		),
		Seam.make(
			"C2",
			"L5",
			Seam.Kind.LAW,
			Seam.Liar.NONE,
			Realm.FOLKVANGR,
			"Decree V sends him to Fólkvangr."
		),
	]
	return first


static func _second() -> Encounter:
	var second := Encounter.new()
	second.id = &"hakon_returned_missed"
	second.soul_name = "Second"
	second.returned = true
	second.plate_label = "Back from Hel. His saga was true."
	second.legal_realm = Realm.VALHALLA
	second.worthy_realm = Realm.VALHALLA
	second.items = [_body("B1", "wound, front", &"front", &"torso_front")]
	return second


static func _body(id: String, label: String, view: StringName, place: StringName) -> EvidenceItem:
	return EvidenceItem.make(id, EvidenceItem.Group.BODY, label, view, place)
