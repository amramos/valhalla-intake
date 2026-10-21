# systems/

Scene-scoped coordinators that connect several entities; never global, never autoloaded.

| System | Role |
|---|---|
| `desk/` | `DeskSystem` connects the desk's entities to `DeskCommands` (the only command layer, D13): selection, pins, threads, Huginn, the mentor's steps, the clock. `StampFlow` owns the stamp: prompt, drag, confirm, the thud, the held soul (D9, D48). `ThreadBoard` draws the threads; `DeskReadouts` reads doors, NEW marks and the HUD; `PhaseFlow` keeps the place in the dawn, dusk and ending cards; `HuginnAsk`, `PinSelection` and `ThreadRouter` are pure helpers |
| `caption_strip/` | The caption strip and its message priority (D33) |

A system holds references to the entities it coordinates (set in the owning scene) and connects
their signals itself.
