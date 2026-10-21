# data/

Typed `Resource` schemas (`*_data.gd`) and their `.tres` instances: the slice's authored content
and every tunable. Each schema converts to a `core/` type with `to_core()`; core never reads
`data/`.

- `slice.tres` (`SliceData`): the days in order, the returned-soul variants (ignored, missed,
  fallback) and the tunables (feathers, costs, clock, thresholds, Hel's reward, desk text).
- `days/` (`DayData`): quota, clock (0 = untimed), open doors, decrees, citations, Huginn's
  answers, NEW marks, the return slot, and the queue of encounters.
- `encounters/` (`EncounterData`): body facts (`FactData`: id, label, view, hit area), claim and
  witness lines (ids C1…, W1… by order), seams (`SeamData`), both destinations and the truth.
- `decrees/` (`DecreeData`): one decree each, word for word as ledger D32.
- `slice_loader.gd`: `SliceLoader.load_slice() -> DeskCommands`, a desk at day-1 dawn in one call.

Content follows `docs/plans/vertical-slice-matrix.md`. Current state: day 1 with Ulf and
Kolbeinn, and decrees L1–L3 (WP1); the rest of the roster arrives in WP4.
