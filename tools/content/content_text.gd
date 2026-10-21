extends RefCounted
## The days and the slice's shared text, transcribed from the evidence matrix (the desk per day,
## section A) and the ledger (D10, D23, D28-D30, D35, D40). Read by build_content.gd.


static func days() -> Array[Dictionary]:
	return [
		{
			"day": 1,
			"quota": 1,
			"clock": 0.0,
			"doors": [Realm.VALHALLA, Realm.HEL],
			"decrees": 3,
			"citations": false,
			"huginn": 0,
			"new_decrees": [],
			"new_doors": [],
			"return_slot": -1,
			"story": "",
			"queue": ["ulf", "kolbeinn", "hallr", "asa"],
			"dawn":
			[
				"Day 1.",
				"Odin wants 1 soul for Valhalla.",
				"Untimed today.",
				"The Law: L1, L2, L3.",
				"Doors: Valhalla and Hel. Fólkvangr is barred.",
				"The senior valkyrie will show you the first three.",
			],
		},
		{
			"day": 2,
			"quota": 1,
			"clock": 300.0,
			"doors": [Realm.VALHALLA, Realm.HEL],
			"decrees": 4,
			"citations": true,
			"huginn": 0,
			"new_decrees": ["L4"],
			"new_doors": [],
			"return_slot": -1,
			"story":
			(
				"A prayer at your shrine, from Eyvind, your brother: 'Sister. Father's ring is"
				+ " mine now. I wear it on my oar hand. If I fall, know me by it.'"
			),
			"queue": ["sigvaldi", "hakon", "grim", "brand"],
			"dawn":
			[
				"Day 2.",
				"Odin wants 1 soul for Valhalla.",
				"The clock: {clock}. It runs while a soul is at the desk.",
				"NEW L4: Even so, those who fled the battle go to Hel.",
				"Witnesses arrive. Claim against witness makes a grey thread.",
				"Citations begin today: 2 feathers for a stamp against a seam you could see.",
			],
		},
		{
			"day": 3,
			"quota": 2,
			"clock": 300.0,
			"doors": [Realm.VALHALLA, Realm.HEL, Realm.FOLKVANGR],
			"decrees": 5,
			"citations": true,
			"huginn": 2,
			"new_decrees": ["L5"],
			"new_doors": [Realm.FOLKVANGR],
			"return_slot": 1,
			"story": "",
			"queue": ["freydis", "ragna", "ketil"],
			"dawn":
			[
				"Day 3.",
				"Odin wants 2 souls for Valhalla.",
				"The clock: {clock}.",
				(
					"NEW L5: Those who fell defending hearth and kin go to Fólkvangr, whatever"
					+ " L1, L3 and L4 say."
				),
				"NEW door: Fólkvangr opens.",
				(
					"Huginn perches on your desk. He answers only about a thread you made: which"
					+ " side of a grey thread lies. 2 answers a day, 5 s each. A third costs 2"
					+ " feathers."
				),
			],
		},
	]


static func slice() -> SliceData:
	var slice := SliceData.new()
	slice.start_feathers = 10
	slice.quota_met_reward = 2
	slice.quota_short_cost = 1
	slice.citation_cost = 2
	slice.daily_loss_cap = 5
	slice.demote_refill = 5
	slice.huginn_extra_cost = 2
	slice.hel_reward = 4
	slice.rank_names.assign(["Chooser of the Slain", "Gate-warden", "Hall-sweeper"])
	slice.no_seam_seconds = 10.0
	slice.huginn_seconds = 5.0
	slice.clock_warning_seconds = 30.0
	slice.tide_threshold = 3
	slice.hollow_threshold = 2
	slice.liar_decree_id = "L2"
	slice.liar_realm = Realm.HEL
	slice.huginn_claim_answer = "Huginn: the claim lies."
	slice.huginn_witness_answer = "Huginn: the witness lies."
	slice.citation_format = "Citation: %s. %s."
	slice.threaded_line = "You threaded it yourself."
	slice.returned_format = ("%s is back. Hel sent him up the road. He will be at your desk tomorrow.")
	slice.hel_offer_format = (
		"Hel, at the serpent door: 'Tomorrow %s comes to your desk. Send her to me, and I pay"
		+ " four feathers at the stamp.'"
	)
	slice.recap_agree_format = "%s, as the Law and the truth agree."
	slice.recap_legal_format = "The Law sent %s to %s. The truth was %s."
	slice.recap_mercy_format = "You sent %s to %s against %s. The truth agrees."
	slice.recap_neither_format = "You sent %s to %s. The Law said %s. The truth was %s."
	slice.recap_uncertain_format = "%s. Which side lied couldn't be proven at the desk."
	slice.recap_never_line = "Never judged."
	slice.ledger_open_format = "Hel: send %s to Hel. %d feathers."
	slice.ledger_kept_format = "Kept. %s went to Hel. Hel paid %d feathers."
	slice.ledger_broken_format = "Broken. %s went to %s."
	slice.ledger_lapsed_format = "Lapsed. %s was never judged."
	slice.mentor_mercy_warning_format = "Kind. %s. From tomorrow, that costs feathers."
	slice.mentor_illegal_warning_format = "%s. Wrong door. From tomorrow, that costs feathers."
	slice.mentor_mercy_format = "Kind. %s. That cost you two."
	slice.mentor_liar_format = "%s. You let a liar through."
	slice.mentor_honest_format = "%s. Nothing in that saga was a lie."
	slice.mentor_promise_format = "%s. Hel pays well."
	slice.mentor_grey_line = "One of them lies. The body may say which."
	slice.mentor_grey_huginn_line = "Huginn answers that. Two a day."
	slice.desk_text = desk_text()
	return slice


static func desk_text() -> DeskTextData:
	var text := DeskTextData.new()
	text.thread_format = "%s against %s: %s"
	text.no_seam_line = "No seam: those two agree."
	text.no_seam_timed_format = "No seam: those two agree. -%d s"
	text.huginn_select_hover = "Select a grey thread first."
	text.huginn_extra_hover = "Extra answer: 2 feathers."
	text.huginn_bought_format = "Huginn takes 2 feathers. %s"
	text.dusk_citations_format = "Citations today: %d."
	text.dusk_no_citations = "No citations today."
	text.quota_met_format = "Odin wanted %d. Valhalla took %d. +%d feathers."
	text.quota_short_format = "Odin wanted %d. Valhalla took %d. -%d feathers."
	text.tide_title = "Hel's tide"
	text.tide_format = (
		"The worthy you damned march with Hel." + " At the first horn they break the line: %s."
	)
	text.hollow_title = "The hollow hall"
	text.hollow_format = (
		"The liars you let in fled at the first horn." + " Their benches stand empty: %s."
	)
	text.hall_title = "The Hall holds"
	text.hall_text = "Odin counts his einherjar and finds them true. The gate holds, for now."
	text.ending_row_format = "%s: %s. Truth: %s."
	text.ending_ignored = " Ignored."
	text.ending_missed = " Missed."
	text.ending_never_format = "%s: never judged."
	text.returned_name_format = "%s (returned)"
	text.standing_format = "Feathers: %d. Rank: %s."
	text.play_again = "Play again"
	return text
