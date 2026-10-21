extends RefCounted
## The 14 authored encounters, transcribed from docs/plans/vertical-slice-matrix.md (days 1-3,
## the slot-10 branches, A3's cited pairs and A7's truth lines). Read by build_content.gd.
##
## body: [id, label, place]; place is one of chest, back, right hand, left hand, neck, legs, hem.
## seams: [a, b, "red"|"grey"] (the claim side lies) or [a, b, "law", realm, caption]. The first
## seam that shows the legal realm is the one a citation names (A3), so it is listed first.
## cite: [a, b, A3's pair text]. herrings: "a|b" pairs that look like seams but aren't (D24).
## mentor (guided souls, A2): [bubble, "read"|"pin"|"stamp", lit] where lit is "body", "body+claim",
## a pair "C1|L1", "door:<realm>" (she points at that door; A2 "the doors", read as the
## tutorial's door as in WP0), or "" for nothing.

const LIE := "the body gives the lie."


static func all() -> Array[Dictionary]:
	var souls: Array[Dictionary] = []
	souls.append_array(_day_one())
	souls.append_array(_day_two())
	souls.append_array(_day_three())
	souls.append_array(_returned())
	return souls


static func _day_one() -> Array[Dictionary]:
	return [
		{
			"id": "ulf",
			"name": "Ulf",
			"pronoun": "him",
			"legal": "valhalla",
			"worthy": "valhalla",
			"liar": false,
			"truth": "Ulf was speared in the shield-wall at Ness, sword up to the end.",
			"body":
			[
				["B1", "spear wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "sword in hand", "right hand"],
			],
			"claim":
			[
				"Speared, in battle.",
				"Took it in the chest.",
				"Sword up to the end.",
				"Sif gets the goat.",
			],
			"seams":
			[["C1", "L1", "law", "valhalla", "the saga is true. L1 sends him to Valhalla."]],
			"cite": ["C1", "L1", "'Speared, in battle' and L1"],
			"mentor":
			[
				["Hover each mark.", "read", "body"],
				["Line one, decree one.", "read", "C1|L1"],
				["Click one, then the other.", "pin", "C1|L1"],
				["The Law agrees. Stamp him.", "stamp", "door:valhalla"],
			],
		},
		{
			"id": "kolbeinn",
			"name": "Kolbeinn",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "hel",
			"liar": true,
			"truth": "Kolbeinn died in his bed after the feast, full of mead. His wife did see.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "nothing in hand", "right hand"],
				["B4", "night-shirt only, bare feet", "hem"],
			],
			"claim":
			[
				"Danes axed my chest.",
				"Mail on. Shield up.",
				"Died sword in hand.",
				"My wife will tell you.",
			],
			"seams":
			[
				["B1", "C1", "red"],
				["B4", "C2", "red"],
				["B3", "C3", "red"],
				["B3", "L3", "law", "hel", "L3 sends him to Hel."],
			],
			"cite": ["B1", "C1", "No wound on his chest, and 'Danes axed my chest'"],
			"mentor":
			[
				["Read him. All of him.", "read", "body+claim"],
				["His chest. His C1.", "read", "B1|C1"],
				["Pin them.", "pin", "B1|C1"],
				["Bodies don't lie. L2 takes liars.", "stamp", "door:hel"],
			],
		},
		{
			"id": "hallr",
			"name": "Hallr",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "hel",
			"liar": true,
			"truth":
			"Hallr fell off the hall roof the night before his duel, drunk, sword out. Gorm never came.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "sword in hand", "right hand"],
				["B4", "broken neck", "neck"],
			],
			"claim":
			[
				"Gorm called me out.",
				"Sword still sheathed.",
				"Blade in my chest.",
				"Not a bone broken.",
			],
			"seams": [["B1", "C3", "red"], ["B4", "C4", "red"], ["B3", "C2", "red"]],
			"cite": ["B1", "C3", "No wound on his chest, and 'Blade in my chest'"],
			"mentor":
			[
				["Your turn to read.", "read", "body+claim"],
				["His chest. His C3.", "read", "B1|C3"],
				["Pin them.", "pin", "B1|C3"],
				["Where does a liar go?", "stamp", ""],
			],
		},
		{
			"id": "asa",
			"name": "Asa",
			"pronoun": "her",
			"legal": "hel",
			"worthy": "valhalla",
			"liar": false,
			"truth":
			"Asa fell in battle on the beach. Her spear broke in a Dane and she fought on bare-handed.",
			"body":
			[
				["B1", "spear wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "nothing in hand", "right hand"],
			],
			"claim":
			[
				"Danes on the beach.",
				"Spear in both hands.",
				"It broke. I kept on.",
				"My girl has the farm.",
			],
			"seams": [["B3", "L3", "law", "hel", "the saga is true. L3 sends her to Hel."]],
			"cite": ["B3", "L3", "Her empty hand, and L3"],
			"herrings": ["B3|C2"],
		},
	]


