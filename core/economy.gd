class_name Economy
extends RefCounted
## Feathers and rank (GDD §3.8, D36, D40). Losses (citations, quota shortfall) are capped per day;
## spends (Huginn's extra answer) and rewards are not, and never count as losses. Demotion is
## checked after every change: at 0 the clerk drops a rank and refills.

var feathers: int = 0
## 0 is the highest rank; see SliceRules.rank_names.
var rank: int = 0
var losses_today: int = 0
## Demotions so far this run; a caller compares it before and after a change.
var demotions: int = 0

var _rules: SliceRules


func _init(rules: SliceRules) -> void:
	_rules = rules
	feathers = rules.start_feathers


func start_day() -> void:
	losses_today = 0


## Applies a loss under the daily cap and returns the feathers actually lost.
func lose(amount: int) -> int:
	var room: int = maxi(_rules.daily_loss_cap - losses_today, 0)
	var applied: int = clampi(amount, 0, room)
	losses_today += applied
	feathers -= applied
	_check_demotion()
	return applied


func can_spend(amount: int) -> bool:
	return feathers >= amount


## An uncapped spend; the caller checks can_spend first.
func spend(amount: int) -> void:
	feathers -= amount
	_check_demotion()


func gain(amount: int) -> void:
	feathers += amount
	_check_demotion()


func lowest_rank() -> int:
	return maxi(_rules.rank_names.size() - 1, 0)


func rank_name() -> String:
	if rank < _rules.rank_names.size():
		return _rules.rank_names[rank]
	return ""


func _check_demotion() -> void:
	if feathers > 0:
		return
	if rank < lowest_rank():
		rank += 1
		demotions += 1
		feathers = _rules.demote_refill
	else:
		# Cast down is outside the slice (D23): the lowest rank simply stays at 0.
		feathers = 0
