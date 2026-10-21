# tests/integration/

Tests that instance real scenes, mirroring the source tree.

- `scenes/desk/desk_test.gd` — the desk with the WP1 slice data, driven through its controls'
  signals: pins and threads, the stamp, hit areas, the caption strip, the D48 hold.
- `scenes/desk/desk_hold_test.gd` — a timed day-3 desk (`desk_fixture.gd`): the held soul refuses
  everything but Next soul, the horn's caption, knots clear of hit areas, threads clear of text.
- `scenes/desk/desk_input_test.gd` — real mouse events pushed through the desk's own SubViewport
  (GUT's window covers the root viewport): double-click guards on the confirm, the doors and the
  phase card, and the prompt clear of the doors.

`tools/desk_shots/` replays a full session with real clicks in a window, checks each step and
exits 1 on a failure.
