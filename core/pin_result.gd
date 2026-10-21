class_name PinResult
extends RefCounted
## What a pin did.

enum Kind { THREAD, NO_SEAM, ALREADY, INVALID }

var kind: Kind = Kind.INVALID
## THREAD and ALREADY: the seam threaded; null otherwise.
var seam: Seam = null
## Clock time the pin cost (D24); 0 when untimed or not a no-seam pin.
var seconds_lost: float = 0.0
