class_name StampResult
extends RefCounted
## What a stamp did. `correct` is for rules and tests; the desk never shows it (D9).

var valid: bool = false
var realm: StringName = &""
## The stamped realm is the legal one.
var correct: bool = false
## A citation was given: citations are on and a visible seam showed the legal realm.
var citation: bool = false
## Day 1: the citation that would have been given, as a warning only (D28).
var warning: bool = false
var citation_text: String = ""
var citation_a: String = ""
var citation_b: String = ""
## Feathers the citation actually cost, after the daily loss cap.
var citation_loss: int = 0
## Wrong, and the player had pinned the seam that showed it (D8).
var ignored: bool = false
## Wrong, but only an unanswered grey thread showed it: permitted uncertainty (D37).
var uncertain: bool = false
## Feathers paid by a kept request at this stamp (Hel, D29).
var reward: int = 0
## The net change at this stamp: citation, reward and any demotion refill.
var feathers_delta: int = 0
var demoted: bool = false
