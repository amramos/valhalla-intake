# systems/

Scene-scoped coordinators that connect several entities; never global, never autoloaded.

| System | Role |
|---|---|
| `desk/` | `DeskSystem` connects the desk's entities to `DeskCommands` (the only command layer, D13), seats each soul, runs the clock (which waits for the tale, D5) and owns its helpers: `DeskPins` (the pin gesture and its outcome: a thread drawn in, a thread already made, a no-seam pin's tick, gutter and slack drop, D8, D12, D36), `DeskHighlights` (the selection, the lit pair, a held soul's pair, the mentor's highlight, D28, D48), `DeskHuginn` (knot clicks and asking Huginn, D29, D33) and `DeskMentor` (her guided step, her comment again, the bubble's "Next"). `DeskTelling` seats the sheets and tells the soul's claim, then its witness, behind one consumed click (D4, D7); `DeskNote` builds the note's Captions (quoted pairs, marks), lights the pair a caption quotes and holds the gate while a caption is written (D10, D28, D43). `StampFlow` owns the stamp: prompt, drag, confirm, the thud, the held soul (D9, D48); `StampConsequences` lands what it leaves: the citation and her comment on the note, the feather's fall and the tide's step at the impact (D16, D38). `PresentationGate` owns "a presentation is in progress": it decides each press (consumed, passed or ignored in the slam), pauses and cancels the presentation clocks (ADR-0009); `ThreadBoard` draws the threads and keeps a slack thread's drop off the papers; `DeskReadouts` reads doors, NEW marks and the HUD; `PhaseFlow` keeps the place in the dawn, dusk and ending cards; `HuginnAsk`, `PinSelection` and `ThreadRouter` are pure helpers |
| `caption_strip/` | The clerk's note: the bottom edge of a parchment page with a speaker mark (`NoteMarks`), up to two lines, the message priority (D33) and the quill's written reveal; `Caption` is its typed message (D10, D43) |

A system holds references to the entities it coordinates (set in the owning scene) and connects
their signals itself.
