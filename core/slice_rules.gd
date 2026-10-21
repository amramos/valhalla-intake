class_name SliceRules
extends RefCounted
## The slice's tunables and desk text, filled from data (data/slice.tres).

var start_feathers: int = 10
var quota_met_reward: int = 2
var quota_short_cost: int = 1
var citation_cost: int = 2
var daily_loss_cap: int = 5
var demote_refill: int = 5
var no_seam_seconds: float = 10.0
var huginn_seconds: float = 5.0
var huginn_extra_cost: int = 2
var hel_reward: int = 4
var tide_threshold: int = 3
var hollow_threshold: int = 2
var clock_warning_seconds: float = 30.0
## Rank names, highest first; a demotion moves one step down the list.
var rank_names: Array[String] = ["Chooser of the Slain", "Gate-warden", "Hall-sweeper"]
## The decree a lie seam reaches, and where it sends a liar (L2, D32).
var liar_decree_id: String = "L2"
var liar_realm: StringName = Realm.HEL
var huginn_claim_answer: String = "The claim lies."
var huginn_witness_answer: String = "The witness lies."
## Format: the decree id, then each side of the pair.
var citation_format: String = "Citation: %s. %s against %s."
var threaded_line: String = "You threaded it yourself."
var uncertain_line: String = "Couldn't be proven at the desk."
## Format: the returned soul's name.
var returned_format: String = "%s is back."
## Format: the named soul, then the reward.
var hel_offer_format: String = "Hel's offer: send %s to her tomorrow, and she pays %d feathers."
## Format: the named soul, then the promise's state.
var promise_format: String = "Hel's promise, %s: %s."
