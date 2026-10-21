class_name HudReadout
extends RefCounted
## What the HUD shows at one moment; the desk system fills it from DeskCommands.

var time_left: float = INF
var feathers: int = 0
## (souls admitted today, today's quota).
var quota := Vector2i.ZERO
var huginn_on: bool = false
var huginn_left: int = 0
var promise_open: bool = false
## The clock is in its last stretch (D22): the clock cell turns over.
var warning: bool = false
## Feathers an extra answer costs once today's are spent (D29, D30); 0 hides the note.
var extra_cost: int = 0
