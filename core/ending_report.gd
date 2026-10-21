class_name EndingReport
extends RefCounted
## The slice ending (D23): every encounter, the souls that tipped it, and the clerk's standing.

const TIDE := &"tide"
const HOLLOW := &"hollow"
const HALL_HOLDS := &"hall_holds"

var entries: Array[EndingEntry] = []
## Souls not worthy of Hel stamped to Hel, one name per encounter.
var tide_names: Array[String] = []
## Souls not worthy of Valhalla admitted to Valhalla, one name per encounter.
var hollow_names: Array[String] = []
var never_judged: Array[String] = []
var tide_reached: bool = false
var hollow_reached: bool = false
## TIDE, HOLLOW or HALL_HOLDS; Hel's tide wins when both thresholds are reached.
var outcome: StringName = HALL_HOLDS
## Hel's promise as the ledger ends it: the named soul ("" if none was offered) and its state.
var promise_soul: String = ""
var promise_state: StringName = &"none"
var feathers: int = 0
var rank: int = 0
var rank_name: String = ""