static func _day_two() -> Array[Dictionary]:
	return [
		{
			"id": "sigvaldi",
			"name": "Sigvaldi",
			"pronoun": "him",
			"legal": "valhalla",
			"worthy": "valhalla",
			"liar": false,
			"truth": "Sigvaldi held the wall at Ness until it broke. A Dane got in behind him.",
			"body":
			[
				["B1", "spear wound, chest", "chest"],
				["B2", "spear wound, back", "back"],
				["B3", "sword in hand", "right hand"],
			],
			"claim":
			[
				"Fell in battle. Ness.",
				"My sword broke early.",
				"Took a Dane's instead.",
				"Mother kept my bed.",
			],
			"witness_name": "Bjorn, his shield-brother",
			"witness": ["Our wall broke.", "A Dane got in behind.", "Speared his back."],
			"seams":
			[["C1", "L1", "law", "valhalla", "the saga is true. L1 sends him to Valhalla."]],
			"cite": ["C1", "L1", "'Fell in battle. Ness' and L1"],
			"herrings": ["B2|L4", "B2|C1", "B3|C2"],
		},
		{
			"id": "hakon",
			"name": "Hakon",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "valhalla",
			"liar": false,
			"return_eligible": true,
			"truth":
			"Hakon carried Ivar out of the fight and took a spear in the back for it. Ivar died anyway.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "spear wound, back", "back"],
				["B3", "sword in hand", "right hand"],
			],
			"claim":
			[
				"Ivar owed me a knife.",
				"He fell. I lifted him.",
				"Left the fight.",
				"A spear, in my back.",
			],
			"witness_name": "Ivar",
			"witness": ["No kin of his. A Jute.", "Carried me out of it.", "I died anyway. Sorry."],
			"seams":
			[
				["C3", "L4", "law", "hel", "the saga is true. L4 sends him to Hel."],
				["W2", "L4", "law", "hel", "the saga is true. L4 sends him to Hel."],
			],
			"cite": ["C3", "L4", "'Left the fight' and L4"],
		},
		{
			"id": "grim",
			"name": "Grim",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "hel",
			"liar": true,
			"truth":
			"Grim ran off the hill for the ford. They speared him from behind in the water. His dog stayed.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "spear wound, back", "back"],
				["B3", "nothing in hand", "right hand"],
				["B4", "wet to the knee", "legs"],
			],
			"claim":
			[
				"Never left the hill.",
				"Dry when I fell.",
				"No wound on my back.",
				"Never in the water.",
			],
			"witness_name": "Orm, who stayed",
			"witness": ["He ran off the hill.", "Waded into the ford.", "The dog stayed."],
			"seams":
			[
				["B2", "C3", "red"],
				["B4", "C2", "red"],
				["C1", "W1", "grey"],
				["C4", "W2", "grey"],
				["B3", "L3", "law", "hel", "L3 sends him to Hel."],
			],
			"cite": ["B2", "C3", "His back wound, and 'No wound on my back'"],
		},
		{
			"id": "brand",
			"name": "Brand",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "hel",
			"liar": true,
			"truth":
			"Brand bought his seat on the ship. He hid under a bench at the boarding and was speared there.",
			"body":
			[
				["B1", "spear wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "nothing in hand", "right hand"],
				["B4", "soft hands, no calluses", "left hand"],
			],
			"claim":
			[
				"Thirty winters rowing.",
				"Hands hard as oak.",
				"One wound: my back.",
				"Mother sent cheese.",
			],
			"witness_name": "Toki, a rower",
			"witness": ["He never rowed. Ever.", "Hid under a bench.", "Smelled of cheese."],
			"seams":
			[
				["B4", "C2", "red"],
				["B1", "C3", "red"],
				["B2", "C3", "red"],
				["C1", "W1", "grey"],
				["B3", "L3", "law", "hel", "L3 sends him to Hel."],
			],
			"cite": ["B4", "C2", "Soft hands, and 'Hands hard as oak'"],
		},
	]


