# systems/

Scene-scoped coordinators that connect several entities; never global, never autoloaded.

| System | Role |
|---|---|
| `desk/` | `DeskSystem` connects the desk's entities to `DeskCommands` (the only command layer, D13): selection, pins, threads, stamping, the clock. `ThreadBoard` draws the threads; `PinSelection`, `ThreadRouter` and `PhaseFlow` (the minimal phase cards) are pure helpers |
| `caption_strip/` | The caption strip and its message priority (D33) |

A system holds references to the entities it coordinates (set in the owning scene) and connects
their signals itself.
