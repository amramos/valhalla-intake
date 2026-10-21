# tools/harness/

The headless text harness (ledger D13): the slice played as text, for blind AI playtesters and
for debugging. Never shipped. It calls the same `DeskCommands` as the desk, and prints only what
the desk shows: never a legal or worthy destination, the seam list or the truth (the dusk recap and
the ending screen reveal the truth by design). `tests/unit/tools/harness/harness_test.gd` checks
that.

```bash
godot --headless -s tools/harness/play.gd -- <session-file> new          # start over
godot --headless -s tools/harness/play.gd -- <session-file> begin
godot --headless -s tools/harness/play.gd -- <session-file> pin C1 L1
godot --headless -s tools/harness/play.gd -- <session-file> stamp valhalla
```

Each run replays the session file (one accepted command per line), runs the new command, appends
it if the desk accepted it, then prints the result, the desk and the available actions.

Screens, as the game shows them, with the same text (`ScreenText`, `DeskText`): the title, the
dawn card, the desk, the dusk cards, the ending and the pause menu. The session starts on the
title.

Commands: `start` and `quit` (title); `begin` (dawn); `pin <id> <id>`, `huginn <thread>`, `buy`,
`ack` (the mentor's read step), `stamp <realm>`, `next` (the next soul after a citation holds the
desk, D48) on the desk; `next` (turn the card; after the last, the next dawn) and `skip` (Skip
all) at dusk; `pause`, then `resume`, `restart` or `quit`, each confirm answered `yes` or `no`;
`restart` at the ending is Play again; `look`. Debug only: `jump <day> <soul> [mercy]` (stamps
every earlier soul to its legal realm, or its worthy one with `mercy`) and `wait <seconds>`.

Time: thinking isn't simulated. The clock moves by action costs (a no-seam pin, a Huginn answer)
plus 20 s per stamp (`STAMP_SECONDS`, charged by `DeskCommands.set_stamp_seconds` on every slot).

- `play.gd`: the command-line entry (a `SceneTree` script).
- `harness.gd`: runs one command and reports what happened.
- `desk_view.gd`: describes the dawn card, the desk, dusk and the ending; lists the actions.
