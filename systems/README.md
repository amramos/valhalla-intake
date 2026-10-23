# systems/

Scene-scoped coordinators that connect several entities; never global, never autoloaded.

| System | Role |
|---|---|
| `desk/` | `DeskSystem` connects the desk's entities to `DeskCommands` (the only command layer, D13): selection, pins, threads, Huginn, the mentor's steps, the clock (which waits for the tale, D5). `DeskTelling` tells the soul's claim, then its witness, behind one consumed click (D4, D7); `DeskNote` builds the note's Captions (quoted pairs, marks), lights the pair a caption quotes and holds the gate while a caption is written (D10, D28, D43). `StampFlow` owns the stamp: prompt, drag, confirm, the thud, the held soul (D9, D48). `PresentationGate` owns "a presentation is in progress": it decides each press (consumed, passed or ignored in the slam), pauses and cancels the presentation clocks (ADR-0009); `ThreadBoard` draws the threads; `DeskReadouts` reads doors, NEW marks and the HUD; `PhaseFlow` keeps the place in the dawn, dusk and ending cards; `HuginnAsk`, `PinSelection` and `ThreadRouter` are pure helpers |
| `caption_strip/` | The clerk's note: the bottom edge of a parchment page with a speaker mark (`NoteMarks`), up to two lines, the message priority (D33) and the quill's written reveal; `Caption` is its typed message (D10, D43) |

A system holds references to the entities it coordinates (set in the owning scene) and connects
their signals itself.
