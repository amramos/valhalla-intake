# Gotchas

Failure modes that cost real time and give a poor or misleading signal. Read this before an editor
session, a test-baseline change or an asset move. Add an entry whenever a trap costs a session;
nothing here is a design rule (ADRs own those).

The first entries are known Godot and GUT traps, carried over from an earlier project.

## Godot editor

**Saving a scene can delete nodes placed inside an instanced scene's interior.** Godot serializes an
instance's interior children only when the instance has *Editable Children*, written as
`[editable path="..."]` at the end of the `.tscn`. Nodes added there by hand or by script run fine
but vanish on the next editor save. A node is at risk when its `parent=` path descends into an
instance *and* it declares its own `type=` or `instance=`. Fix: add the `[editable path]` line; never
delete one; `git restore` a scene that already lost nodes rather than re-adding them by hand.

**Check `git diff` after any editor session.** The editor rewrites resources (reordering, adding
`uid=`), usually harmlessly; the node tree is where the damage happens.

**An exported build can differ from the editor.** Settings and resources the editor shows can be
missing from an export. Test the exported build itself before a release (the release workflow's
smoke test is the minimum).

## Tests and GUT

**GUT silently excludes a script that fails to load.** A test naming a renamed symbol vanishes and the
run stays green. A script count that drops for no visible reason is the only signal — read the
counts whenever the baseline moves.

**A new `class_name` needs `godot --headless --import` before it resolves.** Without it, unrelated
scripts fail with `Nonexistent function 'new' in base 'GDScript'`.

**A fresh clone can fail on "invalid UID".** An asset's uid lives in its git-ignored `.import` file, so
a fresh import may draw a different one than a tracked resource names. Copy the `uid=` from a working
checkout's `.import` into the local one and import again; never edit the tracked resource's `uid=`.

**GUT's `.import` files are tracked here on purpose.** GUT 9.7.1 ships them with uids that match its
own scenes; `.gitignore` excludes every other `.import` but keeps `addons/gut/**/*.import`. A GUT
copied from a project that ignored them logs "invalid UID" on every import until the official ones
are restored.

**Exports exclude `addons/gut/*`.** Packing GUT into a build logs `Cannot set object script` on the
first export from a fresh cache (CI's case), and ships the test framework to players. Keep the
exclusion in both presets.

**`-gselect` is a substring match and takes one pattern.** `-gselect=a_test.gd` can run several
files; a comma list selects nothing useful. Run one file per invocation and read the counts.

**A test that asserts nothing is worse than none.** A guard that skips everything shows up as
"risky" forever and teaches everyone to ignore the count. Collect offenders and assert once.

**A wide tolerance swallows the bug it points at.** Assert exact equality where a value is exact.

**A windowed real-input harness fails when the window loses the OS focus.** The desk pauses every
clock on a focus loss (D35), but a harness's timers and `push_input` events go on: a stamp lands
with its slam frozen, the next soul's evidence never arrives, and desk-shots failed intermittently
(`FORCED Ulf 0.00`) whenever another window or console came forward mid-run. Such a harness hands
the focus straight back in its `_notification` (`tools/desk_shots/desk_shots.gd`).

**A single `print` from a windowed harness is the only timing evidence that survives.** Screenshots
cannot show that a forced wait is short or that the clock is fair; desk-shots prints `FORCED`,
`TELLING` and `DAWN` seconds and `tools/timed_play/` prints the clock left per day, and the
numbers go into the ledger as measurements. A critic scoring stills will mark motion (the
stamp's consequence, the book closing) as absent; read its stamp and dusk scores with that in mind.

## Worktrees and hooks

**In a worktree, the edit hook's Godot parse check runs against the main checkout.** The hook finds
its root from `CLAUDE_PROJECT_DIR` before the edited file's folder, and `.agents/local/godot` lives
only in the main checkout (worktrees do not carry it), so a script that names a `class_name` new to
the worktree fails the parse check with "Could not find type" or "Identifier not declared" while
the worktree itself parses clean. Run the check by hand from the worktree
(`godot --headless --path . --check-only --script <file>` after `--import`) and trust that; the
hook's verdict is advisory there. The same goes for `--import` after adding a `class_name`: run it
in the worktree, not the main checkout.

## Scripts and nodes

**`_ready()` overwrites what a caller set before `add_child()`.** A component that sets a default in
`_ready()` (e.g. `mouse_filter = STOP`) silently clobbers a value its creator set before adding it,
such as a decorative copy set to `IGNORE`. Set defaults in `_init()` or as the property default.

**A lambda that captures a node logs "Lambda capture ... was freed" once the node is freed.** An
`is_instance_valid()` check inside the lambda is too late. Capture a `WeakRef` instead (it bites in
GUT `wait_until` callables).

**The text harness must share the desk's flow, not only its words.** The harness once re-implemented
the phase flow and skipped day 3's dusk; blind testers then reported a gap the game didn't have. The
harness drives `PhaseFlow` and `ScreenText` itself (D13). Reuse them for any new screen.

## Assets and UIDs

**Moving assets invalidates every `uid=` that referenced them.** Strip the stale `uid=` and let Godot
regenerate it; never hand-write one.

**Godot's CSV translation importer claims every `.csv`.** Keep data tables in another format, or set
their import to "keep file".