static func _day_three() -> Array[Dictionary]:
	return [
		{
			"id": "freydis",
			"name": "Freydis",
			"pronoun": "her",
			"legal": "valhalla",
			"worthy": "valhalla",
			"liar": false,
			"truth":
			"Freydis, the jarl's skald, went over the rail first. A Dane behind the mast speared her.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "spear wound, back", "back"],
				["B3", "sword in hand", "right hand"],
				["B4", "soft hands, no calluses", "left hand"],
			],
			"claim":
			[
				"Slain in a sea-battle.",
				"Skald, not a rower.",
				"First over their rail.",
				"Verse half done. Pity.",
			],
			"witness_name": "Bersi, a crewman",
			"witness": ["She went over first.", "One hid by the mast.", "Got her from behind."],
			"seams":
			[["C1", "L1", "law", "valhalla", "the saga is true. L1 sends her to Valhalla."]],
			"cite": ["C1", "L1", "'Slain in a sea-battle' and L1"],
			"herrings": ["B2|L4", "B2|C3", "B4|C3"],
		},
		{
			"id": "ragna",
			"name": "Ragna",
			"pronoun": "her",
			"legal": "folkvangr",
			"worthy": "folkvangr",
			"liar": false,
			"hel_marked": true,
			"plate": "Hel asked for her",
			"truth": "Ragna held her door while her boys got out. The raiders fired the roof.",
			"body":
			[
				["B1", "no wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "sword in hand", "right hand"],
				["B4", "broken neck", "neck"],
				["B5", "night-shirt only, bare feet", "hem"],
			],
			"claim":
			[
				"They came at night.",
				"I held the door.",
				"My boys behind me.",
				"Then the roof fell.",
			],
			"witness_name": "Skeggi, one of the raiders",
			"witness": ["She held that door.", "So we fired the roof.", "Her boys got out."],
			"seams":
			[
				["C2", "L5", "law", "folkvangr", "the saga is true. L5 sends her to Fólkvangr."],
				["C3", "L5", "law", "folkvangr", "the saga is true. L5 sends her to Fólkvangr."],
				["W1", "L5", "law", "folkvangr", "the saga is true. L5 sends her to Fólkvangr."],
			],
			"cite": ["C2", "L5", "'I held the door' and L5"],
			"herrings": ["B5|C2", "B1|C2", "B2|C2", "B4|C2", "C4|L1"],
		},
		{
			"id": "ketil",
			"name": "Ketil",
			"pronoun": "him",
			"legal": "hel",
			"worthy": "hel",
			"liar": true,
			"truth":
			"Ketil ran at the first spear. They caught him in the ford; he turned too late.",
			"body":
			[
				["B1", "spear wound, chest", "chest"],
				["B2", "no wound, back", "back"],
				["B3", "sword in hand", "right hand"],
				["B4", "wet to the knee", "legs"],
			],
			"claim":
			[
				"Raiders at the ford.",
				"Held it. Never ran.",
				"Speared in the chest.",
				"Sigrid will sing it.",
			],
			"witness_name": "Hauk, his neighbour",
			"witness": ["Ketil ran first.", "Caught in the ford.", "He turned. Too late."],
			"seams": [["C2", "W1", "grey"]],
			"cite": ["C2", "W1", "Huginn's answer, and 'Held it. Never ran'"],
			"herrings": ["B1|W1", "B4|C2", "B4|W1"],
		},
	]


static func _returned() -> Array[Dictionary]:
	var souls: Array[Dictionary] = []
	for variant: Array in [
		["hakon_ignored", "You read it. Then Hel.", "Hel taught me better."],
		["hakon_missed", "You didn't even look.", "Hel had time to talk."],
	]:
		(
			souls
			. append(
				{
					"id": variant[0],
					"name": "Hakon",
					"pronoun": "him",
					"legal": "hel",
					"worthy": "valhalla",
					"liar": true,
					"returned": true,
					"plate": "Back from Hel. His saga was true.",
					"witness_note": "No witness came back.",
					"truth": "Hakon's saga was true. Hel taught him to hide the wound in his back.",
					"body":
					[
						["B1", "no wound, chest", "chest"],
						["B2", "spear wound, back", "back"],
						["B3", "sword in hand", "right hand"],
					],
					"claim":
					[variant[1], variant[2], "One wound: the chest.", "Ivar owed me a knife."],
					"seams": [["B1", "C3", "red"], ["B2", "C3", "red"]],
					"cite": ["B1", "C3", "No wound on his chest, and 'One wound: the chest'"],
				}
			)
		)
	(
		souls
		. append(
			{
				"id": "egil",
				"name": "Egil",
				"pronoun": "him",
				"legal": "hel",
				"worthy": "folkvangr",
				"liar": true,
				"truth":
				(
					"Egil held his door against raiders in his night-shirt while Hild gave birth."
					+ " He lied about the mail."
				),
				"body":
				[
					["B1", "spear wound, chest", "chest"],
					["B2", "no wound, back", "back"],
					["B3", "sword in hand", "right hand"],
					["B4", "night-shirt only, bare feet", "hem"],
				],
				"claim":
				[
					"Raiders, in the night.",
					"Hild was in childbed.",
					"I held our door.",
					"In my mail, of course.",
				],
				"witness_name": "Kalf, one of the raiders",
				"witness":
				["Held his door. Long.", "Swore all the while.", "No mail. Just a shirt."],
				"seams":
				[
					["B4", "C4", "red"],
					["C4", "W3", "grey"],
					["C3", "L5", "law", "folkvangr", "L5 sends him to Fólkvangr."],
					["W1", "L5", "law", "folkvangr", "L5 sends him to Fólkvangr."],
				],
				"cite": ["B4", "C4", "A night-shirt, and 'In my mail, of course'"],
			}
		)
	)
	return souls
