# core/

Pure logic with no node or scene dependency: rules, calculations, state machines, enums.
Everything here is testable without a scene tree, and depends on nothing else in the project.

## The desk's rules

- `desk_commands.gd` (`DeskCommands`): the **one command layer**. The desk UI and the text
  harness (`tools/harness/`) call only its methods and read only its getters and signals.
- `run_state.gd`: the day, the queue, feathers and rank, every verdict record, Hel's promise and
  the return arc; the day-end bookkeeping (quota, dusk report).
- Rules, each a static or small class with its own GUT test in `tests/unit/core/`:
  - `pin_resolver.gd`: a pin is THREAD, NO_SEAM (red herrings included), ALREADY or INVALID;
  - `verdict_rules.gd`: correct, citation or day-1 warning, ignored or missed, permitted
    uncertainty (an unanswered grey thread), and the ending's mark;
  - `economy.gd`: the daily loss cap, uncapped spends, demotion after every change;
  - `day_clock.gd`: real time plus action costs, pause, the 30 s warning;
  - `ending_calculator.gd`: Hel's tide and the hollow hall, per encounter by the worthy realm.
- Shared words, so the desk and the text harness print the same text: `screen_text.gd` (dawn,
  dusk, the ending), `desk_text.gd` (the text no rule composes), `caption_formatter.gd` (a thread's
  caption names the pair by its words: quoted excerpts, body labels, decrees by numeral) and
  `decree_numeral.gd` (decree ids to "I".."V"; ids stay in data and commands).
- `options.gd`: text speed, reduce motion, volume and mute, read from `user://options.cfg` with
  validated defaults.
- Value types: `realm.gd`, `evidence_item.gd`, `seam.gd`, `encounter.gd`, `day_rules.gd`,
  `slice_rules.gd` (the tunables), `verdict_record.gd`, and the results `pin_result.gd`,
  `stamp_result.gd`, `dusk_report.gd`, `ending_report.gd`, `ending_entry.gd`.

`data/` converts authored resources into these types (`to_core()`); nothing here knows `data/`.
