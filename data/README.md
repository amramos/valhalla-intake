# data/

Typed `Resource` schemas (`*_data.gd`) and their `.tres` instances: the slice's authored content
and every tunable. Each schema converts to a `core/` type with `to_core()`; core never reads
`data/`.

- `slice.tres` (`SliceData`): the days in order, the returned-soul variants (ignored, missed,
  fallback), the tunables (feathers, costs, clock, thresholds, Hel's reward) and the shared text
  of matrix section A (citations, recap, ledger, the mentor's comments; `DeskTextData` holds the
  text only the UI formats).
- `days/` (`DayData`): quota, clock (0 = untimed), open doors, decrees, citations, Huginn's
  answers, NEW marks, the return slot, the dawn card's lines, the dusk story and the queue.
- `encounters/` (`EncounterData`): body facts (`FactData`: id, label, view, hit area), claim and
  witness lines (ids C1…, W1… by order), seams (`SeamData`, with A3's cited pair text), red
  herrings (for the authoring check), the mentor's guided steps (`MentorStepData`), both
  destinations and the truth.
- `decrees/` (`DecreeData`): one decree each, word for word as ledger D32.
- `slice_loader.gd`: `SliceLoader.load_slice() -> DeskCommands`, a desk at day-1 dawn in one call.

Content follows `docs/plans/vertical-slice-matrix.md`, transcribed in `tools/content/` and
rebuilt with `godot --headless --path . -s tools/content/build_content.gd`; edit the transcription
and rebuild rather than editing a `.tres` by hand. `tests/unit/data/authoring_check_test.gd` checks
it (plan §2.27). Current state: the whole slice, 14 encounters on three days, L1-L5 (WP4).
