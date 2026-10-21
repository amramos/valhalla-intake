class_name DuskReport
extends RefCounted
## What the dusk cards show for one day (D15): citations already given, the quota, a recap of up
## to 3 souls, requests, the story beat and the clerk's standing.

var day: int = 0
## The citation lines given at today's stamps.
var citations: Array[String] = []
var quota: int = 0
## Souls stamped to Valhalla today.
var admitted: int = 0
## The quota result in feathers: +reward, or minus the shortfall actually lost (capped). A
## demotion refill is not counted here; see demoted.
var quota_delta: int = 0
## The quota result dropped the clerk a rank (and refilled the feathers).
var demoted: bool = false
## "<name>: <what really happened>", at most 3.
var recap: Array[String] = []
## God requests and the ledger: Hel's offer, the promise's state.
var requests: Array[String] = []
var story: String = ""
## "<name> is back." when a returned soul waits tomorrow (D2); "" otherwise.
var returned_line: String = ""
var never_judged: Array[String] = []
## Feathers when the day began, and every change since, in order, with its cause (D36).
var feathers_at_dawn: int = 0
var feather_lines: Array[String] = []
var feathers: int = 0
var rank: int = 0
var rank_name: String = ""
