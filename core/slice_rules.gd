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
## The desk's presentation text (matrix section A); see DeskText.
var text: DeskText = DeskText.new()
## Recap outcome lines (A7). Formats: the realm; or pronoun and realms; mercy ends on the decree.
var recap_agree_format: String = "%s, as the Law and the truth agree."
var recap_legal_format: String = "The Law sent %s to %s. The truth was %s."
var recap_mercy_format: String = "You sent %s to %s against %s. The truth agrees."
var recap_neither_format: String = "You sent %s to %s. The Law said %s. The truth was %s."
var recap_uncertain_format: String = "%s. Which side lied couldn't be proven at the desk."
var recap_never_line: String = "Never judged."
## The ledger's entry for Hel's promise (A6). Formats: the soul, then the reward or the realm.
var ledger_open_format: String = "Hel: send %s to Hel. %d feathers."
var ledger_kept_format: String = "Kept. %s went to Hel. Hel paid %d feathers."
var ledger_broken_format: String = "Broken. %s went to %s."
var ledger_lapsed_format: String = "Lapsed. %s was never judged."
## Rank names, highest first; a demotion moves one step down the list.
var rank_names: Array[String] = ["Chooser of the Slain", "Gate-warden", "Hall-sweeper"]
## The decree a lie seam reaches, and where it sends a liar (L2, D32).
var liar_decree_id: String = "L2"
var liar_realm: StringName = Realm.HEL
var huginn_claim_answer: String = "The claim lies."
var huginn_witness_answer: String = "The witness lies."
## Format: the decree id, then the cited pair (A3).
var citation_format: String = "Citation: %s. %s."
var threaded_line: String = "You threaded it yourself."
## Format: the returned soul's name.
var returned_format: String = "%s is back."
## Format: the named soul.
var hel_offer_format: String = "Hel's offer: send %s to her tomorrow."
## The mentor's comments (matrix A2). Formats take the cited pair (A3). Day 1 stamps are only
## warnings (D28); from day 2 an illegal stamp names whether the soul lied.
var mentor_mercy_warning_format: String = "Kind. %s. From tomorrow, that costs feathers."
var mentor_illegal_warning_format: String = "%s. Wrong door. From tomorrow, that costs feathers."
var mentor_mercy_format: String = "Kind. %s. That cost you two."
var mentor_liar_format: String = "%s. You let a liar through."
var mentor_honest_format: String = "%s. Nothing in that saga was a lie."
var mentor_promise_format: String = "%s. Hel pays well."
## On the day's first grey thread: without Huginn on the desk, then with him.
var mentor_grey_line: String = "One of them lies. The body may say which."
var mentor_grey_huginn_line: String = "Huginn answers that. Two a day."
