class_name EndingEntry
extends RefCounted
## One encounter on the slice-ending screen: the verdict beside the truth (D15, D23).

var soul_name: String = ""
var day: int = 0
## The stamped realm; &"" when never judged.
var verdict: StringName = &""
## The worthy destination: the truth the ending counts by.
var worthy: StringName = &""
var truth: String = ""
## &"" (right), &"ignored", &"missed", &"uncertain" or &"never" (VerdictRecord).
var mark: StringName = &""
