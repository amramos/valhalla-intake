class_name Ledger
extends RefCounted
## The ledger's entry for Hel's promise (matrix A6), in every state after her offer.


## "" before the offer (state &"none").
static func line(state: StringName, soul: String, realm: StringName, rules: SliceRules) -> String:
	match state:
		RunState.PROMISE_OPEN:
			return rules.ledger_open_format % [soul, rules.hel_reward]
		RunState.PROMISE_KEPT:
			return rules.ledger_kept_format % [soul, rules.hel_reward]
		RunState.PROMISE_BROKEN:
			return rules.ledger_broken_format % [soul, Realm.display_name(realm)]
		RunState.PROMISE_LAPSED:
			return rules.ledger_lapsed_format % soul
	return ""
